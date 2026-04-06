# In this file, write the R-code necessary to load your original data file
# (e.g., an SPSS, Excel, or SAS-file), and convert it to a data.frame. Then,
# use the function open_data(your_data_frame) or closed_data(your_data_frame)
# to store the data.

library(worcs)
library(dplyr)

# Load the actual data
data <- read.csv("k99_stress_binary_data.csv")

# Store the actual data using WORCS
closed_data(data, synthetic = FALSE)
