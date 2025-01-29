Codebook created on 2025-01-29 at 2025-01-29 06:24:06.951628
================

A codebook contains documentation and metadata describing the contents,
structure, and layout of a data file.

## Dataset description

The data contains 10000 cases and 35 variables.

## Codebook

| name | type | n | missing | unique | mean | median | mode | mode_value | sd | v | min | max | range | skew | skew_2se | kurt | kurt_2se |
|:---|:---|---:|---:|---:|---:|---:|---:|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pid | integer | 10000 | 0.00 | 250 | 125.50 | 125.50 | 125.50 |  | 72.17 |  | 1.00 | 250 | 249.00 | 0.00 | 0.00 | -1.20 | -12.25 |
| stress_binary | factor | 7500 | 0.25 | 3 |  |  | 4129.00 | yes |  | 0.49 |  |  |  |  |  |  |  |
| stress_event_type | factor | 4129 | 0.59 | 8 |  |  | 5871.00 |  |  | 0.86 |  |  |  |  |  |  |  |
| stress_event_intensity | numeric | 4129 | 0.59 | 1351 | 3.62 | 4.00 | 4.00 |  | 0.67 |  | 0.48 | 4 | 3.52 | -1.68 | -22.04 | 1.78 | 11.68 |
| stress_state | numeric | 7500 | 0.25 | 2515 | 2.17 | 2.50 | 2.50 |  | 1.74 |  | 0.00 | 4 | 4.00 | -0.18 | -3.18 | -1.73 | -15.31 |
| thirst_state | numeric | 7500 | 0.25 | 2533 | 2.17 | 2.51 | 2.51 |  | 1.74 |  | 0.00 | 4 | 4.00 | -0.18 | -3.18 | -1.73 | -15.31 |
| hunger_state | numeric | 7500 | 0.25 | 2535 | 2.17 | 2.51 | 2.51 |  | 1.74 |  | 0.00 | 4 | 4.00 | -0.18 | -3.20 | -1.73 | -15.29 |
| tired_state | numeric | 7500 | 0.25 | 2528 | 2.17 | 2.50 | 2.50 |  | 1.74 |  | 0.00 | 4 | 4.00 | -0.18 | -3.15 | -1.73 | -15.31 |
| bored_state | numeric | 7500 | 0.25 | 2527 | 2.17 | 2.51 | 2.51 |  | 1.74 |  | 0.00 | 4 | 4.00 | -0.18 | -3.18 | -1.73 | -15.31 |
| alc_yday | numeric | 7500 | 0.25 | 20 | 5.23 | 4.00 | 4.00 |  | 4.34 |  | 0.00 | 22 | 22.00 | 0.78 | 13.79 | 0.11 | 0.98 |
| alc_today | numeric | 7500 | 0.25 | 19 | 5.22 | 4.00 | 4.00 |  | 4.33 |  | 0.00 | 21 | 21.00 | 0.78 | 13.79 | 0.11 | 0.97 |
| alc_intend | numeric | 7500 | 0.25 | 19 | 5.23 | 4.00 | 4.00 |  | 4.34 |  | 0.00 | 21 | 21.00 | 0.77 | 13.70 | 0.10 | 0.85 |
| alc_craving | numeric | 7500 | 0.25 | 17 | 2.94 | 1.00 | 1.00 |  | 3.64 |  | 0.00 | 19 | 19.00 | 1.30 | 23.04 | 1.15 | 10.17 |
| alc_exp_relaxed | factor | 7500 | 0.25 | 3 |  |  | 4073.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_social | factor | 7500 | 0.25 | 3 |  |  | 4059.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_buzz | factor | 7500 | 0.25 | 3 |  |  | 4063.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_mood | factor | 7500 | 0.25 | 3 |  |  | 4059.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_energetic | factor | 7500 | 0.25 | 3 |  |  | 4032.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_hangover | factor | 7500 | 0.25 | 3 |  |  | 4037.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_embar | factor | 7500 | 0.25 | 3 |  |  | 4054.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_rude | factor | 7500 | 0.25 | 3 |  |  | 4042.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_vomit | factor | 7500 | 0.25 | 3 |  |  | 4037.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| alc_exp_injure | factor | 7500 | 0.25 | 3 |  |  | 4054.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| alc_mot_coping | factor | 7500 | 0.25 | 3 |  |  | 4133.00 | yes |  | 0.49 |  |  |  |  |  |  |  |
| alc_mot_social | factor | 7500 | 0.25 | 3 |  |  | 4052.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| alc_mot_enhance | factor | 7500 | 0.25 | 3 |  |  | 4068.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| time_of_day | factor | 7500 | 0.25 | 3 |  |  | 3767.00 | evening |  | 0.50 |  |  |  |  |  |  |  |
| location | factor | 7500 | 0.25 | 3 |  |  | 3772.00 | home |  | 0.50 |  |  |  |  |  |  |  |
| social | factor | 7500 | 0.25 | 3 |  |  | 3802.00 | alone |  | 0.50 |  |  |  |  |  |  |  |
| alc_cue | factor | 7500 | 0.25 | 3 |  |  | 3823.00 | yes |  | 0.50 |  |  |  |  |  |  |  |
| responsibility | factor | 7500 | 0.25 | 3 |  |  | 3820.00 | no |  | 0.50 |  |  |  |  |  |  |  |
| choice_prop | numeric | 7500 | 0.25 | 1558 | 0.51 | 0.58 | 0.58 |  | 0.46 |  | 0.00 | 1 | 1.00 | -0.06 | -1.10 | -1.86 | -16.48 |
| boundary | numeric | 7500 | 0.25 | 4394 | 2.17 | 2.26 | 2.26 |  | 1.51 |  | 0.00 | 4 | 4.00 | -0.15 | -2.64 | -1.46 | -12.90 |
| drift | numeric | 7500 | 0.25 | 4658 | 1.89 | 1.74 | 1.74 |  | 1.51 |  | 0.00 | 4 | 4.00 | 0.15 | 2.57 | -1.49 | -13.14 |
| bias | numeric | 7500 | 0.25 | 5453 | 0.02 | 0.07 | 0.07 |  | 1.41 |  | -2.00 | 2 | 4.00 | -0.01 | -0.22 | -1.36 | -12.05 |

### Legend

- **Name**: Variable name
- **type**: Data type of the variable
- **missing**: Proportion of missing values for this variable
- **unique**: Number of unique values
- **mean**: Mean value
- **median**: Median value
- **mode**: Most common value (for categorical variables, this shows the
  frequency of the most common category)
- **mode_value**: For categorical variables, the value of the most
  common category
- **sd**: Standard deviation (measure of dispersion for numerical
  variables
- **v**: Agresti’s V (measure of dispersion for categorical variables)
- **min**: Minimum value
- **max**: Maximum value
- **range**: Range between minimum and maximum value
- **skew**: Skewness of the variable
- **skew_2se**: Skewness of the variable divided by 2\*SE of the
  skewness. If this is greater than abs(1), skewness is significant
- **kurt**: Kurtosis (peakedness) of the variable
- **kurt_2se**: Kurtosis of the variable divided by 2\*SE of the
  kurtosis. If this is greater than abs(1), kurtosis is significant.

This codebook was generated using the [Workflow for Open Reproducible
Code in Science (WORCS)](https://osf.io/zcvbs/)
