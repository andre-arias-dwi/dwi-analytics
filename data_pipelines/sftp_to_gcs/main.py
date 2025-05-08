import paramiko
import os
import requests
import pandas as pd
from datetime import datetime
from flask import Request
from google.cloud import storage

# SFTP Credentials
SFTP_HOST = "sftp.aws.directwines.com"
SFTP_PORT = 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ.get("SFTP_PASSWORD")
# Google Cloud Config
GCS_BUCKET_NAME = "dwi_data"

def log_external_ip():
    """Logs the external IP address to verify NAT configuration."""
    try:
        print("🌍 Checking external IP address...")
        external_ip = requests.get("https://ifconfig.me", timeout=10).text.strip()
        print(f"🌍 Cloud Function External IP: {external_ip}")
    except Exception as e:
        print(f"🚨 Failed to retrieve external IP: {str(e)}")

def get_today_filename():
    """Generates today's filename for the SFTP file and the cleaned GCS file."""
    today_date = datetime.now().strftime("%Y-%m-%d")  # Format: YYYY-MM-DD

    # File names
    sftp_filename = f"/REC008 Website Order Type And Customer Type Report-{today_date}.csv"
    gcs_raw_filename = f"REC008/raw/REC008_{today_date}.csv"   # Raw file path in GCS
    gcs_cleaned_filename = f"REC008/clean/REC008_{today_date}.csv"  # Cleaned file path in GCS
   
    return sftp_filename, gcs_raw_filename, gcs_cleaned_filename

def fetch_sftp_file(sftp_filename):
    """Fetch CSV file from SFTP and save locally."""
    print("📢 Connecting to SFTP...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)
    print("✅ Successfully connected to SFTP server.")

    # Save file locally
    local_file = "/tmp/raw_REC008.csv"
    
    print(f"📢 Fetching file from SFTP: {sftp_filename}")
    sftp.get(sftp_filename, local_file)
    sftp.close()
    transport.close()
    print(f"✅ File downloaded from SFTP and saved as: {local_file}")

    return local_file  # Return local file path

def clean_csv(local_file):
    """Clean the CSV file: format OrderDate, update column headers, and fix data types."""
    print("📢 Cleaning CSV file...")
    
    # Load the CSV file into pandas
    df = pd.read_csv(local_file, dtype=str)  # Read all columns as strings to avoid type issues

    # Replace spaces with underscores in column names
    df.columns = [col.replace(" ", "_") for col in df.columns]

    # Convert OrderDate column to YYYY-MM-DD format if it exists
    if "OrderDate" in df.columns:
        df["OrderDate"] = pd.to_datetime(df["OrderDate"], errors="coerce").dt.strftime("%Y-%m-%d")

    # Convert Bottle_Quantity to integer if it exists
    if "Bottle_Quantity" in df.columns:
        df["Bottle_Quantity"] = pd.to_numeric(df["Bottle_Quantity"], errors="coerce").fillna(0).astype(int)

    # Save the cleaned file locally
    cleaned_file = "/tmp/cleaned_REC008.csv"
    df.to_csv(cleaned_file, index=False)
    
    print("✅ CSV file cleaned and saved.")

    return cleaned_file  # Return path to cleaned file

def upload_to_gcs(local_file, gcs_file_name):
    """Upload the cleaned file to Google Cloud Storage."""
    print(f"📢 Uploading file to GCS: gs://{GCS_BUCKET_NAME}/{gcs_file_name}")
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME)
    blob = bucket.blob(gcs_file_name)
    blob.upload_from_filename(local_file)
    print(f"✅ Cleaned file uploaded to GCS as: {gcs_file_name}")

def main(request: Request):
    """Main entry point for the Cloud Function."""
    print("🚀 Cloud Function started.")
    
    log_external_ip()  # Log external IP
    
    try:
        sftp_filename, gcs_raw_filename, gcs_cleaned_filename = get_today_filename()  # Get filenames
        local_raw_file = fetch_sftp_file(sftp_filename)  # Fetch today's file from SFTP

        upload_to_gcs(local_raw_file, gcs_raw_filename)  # Upload raw file to GCS
        
        local_cleaned_file = clean_csv(local_raw_file)  # Clean the file
        upload_to_gcs(local_cleaned_file, gcs_cleaned_filename)  # Upload cleaned file to GCS
        
        print("✅ Function completed successfully.")
        return "Success", 200

    except Exception as e:
        print(f"🚨 ERROR: {type(e).__name__} - {str(e)}")
        return f"Error: {str(e)}", 500
