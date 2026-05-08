import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

# SFTP Credentials
SFTP_HOST = "sftp.aws.directwines.com"
SFTP_PORT = 22
SFTP_USER = "aws-sftp-usecommerce"
SFTP_PASSWORD = os.environ.get("SFTP_PASSWORD")
# Google Cloud Config
GCS_BUCKET_NAME = "dwi_data"
