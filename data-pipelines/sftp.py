import paramiko
import os
import requests
from flask import Request
from google.cloud import storage, bigquery

# SFTP Credentials
SFTP_HOST = "sftp.aws.directwines.com"
SFTP_PORT = 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ.get("SFTP_PASSWORD")
SFTP_FILE_PATH = "/REC008 Website Order Type And Customer Type Report_37_8592683274806895584.csv"

# Google Cloud Config
GCS_BUCKET_NAME = "andre_test1"
GCS_FILE_NAME = "REC008.csv"  # Keeping the original file name
BQ_DATASET = "daily_summary"
BQ_TABLE = "REC008"

def log_external_ip():
    """Logs the external IP address to verify NAT configuration."""
    try:
        print("🌍 Checking external IP address...")
        external_ip = requests.get("https://ifconfig.me", timeout=10).text.strip()
        print(f"🌍 Cloud Function External IP: {external_ip}")
    except Exception as e:
        print(f"🚨 Failed to retrieve external IP: {str(e)}")

def fetch_sftp_file():
    """Fetch CSV file from SFTP and save locally."""
    print("📢 Connecting to SFTP...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)
    print("✅ Successfully connected to SFTP server.")

    local_file = f"/tmp/{GCS_FILE_NAME}"
    print(f"📢 Fetching file from SFTP: {SFTP_FILE_PATH}")
    sftp.get(SFTP_FILE_PATH, local_file)
    sftp.close()
    transport.close()
    print("✅ File downloaded from SFTP.")

    return local_file

def upload_to_gcs(local_file):
    """Upload the CSV file to Google Cloud Storage without modification."""
    print(f"📢 Uploading file to GCS: gs://{GCS_BUCKET_NAME}/{GCS_FILE_NAME}")
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME)
    blob = bucket.blob(GCS_FILE_NAME)
    blob.upload_from_filename(local_file)
    print("✅ File uploaded to GCS.")

def load_to_bigquery():
    """Load CSV from GCS to BigQuery with auto-detection."""
    print(f"📢 Loading CSV from GCS into BigQuery: gs://{GCS_BUCKET_NAME}/{GCS_FILE_NAME}")
    
    client = bigquery.Client()
    table_ref = client.dataset(BQ_DATASET).table(BQ_TABLE)

    job_config = bigquery.LoadJobConfig(
        autodetect=True,  # Auto-detect schema
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        field_delimiter=",",
        encoding="UTF-8"
    )

    uri = f"gs://{GCS_BUCKET_NAME}/{GCS_FILE_NAME}"
    load_job = client.load_table_from_uri(uri, table_ref, job_config=job_config)
    load_job.result()  # Wait for the job to complete
    print("✅ Data loaded into BigQuery.")

def main(request: Request):
    """Main entry point for the Cloud Function."""
    print("🚀 Cloud Function started.")
    
    log_external_ip()  # Log external IP first
    
    try:
        local_file = fetch_sftp_file()  # Fetch file from SFTP
        upload_to_gcs(local_file)  # Upload to GCS
        load_to_bigquery()  # Load into BigQuery
        
        print("✅ Function completed successfully.")
        return "Success", 200

    except Exception as e:
        print(f"🚨 ERROR: {type(e).__name__} - {str(e)}")
        return f"Error: {str(e)}", 500