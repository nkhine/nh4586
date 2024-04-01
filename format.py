import csv

# File paths
input_file_path = "records.txt"
output_file_path = "formatted.csv"

# Process the CSV file
with open(input_file_path, "r", encoding="utf-8") as infile, open(
    output_file_path, "w", newline="", encoding="utf-8"
) as outfile:
    reader = csv.reader(infile)
    writer = csv.writer(outfile)

    # Process the header separately to add the new column names
    headers = next(reader)
    # Modify the header to include new columns for split date and time
    new_headers = (
        headers[:6]
        + [
            "Reservation_Start_Date__c",
            "Reservation_Start_Time__c",
            "Reservation_End_Date__c",
            "Reservation_End_Time__c",
        ]
        + headers[7:]
    )
    writer.writerow(new_headers)

    for row in reader:
        # Check if the row has at least 7 entries (to include the 6th column).
        if len(row) > 6:
            # Assuming the format is 'DD/MM/YYYY HH:MM DD/MM/YYYY HH:MM' for the 7th column (index 6)
            # Split the 6th entry by space to separate each date and time
            split_values = row[6].split(" ")
            # It's expected that split_values now contains 4 items: [start_date, start_time, end_date, end_time]
            row = row[:6] + split_values + row[7:]
        writer.writerow(row)
