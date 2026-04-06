print_log <- function(code) {
  sink("analysis.log", append = TRUE)
  print(eval.parent(code))
  sink()
}

# Renaming and preparing data for consistency with preregistered code

rename_and_prepare_data <- function(data, predictor_col, predictor_name, predictor_is_binary = FALSE) {
  data_renamed <- data %>%
    rename(
      pid = subject,
      choice_prop = prop_alc_responses
    )

  # Rename predictor column if it has a different name in the raw data
  if (predictor_col != predictor_name) {
    data_renamed <- data_renamed %>% rename(!!predictor_name := !!predictor_col)
  }

  # Convert character columns to factors
  char_cols <- sapply(data_renamed, is.character)
  data_renamed[char_cols] <- lapply(data_renamed[char_cols], as.factor)

  # Convert to numeric (0/1) if the predictor is binary
  if (predictor_is_binary) {
    data_renamed[[predictor_name]] <- as.numeric(data_renamed[[predictor_name]] == "Yes")
  }

  return(data_renamed)
}

# Impute missing data
impute_full_dataset <- function(data) {
  data_imputed <- missRanger(data, num.trees = 100, pmm.k = 3)
  return(data_imputed)
}

name_variants <- function(formula) {
  variant_name <- "raw"
  if (any(grepl("PC_", as.character(formula))))
    variant_name = "PCA"
  else if (any(grepl("UMAP_", as.character(formula))))
    variant_name = "UMAP"
  paste0(as.character(formula[2]), "_", variant_name)
}

# Setup folds
create_folds <- function(data, k_folds) {
  participant_ids <- unique(data$pid)
  split(sample(participant_ids),
        rep(1:k_folds, length.out = length(participant_ids)))
}

# Filter data
filter_data <- function(data_imputed, variables_to_remove) {
  data_filtered <- data_imputed[, !names(data_imputed) %in% variables_to_remove]
  return(data_filtered)
}

# Show top loadings for PCs
top_loadings <- function(rotation_matrix, pc_num, n = 10) {
  loadings <- rotation_matrix[, pc_num]
  sorted_idx <- order(abs(loadings), decreasing = TRUE)
  return(data.frame(
    variable = rownames(rotation_matrix)[sorted_idx[1:n]],
    loading = loadings[sorted_idx[1:n]]
  ))
}

# Feature engineering (PCA, UMAP, dummies)

feature_engineering <- function(df, outcome, predictor) {
  # Get numeric variables (excluding pid, outcome, and predictor)
  numeric_vars <- names(df)[sapply(df, is.numeric)]
  numeric_vars <- setdiff(numeric_vars, c("pid", outcome, predictor))

  # Get factor variables
  factor_vars <- names(df)[sapply(df, is.factor)]

  # Create dummies for factor variables, using first level as reference
  dummy_df <- model.matrix(as.formula(paste("~", paste(
    factor_vars, collapse = "+"
  ))), data = df)[, -1]

  # Add dummy variables to dataset
  df_with_dummies <- cbind(df[c("pid", predictor, outcome, numeric_vars)], dummy_df)

  # Get variables for PCA/UMAP (exclude pid, predictor, outcome)
  vars_for_reduction <- setdiff(names(df_with_dummies), c("pid", predictor, outcome))

  # Run PCA
  pca_result_filtered <- prcomp(df_with_dummies[, vars_for_reduction], scale. = TRUE)

  print_log(summary(pca_result_filtered))

  # Calculate number of PCs for 80% variance
  cum_var <- cumsum(pca_result_filtered$sdev^2) / sum(pca_result_filtered$sdev^2)
  n_pcs <- min(which(cum_var >= 0.8)[1], 5)
  print_log(paste("Number of PCs needed for 80% variance:", n_pcs))

  for (i in 1:min(n_pcs, 5)) {
    print_log(paste("Top loadings for PC", i))
    print_log(top_loadings(pca_result_filtered$rotation, i))
  }

  # Dataset with PCs
  pca_data <- data.frame(pca_result_filtered$x[, 1:n_pcs])
  names(pca_data) <- paste0("PC_", 1:ncol(pca_data))

  # Create UMAP
  umap_result_filtered <- umap(df_with_dummies[, vars_for_reduction], n_components = n_pcs)
  umap_data <- data.frame(umap_result_filtered$layout)
  names(umap_data) <- paste0("UMAP_", 1:ncol(umap_data))

  # Scale
  pca_data <- data.frame(scale(pca_data))
  umap_data <- data.frame(scale(umap_data))

  return(data.frame(df_with_dummies, pca_data, umap_data))
}

# glmmLasso with CV

run_glmm_cv <- function(data, formula, outcome, predictor,
                         lambdas = seq(100, 0, by = -5), folds) {

  variant_name <- name_variants(formula)
  n_predictors <- length(attr(terms(formula), "term.labels"))

  if(is.null(data)) stop("data is NULL")
  if(is.null(formula)) stop("formula is NULL")
  if(is.null(folds)) stop("folds is NULL")

  data$pid <- as.factor(as.character(data$pid))

  # Build random effects formula
  rnd_formula <- as.formula(paste0("~1 + ", predictor))
  rnd_list <- setNames(list(rnd_formula), "pid")

  all_se <- list()
  fold_mses <- matrix(NA, nrow = length(folds), ncol = length(lambdas))

  # I rewrote this to store se by fold for each lambda, in case that is useful later

  for (k in seq_along(folds)) {
    test_pids <- folds[[k]]
    train_data <- data[!(data$pid %in% test_pids), ]
    test_data  <- data[data$pid %in% test_pids, ]

    fold_se <- do.call(cbind, lapply(lambdas, function(this_lambda) {
      fold_model <- suppressWarnings(glmmLasso::glmmLasso(
        formula,
        rnd = rnd_list,
        family = gaussian(),
        data = train_data,
        lambda = this_lambda,
        control = list(index = c(NA, rep(1:(n_predictors - 1))))))
      (test_data[[outcome]] - predict(fold_model, test_data))^2
    }))
    all_se[[k]] <- fold_se
    fold_mses[k, ] <- colMeans(fold_se)  # mean SE per fold per lambda
  }

  # Pooled RMSE across all test observations
  se_pooled <- do.call(rbind, all_se)
  rmses <- sqrt(colMeans(se_pooled))

  # Fold-level RMSEs and their SD
  fold_rmses <- sqrt(fold_mses)
  rmse_sds <- apply(fold_rmses, 2, sd)

  optimal_lambda <- which.min(rmses)
  final_model <- fit_final_glmm(data, formula, predictor,
                                 optimal_lambda = lambdas[which.min(rmses)])

  return(list(
    rmse = min(rmses),
    optimal_lambda = optimal_lambda,
    final_model = final_model,
    coefficients = coef(final_model),
    all_rmses = rmses,                             # RMSE at every lambda
    all_rmse_sds = rmse_sds,                       # SD of fold-level RMSEs
    mse_cv = fold_mses[, optimal_lambda]           # fold-level MSEs at optimal lambda
  ))
}

# Fit final glmm on full dataset
fit_final_glmm <- function(data, formula, predictor, optimal_lambda) {
  n_predictors <- length(attr(terms(formula), "term.labels"))

  rnd_formula <- as.formula(paste0("~1 + ", predictor))
  rnd_list <- setNames(list(rnd_formula), "pid")

  final_model <- suppressWarnings(glmmLasso::glmmLasso(
    formula,
    rnd = rnd_list,
    family = gaussian(),
    data = data,
    lambda = optimal_lambda,
    control = list(index = c(NA, rep(1:(n_predictors-1))))
  ))

  return(final_model)
}

# Random forests
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

  res_tuned <- tuneRanger(tune_task, measure = list(rmse), ...)
  res_tuned[["rmse"]] <- res_tuned$recommended.pars$rmse[1]
  return(res_tuned)
}

# Decision tree with tuning
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
  ps = makeParamSet(makeDiscreteParam("cp", values = c(.001, .005, .01, .02, .04)),
                    makeDiscreteParam("minsplit", values = c(10, 20, 50, 100, 200)))
  resamp = makeResampleDesc("CV", iters = length(folds), blocking.cv = TRUE)
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

# Define formulas
# predictor: the predictor variable name (used for interactions and exclusion)
define_formulas <- function(yvars, predictor,
                            xvars) {
  pca_terms <- grep("^PC_", xvars, value = TRUE)

  pca_interactions <- paste0(predictor, ":", pca_terms)
  pca_formulas <- lapply(yvars, function(y) {
    paste(y, "~", predictor, "+", paste(c(pca_terms, pca_interactions), collapse = " + "))
  })

  umap_terms <- grep("^UMAP_", xvars, value = TRUE)
  umap_interactions <- paste0(predictor, ":", umap_terms)
  umap_formulas <- lapply(yvars, function(y) {
    paste(y, "~", predictor, "+", paste(c(umap_terms, umap_interactions), collapse = " + "))
  })

  raw_vars <- setdiff(xvars, c(pca_terms, umap_terms))
  raw_interactions <- expand.grid(var = raw_vars, stress = predictor) |> apply(MARGIN = 1,
                                                                                FUN = paste0,
                                                                                collapse = ":")

  raw_formulas <- lapply(yvars, function(y) {
    paste(y, "~", predictor, "+", paste(c(raw_vars, raw_interactions), collapse = " + "))
  })

  out <- c(pca_formulas, umap_formulas, raw_formulas)
  return(lapply(out, as.formula))
}
