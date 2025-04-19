import csv
import sys

def update_last_column(csv_file, new_value):
    updated_rows = []
    
    # Read the CSV file and update the last column
    with open(csv_file, mode='r', newline='', encoding='utf-8') as file:
        reader = csv.reader(file)
        for row in reader:
            if row:  # Ensure the row is not empty
                row[-1] = new_value
            updated_rows.append(row)
    
    # Write the updated rows back to the CSV file
    with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerows(updated_rows)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python a.py <csv_file> <new_value>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    new_value = sys.argv[2]
    
    try:
        update_last_column(csv_file, new_value)
        print(f"Updated the last column of {csv_file} to {new_value}.")
    except Exception as e:
        print(f"An error occurred: {e}")