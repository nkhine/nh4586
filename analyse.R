# Load required libraries
library(tidyverse)
library(lubridate)

# Load the CSV file
data <- read.csv("records.csv")

# Convert date and time columns to appropriate data types
data$B25__Reservation_Start_Date__c <- as.Date(data$B25__Reservation_Start_Date__c, format = "%d/%m/%Y")
data$B25__Reservation_Start_Time__c <- as.POSIXct(data$B25__Reservation_Start_Time__c, format = "%H:%M")
data$Swipe_Status__c <- as.factor(data$Swipe_Status__c)

# Extract year and month from the start date
data$year_month <- floor_date(data$B25__Reservation_Start_Date__c, unit = "month")

# Aggregate attendance data by month and class type
attendance_summary <- data %>%
  group_by(year_month, B25__Reservation_Title__c) %>%
  summarise(attendance_count = sum(Swipe_Status__c == "Attended"))

# Plot attendance trends over time
plot1 <- ggplot(attendance_summary, aes(x = year_month, y = attendance_count, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Year-Month", y = "Attendance Count", title = "Class Attendance Over Time",
       fill = "Class Type") +
  theme_minimal()

# Save plot1 as an image file
ggsave("attendance_over_time.png", plot1, width = 10, height = 6, units = "in")

# Plot attendance percentage by class type
attendance_percentage <- attendance_summary %>%
  group_by(B25__Reservation_Title__c) %>%
  summarise(attendance_percentage = mean(attendance_count))

plot2 <- ggplot(attendance_percentage, aes(x = B25__Reservation_Title__c, y = attendance_percentage)) +
  geom_bar(stat = "identity") +
  labs(x = "Class Type", y = "Attendance Percentage", title = "Attendance Percentage by Class Type") +
  theme_minimal()

# Save plot2 as an image file
ggsave("attendance_percentage.png", plot2, width = 8, height = 6, units = "in")
