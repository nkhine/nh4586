import os
import fitz  # PyMuPDF
import re

def extract_text_line_by_line(pdf_path):
    pdf_password = os.environ.get('PDF_PASSWORD')
    if pdf_password is None:
        print("PDF password not found in environment variables.")
        return

    try:
        doc = fitz.open(pdf_path)
        if doc.is_encrypted:
            if not doc.authenticate(pdf_password):
                print("Failed to decrypt PDF. Check if the password is correct.")
                return
            else:
                print("PDF successfully decrypted.")

        column_titles = []
        records = []

        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text()
            print(f"--- Page {page_num + 1} ---")
            lines = text.split('\n')
            if page_num == 0:
                column_titles = lines[:7]
                print("Column Titles:", column_titles)
            else:
                records.extend(lines)

        print("Records:", records)
        return column_titles, records

    except Exception as e:
        print(f"An error occurred: {e}")


def group_lines_into_records(lines):
    records = []
    for i in range(0, len(lines), 6):
        record = lines[i:i + 6]
        records.append(record)
    return records

def extract_fields_from_record(record):
    date_time_pattern = r'\d{2}/\d{2}/\d{4} \d{2}:\d{2}'
    date_time_match = re.findall(date_time_pattern, record[0])
    start_date, start_time = date_time_match[0].split()
    end_date, end_time = date_time_match[1].split()

    class_title_type = record[2].rsplit(' ', 1)
    class_title = class_title_type[0]
    class_type = class_title_type[1] if len(class_title_type) > 1 else ""

    status = record[-1]

    return start_date, start_time, end_date, end_time, class_title, class_type, status

# Example usage
pdf_path = 'class_booking_data.pdf'
extract_text_line_by_line(pdf_path)
