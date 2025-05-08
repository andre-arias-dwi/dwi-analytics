import paramiko
import os
import re
from datetime import datetime
from flask import Request
from google.cloud import storage, bigquery

# SFTP Credentials
SFTP_HOST = "sftp.aws.directwines.com"
SFTP_PORT = 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ.get("SFTP_PASSWORD")
SFTP_DIRECTORY = "/"  # Adjust if needed

# Google Cloud Config
GCS_BUCKET_NAME = "andre_test1"
BQ_DATASET = "DWI_DB"
BQ_TABLE = "daily_REC008"

def get_latest_sftp_file():
    """Fetch the latest file from SFTP based on date in filename."""
    print("📢 Connecting to SFTP...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)

    print("📢 Listing available files...")
    files = sftp.listdir(SFTP_DIRECTORY)
    
    # Regex pattern to match files with the expected date format
    pattern = re.compile(r"REC008 Website Order Type And Customer Type Report-(\d{4}-\d{2}-\d{2})")
    
    latest_file = None
    latest_date = None

    for file in files:
        match = pattern.search(file)
        if match:
            file_date = datetime.strptime(match.group(1), "%Y-%m-%d")
            if latest_date is None or file_date > latest_date:
                latest_date = file_date
                latest_file = file

    if not latest_file:
        raise FileNotFoundError("🚨 No valid REC008 file found in SFTP.")

    print(f"✅ Latest file found: {latest_file}")
    
    local_file = f"/tmp/{latest_file}"
    sftp.get(f"{SFTP_DIRECTORY}/{latest_file}", local_file)
    
    sftp.close()
    transport.close()
    print("✅ File downloaded from SFTP.")

    return local_file, latest_file  # Returning both local file and filename

def upload_to_gcs(local_file, latest_file):
    """Upload the latest CSV file to Google Cloud Storage."""
    print(f"📢 Uploading file to GCS: gs://{GCS_BUCKET_NAME}/{latest_file}")
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME)
    blob = bucket.blob(latest_file)  # Keep original filename in GCS
    blob.upload_from_filename(local_file)
    print("✅ File uploaded to GCS.")

def load_to_bigquery(latest_file):
    """Load CSV from GCS to BigQuery."""
    print(f"📢 Loading CSV from GCS into BigQuery: gs://{GCS_BUCKET_NAME}/{latest_file}")
    
    client = bigquery.Client()
    table_ref = client.dataset(BQ_DATASET).table(BQ_TABLE)

    job_config = bigquery.LoadJobConfig(
        autodetect=True,  # Auto-detect schema
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        field_delimiter=",",
        encoding="UTF-8"
    )

    uri = f"gs://{GCS_BUCKET_NAME}/{latest_file}"
    load_job = client.load_table_from_uri(uri, table_ref, job_config=job_config)
    load_job.result()  # Wait for the job to complete
    print("✅ Data loaded into BigQuery.")

def main(request: Request):
    """Main entry point for the Cloud Function."""
    print("🚀 Cloud Function started.")
    
    try:
        local_file, latest_file = get_latest_sftp_file()  # Get latest file
        upload_to_gcs(local_file, latest_file)  # Upload to GCS
        load_to_bigquery(latest_file)  # Load into BigQuery
        
        print("✅ Function completed successfully.")
        return "Success", 200

    except Exception as e:
        print(f"🚨 ERROR: {type(e).__name__} - {str(e)}")
        return f"Error: {str(e)}", 500