# Function to select lambda with smallest rmse
select_lambda_min_rmse <- function(cv_results) {
  # Add error checking
  if(is.null(cv_results)) {
    stop("cv_results is NULL")
  }

  lambda_stats <- cv_results %>%
    dplyr::group_by(lambda) %>%
    dplyr::summarise(
      mean_rmse = mean(sqrt(mse)),
      .groups = 'drop'
    )

  # Select lambda with minimum mean RMSE
  lambda_min_rmse <- lambda_stats %>%
    dplyr::filter(mean_rmse == min(mean_rmse)) %>%
    dplyr::pull(lambda)

  return(lambda_min_rmse)
}



print_log <- function(code) {
  sink("analysis.log", append = TRUE)
  print(eval.parent(code))
  sink()
}
# Impute missing data function
impute_full_dataset <- function(data) {
  data_imputed <- missRanger(data, num.trees = 100, pmm.k = 3)
  return(data_imputed)
}

name_variants <- function(formula) {
  variant_name <- "raw"
  if (any(grepl("UMAP", as.character(formula))))
    variant_name = "UMAP"
  if (any(grepl("PCA", as.character(formula))))
    variant_name = "PCA"
  paste0(as.character(formula[2]), "_", variant_name)
}

# Setup folds -------------------------------------------------------------

create_folds <- function(data, k_folds) {
  # Setup CV folds (using same folds for all models)

  participant_ids <- unique(data$pid)
  split(sample(participant_ids),
        rep(1:k_folds, length.out = length(participant_ids)))
}

# Filter data -------------------------------------------------------------


filter_data <- function(data_imputed, variables_to_remove) {
  # remove variables we don't want for this specific analysis (alternative affective predictors + outcomes)
  # in this code, I am showing the analysis pipeline for one affective state and one outcome
  # the other variables are removed because they are not used in this analysis
  data_filtered <- data_imputed[, !names(data_imputed) %in% variables_to_remove]
  return(data_filtered)
}

# show top loadings for PCs
top_loadings <- function(rotation_matrix, pc_num, n = 10) {
  loadings <- rotation_matrix[, pc_num]
  sorted_idx <- order(abs(loadings), decreasing = TRUE)
  return(data.frame(
    variable = rownames(rotation_matrix)[sorted_idx[1:n]],
    loading = loadings[sorted_idx[1:n]]
  ))
}



# Add pcas ----------------------------------------------------------------

feature_engineering <- function(df) {
  # Create PCA, UMAP, and raw versions of the filtered data
  # identify categorical variables that need dummies

  # Get numeric variables (excluding pid, choice_prop, and stress_state)
  numeric_vars <- names(df)[sapply(df, is.numeric)]
  numeric_vars <- setdiff(numeric_vars, c("pid", "choice_prop", "stress_state"))

  # Get factor variables
  factor_vars <- names(df)[sapply(df, is.factor)]

  #
  # # Create dummies for factor variables, using first level as reference
  dummy_df <- model.matrix(as.formula(paste("~", paste(
    factor_vars, collapse = "+"
  ))), data = df)[, -1]

  # # Add dummy variables to dataset
  df_with_dummies <- cbind(df[c("pid", "stress_state", "choice_prop", numeric_vars)], dummy_df)


  # Run PCA
  pca_result_filtered <- prcomp(df_with_dummies[, setdiff(names(df_with_dummies),
                                                          c("pid", "stress_state", "choice_prop"))], scale. = TRUE)

  # Summary and plots
  print_log(summary(pca_result_filtered))

  # plot(pca_result_filtered, type = "l", main = "Scree Plot")

  # calculate number of PCs for 80% variance
  cum_var <- cumsum(pca_result_filtered$sdev^2) / sum(pca_result_filtered$sdev^2)
  n_pcs <- which(cum_var >= 0.8)[1]
  print_log(paste("Number of PCs needed for 80% variance:", n_pcs))



  for (i in 1:min(n_pcs, 5)) {
    # Show first 5 PCs or fewer if n_pcs < 5
    print_log(paste("Top loadings for PC", i))
    print_log(top_loadings(pca_result_filtered$rotation, i))
  }

  # dataset with PCs using dynamic number of components
  pca_data <- data.frame(pca_result_filtered$x[, 1:n_pcs])
  names(pca_data) <- paste0("PC_", 1:ncol(pca_data))
  #UMAP: https://arxiv.org/abs/2109.02508

  # Create UMAP with same number of components as PCs
  umap_result_filtered <- umap(df_with_dummies[, setdiff(names(df_with_dummies),
                                                         c("pid", "stress_state", "choice_prop"))], n_components = n_pcs)
  umap_data <- data.frame(umap_result_filtered$layout)
  names(umap_data) <- paste0("UMAP_", 1:ncol(umap_data))

  return(data.frame(df_with_dummies, pca_data, umap_data))
}



# Function to flexibly run glmmLasso CV -----------------------------------

run_glmm_cv <- function(data, formula, lambdas = seq(100, 0, by = -5), folds) {

  variant_name <- name_variants(formula)
  cv_results <- list()
  n_predictors <- length(attr(terms(formula), "term.labels"))
  coef_storage <- list()

  # Check inputs
  if(is.null(data)) stop("data is NULL")
  if(is.null(formula)) stop("formula is NULL")
  if(is.null(folds)) stop("folds is NULL")

  data$pid <- as.factor(as.character(data$pid))

  se_by_fold <- do.call(rbind, lapply(folds, function(test_pids){
    # test_pids <- folds[[fold]]
    train_data <- data[!(data$pid %in% test_pids),]
    test_data <- data[data$pid %in% test_pids,]
    do.call(cbind, lapply(lambdas, function(this_lambda){
      fold_model <- suppressWarnings(glmmLasso::glmmLasso(
        formula,
        rnd = list(pid=~1 + stress_state),
        family = gaussian(),
        data = train_data,
        lambda = this_lambda,
        control = list(index = c(NA, rep(1:(n_predictors-1))))))
        ((test_data$choice_prop - predict(fold_model, test_data))^2)
    }))

  }))
  rmses <- sqrt(colMeans(se_by_fold))

  optimal_lambda <- which.min(rmses)
  final_model <- fit_final_glmm(data, formula, optimal_lambda = lambdas[which.min(rmses)])

  return(list(
    rmse = min(rmses),
    optimal_lambda = optimal_lambda,
    final_model = final_model,
    coefficients = coef(final_model)
  ))
}


# Function to run CV for trees and forests --------------------------------
#                   function(data, formula, lambdas = seq(100, 0, by=-5), folds) {
run_forests <- function(data, formula, folds, ...) {
  fold_results <- list()

  library(tuneRanger)
  library(mlr)

  blocks <- factor(data$pid,
                   levels = unlist(folds),
                   labels = unlist(lapply(seq_along(folds), function(i) {
                     rep(i, length(folds[[i]]))
                   })))

  tune_task <- makeRegrTask(data = data[, as.character(attr(terms(formula), "variables"))[-1]],
                            target = as.character(formula[2]),
                            blocking = blocks)

  # Tuning process (takes around 1 minute); Tuning measure is the multiclass brier score
  res_tuned <- tuneRanger(tune_task, measure = list(rmse), ...)
  res_tuned[["rmse"]] <- res_tuned$recommended.pars$rmse[1]
  return(res_tuned)
}

run_tree <- function(data, formula, folds, ...) {
  fold_results <- list()
  frml <- as.formula(paste0(
    as.character(formula[[2]]),
    "~",
    paste0(as.character(attr(
      terms(formula), "variables"
    )), collapse = "+")
  ))

  library(mlr)

  blocks <- factor(data$pid,
                   levels = unlist(folds),
                   labels = unlist(lapply(seq_along(folds), function(i) {
                     rep(i, length(folds[[i]]))
                   })))

  tune_task <- makeRegrTask(data = data[, as.character(attr(terms(formula), "variables"))[-1]],
                            target = as.character(formula[2]),
                            blocking = blocks)


  lrn = makeLearner("regr.rpart")

  control.grid = makeTuneControlGrid()
  #you can pass resolution = N if you want the algorithm to
  #select N tune params given upper and lower bounds to a NumericParam
  #instead of a discrete one
  ps = makeParamSet(makeDiscreteParam("cp", values = c(.001, .005, .01, .02, .04)),
                    makeDiscreteParam("minsplit", values = c(10, 20, 50, 100, 200)))
  resamp = makeResampleDesc("CV", iters = length(folds), blocking.cv = TRUE)
  #and the actual tuning, with accuracy as evaluation metric
  res = tuneParams(
    lrn,
    task = tune_task,
    control = control.grid,
    par.set = ps,
    measures = list(rmse),
    resampling = resamp
  )
  tuned_pars = as.data.frame(res$opt.path)
  out <- list(rmse = min(tuned_pars$rmse.test.rmse))

  tuned_pars <- lapply(tuned_pars[which.min(tuned_pars$rmse.test.rmse), c("cp", "minsplit")], function(x) {
    as.numeric(as.character(x))
  })

  lrn = mlr::makeLearner("regr.rpart", par.vals = tuned_pars, predict.type = "response")
  out$final_model <- mlr::train(lrn, tune_task)
  return(out)
}


# Define all formulas -----------------------------------------------------

define_formulas <- function(yvars = "coice_prop",
                            xvars = setdiff(names(df_analysis), c("pid", "stress_state", "choice_prop"))) {
  # Define formulas with dynamic number of components
  pca_terms <- grep("^PC_", xvars, value = TRUE)

  pca_interactions <- paste0("stress_state:", pca_terms)
  pca_formulas <- lapply(yvars, function(y) {
    paste(y, "~ stress_state +", paste(c(pca_terms, pca_interactions), collapse = " + "))
  })

  umap_terms <- grep("^UMAP_", xvars, value = TRUE)
  umap_interactions <- paste0("stress_state:", umap_terms)
  umap_formulas <- lapply(yvars, function(y) {
    paste(y, "~ stress_state +", paste(c(umap_terms, umap_interactions), collapse = " + "))
  })

  # Create formula using raw variables
  raw_vars <- setdiff(xvars, c(pca_terms, umap_terms))
  raw_interactions <- expand.grid(var = raw_vars, stress = "stress_state") |> apply(MARGIN = 1,
                                                                                    FUN = paste0,
                                                                                    collapse = ":")

  raw_formulas <- lapply(yvars, function(y) {
    paste(y, "~ stress_state +", paste(c(raw_vars, raw_interactions), collapse = " + "))
  })

  out <- c(pca_formulas, umap_formulas, raw_formulas)
  return(lapply(out, as.formula))
}

# Fit final models using optimal lambda on full dataset  -----------------------------------------------------

fit_final_glmm <- function(data, formula, optimal_lambda) {
  n_predictors <- length(attr(terms(formula), "term.labels"))

  final_model <- suppressWarnings(glmmLasso::glmmLasso(
    formula,
    rnd = list(pid = ~1 + stress_state),
    family = gaussian(),
    data = data,
    lambda = optimal_lambda,
    control = list(index = c(NA, rep(1:(n_predictors-1))))
  ))

  return(final_model)
}

