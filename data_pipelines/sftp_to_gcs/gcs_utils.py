from google.cloud import storage
from config_vars import GCS_BUCKET_NAME

def upload_to_gcs(local_path, gcs_path):
    print(f"📤 Uploading to GCS: gs://{GCS_BUCKET_NAME}/{gcs_path}")
    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET_NAME)
    blob = bucket.blob(gcs_path)
    blob.upload_from_filename(local_path)
    print(f"✅ GCS upload complete: {gcs_path}")
