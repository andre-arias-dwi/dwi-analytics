
# 📦 SFTP to GCS Pipeline (REC008 / REC013)

This Cloud Run pipeline fetches daily CSV reports from an SFTP server, optionally cleans them, and uploads both raw and cleaned files to Google Cloud Storage (GCS).

---

## 🧠 Logic Overview

1. **Triggered by Cloud Scheduler**
2. **Connects to SFTP** (via VPC with approved static IP)
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

```text
sftp_to_gcs/
├── main.py              # Entrypoint
├── run_pipeline.py      # Core pipeline logic
├── sftp_utils.py        # SFTP fetch logic
├── gcs_utils.py         # GCS uploader
├── cleaner/rec008.py    # Cleaning function for REC008
├── cleaner/rec013.py    # Cleaning function for REC013
└── requirements.txt
```

---

## 🕒 Triggering

- **Cloud Scheduler** invokes the HTTP endpoint with query param:

  ```text
  POST https://your-cloud-run-url?report_id=REC008
  ```

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

## 🌐 Networking Architecture (How SFTP Access Works)

This pipeline relies on a **controlled outbound networking setup** to ensure all SFTP traffic exits Google Cloud from a **single, static IP** that is allowlisted by IT.

This section explains **what components exist**, **how traffic flows**, and **how to troubleshoot when things break**.

---

### 🧩 Components Involved

#### 1. VPC (Virtual Private Cloud)

- A private network in GCP (`sftp-vpc`)
- Contains subnets, routes, firewall rules, and NAT
- By itself, **Cloud Run does not live in the VPC**

Think of the VPC as **the private network we want Cloud Run to temporarily use**.

---

#### 2. Serverless VPC Connector

- A managed bridge between **Cloud Run** and the **VPC**
- Uses a dedicated **/28 subnet**
- Has a minimum of **2 instances** (cannot scale to zero)
- Required because Cloud Run is serverless and external to the VPC by default

Think of it as ***a network adapter that plugs Cloud Run into the VPC***.

---

#### 3. Cloud NAT + Cloud Router

- Cloud NAT provides **outbound internet access** for private IPs
- Uses a **reserved static external IP**
- All traffic exiting through NAT appears to come from this IP

This is the IP that:

- IT allowlists on the SFTP server
- Must remain stable for SFTP access to work

---

### 🔁 Traffic Flow (Mental Model)

When the pipeline runs, traffic flows like this:

```text
Cloud Scheduler
↓
Cloud Run (Python container)
↓
Serverless VPC Connector
↓
VPC Subnet (private IP)
↓
Cloud NAT
↓
Static Public IP (allowlisted)
↓
SFTP Server
↓
GCS Bucket
```

Key rule:
> **Cloud Run must be configured to “route all traffic through the VPC”**  
Otherwise, traffic bypasses NAT and uses random Google egress IPs.

---

### ⚙️ Required Cloud Run Settings

For this pipeline to work correctly:

- VPC connector attached
- Traffic routing set to **route all traffic through the VPC**
- Scheduler sends an identity token
- Optional but recommended:
  - Cloud Run minimum instances = 2 (minimum)
  - CPU always allocated

---

### 🚨 Common Failure Modes & What to Check

#### 1. Network is unreachable or SFTP timeouts

Most common cause: broken or wedged **Serverless VPC connector**

What to check:

- Can the service reach any external site
- Does the NAT IP appear in logs
- If not, recreate the connector

Recreating the connector is safe and often the fastest fix.

---

#### 2. External IP works, but SFTP times out

Likely cause: traffic is bypassing NAT

What to check:

- Cloud Run traffic routing is set to private ranges only
- Traffic exits via random IPv4 or IPv6

Fix: switch back to **route all traffic through the VPC**

---

#### 3. NAT looks healthy but nothing gets through

Important detail: NAT can be running even if traffic never reaches it

What to check:

- Enable NAT logging temporarily
- If no NAT logs appear, traffic is not reaching NAT
- Points to connector or routing issue

---

### 🔄 Why Recreating the Connector Works

Serverless VPC connectors are:

- Managed infrastructure
- Stateful at the network level
- Known to occasionally enter bad routing states

Symptoms:

- No config changes
- Worked yesterday, broken today
- NAT never sees traffic
- Network is unreachable errors

Best practice: **create a new connector, attach it, test, then delete the old one**.

---

### 🧠 Summary Mental Model

- VPC = private network
- Subnet = IP space
- VPC connector = serverless bridge
- Cloud NAT = static internet exit
- Cloud Run = compute that borrows the VPC

If SFTP breaks, always ask:

1. Is traffic going through the connector
2. Is traffic reaching NAT
3. Is NAT using the expected static IP

---

This setup is intentionally more complex than default Cloud Run networking, but it is the correct and secure design for SFTP access with IP allowlisting.

---

## 📎 Related Links

- [Cloud Run logs](https://console.cloud.google.com/run/)
- [Cloud Scheduler jobs](https://console.cloud.google.com/cloudscheduler)
- [Alert policies](https://console.cloud.google.com/monitoring/alerts)
- [Secret Manager](https://console.cloud.google.com/security/secret-manager)
