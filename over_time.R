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

# Get the first and last date from the data
start_date <- min(data$B25__Reservation_Start_Date__c)
end_date <- max(data$B25__Reservation_Start_Date__c)

# Calculate the start and end of 3-month blocks
start_block <- floor_date(start_date, unit = "3 months")
end_block <- ceiling_date(end_date, unit = "3 months")

# Generate sequence of 3-month blocks
blocks <- seq(start_block, end_block, by = "3 months")

# Format the dates
date_range <- paste(format(start_date, "%d/%m/%Y"), format(end_date, "%d/%m/%Y"), sep = " to ")

# Aggregate attendance data by month and class type, considering multiple statuses
attendance_summary <- data %>%
  filter(Swipe_Status__c %in% c("Attended", "Unmeasured", "Ignore")) %>%
  group_by(year_month, B25__Reservation_Title__c) %>%
  summarise(attendance_count = sum(Swipe_Status__c %in% c("Attended", "Unmeasured", "Ignore")))

# Plot attendance trends over time
# plot1 <- ggplot(attendance_summary, aes(x = year_month, y = attendance_count, fill = B25__Reservation_Title__c)) +
#   geom_bar(stat = "identity", position = "stack") +
#   labs(x = "Year-Month", y = "Attendance Count", title = paste("Class Attendance Over Time (", date_range, ")"),
#        fill = "Class Type") +  # Set font color to white
#   theme_minimal() +
#   theme(axis.text.x = element_text(color = "white"),
#         axis.text.y = element_text(color = "white"),
#         legend.text = element_text(color = "white"),
#         plot.title = element_text(color = "white"),
#         axis.title.x = element_text(color = "white"),
#         axis.title.y = element_text(color = "white")) +
#   scale_x_date(breaks = blocks, date_labels = "%Y-%m")  # Set breaks and labels for 3-month blocks
my_colors <- c(rainbow(length(unique(attendance_summary$B25__Reservation_Title__c))))
plot1 <- ggplot(attendance_summary, aes(x = year_month, y = attendance_count, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = my_colors) +
  labs(x = "Year-Month", y = "Attendance Count", title = "Class Attendance Over Time", fill = "Class Type") +
  theme_minimal()
# Save plot1 as an image file
ggsave("attendance_over_time.png", plot1, width = 10, height = 6, units = "in")