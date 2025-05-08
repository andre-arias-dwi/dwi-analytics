'''
Used to fetch the new REC013 file from SFTP and upload it to GCS

enter prefix when running the function in GCP console

{
  "prefix": "REC013"
}

'''

import fnmatch, os, paramiko, pandas as pd, requests
from datetime import datetime
from flask import Request
from google.cloud import storage

SFTP_HOST, SFTP_PORT = "sftp.aws.directwines.com", 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ["SFTP_PASSWORD"]
GCS_BUCKET_NAME = "dwi_data"

def log_external_ip():
    try:
        ip = requests.get("https://ifconfig.me", timeout=6).text.strip()
        print(f"🌍 Cloud Function external IP: {ip}")
    except Exception as e:
        print(f"⚠️  Couldn’t fetch external IP: {e}")

# ▼ keeps your original “Connecting…” / “Successfully connected…” wording
def open_sftp():
    print("📢 Connecting to SFTP...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)
    print("✅ Successfully connected to SFTP server.")
    return sftp, transport

def newest_remote_file(sftp, prefix, remote_dir="/"):
    files = [f for f in sftp.listdir_attr(remote_dir) if fnmatch.fnmatch(f.filename, f"{prefix}*")]
    if not files:
        raise FileNotFoundError(f"No file starting with {prefix} found")
    return f"{remote_dir.rstrip('/')}/{max(files, key=lambda f: f.st_mtime).filename}"

def upload_to_gcs(local, gcs_path):
    print(f"📢 Uploading file to GCS: gs://{GCS_BUCKET_NAME}/{gcs_path}")
    storage.Client().bucket(GCS_BUCKET_NAME).blob(gcs_path).upload_from_filename(local)
    print(f"✅ Cleaned file uploaded to GCS as: {gcs_path}")

def clean_csv(local_file):
    print("📢 Cleaning CSV file...")
    df = pd.read_csv(local_file, dtype=str)
    df.columns = [c.replace(" ", "_") for c in df.columns]
    if "OrderDate" in df.columns:
        df["OrderDate"] = pd.to_datetime(df["OrderDate"], errors="coerce").dt.strftime("%Y-%m-%d")
    if "Bottle_Quantity" in df.columns:
        df["Bottle_Quantity"] = pd.to_numeric(df["Bottle_Quantity"], errors="coerce").fillna(0).astype(int)
    cleaned = "/tmp/cleaned.csv"
    df.to_csv(cleaned, index=False)
    print("✅ CSV file cleaned and saved.")              # ▼ unchanged
    return cleaned

def main(request: Request):
    print("🚀 Cloud Function started.")
    log_external_ip()

    # NEW:
    data = request.get_json(silent=True) or {}
    prefix  = request.args.get("prefix") or data.get("prefix")
    file_q  = request.args.get("file") or data.get("file")
    rdir    = request.args.get("dir", "/")
    today   = datetime.now().strftime("%Y-%m-%d")

    default_rec008 = f"/REC008 Website Order Type And Customer Type Report-{today}.csv"

    try:
        sftp, transport = open_sftp()

        if file_q:
            remote_file = file_q
            gcs_prefix  = "override"
        elif prefix:
            remote_file = newest_remote_file(sftp, prefix, rdir)
            gcs_prefix  = prefix
            print(f"📢 Fetching file from SFTP: {remote_file}")   # ▼ unchanged
        else:
            remote_file = default_rec008
            gcs_prefix  = "REC008"
            print(f"📢 Fetching file from SFTP: {remote_file}")   # ▼ unchanged

        local_raw = "/tmp/raw.csv"
        sftp.get(remote_file, local_raw)
        print(f"✅ File downloaded from SFTP and saved as: {local_raw}")  # ▼ unchanged

        raw_blob  = f"{gcs_prefix}/raw/{os.path.basename(remote_file)}"
        upload_to_gcs(local_raw, raw_blob)

        local_clean = clean_csv(local_raw)
        clean_blob = f"{gcs_prefix}/clean/{os.path.basename(remote_file)}"
        upload_to_gcs(local_clean, clean_blob)

        sftp.close(); transport.close()
        os.remove(local_raw); os.remove(local_clean)
        print("✅ Function completed successfully.")
        return "Success", 200

    except Exception as e:
        print(f"🚨 ERROR: {type(e).__name__} – {e}")
        return f"Error: {e}", 500
