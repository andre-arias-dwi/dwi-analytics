#transfer all files from SFTP to GCS

import os, paramiko, requests
from flask import Request
from google.cloud import storage
from datetime import datetime

# SFTP and GCS settings
SFTP_HOST = "sftp.aws.directwines.com"
SFTP_PORT = 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ["SFTP_PASSWORD"]
GCS_BUCKET_NAME = "dwi_data"

def log_external_ip():
    try:
        ip = requests.get("https://ifconfig.me", timeout=6).text.strip()
        print(f"🌍 Cloud Function external IP: {ip}")
    except Exception as e:
        print(f"⚠️ Couldn’t fetch external IP: {e}")

def open_sftp():
    print("📢 Connecting to SFTP...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)
    print("✅ Successfully connected to SFTP server.")
    return sftp, transport

def upload_to_gcs(local_file, gcs_path):
    print(f"📤 Uploading to GCS: {gcs_path}")
    storage.Client().bucket(GCS_BUCKET_NAME).blob(gcs_path).upload_from_filename(local_file)
    print(f"✅ Uploaded to GCS: {gcs_path}")

def transfer_all_files_to_adhoc(sftp, remote_dir="/"):
    files = sftp.listdir_attr(remote_dir)
    if not files:
        print("⚠️ No files found in the SFTP directory.")
        return

    for f in files:
        filename = f.filename
        modified_time = datetime.fromtimestamp(f.st_mtime)
        timestamp_str = modified_time.strftime("%Y%m%d_%H%M%S")

        # Split the filename into name and extension
        if "." in filename:
            name, ext = filename.rsplit(".", 1)
            gcs_filename = f"{name}__{timestamp_str}.{ext}"
        else:
            gcs_filename = f"{filename}__{timestamp_str}"

        remote_path = f"{remote_dir.rstrip('/')}/{filename}"
        local_path = f"/tmp/{filename}"
        gcs_path = f"adhoc/{gcs_filename}"  # ✅ Use the new filename with timestamp

        try:
            print(f"📥 Downloading: {remote_path}")
            sftp.get(remote_path, local_path)
            print(f"✅ Downloaded: {local_path}")
            print(f"🕒 Last Modified: {modified_time.strftime('%Y-%m-%d %H:%M:%S')}")

            upload_to_gcs(local_path, gcs_path)
            os.remove(local_path)
        except Exception as e:
            print(f"🚨 Failed: {filename} – {type(e).__name__}: {e}")

def main(request: Request):
    print("🚀 Cloud Function started.")
    log_external_ip()

    try:
        sftp, transport = open_sftp()
        transfer_all_files_to_adhoc(sftp)
        sftp.close()
        transport.close()
        return "All files uploaded to GCS /adhoc/", 200
    except Exception as e:
        print(f"❌ Main failed: {type(e).__name__}: {e}")
        return f"Error: {e}", 500
