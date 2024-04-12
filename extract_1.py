import csv
import os
import fitz  # PyMuPDF
import re
from datetime import datetime

def extract_text_line_by_line(pdf_path):
    pdf_password = os.environ.get('PDF_PASSWORD')
    if pdf_password is None:
        print("PDF password not found in environment variables.")
        return

    column_titles = []
    records = []

    try:
        doc = fitz.open(pdf_path)
        if doc.is_encrypted:
            if not doc.authenticate(pdf_password):
                print("Failed to decrypt PDF. Check if the password is correct.")
                return
            else:
                print("PDF successfully decrypted.")

        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text()
            print(f"--- Page {page_num + 1} ---")
            lines = text.split('\n')
            
            # Dynamically find where the records start based on a known line format.
            record_start_index = next((i for i, line in enumerate(lines) if line.startswith("Select Item")), None)
            
            if page_num == 0 and record_start_index is not None:
                column_titles = lines[:record_start_index]  # Assuming headers only appear before records
                print("Column Titles:", column_titles)

            if record_start_index is not None:
                # print(lines[record_start_index:])
                records.extend(lines[record_start_index:])

        # Filter and process records
        records = [extract_fields_from_record(line) for line in records if line.startswith("Select Item")]

        print("Records:", len(records))
        
        return column_titles, records

    except Exception as e:
        print(f"An error occurred: {e}")

def extract_fields_from_record(record):
    # Split the record by spaces after the initial "Select Item"
    print(record)
    parts = record.split(' ', 3)[3:]
    if parts:
        # Further split the remaining part correctly handling the parts with spaces
        return parts[0].split()
    return []

def convert_date_time(date_str, time_str):
    # Convert date and time strings to a datetime object for sorting
    date_format = '%Y-%m-%d'
    time_format = '%H:%M'
    return datetime.strptime(date_str + ' ' + time_str, date_format + ' ' + time_format)

pdf_path = 'class_booking_fix.pdf'
column_titles, records = extract_text_line_by_line(pdf_path)

# Sort records by date and time
# records.sort(key=lambda x: (convert_date_time(x[1], x[2]), convert_date_time(x[3], x[4])))

# # Specify column headers for the CSV file
# csv_column_headers = [
#     'ID', 'Reservation_Start_Date__c', 'Reservation_Start_Time__c',
#     'Reservation_End_Date__c', 'Reservation_End_Time__c',
#     'Status', 'Created_Date', 'Created_Time', 'Swipe_Status__c'
# ]

# # Write the extracted records to a CSV file
# with open('records_fix.csv', mode='w', newline='') as file:
#     writer = csv.writer(file)
#     writer.writerow(csv_column_headers)  # Write column headers
#     for record in records:
#         writer.writerow(record)

# print("CSV file 'records.csv' has been created successfully.")
