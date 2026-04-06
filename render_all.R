
# Renders one HTML report per outcome from the results_summary.Rmd
# I split this so that each file is not so huge

outcome_config <- list(
  list(outcome = "choice_prop", outcome_label = "Choice Proportion"),
  list(outcome = "B",           outcome_label = "Boundary Separation (B)"),
  list(outcome = "drift",       outcome_label = "Drift Rate"),
  list(outcome = "alcbias",     outcome_label = "Alcohol Bias")
)

for (cfg in outcome_config) {
  rmarkdown::render(
    input       = "results_summary.Rmd",
    output_file = paste0("results_", cfg$outcome, ".html"),
    params      = cfg,
    envir       = new.env(parent = globalenv()),
    quiet       = TRUE
  )
}
