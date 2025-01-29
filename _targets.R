# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed.

set.seed(738298156)


if(file.exists("analysis.log")) file.remove("analysis.log")
# Set target options:
tar_option_set(
  packages = c("worcs", "tibble", "tidyverse", "glmmLasso", "caret", "ranger", "rpart", "umap", "missRanger", "tuneRanger", "mlr") # Packages that your targets need for their tasks.
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

# Set default priority to 1 to ensure all results are completed before manuscript.
tar_option_set(priority = 1)
# Replace the target list below with your own:
list(
  tar_target(
    name = data,
    command = load_data(to_envir = FALSE)[["data"]]
  )
  , tar_target(
    name = data_imputed, # impute the full dataset with all variables
    command = impute_full_dataset(data)
  )
  , tar_target(
    name = data_filtered,
    command = filter_data(data_imputed,
                          variables_to_remove = c("stress_binary",
                                                  "stress_event_type",
                                                  "stress_event_intensity",
                                                  "PA_state", "NA_state",
                                                  "boundary", "drift", "bias"))
  )
  , tar_target(
    name = df_analysis,
    command = feature_engineering(data_filtered)
  )
  , tar_target(
    name = folds,
    command = create_folds(df_analysis, k_folds = 5)
  )
  , tar_target(
    name = all_formulas,
    command = define_formulas(yvars = "choice_prop", xvars = setdiff(names(df_analysis), c("pid", "stress_state", "choice_prop")))
  )
  , tar_target(
    name = all_glmms,
    command = lapply(all_formulas, function(f){
      run_glmm_cv(data = df_analysis, formula = f,
                  lambdas = seq(100, 0, by=-100),
                  folds = folds)
    })
  )
  , tar_target(
    name = all_forests,
    command = lapply(all_formulas, function(f){
      run_forests(data = df_analysis, formula = f, folds = folds, num.trees = 500, iters = 10)}) # Increase iters for real analysis; 70 is default
  )
  , tar_target(
    name = all_trees,
    command = lapply(all_formulas, function(f){
      run_tree(data = df_analysis, formula = f, folds = folds)
    })
  )
  , tar_target(
    name = tab_fits,
    command = data.frame(
      model = rep(sapply(all_formulas, name_variants), 3),
      method = rep(c("forest", "tree", "glmm"), each = 3),
      rmse = sapply(c(all_forests, all_trees, all_glmms), `[[`, "rmse")
      )
  )
  , tar_target(
    name = fl_tab_fits,
    command = {
      write.csv(tab_fits, "tab_fits.csv", row.names = FALSE)
      "tab_fits.csv"
      },
    format = "file"
  )
  , tarchetypes::tar_render(manuscript, "manuscript/manuscript.Rmd", priority = 0) # Set priority to 0 to ensure the manuscript is rendered after other results are available
)
