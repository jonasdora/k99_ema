library(targets)
library(tarchetypes)

set.seed(738298156)
options(scipen = 999)

if (file.exists("analysis.log")) file.remove("analysis.log")

tar_option_set(
  packages = c("worcs", "tibble", "tidyverse", "glmmLasso", "caret",
               "ranger", "rpart", "umap", "missRanger", "tuneRanger", "mlr")
)

source("R/_functions.R")
source("R/_build_pipeline.R")

build_pipeline(
  data_csv           = "k99_stress_binary_data.csv",
  predictor_col      = "stress_event",
  predictor_name     = "stress_binary",
  predictor_is_binary = TRUE
)
