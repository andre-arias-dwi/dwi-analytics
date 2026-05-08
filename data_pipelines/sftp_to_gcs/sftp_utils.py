import paramiko
from config_vars import SFTP_HOST, SFTP_PORT, SFTP_USER, SFTP_PASSWORD

def fetch_sftp_file(report_id, sftp_path):
    print(f"📡 Connecting to SFTP for report_id={report_id}...")
    transport = paramiko.Transport((SFTP_HOST, SFTP_PORT))
    transport.connect(username=SFTP_USER, password=SFTP_PASSWORD)
    sftp = paramiko.SFTPClient.from_transport(transport)
    print("✅ SFTP connection established")

    # List available files
    print("📂 SFTP directory contents:")
    for f in sftp.listdir():
        print(f" - {f}")

    local_file = "/tmp/raw_file.csv"
    try:
        sftp.get(sftp_path, local_file)
        print(f"✅ SFTP file downloaded: {sftp_path}")
    except FileNotFoundError:
        print(f"🚨 [ALERT] SFTP file missing | report_id={report_id} | path={sftp_path}")
        raise
    finally:
        sftp.close()
        transport.close()

    return local_file
