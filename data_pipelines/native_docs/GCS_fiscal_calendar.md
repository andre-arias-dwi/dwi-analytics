
# 📆 Fiscal Calendar Update Workflow

## Purpose

This workflow ensures that fiscal calendar data is available in daily granularity and properly joined to downstream transactional models. It supports time-based aggregations such as fiscal week, month, quarter, and year across reports.

---

## Overview

| Step | Description |
|------|-------------|
| 1. Upload | Upload a new fiscal year CSV to Cloud Storage |
| 2. Load | GCS → BigQuery transfer appends data to `stg_fiscal_weeks` |
| 3. Transform | `dim_fiscal_dates` expands weekly data into daily rows |
| 4. Consumption | Downstream models join with `dim_fiscal_dates` by date |

---

## Step-by-Step

### 1️⃣ Upload New Fiscal Calendar CSV

- Upload to:

```bash gs://dwi_data/fiscal_calendars/```

- File naming convention:

  ```bash
  FY 2025-26 Fiscal Calendar by Week.csv

  ```

- The file must include:
  - `week_start`, `week_end`, `week`, `month`, `fiscal_year`
- Each row represents one fiscal week.

> 🔁 This happens once per year, shortly before or after the new fiscal year begins.

---

### 2️⃣ Daily Data Transfer Service (GCS → BigQuery)

**Transfer Config**:

| Field | Value |
|-------|-------|
| Source | Google Cloud Storage |
| URI | `gs://dwi_data/fiscal_calendars/*.csv` |
| Destination Dataset | `analytics_staging` |
| Destination Table | `stg_fiscal_weeks` |
| Write Preference | `APPEND` |
| Repeat Frequency | Every 24 hours |
| File Format | CSV |
| Header Rows to Skip | 1 |
| Encoding | UTF-8 |
| Notifications | Email enabled |

**Behavior**:

- Only new files are processed.
- Files already appended are ignored (by design).
- Source files are retained in GCS.

---

### 3️⃣ `dim_fiscal_dates` Model

**Type**: `incremental`  
**Output Table**: `analytics_unified.dim_fiscal_dates`

**Logic**:

- Reads from `analytics_staging.stg_fiscal_weeks`
- Uses `GENERATE_DATE_ARRAY` to expand each week into daily rows
- Adds helper columns:
  - Fiscal week number
  - Fiscal month/quarter
  - Fiscal day of week/month/year
  - Month names and display numbers

**Partitioning**:

- Partitioned by `date`
- Clustered by `fiscal_year`, `fiscal_week_number`

**Run Frequency**:

- Daily (via Dataform schedule)

---

## 🔁 Backfilling Late Fiscal Year Uploads

If the fiscal calendar is uploaded **after** the fiscal year starts:

- The incremental model will **not backfill past dates** automatically.
- This results in missing fiscal dimensions for past events.

### ✅ Solution

1. Temporarily hardcode:

   ```sql
   SET date_checkpoint = DATE('YYYY-MM-DD'); -- e.g., '2024-06-28'
   ```

2. Re-run `dim_fiscal_dates` to backfill
3. Restore original logic afterward
