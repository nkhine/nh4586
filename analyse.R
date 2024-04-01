library(ggplot2)
library(dplyr)
library(readr)

# Load the data
data <- read_csv("formatted.csv")

# Check for parsing issues
parsing_issues <- problems(data)
if(nrow(parsing_issues) > 0) {
  print(parsing_issues)
}
# Use 'Reservation_Start_Date__c' as the date,
# and count the number of occurrences of each 'B25__Reservation_Title__c' for each date.
data_grouped <- data %>%
  group_by(Reservation_Start_Date__c, B25__Reservation_Title__c) %>%
  summarise(Count = n(), .groups = 'drop')

# Plot
ggplot(data_grouped, aes(x = Reservation_Start_Date__c, y = Count, fill = B25__Reservation_Title__c)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x = "Reservation Start Date", y = "Number of Reservations", fill = "Reservation Title") +
  ggtitle("Reservation Counts by Date and Title")
