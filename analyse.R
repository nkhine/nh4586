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

# Get the first and last date from the data
start_date <- min(data$B25__Reservation_Start_Date__c)
end_date <- max(data$B25__Reservation_Start_Date__c)

# Format the dates
date_range <- paste(format(start_date, "%d/%m/%Y"), format(end_date, "%d/%m/%Y"), sep = " to ")

# Aggregate attendance data by month and class type
attendance_summary <- data %>%
  group_by(year_month, B25__Reservation_Title__c) %>%
  summarise(attendance_count = sum(Swipe_Status__c == "Attended"))

# Plot attendance trends over time
plot1 <- ggplot(attendance_summary, aes(x = year_month, y = attendance_count, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Year-Month", y = "Attendance Count", title = paste("Class Attendance Over Time (", date_range, ")"),
       fill = "Class Type") +  # Set font color to white
  theme_minimal() +
  theme(axis.text.x = element_text(color = "white"),
        axis.text.y = element_text(color = "white"),
        legend.text = element_text(color = "white"),
        plot.title = element_text(color = "white"),
        axis.title.x = element_text(color = "white"),
        axis.title.y = element_text(color = "white"))


# Save plot1 as an image file
ggsave("attendance_over_time.png", plot1, width = 10, height = 6, units = "in")

# Plot attendance percentage by class type
attendance_percentage <- attendance_summary %>%
  group_by(B25__Reservation_Title__c) %>%
  summarise(attendance_percentage = mean(attendance_count))

plot2 <- ggplot(attendance_percentage, aes(x = B25__Reservation_Title__c, y = attendance_percentage, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity") +
  labs(x = "Class Type", y = "Attendance Percentage", title = paste("Attendance Percentage by Class Type (", date_range, ")")) +
  theme_minimal() +
  theme(axis.text.x = element_text(color = "white"),
        axis.text.y = element_text(color = "white"),
        legend.text = element_text(color = "white"),
        plot.title = element_text(color = "white"),
        axis.title.x = element_text(color = "white"),
        axis.title.y = element_text(color = "white"))


# Save plot2 as an image file
ggsave("attendance_percentage.png", plot2, width = 8, height = 6, units = "in")

# Group data by class type and week number, calculate the attendance count
class_attendance <- data %>%
  mutate(week_number = week(B25__Reservation_Start_Date__c) - min(week(B25__Reservation_Start_Date__c))) %>%
  group_by(B25__Reservation_Title__c, week_number) %>%
  summarise(attendance_count = sum(Swipe_Status__c == "Attended"))

# Plot line chart for each class type
plot3 <- ggplot(class_attendance, aes(x = week_number, y = attendance_count, color = B25__Reservation_Title__c)) +
  geom_line() +
  labs(x = "Week Number", y = "Attendance Count", title = paste("Attendance Trend for Each Class Type (", date_range, ")"),
       color = "Class Type") +
  theme_minimal() +
  theme(axis.text.x = element_text(color = "white"),
        axis.text.y = element_text(color = "white"),
        legend.text = element_text(color = "white"),
        plot.title = element_text(color = "white"),
        axis.title.x = element_text(color = "white"),
        axis.title.y = element_text(color = "white"))

# Save the plot as an image file
ggsave("attendance_trend_by_class_type.png", plot3, width = 10, height = 6, units = "in")


# Determine the date range of the analysis
analysis_start_date <- min(data$B25__Reservation_Start_Date__c)
analysis_end_date <- max(data$B25__Reservation_Start_Date__c)
date_range <- paste(format(analysis_start_date, "%Y-%m-%d"), "to", format(analysis_end_date, "%Y-%m-%d"))

# Group data by class type and week number, calculate the attendance count
class_attendance <- data %>%
  mutate(week_number = week(B25__Reservation_Start_Date__c) - min(week(B25__Reservation_Start_Date__c))) %>%
  group_by(B25__Reservation_Title__c, week_number) %>%
  summarise(attendance_count = sum(Swipe_Status__c == "Attended"))

# Sort class types in descending order
class_attendance <- class_attendance %>%
  arrange(desc(B25__Reservation_Title__c))

# Plot heatmap for class attendance with yellow to red color range
plot4 <- ggplot(class_attendance, aes(x = week_number, y = reorder(B25__Reservation_Title__c, desc(B25__Reservation_Title__c)), fill = attendance_count)) +
  geom_tile() +
  labs(x = "Week Number", y = "Class Type", title = paste("Class Attendance Over Time (", date_range, ")")) +
  scale_fill_gradient(low = "yellow", high = "red", name = "Counts") +  # Set color gradient and legend title
  theme_minimal() +
  theme(axis.text.x = element_text(color = "white"),
        axis.text.y = element_text(color = "white"),
        legend.text = element_text(color = "white"),
        plot.title = element_text(color = "white"),
        axis.title.x = element_text(color = "white"),
        axis.title.y = element_text(color = "white")) +
  scale_x_continuous(breaks = seq(0, max(class_attendance$week_number), by = 8), labels = seq(0, max(class_attendance$week_number), by = 8)) +
  geom_text(x = max(class_attendance$week_number) + 1, y = 0, label = date_range, color = "white", hjust = 0) +
  theme(legend.title = element_text(color = "white"),
        legend.text.align = 0)

ggsave("class_attendance_heatmap.png", plot4, width = 10, height = 6, units = "in")
