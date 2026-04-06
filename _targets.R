
# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

set.seed(738298156)
options(scipen=999)

if(file.exists("analysis.log")) file.remove("analysis.log")

# Set target options:
tar_option_set(
  packages = c("worcs", "tibble", "tidyverse", "glmmLasso", "caret", "ranger", "rpart", "umap", "missRanger", "tuneRanger", "mlr")
)

# Replace the target list below with your own:
list(
  # ========== COMMON DATA PREPARATION ==========
  tar_target(
    name = data,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      load_data(to_envir = FALSE)[["data"]]
    }
  ),
  tar_target(
    name = data_renamed,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      rename_and_prepare_data(data)
    }
  ),
  tar_target(
    name = data_imputed,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      impute_full_dataset(data_renamed)
    }
  ),

  # ========== CHOICE_PROP ANALYSIS ==========
  tar_target(
    name = data_filtered_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      filter_data(data_imputed, variables_to_remove = c("alcbias", "median_rt", "drift", "B"))
    }
  ),
  tar_target(
    name = df_analysis_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      feature_engineering(data_filtered_choice_prop)
    }
  ),
  tar_target(
    name = folds_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      create_folds(df_analysis_choice_prop, k_folds = 5)
    }
  ),
  tar_target(
    name = all_formulas_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      define_formulas(yvars = "choice_prop", xvars = setdiff(names(df_analysis_choice_prop), c("pid", "stress_binary", "choice_prop")))
    }
  ),
  tar_target(
    name = all_glmms_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      lapply(all_formulas_choice_prop, function(f){
        run_glmm_cv(data = df_analysis_choice_prop, formula = f,
                    lambdas = seq(100, 0, by=-5),
                    folds = folds_choice_prop)
      })
    }
  ),
  tar_target(
    name = all_forests_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      lapply(all_formulas_choice_prop, function(f){
        run_forests(data = df_analysis_choice_prop, formula = f, folds = folds_choice_prop, num.trees = 500, iters = 10)
      })
    }
  ),
  tar_target(
    name = all_trees_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      lapply(all_formulas_choice_prop, function(f){
        run_tree(data = df_analysis_choice_prop, formula = f, folds = folds_choice_prop)
      })
    }
  ),
  tar_target(
    name = tab_fits_choice_prop,
    command = {
      source("R/_functions_choice_prop_stress_event.R")
      data.frame(
        outcome = "choice_prop",
        model = rep(sapply(all_formulas_choice_prop, name_variants), 3),
        method = rep(c("forest", "tree", "glmm"), each = 3),
        rmse = sapply(c(all_forests_choice_prop, all_trees_choice_prop, all_glmms_choice_prop), `[[`, "rmse")
      )
    }
  ),
  tar_target(
    name = fl_tab_fits_choice_prop,
    command = {
      write.csv(tab_fits_choice_prop, "tab_fits_choice_prop.csv", row.names = FALSE)
      "tab_fits_choice_prop.csv"
    },
    format = "file"
  ),

  # ========== MEDIAN_RT ANALYSIS ==========
  tar_target(
    name = data_filtered_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      filter_data(data_imputed, variables_to_remove = c("alcbias", "choice_prop", "drift", "B"))
    }
  ),
  tar_target(
    name = df_analysis_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      feature_engineering(data_filtered_median_rt)
    }
  ),
  tar_target(
    name = folds_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      create_folds(df_analysis_median_rt, k_folds = 5)
    }
  ),
  tar_target(
    name = all_formulas_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      define_formulas(yvars = "median_rt", xvars = setdiff(names(df_analysis_median_rt), c("pid", "stress_binary", "median_rt")))
    }
  ),
  tar_target(
    name = all_glmms_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      lapply(all_formulas_median_rt, function(f){
        run_glmm_cv(data = df_analysis_median_rt, formula = f,
                    lambdas = seq(100, 0, by=-5),
                    folds = folds_median_rt)
      })
    }
  ),
  tar_target(
    name = all_forests_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      lapply(all_formulas_median_rt, function(f){
        run_forests(data = df_analysis_median_rt, formula = f, folds = folds_median_rt, num.trees = 500, iters = 10)
      })
    }
  ),
  tar_target(
    name = all_trees_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      lapply(all_formulas_median_rt, function(f){
        run_tree(data = df_analysis_median_rt, formula = f, folds = folds_median_rt)
      })
    }
  ),
  tar_target(
    name = tab_fits_median_rt,
    command = {
      source("R/_functions_median_rt_stress_event.R")
      data.frame(
        outcome = "median_rt",
        model = rep(sapply(all_formulas_median_rt, name_variants), 3),
        method = rep(c("forest", "tree", "glmm"), each = 3),
        rmse = sapply(c(all_forests_median_rt, all_trees_median_rt, all_glmms_median_rt), `[[`, "rmse")
      )
    }
  ),
  tar_target(
    name = fl_tab_fits_median_rt,
    command = {
      write.csv(tab_fits_median_rt, "tab_fits_median_rt.csv", row.names = FALSE)
      "tab_fits_median_rt.csv"
    },
    format = "file"
  ),

  # ========== DRIFT ANALYSIS ==========
  tar_target(
    name = data_filtered_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      filter_data(data_imputed, variables_to_remove = c("alcbias", "choice_prop", "median_rt", "B"))
    }
  ),
  tar_target(
    name = df_analysis_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      feature_engineering(data_filtered_drift)
    }
  ),
  tar_target(
    name = folds_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      create_folds(df_analysis_drift, k_folds = 5)
    }
  ),
  tar_target(
    name = all_formulas_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      define_formulas(yvars = "drift", xvars = setdiff(names(df_analysis_drift), c("pid", "stress_binary", "drift")))
    }
  ),
  tar_target(
    name = all_glmms_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      lapply(all_formulas_drift, function(f){
        run_glmm_cv(data = df_analysis_drift, formula = f,
                    lambdas = seq(100, 0, by=-5),
                    folds = folds_drift)
      })
    }
  ),
  tar_target(
    name = all_forests_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      lapply(all_formulas_drift, function(f){
        run_forests(data = df_analysis_drift, formula = f, folds = folds_drift, num.trees = 500, iters = 10)
      })
    }
  ),
  tar_target(
    name = all_trees_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      lapply(all_formulas_drift, function(f){
        run_tree(data = df_analysis_drift, formula = f, folds = folds_drift)
      })
    }
  ),
  tar_target(
    name = tab_fits_drift,
    command = {
      source("R/_functions_drift_stress_event.R")
      data.frame(
        outcome = "drift",
        model = rep(sapply(all_formulas_drift, name_variants), 3),
        method = rep(c("forest", "tree", "glmm"), each = 3),
        rmse = sapply(c(all_forests_drift, all_trees_drift, all_glmms_drift), `[[`, "rmse")
      )
    }
  ),
  tar_target(
    name = fl_tab_fits_drift,
    command = {
      write.csv(tab_fits_drift, "tab_fits_drift.csv", row.names = FALSE)
      "tab_fits_drift.csv"
    },
    format = "file"
  ),

  # ========== ALCBIAS ANALYSIS ==========
  tar_target(
    name = data_filtered_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      filter_data(data_imputed, variables_to_remove = c("choice_prop", "median_rt", "drift", "B"))
    }
  ),
  tar_target(
    name = df_analysis_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      feature_engineering(data_filtered_alcbias)
    }
  ),
  tar_target(
    name = folds_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      create_folds(df_analysis_alcbias, k_folds = 5)
    }
  ),
  tar_target(
    name = all_formulas_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      define_formulas(yvars = "alcbias", xvars = setdiff(names(df_analysis_alcbias), c("pid", "stress_binary", "alcbias")))
    }
  ),
  tar_target(
    name = all_glmms_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      lapply(all_formulas_alcbias, function(f){
        run_glmm_cv(data = df_analysis_alcbias, formula = f,
                    lambdas = seq(200, 0, by=-10),
                    folds = folds_alcbias)
      })
    }
  ),
  tar_target(
    name = all_forests_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      lapply(all_formulas_alcbias, function(f){
        run_forests(data = df_analysis_alcbias, formula = f, folds = folds_alcbias, num.trees = 500, iters = 10)
      })
    }
  ),
  tar_target(
    name = all_trees_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      lapply(all_formulas_alcbias, function(f){
        run_tree(data = df_analysis_alcbias, formula = f, folds = folds_alcbias)
      })
    }
  ),
  tar_target(
    name = tab_fits_alcbias,
    command = {
      source("R/_functions_alcbias_stress_event.R")
      data.frame(
        outcome = "alcbias",
        model = rep(sapply(all_formulas_alcbias, name_variants), 3),
        method = rep(c("forest", "tree", "glmm"), each = 3),
        rmse = sapply(c(all_forests_alcbias, all_trees_alcbias, all_glmms_alcbias), `[[`, "rmse")
      )
    }
  ),
  tar_target(
    name = fl_tab_fits_alcbias,
    command = {
      write.csv(tab_fits_alcbias, "tab_fits_alcbias.csv", row.names = FALSE)
      "tab_fits_alcbias.csv"
    },
    format = "file"
  ),

  # ========== B ANALYSIS ==========
  tar_target(
    name = data_filtered_B,
    command = {
      source("R/_functions_B_stress_event.R")
      filter_data(data_imputed, variables_to_remove = c("alcbias", "choice_prop", "median_rt", "drift"))
    }
  ),
  tar_target(
    name = df_analysis_B,
    command = {
      source("R/_functions_B_stress_event.R")
      feature_engineering(data_filtered_B)
    }
  ),
  tar_target(
    name = folds_B,
    command = {
      source("R/_functions_B_stress_event.R")
      create_folds(df_analysis_B, k_folds = 5)
    }
  ),
  tar_target(
    name = all_formulas_B,
    command = {
      source("R/_functions_B_stress_event.R")
      define_formulas(yvars = "B", xvars = setdiff(names(df_analysis_B), c("pid", "stress_binary", "B")))
    }
  ),
  tar_target(
    name = all_glmms_B,
    command = {
      source("R/_functions_B_stress_event.R")
      lapply(all_formulas_B, function(f){
        run_glmm_cv(data = df_analysis_B, formula = f,
                    lambdas = seq(200, 0, by=-10),
                    folds = folds_B)
      })
    }
  ),
  tar_target(
    name = all_forests_B,
    command = {
      source("R/_functions_B_stress_event.R")
      lapply(all_formulas_B, function(f){
        run_forests(data = df_analysis_B, formula = f, folds = folds_B, num.trees = 500, iters = 10)
      })
    }
  ),
  tar_target(
    name = all_trees_B,
    command = {
      source("R/_functions_B_stress_event.R")
      lapply(all_formulas_B, function(f){
        run_tree(data = df_analysis_B, formula = f, folds = folds_B)
      })
    }
  ),
  tar_target(
    name = tab_fits_B,
    command = {
      source("R/_functions_B_stress_event.R")
      data.frame(
        outcome = "B",
        model = rep(sapply(all_formulas_B, name_variants), 3),
        method = rep(c("forest", "tree", "glmm"), each = 3),
        rmse = sapply(c(all_forests_B, all_trees_B, all_glmms_B), `[[`, "rmse")
      )
    }
  ),
  tar_target(
    name = fl_tab_fits_B,
    command = {
      write.csv(tab_fits_B, "tab_fits_B.csv", row.names = FALSE)
      "tab_fits_B.csv"
    },
    format = "file"
  ),

  # ========== COMBINED RESULTS ==========
  tar_target(
    name = combined_tab_fits,
    command = {
      combined_results <- rbind(
        tab_fits_choice_prop,
        tab_fits_median_rt,
        tab_fits_drift,
        tab_fits_alcbias,
        tab_fits_B
      )
      write.csv(combined_results, "combined_tab_fits.csv", row.names = FALSE)
      combined_results
    }
  )
)
