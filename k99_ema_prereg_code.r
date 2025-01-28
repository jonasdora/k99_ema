# Impute missing data function
impute_full_dataset <- function(data) {
  data_imputed <- missRanger(
    data,
    num.trees = 100,
    pmm.k = 3,
    seed = 123
  )
  return(data_imputed)
}

# set seed for reproducibility

set.seed(123)

# simulating data

n_participants <- 250
n_obs_per_participant <- 40
n_total <- n_participants * n_obs_per_participant

# Create person-level tendencies to make data a bit sensible (low-effort)
# I'm just doing this to end up with fewer PCs in the end in this simulated example.
# The data are still not very realistic, but that's ok, I'm just focusing on the structure of the dataset to be able to
# write the analysis code

person_data <- data.frame(
  pid = 1:n_participants,
  consumption = rnorm(n_participants, 0, 5),
  affect = rnorm(n_participants, 0, 5)
)

# Create dataset
data <- data.frame(
  pid = rep(1:n_participants, each = n_obs_per_participant)
) %>%
  left_join(person_data, by="pid") %>%
  mutate(
    consumption_state = consumption + rnorm(n_total, 0, 0.1),
    affect_state = affect + rnorm(n_total, 0, 0.1),

    stress_binary = factor(rbinom(n_total, 1, plogis(3 * affect_state)), labels = c("no", "yes")),
    stress_event_type = case_when(
      stress_binary == "yes" ~ factor(sample(paste0("type", 1:7), n_total, replace=TRUE)),
      TRUE ~ NA_character_
    ),
    stress_event_intensity = case_when(
      stress_binary == "yes" ~ pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),
      TRUE ~ NA_real_
    ),

    stress_state = pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),
    thirst_state = pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),
    hunger_state = pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),
    tired_state = pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),
    bored_state = pmax(0, pmin(4, 2 + affect_state + rnorm(n_total, 0, 0.1))),

    alc_yday = pmax(0, round(5 + consumption_state + rnorm(n_total, 0, 0.1))),
    alc_today = pmax(0, round(5 + consumption_state + rnorm(n_total, 0, 0.1))),
    alc_intend = pmax(0, round(5 + consumption_state + rnorm(n_total, 0, 0.1))),
    alc_craving = pmax(0, round(2 + consumption_state + rnorm(n_total, 0, 0.1))),

    alc_exp_relaxed = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_social = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_buzz = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_mood = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_energetic = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_hangover = factor(rbinom(n_total, 1, plogis(-3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_embar = factor(rbinom(n_total, 1, plogis(-3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_rude = factor(rbinom(n_total, 1, plogis(-3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_vomit = factor(rbinom(n_total, 1, plogis(-3 * consumption_state)), labels = c("no", "yes")),
    alc_exp_injure = factor(rbinom(n_total, 1, plogis(-3 * consumption_state)), labels = c("no", "yes")),

    alc_mot_coping = factor(rbinom(n_total, 1, plogis(3 * affect_state)), labels = c("no", "yes")),
    alc_mot_social = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),
    alc_mot_enhance = factor(rbinom(n_total, 1, plogis(3 * consumption_state)), labels = c("no", "yes")),

    time_of_day = factor(sample(c("afternoon", "evening"), n_total, replace=TRUE)),
    location = factor(sample(c("home", "other"), n_total, replace=TRUE)),
    social = factor(sample(c("alone", "other"), n_total, replace=TRUE)),
    alc_cue = factor(sample(c("no", "yes"), n_total, replace=TRUE)),
    responsibility = factor(sample(c("no", "yes"), n_total, replace=TRUE)),

    choice_prop = pmax(0, pmin(1, 0.5 + 0.3 * consumption_state + 0.2 * affect_state + rnorm(n_total, 0, 0.1))),
    boundary = pmax(0, pmin(4, 2 + 0.5 * affect_state + rnorm(n_total, 0, 0.1))),
    drift = pmax(0, pmin(4, 2 + 0.5 * consumption_state + rnorm(n_total, 0, 0.1))),
    bias = pmax(-2, pmin(2, 0.3 * consumption_state + 0.2 * affect_state + rnorm(n_total, 0, 0.1)))
  ) %>%
  select(-consumption_state, -affect_state)

# Introduce missingness for imputation(very lazy)
for(p in unique(data$pid)) {
  missing_rows <- sample(which(data$pid == p), 10)
  data[missing_rows, !(names(data) %in% c("pid", "consumption", "affect"))] <- NA
}

# Remove made up tendencies
data$consumption <- NULL
data$affect <- NULL

# Function to select largest lambda within 1se of smallest mse (thanks, Caspar!)
select_lambda_1se <- function(cv_results) {
  lambda_stats <- cv_results %>%
    group_by(lambda) %>%
    summarise(
      mean_mse = mean(mse),
      se_mse = sd(mse) / sqrt(n()),
      .groups = 'drop'
    )
  min_mse <- min(lambda_stats$mean_mse)
  min_mse_se <- lambda_stats$se_mse[which.min(lambda_stats$mean_mse)]
  lambda_1se <- lambda_stats %>%
    filter(mean_mse <= min_mse + min_mse_se) %>%
    pull(lambda) %>%
    max()
  return(lambda_1se)
}



# impute the full dataset with all variables
data_imputed <- impute_full_dataset(data)

# remove variables we don't want for this specific analysis (alternative affective predictors + outcomes)
# in this code, I am showing the analysis pipeline for one affective state and one outcome
# the other variables are removed because they are not used in this analysis
variables_to_remove <- c("stress_binary", "stress_event_type", "stress_event_intensity",
                         "PA_state", "NA_state", "boundary", "drift", "bias")
data_filtered <- data_imputed[, !names(data_imputed) %in% variables_to_remove]
# Create PCA, UMAP, and raw versions of the filtered data
# identify categorical variables that need dummies
factor_vars <- names(data_filtered)[sapply(data_filtered, is.factor)]
dummy_data_filtered <- predict(dummyVars(as.formula(paste("~", paste(factor_vars, collapse = "+"))),
                                         data = data_filtered),
                               newdata = data_filtered)

# Get numeric variables (excluding pid, choice_prop, and stress_state)
numeric_vars <- names(data_filtered)[sapply(data_filtered, is.numeric)]
numeric_vars <- setdiff(numeric_vars, c("pid", "choice_prop", "stress_state"))

# Combine for dimension reduction
pca_input_filtered <- cbind(dummy_data_filtered, data_filtered[numeric_vars])
# Run PCA
pca_result_filtered <- prcomp(pca_input_filtered, scale. = TRUE)

# Summary and plots
print(summary(pca_result_filtered))
plot(pca_result_filtered, type = "l", main = "Scree Plot")

# calculate number of PCs for 80% variance
cum_var <- cumsum(pca_result_filtered$sdev^2)/sum(pca_result_filtered$sdev^2)
n_pcs <- which(cum_var >= 0.8)[1]
print(paste("Number of PCs needed for 80% variance:", n_pcs))

# show top loadings for these PCs
top_loadings <- function(rotation_matrix, pc_num, n=10) {
  loadings <- rotation_matrix[,pc_num]
  sorted_idx <- order(abs(loadings), decreasing=TRUE)
  return(data.frame(
    variable = rownames(rotation_matrix)[sorted_idx[1:n]],
    loading = loadings[sorted_idx[1:n]]
  ))
}

for(i in 1:min(n_pcs, 5)) {  # Show first 5 PCs or fewer if n_pcs < 5
  print(paste("Top loadings for PC", i))
  print(top_loadings(pca_result_filtered$rotation, i))
}

# dataset with PCs using dynamic number of components
data_filtered_with_pcs <- data.frame(
  pid = data_filtered$pid,
  stress_state = data_filtered$stress_state,
  choice_prop = data_filtered$choice_prop
)
# Add PCs
for(i in 1:n_pcs) {
  data_filtered_with_pcs[[paste0("PC", i)]] <- pca_result_filtered$x[,i]
}

#UMAP: https://arxiv.org/abs/2109.02508

# Create UMAP with same number of components as PCs
umap_result_filtered <- umap(pca_input_filtered, n_components = n_pcs)
data_filtered_with_umap <- data.frame(
  pid = data_filtered$pid,
  stress_state = data_filtered$stress_state,
  choice_prop = data_filtered$choice_prop
)
# Add UMAP components
for(i in 1:n_pcs) {
  data_filtered_with_umap[[paste0("UMAP", i)]] <- umap_result_filtered$layout[,i]
}

# Get valid factors and numeric variables (excluding outcome, predictor, and ID) for raw analysis
numeric_vars <- names(data_filtered)[sapply(data_filtered, is.numeric)]
numeric_vars <- setdiff(numeric_vars, c("pid", "choice_prop", "stress_state"))

# Get factor variables
factor_vars <- names(data_filtered)[sapply(data_filtered, is.factor)]

# Create dummies for factor variables, using first level as reference
dummy_matrix <- model.matrix(as.formula(paste("~", paste(factor_vars, collapse = "+"))),
                             data = data_filtered)
# Remove intercept column
dummy_data <- dummy_matrix[, -1]

# Add dummy variables to dataset
data_filtered_with_dummies <- cbind(data_filtered[c("pid", "stress_state", "choice_prop", numeric_vars)],
                                    as.data.frame(dummy_data))

# next, I will run the LASSO

# Setup CV folds (using same folds for all models)
k_folds <- 5
participant_ids <- unique(data$pid)
fold_ids <- split(sample(participant_ids), rep(1:k_folds, length.out=length(participant_ids)))

# specify values of lambda to try, glmmLasso documentation advised to start high and go down
# https://github.com/cran/glmmLasso/blob/master/demo/glmmLasso-soccer.r; possibly need to increase above 100 later
lambdas <- seq(100, 0, by=-5)

# Function to flexibly run glmmLasso CV with PCA, UMAP, or raw variables
run_glmm_cv <- function(data, formula, variant_name) {
  cv_results <- list()
  n_predictors <- length(attr(terms(formula), "term.labels"))
  coef_storage <- list()

  for(fold in 1:k_folds) {
    test_pids <- fold_ids[[fold]]
    train_data <- data[!(data$pid %in% test_pids),]
    test_data <- data[data$pid %in% test_pids,]

    for(j in 1:length(lambdas)) {
      print(paste(variant_name, "lambda iteration:", j, "of", length(lambdas)))

      fold_model <- try(glmmLasso(formula,
                                  rnd = list(pid = ~1 + stress_state),
                                  family = gaussian(),
                                  data = train_data,
                                  lambda = lambdas[j],
                                  control = list(index = c(NA, rep(1:(n_predictors-1))))),
                        silent = TRUE)

      if(!inherits(fold_model, "try-error")) {
        cv_results[[paste0("lambda_", j, "_fold_", fold)]] <-
          data.frame(lambda = lambdas[j],
                     fold = fold,
                     variant = variant_name,
                     mse = mean((test_data$choice_prop - predict(fold_model, test_data))^2))

        coef_storage[[paste0("lambda_", j, "_fold_", fold)]] <-
          data.frame(
            lambda = lambdas[j],
            fold = fold,
            coefficient = names(fold_model$coefficients),
            value = as.numeric(fold_model$coefficients)
          )
      }
    }
  }

  cv_df <- do.call(rbind, cv_results)
  optimal_lambda <- select_lambda_1se(cv_df)

  return(list(
    cv_results = cv_results,
    optimal_lambda = optimal_lambda,
    coefficients = do.call(rbind, coef_storage)
  ))
}

# Define formulas with dynamic number of components
pca_terms <- paste0("PC", 1:n_pcs)
pca_interactions <- paste0("stress_state:", pca_terms)
pca_formula <- as.formula(paste("choice_prop ~ stress_state +",
                                paste(c(pca_terms, pca_interactions), collapse = " + ")))

umap_terms <- paste0("UMAP", 1:n_pcs)
umap_interactions <- paste0("stress_state:", umap_terms)
umap_formula <- as.formula(paste("choice_prop ~ stress_state +",
                                 paste(c(umap_terms, umap_interactions), collapse = " + ")))

# Create formula using raw variables
raw_vars <- c(numeric_vars, colnames(dummy_data))
raw_interactions <- expand.grid(
  var = raw_vars,
  stress = "stress_state"
) %>%
  mutate(interaction = paste(var, stress, sep=":"))

raw_formula <- as.formula(paste("choice_prop ~ stress_state +",
                                paste(c(raw_vars, raw_interactions$interaction), collapse = " + ")))

data_filtered_with_dummies$pid <- as.factor(as.character(data_filtered_with_dummies$pid))
data_filtered_with_pcs$pid <- as.factor(as.character(data_filtered_with_pcs$pid))
data_filtered_with_umap$pid <- as.factor(as.character(data_filtered_with_umap$pid))


# Run glmmLasso analyses
raw_results <- run_glmm_cv(data_filtered_with_dummies, raw_formula, "raw")
pca_results <- run_glmm_cv(data_filtered_with_pcs, pca_formula, "pca")
umap_results <- run_glmm_cv(data_filtered_with_umap, umap_formula, "umap")

# Process results for all
all_results <- list(
  raw = raw_results,
  pca = pca_results,
  umap = umap_results
)

results_summary <- lapply(names(all_results), function(variant) {
  result <- all_results[[variant]]
  cv_df <- do.call(rbind, result$cv_results)

  # Summarize results
  data.frame(
    model = paste0("glmm_", variant),
    mean_rmse = sqrt(mean(cv_df$mse)),
    sd_rmse = sd(sqrt(cv_df$mse)),
    min_rmse = min(sqrt(cv_df$mse)),
    max_rmse = max(sqrt(cv_df$mse)),
    optimal_lambda = result$optimal_lambda
  )
}) %>% bind_rows()

# Prepare for non-linear models

# Initialize storage for tree/forest results
nonlinear_results <- list()

# Define simpler formulas for nonlinear models
# PCA
pca_nonlinear_formula <- choice_prop ~ stress_state +
  PC1 + PC2 + PC3 + PC4  # Adjust number based on n_pcs

# UMAP
umap_nonlinear_formula <- choice_prop ~ stress_state +
  UMAP1 + UMAP2 + UMAP3 + UMAP4  # Adjust number based on n_pcs

# Raw (use all predictors but no need to specify interactions)
raw_nonlinear_formula <- as.formula(paste("choice_prop ~ stress_state +",
                                          paste(raw_vars, collapse = " + ")))

# Function to run CV for trees and forests
run_nonlinear_cv <- function(data, formula, method, variant_name) {
  fold_results <- list()

  for(fold in 1:k_folds) {
    # Split data using same folds as glmmLasso
    test_pids <- fold_ids[[fold]]
    train_data <- data[!(data$pid %in% test_pids),]
    test_data <- data[data$pid %in% test_pids,]

    # Fit model and get predictions based on method
    if(method == "forest") {
      model <- ranger(formula,
                      data = train_data,
                      importance = 'permutation')
      predictions <- predict(model, test_data)$predictions
      model_name <- paste0("rf_", variant_name)
    } else if(method == "tree") {
      model <- rpart(formula,
                     data = train_data,
                     method = "anova")
      predictions <- predict(model, test_data)
      model_name <- paste0("tree_", variant_name)
    }

    # Store results
    fold_results[[fold]] <- data.frame(
      fold = fold,
      model = model_name,
      rmse = sqrt(mean((test_data$choice_prop - predictions)^2))
    )
  }
  return(do.call(rbind, fold_results))
}

# Run all combinations with new formulas
# 1. Random Forest
nonlinear_results[["rf_pca"]] <- run_nonlinear_cv(data_filtered_with_pcs, pca_nonlinear_formula, "forest", "pca")
nonlinear_results[["rf_umap"]] <- run_nonlinear_cv(data_filtered_with_umap, umap_nonlinear_formula, "forest", "umap")
nonlinear_results[["rf_raw"]] <- run_nonlinear_cv(data_filtered_with_dummies, raw_nonlinear_formula, "forest", "raw")

# 2. Decision Trees
nonlinear_results[["tree_pca"]] <- run_nonlinear_cv(data_filtered_with_pcs, pca_nonlinear_formula, "tree", "pca")
nonlinear_results[["tree_umap"]] <- run_nonlinear_cv(data_filtered_with_umap, umap_nonlinear_formula, "tree", "umap")
nonlinear_results[["tree_raw"]] <- run_nonlinear_cv(data_filtered_with_dummies, raw_nonlinear_formula, "tree", "raw")

# Process nonlinear results
nonlinear_summary <- do.call(rbind, nonlinear_results) %>%
  group_by(model) %>%
  summarise(
    mean_rmse = mean(rmse),
    sd_rmse = sd(rmse),
    min_rmse = min(rmse),
    max_rmse = max(rmse)
  )

# Combine LASSO and nonlinear results
final_comparison <- bind_rows(
  results_summary,
  nonlinear_summary
) %>%
  mutate(percent_diff = (results_summary$mean_rmse[1] - mean_rmse) / results_summary$mean_rmse[1] * 100) %>%
  arrange(mean_rmse)

# Plot final comparison
final_comparison %>%
  separate(model, into = c("method", "var_type"), sep = "_") %>%
  ggplot(aes(x = var_type, y = mean_rmse, fill = method)) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = mean_rmse - sd_rmse,
                    ymax = mean_rmse + sd_rmse),
                position = position_dodge(0.9),
                width = 0.25) +
  theme_minimal() +
  labs(title = "Model Performance by Method and Variable Type",
       x = "Variable Type",
       y = "Mean RMSE")

print(final_comparison)
