
# this is work in progress, trying to figure out how to make plots

# Load the LASSO results from targets
library(targets)
tar_load(all_glmms_choice_prop)
tar_load(all_glmms_alcbias)

# Extract coefficients from the raw variable models (third element)
coef_choice <- all_glmms_choice_prop[[3]]$coefficients
coef_bias <- all_glmms_alcbias[[3]]$coefficients

# Now create the plotting function
plot_lasso_interaction <- function(coef, var_name, var_label,
                                   y_label = "P(Alcohol Choice)",
                                   continuous = FALSE,
                                   cont_values = c(0, 2, 4)) {
  # Get coefficients
  intercept <- coef["(Intercept)"]
  stress_main <- coef["stress_binary"]
  var_main <- coef[var_name]
  interaction <- coef[paste0(var_name, ":stress_binary")]

  if (!continuous) {
    # Binary predictor
    pred_data <- expand.grid(
      stress = c(0, 1),
      var_value = c(0, 1)
    ) %>%
      mutate(
        prediction = intercept +
          stress * stress_main +
          var_value * var_main +
          stress * var_value * interaction,
        stress_label = factor(stress, labels = c("No Stress", "Stress")),
        var_label = factor(var_value, labels = c("No", "Yes"))
      )
  } else {
    # Continuous predictor
    pred_data <- expand.grid(
      stress = c(0, 1),
      var_value = cont_values
    ) %>%
      mutate(
        prediction = intercept +
          stress * stress_main +
          var_value * var_main +
          stress * var_value * interaction,
        stress_label = factor(stress, labels = c("No Stress", "Stress")),
        var_label = factor(var_value)
      )
  }

  # Create plot
  ggplot(pred_data, aes(x = stress_label, y = prediction,
                        group = var_label, color = var_label)) +
    geom_line(size = 1.2) +
    geom_point(size = 3) +
    scale_color_manual(values = if(continuous) viridis::viridis(length(cont_values)) else c("darkblue", "darkred"),
                       name = var_label) +
    labs(x = "Stress Event", y = y_label) +
    theme_minimal() +
    theme(legend.position = "bottom",
          legend.title = element_text(size = 10),
          axis.title = element_text(size = 11),
          axis.text = element_text(size = 10))
}

# Create all 6 plots
p1_choice <- plot_lasso_interaction(
  coef_choice,
  "social_context_strangerYes",
  "With Strangers",
  "P(Alcohol Choice)"
)

p1_bias <- plot_lasso_interaction(
  coef_bias,
  "social_context_strangerYes",
  "With Strangers",
  "Alcohol Bias"
)

p2_choice <- plot_lasso_interaction(
  coef_choice,
  "alc_exp_sociableYes",
  "Expect Sociability",
  "P(Alcohol Choice)"
)

p2_bias <- plot_lasso_interaction(
  coef_bias,
  "alc_exp_sociableYes",
  "Expect Sociability",
  "Alcohol Bias"
)

p3_choice <- plot_lasso_interaction(
  coef_choice,
  "thirst_state",
  "Thirst Level",
  "P(Alcohol Choice)",
  continuous = TRUE,
  cont_values = c(0, 2, 4)
)

p3_bias <- plot_lasso_interaction(
  coef_bias,
  "thirst_state",
  "Thirst Level",
  "Alcohol Bias",
  continuous = TRUE,
  cont_values = c(0, 2, 4)
)

# Combine into multi-panel figure
library(patchwork)
combined_figure <- (p1_choice | p1_bias) /
  (p2_choice | p2_bias) /
  (p3_choice | p3_bias) +
  plot_annotation(
    title = "Moderation of Stress Effects on Alcohol Decision-Making (LASSO Results)",
    subtitle = "Based on mixed-effects LASSO with all predictors included",
    tag_levels = 'A'
  )

# Save the figure
ggsave("lasso_marginal_effects.jpg", combined_figure,
       width = 10, height = 12, units = "in")























# Enhanced plotting function with proper axis limits
plot_lasso_interaction <- function(coef, var_name, var_label,
                                   y_label = "P(Alcohol Choice)",
                                   y_limits = c(0, 1),
                                   continuous = FALSE,
                                   cont_values = c(0, 2, 4)) {
  # Get coefficients
  intercept <- coef["(Intercept)"]
  stress_main <- coef["stress_binary"]
  var_main <- coef[var_name]
  interaction <- coef[paste0(var_name, ":stress_binary")]

  if (!continuous) {
    # Binary predictor
    pred_data <- expand.grid(
      stress = c(0, 1),
      var_value = c(0, 1)
    ) %>%
      mutate(
        prediction = intercept +
          stress * stress_main +
          var_value * var_main +
          stress * var_value * interaction,
        stress_label = factor(stress, labels = c("No Stress", "Stress")),
        var_label = factor(var_value, labels = c("No", "Yes"))
      )
  } else {
    # Continuous predictor (thirst)
    pred_data <- expand.grid(
      stress = c(0, 1),
      var_value = cont_values
    ) %>%
      mutate(
        prediction = intercept +
          stress * stress_main +
          var_value * var_main +
          stress * var_value * interaction,
        stress_label = factor(stress, labels = c("No Stress", "Stress")),
        var_label = factor(var_value,
                           labels = c("Not Thirsty", "Moderate", "Very Thirsty"))
      )
  }

  # Create plot with fixed y-axis
  p <- ggplot(pred_data, aes(x = stress_label, y = prediction,
                             group = var_label, color = var_label)) +
    geom_line(size = 1.2) +
    geom_point(size = 3) +
    scale_color_manual(values = if(continuous)
      c("#440154", "#31688E", "#35B779")
      else c("#1F77B4", "#FF7F0E"),
      name = var_label) +
    scale_y_continuous(limits = y_limits) +
    labs(x = "Stress Event", y = y_label) +
    theme_minimal() +
    theme(legend.position = "bottom",
          legend.title = element_text(size = 10),
          axis.title = element_text(size = 11),
          axis.text = element_text(size = 10),
          panel.grid.minor = element_blank())

  return(p)
}

# Create all plots with proper axis limits
p1_choice <- plot_lasso_interaction(coef_choice, "social_context_strangerYes",
                                    "With Strangers", "P(Alcohol Choice)",
                                    y_limits = c(0, 0.5))

p1_bias <- plot_lasso_interaction(coef_bias, "social_context_strangerYes",
                                  "With Strangers", "Alcohol Bias",
                                  y_limits = c(-2.5, 0))

p2_choice <- plot_lasso_interaction(coef_choice, "alc_exp_sociableYes",
                                    "Expect Sociability", "P(Alcohol Choice)",
                                    y_limits = c(0, 0.5))

p2_bias <- plot_lasso_interaction(coef_bias, "alc_exp_sociableYes",
                                  "Expect Sociability", "Alcohol Bias",
                                  y_limits = c(-2.5, 0))

p3_choice <- plot_lasso_interaction(coef_choice, "thirst_state",
                                    "Thirst Level", "P(Alcohol Choice)",
                                    y_limits = c(0, 0.5),
                                    continuous = TRUE)

p3_bias <- plot_lasso_interaction(coef_bias, "thirst_state",
                                  "Thirst Level", "Alcohol Bias",
                                  y_limits = c(-2.5, 0),
                                  continuous = TRUE)

# Combine
library(patchwork)
combined_figure <- (p1_choice | p1_bias) /
  (p2_choice | p2_bias) /
  (p3_choice | p3_bias) +
  plot_annotation(
    caption = "Note: Predictions shown without confidence intervals due to LASSO regularization",
    tag_levels = 'A'
  )

ggsave("stress_event.jpg", combined_figure,
       width = 10, height = 12, units = "in")
