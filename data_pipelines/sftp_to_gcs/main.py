import pandas as pd
from flask import Request
from helpers import build_filenames, log_external_ip
from sftp_utils import fetch_sftp_file
from gcs_utils import upload_to_gcs

def run_pipeline(report_id):
    print(f"🚀 Starting pipeline for {report_id}")
    log_external_ip()

    sftp_path, gcs_raw, gcs_clean = build_filenames(report_id)

    # Download raw file
    local_raw = fetch_sftp_file(report_id, sftp_path)
    upload_to_gcs(local_raw, gcs_raw)

    # Clean file
    df = pd.read_csv(local_raw, dtype=str)
    try:
        clean_module = __import__(f"cleaner.{report_id.lower()}", fromlist=["clean"])
        print(f"🧹 Cleaning {report_id}...")
        df_clean = clean_module.clean(df)
        print(f"✅ Cleaned {report_id} rows: {len(df_clean)}")
    except ModuleNotFoundError:
        raise Exception(f"❌ No cleaning function defined for report_id={report_id}")

    # Save and upload cleaned file
    local_clean = "/tmp/cleaned_file.csv"
    df_clean.to_csv(local_clean, index=False)
    upload_to_gcs(local_clean, gcs_clean)

    print(f"✅ Pipeline completed for report_id={report_id}")

def main(request: Request):
    report_id = request.args.get("report_id", "REC008")
    try:
        run_pipeline(report_id)
        return "✅ Success", 200
    except Exception as e:
        print(f"🚨 [ALERT] report_id={report_id} | ERROR: {type(e).__name__} - {e}")
        return f"Error: {str(e)}", 500
