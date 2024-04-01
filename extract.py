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
            if page_num == 0:
                column_titles = lines[:7]
                print("Column Titles:", column_titles)
            else:
                records.extend(group_lines_into_records(lines))

        # Filter out empty records
        records = [record for record in records if record != ['']]

        # print("Records:", records)
        return column_titles, records

    except Exception as e:
        print(f"An error occurred: {e}")

def group_lines_into_records(lines):
    records = []
    for i in range(0, len(lines), 5):
        record = lines[i:i + 5]
        records.append(record)
    return records

def extract_fields_from_record(record):
    flattened_record = []
    for index, item in enumerate(record):
        if index == 1 or index == 3:
            parts = item.split(' ', 2)[:3]
            flattened_record.extend(parts)
        else:
            parts = item.split(' ', 2)
            flattened_record.extend(parts)
    return flattened_record

def convert_date_time(date_str, time_str):
    # Convert date and time strings to a datetime object for sorting
    date_format = '%d/%m/%Y'
    time_format = '%H:%M'
    return datetime.strptime(date_str, date_format), datetime.strptime(time_str, time_format)

pdf_path = 'class_booking_data.pdf'
column_titles, records = extract_text_line_by_line(pdf_path)

# Extract and sort fields
extracted_fields = []
for record in records:
    extracted_field = extract_fields_from_record(record)
    if len(extracted_field) >= 8:  # Ensure record has enough elements for date and time
        extracted_fields.append(extracted_field)

# Sort extracted fields by start date and start time
extracted_fields.sort(key=lambda x: (convert_date_time(x[6], x[7]), convert_date_time(x[0], x[1])))

# Specify column headers for the CSV file
csv_column_headers = [
    'B25__Reservation_Start_Date__c',
    'B25__Reservation_Start_Time__c',
    'B25__Reservation_End_Date__c',
    'B25__Reservation_End_Time__c',
    'B25__Reservation_Title__c',
    'ReservationContactAttendance_B25__c',
    'Reservation_Start_Date__c',
    'Reservation_Start_Time__c',
    'Reservation_End_Date__c',
    'Reservation_End_Time__c',
    'Swipe_Status__c'
]

# Write the extracted fields to a CSV file
with open('records.csv', mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(csv_column_headers)  # Write column headers
    for extracted_field in extracted_fields:
        if len(extracted_field) < 11:
            if extracted_field[5] == 'DNA':
                # print(extracted_field)
                extracted_field.append(extracted_field[5])
            else:
                extracted_field.append(extracted_field[5])
        writer.writerow(extracted_field)

print("CSV file 'records.csv' has been created successfully.")
