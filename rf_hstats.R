


library(targets)
library(ranger)
library(hstats)

stores <- c(stress_binary = "_targets_store_stress_binary",
            stress_state  = "_targets_store_stress_state",
            NA_state      = "_targets_store_na_state",
            PA_state      = "_targets_store_pa_state")
outcomes <- c("choice_prop", "median_rt", "drift", "alcbias")

get_variant_label <- function(f) {
  ft <- as.character(f)
  if (any(grepl("PC_",   ft))) "PCA"
  else if (any(grepl("UMAP_", ft))) "UMAP"
  else "Raw"
}

# refitting for hstats
refit_ranger <- function(fr, df, f) {
  rec <- fr$recommended.pars
  ov  <- as.character(f)[2]
  pv  <- setdiff(all.vars(f), ov)
  ranger(as.formula(paste(ov, "~ .")), data = df[, c(ov, pv)],
         num.trees = 500, mtry = rec$mtry,
         min.node.size = rec$min.node.size,
         sample.fraction = rec$sample.fraction,
         importance = "permutation", num.threads = 0)
}


# hstats for each outcome x predictor
hs <- list()
for (outcome in outcomes) {
  for (pred in names(stores)) {
    cat(sprintf("=== %s / %s ===\n", outcome, pred))
    store <- stores[[pred]]
    df_a <- tar_read_raw(paste0("df_analysis_",  outcome), store = store)
    fs   <- tar_read_raw(paste0("all_formulas_", outcome), store = store)
    fr   <- tar_read_raw(paste0("all_forests_",  outcome), store = store)
    raw  <- which(sapply(fs, get_variant_label) == "Raw")
    rf   <- refit_ranger(fr[[raw]], df_a, fs[[raw]])
    X    <- df_a[, setdiff(all.vars(fs[[raw]]), outcome)]

    hs[[paste(outcome, pred, sep = "__")]] <-
      hstats(rf, X = X,
             pairwise_m = 10,
             threeway_m = 5,
             n_max      = 500,
             verbose    = FALSE)
  }
}
saveRDS(hs, "hstats_results.rds")

# tidy frame for csv
bind_h <- function(hs, fn) {
  do.call(rbind, lapply(names(hs), function(k) {
    parts <- strsplit(k, "__")[[1]]
    m <- tryCatch(as.matrix(fn(hs[[k]])), error = function(e) NULL)
    if (is.null(m) || nrow(m) == 0) return(NULL)
    data.frame(outcome   = parts[1],
               predictor = parts[2],
               variable  = rownames(m),
               h_squared = m[, 1],
               row.names = NULL)
  }))
}

write.csv(bind_h(hs, h2_overall),  "hstats_overall.csv",  row.names = FALSE)
write.csv(bind_h(hs, h2_pairwise), "hstats_pairwise.csv", row.names = FALSE)
write.csv(bind_h(hs, h2_threeway), "hstats_threeway.csv", row.names = FALSE)
