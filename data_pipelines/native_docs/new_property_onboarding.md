# Onboarding a New GA4 Property into Dataform

This guide explains the process to add a new GA4 export dataset into our Dataform pipeline.

---

## 1. Install Superform Repo (ga4dataform.com)

- Download from [ga4dataform.com](https://ga4dataform.com) and follow the setup instructions.  
- In Dataform, select **“Process data now”** and **“Schedule workflow”** to deploy & run the initial build.  
- Confirm that a new repo (`superform_analytics_<propertyID>`) is created in Dataform, and that all Superform datasets are successfully built.  

✅ **Why:** This gives you the raw GA4-enhanced models (sessions, transactions, events) for the new property.  

---

## 2. Apply Custom Configs in the Superform Repo

- Add project-specific configs in `includes/custom/config.js`:  
  - `CUSTOM_EVENT_PARAMS_ARRAY`  
  - `CUSTOM_URL_PARAMS_ARRAY`  
  - `GA4_START_DATE`  

- In `includes/core/default_config.js`, set:  
  - `TRANSACTIONS_DEDUPE = true`  

- Run all actions with **full refresh** (ensures all new configs propagate).  
- Create `assert_ga4_table_ready` in `definitions/custom/` (copy from an existing repo, update property ID).  
- In `definitions/core/03_outputs/ga4-events.sqlx`, add:  

  ```js
  dependencies: ["assert_ga4_table_ready"],
  ```

  to ensure models only build once the daily GA4 table is present.  

- Commit changes and schedule the workflow to run hourly between **8AM–5PM EST**.  

✅ **Why:** These configs align the repo to our standards (custom params, deduped transactions, table availability checks).  

---

## 3. Update `analytics_unified` Repo

- In `includes/brands.js`, add the new brand/property attributes (dataset name, brand code, etc.).  
- Commit changes.  
- Run:  
  - `int_events`  
  - `int_sessions`  
  - `int_transactions`  
  with **“Include dependents”** checked.  

✅ **Why:** This ensures the unified models start pulling in data from the new property.  

---

## 4. Validate

- Check the new brand in `rpt_sessions_transactions` and compare counts vs. GA4 UI.  
- Check the new brand in:  
  - `fact_searchdata_site_impression`  
  - `fact_searchdata_url_impression`  
  and validate vs. GSC UI.  
- Confirm joins against the fiscal calendar dimension.  

✅ **Why:** Validation confirms data quality before stakeholders rely on it.  
