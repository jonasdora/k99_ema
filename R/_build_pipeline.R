
# I changed this so that I can run the pipeline for all four analyses, since we only wrote code
# for 1 at the time of preregistration (but they are essentially the same)

build_pipeline <- function(data_csv, predictor_col, predictor_name,
                           predictor_is_binary = FALSE) {

  outcomes <- c("choice_prop", "median_rt", "drift", "alcbias", "B")

  lambda_list <- list(
    choice_prop = seq(100, 0, by = -5),
    median_rt   = seq(100, 0, by = -5),
    drift       = seq(100, 0, by = -5),
    alcbias     = seq(200, 0, by = -10), # increased due to hitting bound
    B           = seq(200, 0, by = -10) # increased due to hitting bound
  )

  # data prep
  data_targets <- list(
    tar_target_raw("data", substitute(
      read.csv(data_csv),
      list(data_csv = data_csv)
    )),
    tar_target_raw("data_renamed", substitute(
      rename_and_prepare_data(data, predictor_col, predictor_name, predictor_is_binary),
      list(predictor_col = predictor_col, predictor_name = predictor_name,
           predictor_is_binary = predictor_is_binary)
    )),
    tar_target_raw("data_imputed", quote(
      impute_full_dataset(data_renamed)
    ))
  )

  # outcomes
  outcome_targets <- unlist(lapply(outcomes, function(out) {
    other_outcomes <- setdiff(outcomes, out)
    lambdas <- lambda_list[[out]]

    list(
      # Filter data
      tar_target_raw(
        paste0("data_filtered_", out),
        substitute(filter_data(data_imputed, variables_to_remove = rem),
                   list(rem = other_outcomes))
      ),
      # Feature engineering
      tar_target_raw(
        paste0("df_analysis_", out),
        substitute(feature_engineering(df, outcome = out, predictor = pred),
                   list(df = as.name(paste0("data_filtered_", out)),
                        out = out, pred = predictor_name))
      ),
      # Folds
      tar_target_raw(
        paste0("folds_", out),
        substitute(create_folds(df, k_folds = 5),
                   list(df = as.name(paste0("df_analysis_", out))))
      ),
      # Formulas
      tar_target_raw(
        paste0("all_formulas_", out),
        substitute(define_formulas(yvars = out, predictor = pred,
                                   xvars = setdiff(names(df), c("pid", pred, out))),
                   list(df = as.name(paste0("df_analysis_", out)),
                        out = out, pred = predictor_name))
      ),
      # GLMM
      tar_target_raw(
        paste0("all_glmms_", out),
        substitute(
          lapply(formulas, function(f) {
            run_glmm_cv(data = df, formula = f, outcome = out,
                        predictor = pred, lambdas = lam, folds = fld)
          }),
          list(formulas = as.name(paste0("all_formulas_", out)),
               df = as.name(paste0("df_analysis_", out)),
               fld = as.name(paste0("folds_", out)),
               out = out, pred = predictor_name, lam = lambdas))
      ),
      # Forests
      tar_target_raw(
        paste0("all_forests_", out),
        substitute(
          lapply(formulas, function(f) {
            run_forests(data = df, formula = f, folds = fld,
                        num.trees = 500, iters = 10)
          }),
          list(formulas = as.name(paste0("all_formulas_", out)),
               df = as.name(paste0("df_analysis_", out)),
               fld = as.name(paste0("folds_", out))))
      ),
      # Trees
      tar_target_raw(
        paste0("all_trees_", out),
        substitute(
          lapply(formulas, function(f) {
            run_tree(data = df, formula = f, folds = fld)
          }),
          list(formulas = as.name(paste0("all_formulas_", out)),
               df = as.name(paste0("df_analysis_", out)),
               fld = as.name(paste0("folds_", out))))
      ),
      # Results table
      tar_target_raw(
        paste0("tab_fits_", out),
        substitute(
          data.frame(
            outcome = out,
            model = rep(sapply(formulas, name_variants), 3),
            method = rep(c("forest", "tree", "glmm"), each = 3),
            rmse = sapply(c(forests, trees, glmms), `[[`, "rmse")
          ),
          list(out = out,
               formulas = as.name(paste0("all_formulas_", out)),
               forests = as.name(paste0("all_forests_", out)),
               trees = as.name(paste0("all_trees_", out)),
               glmms = as.name(paste0("all_glmms_", out))))
      ),
      # Save results
      tar_target_raw(
        paste0("fl_tab_fits_", out),
        substitute({
          write.csv(tab, fname, row.names = FALSE)
          fname
        },
        list(tab = as.name(paste0("tab_fits_", out)),
             fname = paste0("tab_fits_", out, "_", predictor_name, ".csv"))),
        format = "file"
      )
    )
  }), recursive = FALSE)

  # Combined results
  combined_target <- list(
    tar_target_raw("combined_tab_fits", substitute({
      combined_results <- rbind(
        tab_fits_choice_prop, tab_fits_median_rt, tab_fits_drift,
        tab_fits_alcbias, tab_fits_B
      )
      write.csv(combined_results, fname, row.names = FALSE)
      combined_results
    },
    list(fname = paste0("combined_tab_fits_", predictor_name, ".csv"))))
  )

  c(data_targets, outcome_targets, combined_target)
}
