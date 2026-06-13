

outcome_config <- list(
  list(outcome = "choice_prop", outcome_label = "Choice Proportion"),
  list(outcome = "B",           outcome_label = "Boundary Separation (B)"),
  list(outcome = "drift",       outcome_label = "Drift Rate"),
  list(outcome = "alcbias",     outcome_label = "Alcohol Bias")
)

for (cfg in outcome_config) {
  rmarkdown::render(
    input       = "results_summary_sensitivity.Rmd",
    output_file = paste0("results_sensitivity_", cfg$outcome, ".html"),
    params      = cfg,
    envir       = new.env(parent = globalenv()),
    quiet       = TRUE
  )
}
