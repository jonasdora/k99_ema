# In this file, write the R-code necessary to load your original data file
# (e.g., an SPSS, Excel, or SAS-file), and convert it to a data.frame. Then,
# use the function open_data(your_data_frame) or closed_data(your_data_frame)
# to store the data.

library(worcs)
library(dplyr)
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
) |>
  left_join(person_data, by="pid") |>
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
  ) |>
  select(-consumption_state, -affect_state)

# Introduce missingness for imputation(very lazy)
for(p in unique(data$pid)) {
  missing_rows <- sample(which(data$pid == p), 10)
  data[missing_rows, !(names(data) %in% c("pid", "consumption", "affect"))] <- NA
}

# Recode factor
data$stress_event_type <- factor(data$stress_event_type)
# Remove made up tendencies
data$consumption <- NULL
data$affect <- NULL

# now we have a data set that resembles (in structure) the data we will collect
closed_data(data)

