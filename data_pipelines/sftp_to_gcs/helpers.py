from datetime import datetime
import requests

def get_today_date():
    return datetime.now().strftime("%Y-%m-%d")

def build_filenames(report_id):
    today = get_today_date()

    # Customize filename pattern based on report type
    if report_id == "REC008":
        sftp = f"/{report_id} Website Order Type And Customer Type Report-{today}.csv"
    elif report_id == "REC013":
        sftp = f"/{report_id}-Campaign IDs Report-{today}.csv"
    else:
        sftp = f"/{report_id}-{today}.csv"

    # Define GCS raw/cleaned file paths
    gcs_raw = f"{report_id}/raw/{report_id}_{today}.csv"
    gcs_clean = f"{report_id}/clean/{report_id}_{today}.csv"
    return sftp, gcs_raw, gcs_clean

def log_external_ip():
    try:
        print("🌍 Checking external IP...")
        ip = requests.get("https://ifconfig.me", timeout=10).text.strip()
        print(f"🌍 External IP: {ip}")
    except Exception as e:
        print(f"⚠️ Failed to retrieve external IP: {e}")
