# 📦 SFTP to GCS Pipeline (REC008 / REC013)

This Cloud Run pipeline fetches daily CSV reports from an SFTP server, optionally cleans them, and uploads both raw and cleaned files to Google Cloud Storage (GCS).

---

## 🧠 Logic Overview

1. **Triggered by Cloud Scheduler**
2. **Connects to SFTP** (via VPN with approved static IP)
3. **Downloads daily file** (e.g. `REC008-YYYY-MM-DD.csv`)
4. **Uploads raw file to GCS** → `gs://dwi_data/REC008/raw/...`
5. **Cleans data** using a modular cleaner (`/cleaner/rec008.py`)
6. **Uploads cleaned file** → `gs://dwi_data/REC008/clean/...`

---

## ⚙️ Deployment Details

- **Runtime**: Python 3.11 on **Cloud Run (Gen 2)**
- **VPC connector**: Required for SFTP access via fixed outbound IP
- **Secrets**: `SFTP_PASSWORD` stored in Secret Manager and injected as an env var
- **Directory structure**:

  sftp_to_gcs/
  ├── main.py              # Entrypoint
  ├── run_pipeline.py      # Core pipeline logic
  ├── sftp_utils.py        # SFTP fetch logic
  ├── gcs_utils.py         # GCS uploader
  ├── cleaner/rec008.py    # Cleaning function for REC008
  ├── cleaner/rec013.py    # Cleaning function for REC013
  └── requirements.txt

---

## 🕒 Triggering

- **Cloud Scheduler** invokes the HTTP endpoint with query param:

  POST [https://your-cloud-run-url?report_id=REC008](https://your-cloud-run-url?report_id=REC008)

- **Two jobs set up**: one for `REC008`, one for `REC013`
- Example schedule: `0 9 * * *` (daily at 9AM)

---

## 🔔 Alerts

### A. Cloud Scheduler invocation failure (before function starts)

**Triggers on:**

- Missing/invalid identity token
- Timeout or VPC routing error
- URL unreachable

**Log-based filter:**

```text
resource.type="cloud_scheduler_job"
(jsonPayload.status="UNAUTHENTICATED" OR
 jsonPayload.status="PERMISSION_DENIED" OR
 jsonPayload.status="FAILED_PRECONDITION")
```

---

### B. Runtime error during pipeline execution

**Triggers on:**

- SFTP file not found
- Missing cleaning function
- Any uncaught Python exception

**Log-based filter:**

```text
resource.type="cloud_run_revision"
textPayload:"[ALERT] report_id=" AND textPayload:"ERROR:"
```

**Example log messages:**

- `[ALERT] SFTP file missing | report_id=REC008`
- `[ALERT] report_id=REC013 | ERROR: Exception - No cleaning function defined`

---

## ✅ Best Practices

- Modular cleaners for each report under `/cleaner/recXXX.py`
- New reports only require:
  - Cleaner function
  - Cloud Scheduler job with correct `report_id`
- Log alerts use meaningful patterns and exception types
- Raw files preserved in GCS even if cleaning fails

---

## 📎 Related Links

- [Cloud Run logs](https://console.cloud.google.com/run/)
- [Cloud Scheduler jobs](https://console.cloud.google.com/cloudscheduler)
- [Alert policies](https://console.cloud.google.com/monitoring/alerts)
- [Secret Manager](https://console.cloud.google.com/security/secret-manager)
