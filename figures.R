
DATA_DIR <- "."
FIG_DIR  <- "figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

library(ggplot2)
library(dplyr)
library(tibble)
library(tidyr)
library(readr)
library(forcats)
library(stringr)
library(patchwork)
library(ggh4x)

theme_paper <- theme_bw(base_size = 9) +
  theme(panel.grid.minor   = element_blank(),
        strip.background   = element_rect(fill = "grey92", color = NA),
        strip.text         = element_text(size = 12, face = "bold"),
        plot.title         = element_text(size = 14, face = "bold"),
        plot.subtitle      = element_text(size = 12),
        plot.tag           = element_text(size = 14, face = "bold"),
        legend.position    = "bottom",
        legend.margin      = margin(t = 0, b = 0),
        panel.spacing      = unit(0.6, "lines"))
theme_set(theme_paper)


pred_order <- c("stress_binary", "stress_state", "NA_state", "PA_state")
pred_labels <- c(
  stress_binary = "Stressful event",
  stress_state  = "Stress rating",
  NA_state      = "Negative affect",
  PA_state      = "Positive affect"
)
pred_range <- c(
  stress_binary = 1,
  stress_state  = 4,
  NA_state      = 4,
  PA_state      = 4
)
pred_colors <- c( # Mystic ember glow from coolors.co
  "Stressful event" = "#3c1518",
  "Stress rating"   = "#69140e",
  "Negative affect" = "#a44200",
  "Positive affect" = "#d58936"
)

outcome_labels <- c(
  choice_prop = "Alcohol choice proportion",
  median_rt   = "Median response time",
  drift       = "Drift rate",
  alcbias     = "Alcohol bias",
  B           = "Decision boundary"
)
outcome_order_full <- c("choice_prop", "median_rt", "B", "drift", "alcbias")

method_order  <- c("Mixed-effects LASSO", "Random forest", "Decision tree")
method_labels <- c(
  glmm   = "Mixed-effects LASSO",
  forest = "Random forest",
  tree   = "Decision tree"
)
method_colors <- c( # Oceanic minty splash from coolors.co
  "Mixed-effects LASSO" = "#00a9a5",
  "Random forest"       = "#0b5351",
  "Decision tree"       = "#092327"
)
method_shapes <- c(
  "Mixed-effects LASSO" = 16,
  "Random forest"       = 17,
  "Decision tree"       = 15
)

feature_order <- c("Raw", "PCA", "UMAP")

raw_means   <- read_csv("raw_means_by_level.csv")
glmm_coefs  <- read_csv("glmm_raw_coefs.csv")
forest_vi   <- read_csv("forest_vi_top30.csv")
focal_pdp   <- read_csv("focal_pdp.csv")
model_meta  <- read_csv("model_meta.csv")
rmse_all    <- read_csv("rmse_all.csv")

raw_means <- raw_means %>%
  mutate(outcome = if_else(outcome == "prop_alc_responses",
                           "choice_prop", outcome))
focal_pdp <- focal_pdp %>% mutate(x_value = as.numeric(x_value))

# rescaling for continuous predicotrs so that they are comparable to binary predictor
rescale_coef <- function(estimate, predictor) {
  estimate * unname(pred_range[predictor])
}

clean_term <- function(x) {
  x %>%
    str_replace("^alc_exp_",        "Expect: ") %>%
    str_replace("^alc_mot_",        "Motive: ") %>%
    str_replace("^alc_cue",         "Alc. cue: ") %>%
    str_replace("^social_context_", "With: ") %>%
    str_replace("^location",        "Loc: ") %>%
    str_replace("^time_of_day",     "Time: ") %>%
    str_replace("Yes$", "") %>%
    str_replace_all("_", " ") %>%
    str_replace_all("\\s+", " ") %>%
    str_replace("nauseous vomit",  "nausea/vomit") %>%
    str_replace("restaurant cafe", "restaurant/cafe") %>%
    str_replace("better mood",     "better mood") %>%
    str_squish()
}

interaction_partner_one <- function(term, predictor) {
  out <- sub(paste0(":", predictor, "$"), "", term)
  out <- sub(paste0("^", predictor, ":"), "", out)
  out
}
interaction_partner <- Vectorize(interaction_partner_one, USE.NAMES = FALSE)

save_fig <- function(plot, name, width, height) {
  pdf_path <- file.path(FIG_DIR, paste0(name, ".pdf"))
  png_path <- file.path(FIG_DIR, paste0(name, ".png"))

  ggsave(pdf_path, plot, width = width, height = height, units = "in",
         device = cairo_pdf)
  ggsave(png_path, plot, width = width, height = height, units = "in",
         dpi = 600, bg = "white")
}

make_outcome_figure <- function(outcome_name,
                                sesoi              = NULL,
                                n_top_interactions = 8,
                                min_abs_rescaled   = 0.01,
                                y_label            = NULL,
                                ylim_A             = NULL,
                                xlim_B             = NULL,
                                fig_tag_A          = "A",
                                fig_tag_B          = "B") {

  if (is.null(y_label)) y_label <- unname(outcome_labels[outcome_name])

  raw_dat <- raw_means %>%
    filter(outcome == outcome_name) %>%
    mutate(
      predictor_lab = factor(predictor,
                             levels = pred_order,
                             labels = pred_labels[pred_order]),
      se = sd / sqrt(n)
    )

  present_preds <- unique(as.character(raw_dat$predictor))
  missing_preds <- setdiff(pred_order, present_preds)
  if (length(missing_preds) > 0) {
    pad <- tibble(
      level         = NA_real_,
      predictor     = missing_preds,
      outcome       = outcome_name,
      n             = NA_integer_,
      mean          = NA_real_,
      sd            = NA_real_,
      predictor_lab = factor(missing_preds,
                             levels = pred_order,
                             labels = pred_labels[pred_order]),
      se            = NA_real_
    )
    raw_dat <- bind_rows(raw_dat, pad)
  }

  pA <- ggplot(raw_dat,
               aes(x = level, y = mean,
                   color = predictor_lab, group = predictor_lab)) +
    geom_line(linewidth = 0.6, na.rm = TRUE) +
    geom_point(size = 2.2, na.rm = TRUE) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                  width = 0.12, linewidth = 0.4, na.rm = TRUE) +
    facet_wrap(~ predictor_lab, nrow = 1, scales = "free_x") +
    scale_x_continuous(breaks = function(lim) {
      seq(floor(lim[1]), ceiling(lim[2]), by = 1)
    }) +
    scale_color_manual(values = pred_colors, guide = "none") +
    labs(x = "",
         y = y_label,
         tag = fig_tag_A,
         title    = "Raw data")

  if (!is.null(ylim_A)) {
    pA <- pA + coord_cartesian(ylim = ylim_A)
  }

  coefs <- glmm_coefs %>%
    filter(outcome == outcome_name) %>%
    filter(category %in% c("Focal predictor",
                           "Interaction with focal predictor")) %>%
    mutate(
      predictor_lab = factor(predictor,
                             levels = pred_order,
                             labels = pred_labels[pred_order]),
      is_focal = category == "Focal predictor",
      rescaled = rescale_coef(estimate, predictor),
      display_term = if_else(
        is_focal,
        "(main effect)",
        clean_term(interaction_partner(term, predictor))
      )
    )

  coefs_display <- coefs %>%
    group_by(predictor) %>%
    arrange(desc(is_focal), desc(abs(rescaled)), .by_group = TRUE) %>%
    mutate(row_within = row_number()) %>%
    ungroup() %>%
    filter(
      is_focal |
        (estimate != 0 &
           abs(rescaled) >= min_abs_rescaled &
           row_within <= (n_top_interactions + 1))
    )

  coefs_display <- coefs_display %>%
    group_by(predictor) %>%
    arrange(desc(is_focal), desc(abs(rescaled)), .by_group = TRUE) %>%
    mutate(
      display_key = paste(predictor, sprintf("%03d", row_number()),
                          display_term, sep = "|")
    ) %>%
    ungroup() %>%
    mutate(display_key = factor(display_key, levels = rev(display_key)))

  strip_key <- function(x) {
    sub("^[^|]+\\|[^|]+\\|", "", x)
  }

  x_rng <- max(abs(coefs_display$rescaled), na.rm = TRUE) * 1.05
  if (!is.finite(x_rng) || x_rng == 0) x_rng <- 0.1
  effective_xlim <- if (!is.null(xlim_B)) xlim_B else c(-x_rng, x_rng)

  pB <- ggplot(coefs_display,
               aes(x = rescaled, y = display_key,
                   color = predictor_lab, shape = is_focal))

  if (!is.null(sesoi)) {
    pB <- pB + annotate("rect",
                        xmin = -sesoi, xmax = sesoi,
                        ymin = -Inf,   ymax = Inf,
                        fill = "grey85", alpha = 0.45)
  }

  pB <- pB +
    geom_vline(xintercept = 0, color = "grey40", linewidth = 0.3) +
    geom_segment(aes(x = 0, xend = rescaled,
                     y = display_key, yend = display_key),
                 linewidth = 0.3, color = "grey70") +
    geom_point(size = 2.3) +
    scale_y_discrete(labels = strip_key) +
    coord_cartesian(xlim = effective_xlim) +
    scale_color_manual(values = pred_colors, guide = "none") +
    scale_shape_manual(values = c(`TRUE` = 17, `FALSE` = 16), guide = "none") +
    facet_wrap(~ predictor_lab, nrow = 1, scales = "free_y") +
    labs(
      x = "",
      y = NULL,
      tag = fig_tag_B,
      title = "LASSO effects"
    )

  pA / pB + plot_layout(heights = c(1, 1.9))
}

rmse_fig <- rmse_all %>%
  group_by(outcome, predictor) %>%
  mutate(
    rmse_glmm_raw = rmse[method == "glmm" & feature_set == "Raw"],
    rmse_dev      = 100 * (rmse - rmse_glmm_raw) / rmse_glmm_raw
  ) %>%
  ungroup() %>%
  mutate(
    method_lbl    = factor(unname(method_labels[method]),
                           levels = method_order),
    outcome_lbl   = factor(unname(outcome_labels[outcome]),
                           levels = unname(outcome_labels[outcome_order_full])),
    predictor_lbl = factor(unname(pred_labels[predictor]),
                           levels = unname(pred_labels[pred_order])),
    feature_set   = factor(feature_set, levels = feature_order)
  )

fig5 <- ggplot(rmse_fig, aes(x = feature_set, y = rmse_dev,
                             color = method_lbl, shape = method_lbl)) +
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.3) +
  geom_hline(yintercept = -10, linetype = "dashed",
             color = "grey40", linewidth = 0.4) +
  geom_point(size = 2.8, stroke = 0.9) +
  facet_grid(outcome_lbl ~ predictor_lbl, switch = "y") +
  scale_color_manual(values = method_colors, name = NULL) +
  scale_shape_manual(values = method_shapes,  name = NULL) +
  scale_y_continuous(
    breaks = c(-40, -30, -20, -10, 0, 10),
    labels = function(x) sprintf("%+d%%", x)
  ) +
  labs(
    x = "Feature set",
    y = "Cross-validated RMSE (% deviation from mixed-effects LASSO with raw features)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor    = element_blank(),
    panel.grid.major.x  = element_blank(),
    panel.spacing       = unit(0.6, "lines"),
    strip.text.x        = element_text(face = "bold", size = 11),
    strip.text.y.left   = element_text(face = "bold", size = 12, angle = 0,
                                       hjust = 1),
    strip.placement     = "outside",
    axis.title          = element_text(size = 12),
    axis.text           = element_text(size = 12),
    legend.position     = "top",
    legend.margin       = margin(0, 0, 0, 0),
    legend.box.margin   = margin(0, 0, -6, 0),
    plot.margin         = margin(6, 10, 6, 6)
  )

save_fig(fig5, "fig_05_model_comparison", width = 10, height = 10)

fig6 <- make_outcome_figure(
  outcome_name       = "choice_prop",
  sesoi              = 0.025,
  n_top_interactions = 8,
  min_abs_rescaled   = 0.01,
  y_label            = "Alcohol choice proportion",
  ylim_A             = c(0.25, 0.5),
  xlim_B             = c(-0.1, 0.1),
  fig_tag_A          = "A",
  fig_tag_B          = "B"
)
save_fig(fig6, "fig_06_choice_prop", width = 10.5, height = 8.5)


fig7 <- make_outcome_figure(
  outcome_name       = "alcbias",
  sesoi              = NULL,
  n_top_interactions = 8,
  min_abs_rescaled   = 0.03,
  y_label            = "Alcohol bias",
  ylim_A             = c(-1, 1),
  xlim_B             = c(-0.5, 0.5),
  fig_tag_A          = "A",
  fig_tag_B          = "B"
)
save_fig(fig7, "fig_07_alcbias", width = 10.5, height = 8.5)

forest_outcomes <- c("choice_prop", "alcbias")

vi_rep_predictor <- "stress_state"

vi_tbl <- forest_vi %>%
  filter(outcome %in% forest_outcomes,
         predictor == vi_rep_predictor) %>%
  group_by(outcome) %>%
  slice_max(importance, n = 15, with_ties = FALSE) %>%
  arrange(desc(importance), .by_group = TRUE) %>%
  mutate(
    row_in_outcome = row_number(),
    display_key    = paste(outcome, sprintf("%03d", row_in_outcome),
                           clean_term(variable), sep = "|")
  ) %>%
  ungroup() %>%
  mutate(
    outcome_lab    = factor(outcome,
                            levels = forest_outcomes,
                            labels = outcome_labels[forest_outcomes]),
    focal_category = if_else(variable == vi_rep_predictor,
                             "Focal predictor",
                             "Other covariate"),
    display_key    = factor(display_key, levels = rev(display_key))
  )

strip_key <- function(x) sub("^[^|]+\\|[^|]+\\|", "", x)

pA_f8 <- ggplot(vi_tbl,
                aes(x = importance, y = display_key,
                    color = focal_category)) +
  geom_segment(aes(x = 0, xend = importance,
                   y = display_key, yend = display_key),
               linewidth = 0.3, color = "grey70", linetype = 2) +
  geom_point(size = 2.2) +
  scale_y_discrete(labels = strip_key) +
  scale_color_manual(
    values = c("Focal predictor" = "#D55E00",
               "Other covariate" = "steelblue"),
    name = NULL
  ) +
  facet_wrap(~ outcome_lab, scales = "free", nrow = 2) +
  labs(x = "",
       y = NULL,
       tag = "A",
       title = "Variable importance (stressful event model)") +
  theme(legend.position = "bottom")

ylim_choice_prop <- c(0.25, 0.55)    # row for alcohol choice proportion
ylim_alcbias     <- c(-1.10, 1.1)  # row for alcohol bias

pdp_dat <- focal_pdp %>%
  filter(outcome %in% forest_outcomes) %>%
  mutate(
    outcome_lab   = factor(outcome,
                           levels = forest_outcomes,
                           labels = outcome_labels[forest_outcomes]),
    predictor_lab = factor(predictor,
                           levels = pred_order,
                           labels = pred_labels[pred_order])
  ) %>%
  filter(predictor != "stress_binary" | x_value %in% c(0, 1))

pB_f8 <- ggplot(pdp_dat,
                aes(x = x_value, y = yhat, color = predictor_lab)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.3) +
  facet_grid(outcome_lab ~ predictor_lab, scales = "free") +
  scale_color_manual(values = pred_colors, guide = "none") +
  labs(x = "",
       y = "Random forest predicted outcome",
       tag = "B",
       title = "Partial dependence for focal predictors")

pos_scales <- list()
if (!is.null(ylim_choice_prop)) {
  pos_scales <- c(pos_scales, list(
    outcome_lab == outcome_labels[["choice_prop"]] ~
      scale_y_continuous(limits = ylim_choice_prop,
                         oob    = scales::oob_keep)
  ))
}
if (!is.null(ylim_alcbias)) {
  pos_scales <- c(pos_scales, list(
    outcome_lab == outcome_labels[["alcbias"]] ~
      scale_y_continuous(limits = ylim_alcbias,
                         oob    = scales::oob_keep)
  ))
}
if (length(pos_scales) > 0) {
  pB_f8 <- pB_f8 + ggh4x::facetted_pos_scales(y = pos_scales)
}

fig8 <- pA_f8 / pB_f8 + plot_layout(heights = c(1, 1.25))
save_fig(fig8, "fig_08_forest", width = 11, height = 13)
