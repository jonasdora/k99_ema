Codebook created on 2026-02-25 at 2026-02-25 12:30:14.593842
================

A codebook contains documentation and metadata describing the contents,
structure, and layout of a data file.

## Dataset description

The data contains 5982 cases and 44 variables.

## Codebook

    ## Warning in attr(x, "align"): 'xfun::attr()' is deprecated.
    ## Use 'xfun::attr2()' instead.
    ## See help("Deprecated")

    ## Warning in attr(x, "format"): 'xfun::attr()' is deprecated.
    ## Use 'xfun::attr2()' instead.
    ## See help("Deprecated")

| name                              | type      |    n | missing | unique |   mean | median |    mode | mode_value |    sd |    v |   min |    max |  range |  skew | skew_2se |  kurt | kurt_2se |
|:----------------------------------|:----------|-----:|--------:|-------:|-------:|-------:|--------:|:-----------|------:|-----:|------:|-------:|-------:|------:|---------:|------:|---------:|
| subject                           | integer   | 5982 |    0.00 |    250 | 123.87 | 127.00 |  127.00 |            | 72.35 |      |  1.00 | 250.00 | 249.00 | -0.01 |    -0.13 | -1.17 |    -9.27 |
| stress_event                      | character | 5982 |    0.00 |      3 |        |        | 4816.00 | No         |       | 0.31 |       |        |        |       |          |       |          |
| alc_yday                          | integer   | 5946 |    0.01 |     12 |   2.27 |   2.00 |    2.00 |            |  2.40 |      |  0.00 |  10.00 |  10.00 |  1.02 |    16.00 |  0.51 |     4.03 |
| soft_yday                         | integer   | 5919 |    0.01 |     12 |   1.93 |   1.00 |    1.00 |            |  2.08 |      |  0.00 |  10.00 |  10.00 |  1.40 |    22.02 |  2.06 |    16.21 |
| alc_today                         | integer   | 5982 |    0.00 |     11 |   0.85 |   0.00 |    0.00 |            |  1.53 |      |  0.00 |  10.00 |  10.00 |  2.24 |    35.33 |  5.76 |    45.51 |
| soft_today                        | integer   | 5982 |    0.00 |     11 |   1.40 |   1.00 |    1.00 |            |  1.65 |      |  0.00 |  10.00 |  10.00 |  1.48 |    23.40 |  2.32 |    18.31 |
| alc_intend                        | integer   | 5982 |    0.00 |     11 |   1.33 |   0.00 |    0.00 |            |  1.79 |      |  0.00 |  10.00 |  10.00 |  1.60 |    25.20 |  2.73 |    21.58 |
| soft_intend                       | integer   | 5982 |    0.00 |     10 |   0.77 |   0.00 |    0.00 |            |  1.18 |      |  0.00 |  10.00 |  10.00 |  1.94 |    30.60 |  4.61 |    36.44 |
| thirst_state                      | integer   | 5982 |    0.00 |      5 |   1.19 |   1.00 |    1.00 |            |  1.13 |      |  0.00 |   4.00 |   4.00 |  0.68 |    10.72 | -0.39 |    -3.08 |
| hunger_state                      | integer   | 5982 |    0.00 |      5 |   0.88 |   0.00 |    0.00 |            |  1.14 |      |  0.00 |   4.00 |   4.00 |  1.11 |    17.49 |  0.20 |     1.60 |
| tired_state                       | integer   | 5982 |    0.00 |      5 |   1.62 |   2.00 |    2.00 |            |  1.25 |      |  0.00 |   4.00 |   4.00 |  0.26 |     4.13 | -0.97 |    -7.63 |
| bored_state                       | integer   | 5982 |    0.00 |      5 |   0.64 |   0.00 |    0.00 |            |  0.89 |      |  0.00 |   4.00 |   4.00 |  1.37 |    21.65 |  1.38 |    10.92 |
| alc_exp_relaxed                   | character | 5982 |    0.00 |      3 |        |        | 3756.00 | Yes        |       | 0.47 |       |        |        |       |          |       |          |
| alc_exp_sociable                  | character | 5982 |    0.00 |      3 |        |        | 4558.00 | No         |       | 0.36 |       |        |        |       |          |       |          |
| alc_exp_buzz                      | character | 5982 |    0.00 |      3 |        |        | 3529.00 | No         |       | 0.48 |       |        |        |       |          |       |          |
| alc_exp_better_mood               | character | 5982 |    0.00 |      3 |        |        | 3980.00 | No         |       | 0.45 |       |        |        |       |          |       |          |
| alc_exp_energetic                 | character | 5982 |    0.00 |      3 |        |        | 5233.00 | No         |       | 0.22 |       |        |        |       |          |       |          |
| alc_exp_hangover                  | character | 5982 |    0.00 |      3 |        |        | 5388.00 | No         |       | 0.18 |       |        |        |       |          |       |          |
| alc_exp_embarrassed               | character | 5982 |    0.00 |      3 |        |        | 5759.00 | No         |       | 0.07 |       |        |        |       |          |       |          |
| alc_exp_be_rude                   | character | 5982 |    0.00 |      3 |        |        | 5756.00 | No         |       | 0.07 |       |        |        |       |          |       |          |
| alc_exp_nauseous_vomit            | character | 5982 |    0.00 |      3 |        |        | 5776.00 | No         |       | 0.07 |       |        |        |       |          |       |          |
| alc_exp_injury                    | character | 5982 |    0.00 |      3 |        |        | 5869.00 | No         |       | 0.04 |       |        |        |       |          |       |          |
| alc_mot_coping                    | character | 5982 |    0.00 |      3 |        |        | 4406.00 | No         |       | 0.39 |       |        |        |       |          |       |          |
| alc_mot_social                    | character | 5982 |    0.00 |      3 |        |        | 5359.00 | No         |       | 0.19 |       |        |        |       |          |       |          |
| alc_mot_enhance                   | character | 5982 |    0.00 |      3 |        |        | 3423.00 | Yes        |       | 0.49 |       |        |        |       |          |       |          |
| alc_craving                       | integer   | 5982 |    0.00 |      5 |   0.80 |   0.00 |    0.00 |            |  1.09 |      |  0.00 |   4.00 |   4.00 |  1.29 |    20.33 |  0.75 |     5.93 |
| soft_craving                      | integer   | 5982 |    0.00 |      5 |   0.57 |   0.00 |    0.00 |            |  0.92 |      |  0.00 |   4.00 |   4.00 |  1.71 |    26.95 |  2.36 |    18.65 |
| location                          | character | 5982 |    0.00 |      8 |        |        | 4667.00 | home       |       | 0.38 |       |        |        |       |          |       |          |
| social_context_alone              | character | 5982 |    0.00 |      3 |        |        | 3197.00 | Yes        |       | 0.50 |       |        |        |       |          |       |          |
| social_context_friend_roommate    | character | 5982 |    0.00 |      3 |        |        | 5608.00 | No         |       | 0.12 |       |        |        |       |          |       |          |
| social_context_romantic_partner   | character | 5982 |    0.00 |      3 |        |        | 4499.00 | No         |       | 0.37 |       |        |        |       |          |       |          |
| social_context_family             | character | 5982 |    0.00 |      3 |        |        | 4907.00 | No         |       | 0.29 |       |        |        |       |          |       |          |
| social_context_coworker_classmate | character | 5982 |    0.00 |      3 |        |        | 5763.00 | No         |       | 0.07 |       |        |        |       |          |       |          |
| social_context_stranger           | character | 5982 |    0.00 |      3 |        |        | 5848.00 | No         |       | 0.04 |       |        |        |       |          |       |          |
| social_context_other              | character | 5982 |    0.00 |      3 |        |        | 5949.00 | No         |       | 0.01 |       |        |        |       |          |       |          |
| alc_cue                           | character | 5982 |    0.00 |      4 |        |        | 4127.00 | none       |       | 0.45 |       |        |        |       |          |       |          |
| responsibility                    | character | 5982 |    0.00 |      3 |        |        | 3831.00 | Yes        |       | 0.46 |       |        |        |       |          |       |          |
| day_of_week                       | character | 5982 |    0.00 |      8 |        |        |  881.00 | Tue        |       | 0.86 |       |        |        |       |          |       |          |
| prop_alc_responses                | numeric   | 5973 |    0.00 |   1081 |   0.35 |   0.32 |    0.32 |            |  0.27 |      |  0.00 |   1.00 |   1.00 |  0.57 |     9.06 | -0.52 |    -4.13 |
| median_rt                         | numeric   | 5977 |    0.00 |   1983 |   0.78 |   0.75 |    0.75 |            |  0.28 |      |  0.02 |   4.00 |   3.98 |  1.28 |    20.21 | 10.98 |    86.65 |
| time_of_day                       | character | 5982 |    0.00 |      3 |        |        | 3019.00 | evening    |       | 0.50 |       |        |        |       |          |       |          |
| drift                             | numeric   | 5803 |    0.03 |   5804 |   0.39 |   0.39 |    0.39 |            |  0.30 |      | -0.62 |   1.26 |   1.88 |  0.06 |     0.97 | -0.70 |    -5.41 |
| alcbias                           | numeric   | 5803 |    0.03 |   5804 |  -0.78 |  -0.69 |   -0.69 |            |  1.50 |      | -8.12 |   5.96 |  14.08 | -0.04 |    -0.57 |  0.89 |     6.95 |
| B                                 | numeric   | 5803 |    0.03 |   5804 |   0.81 |   0.76 |    0.76 |            |  0.32 |      |  0.27 |   8.00 |   7.73 |  5.48 |    85.29 | 71.91 |   559.33 |

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
