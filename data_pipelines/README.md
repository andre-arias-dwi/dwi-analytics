# Data Pipelines Overview

This folder contains the code and documentation for data ingestion pipelines.

---

## 🐍 Python Scripts

- [SFTP to GCS](./sftp_to_gcs): Ingests daily CSV reports from an SFTP server into Google Cloud Storage (GCS).  
- [SFTP to GCS All Files](./sftp_to_gcs_all): Ad hoc function to backfill all files from an SFTP server to GCS.

---

## 🔄 Dataform

- [Dataform New Property Onboarding (GA, GSC)](./native_docs/new_property_onboarding.md): Steps for onboarding new GA/GSC properties.  
- [Dataform Repo Documentation](https://github.com/andre-arias-dwi/analytics_unified): Main Dataform repo integrating GA4 exports with internal data.
- [GA Intraday Pipeline - Phase Plan](./native_docs/ga_intraday_plan.md): Phase plans to add intraday freshness to GA models in dataform.

---

## 🔄 BigQuery Data Transfers

- **Google Analytics**: Native BigQuery export for GA4 properties.  
- **Google Ads**: BigQuery Data Transfer Service for ads campaign data.  
- **Google Search Console**: Native export integration for search performance data.  
- **REC Reports (Internal BI)**: CSVs ingested from Google Cloud Storage into BigQuery.  
- **Meta Ads**: BigQuery Data Transfer Service for paid social campaigns.  
- [Fiscal Calendars](./native_docs/GCS_fiscal_calendar.md): Ingests fiscal calendar CSVs from GCS into BigQuery.
