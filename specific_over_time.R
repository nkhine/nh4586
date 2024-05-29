# Load required libraries
library(tidyverse)
library(lubridate)
library(viridis)
library(RColorBrewer)
library(ggplot2)

# Load the CSV file
data <- read.csv("records.csv")

# Convert date and time columns to appropriate data types
data$B25__Reservation_Start_Date__c <- as.Date(data$B25__Reservation_Start_Date__c, format = "%d/%m/%Y")
data$B25__Reservation_Start_Time__c <- as.POSIXct(data$B25__Reservation_Start_Time__c, format = "%H:%M")
data$Swipe_Status__c <- as.factor(data$Swipe_Status__c)

# Extract year and month from the start date
data$year_month <- floor_date(data$B25__Reservation_Start_Date__c, unit = "month")

# Define the categories of interest
categories_of_interest <- c("Aqua Aerobics", "Freestyle Dance", "Freestyle Tone", "BoxFit")

# Filter the data to include only the specified categories
filtered_data <- data %>%
  filter(B25__Reservation_Title__c %in% categories_of_interest)

# Get the first and last date from the filtered data
start_date <- min(filtered_data$B25__Reservation_Start_Date__c)
end_date <- max(filtered_data$B25__Reservation_Start_Date__c)

# Calculate the start and end of 3-month blocks
start_block <- floor_date(start_date, unit = "3 months")
end_block <- ceiling_date(end_date, unit = "3 months")

# Generate sequence of 3-month blocks
blocks <- seq(start_block, end_block, by = "3 months")

# Aggregate attendance data by month and class type, considering multiple statuses
attendance_summary <- filtered_data %>%
  filter(Swipe_Status__c %in% c("Attended", "Unmeasured", "Ignore")) %>%
  group_by(year_month, B25__Reservation_Title__c) %>%
  summarise(attendance_count = sum(Swipe_Status__c %in% c("Attended", "Unmeasured", "Ignore")), .groups = 'drop')

# Create a custom color palette
my_colors <- setNames(c("cyan", "magenta", "yellow", "black"), categories_of_interest)

# Plot attendance trends over time for selected categories
plot1 <- ggplot(attendance_summary, aes(x = year_month, y = attendance_count, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = my_colors) +
  labs(x = "Year-Month", y = "Attendance Count", title = "Class Attendance Over Time", fill = "Class Type") +
  theme_minimal()

# Save plot as an image file
ggsave("attendance_over_time_specific.png", plot1, width = 10, height = 6, units = "in")
