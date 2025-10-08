# GA4 Intraday Pipeline — Phase Plan (Concise)

## Executive Summary
Add **intraday freshness** to GA4 with a tiny Dataform pipeline that mirrors Superform, **unions all properties**, and feeds GLS. We’ll keep it **simple**, use **hourly full-refresh tables**, and align **final** intraday schemas to your daily `analytics_unified` facts.

---

## Scope & Ground Rules
- **Sources:** `events_intraday_*` (today only) in each GA4 dataset.
- **Union all properties:** in the first step (events) using your brands list.
- **Session ID:** `farm_fingerprint(user_pseudo_id || ga_session_id)` (Superform style).
- **Attribution (intraday):** use `traffic_source.*` from the **first event by time** in each session.
- **Schemas:** only **final** intraday tables must match daily (`fact_ga4_sessions`, `fact_ga4_transactions`). Intermediates carry only minimal extra fields.

---

## Architecture (Phase 1 → 3)
```
events_intraday_* (per property) ──(UNION ALL)──▶ fact_ga4_intraday_events  [TABLE, hourly, partition: event_date]
                                                      ├──▶ int_ga4_intraday_sessions           [TABLE, partition: session_date]
                                                      │        └──▶ fact_ga4_intraday_sessions [TABLE, final schema = daily]
                                                      └──▶ int_ga4_intraday_transactions       [TABLE, partition: event_date]
                                                               └──▶ fact_ga4_intraday_transactions [TABLE, final schema = daily]

(Optional GLS) ▶ rpt_ga4_intraday_* [VIEW → TABLE if needed]
```

---

## Phase 1 — Standalone Intraday (Ship Fast)
**Models:** all **TABLES** (hourly full refresh).

- **Events (union all properties):**
  ```sql
  SELECT ... FROM `project.analytics_<pid>.events_intraday_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  UNION ALL
  -- repeat for each property_id
  ```
- **Session landing (first-by-time):**
  ```sql
  ARRAY_AGG(ts_source   IGNORE NULLS ORDER BY event_ts_micros ASC LIMIT 1)[SAFE_OFFSET(0)] AS lnd_source,
  ARRAY_AGG(ts_medium   IGNORE NULLS ORDER BY event_ts_micros ASC LIMIT 1)[SAFE_OFFSET(0)] AS lnd_medium,
  ARRAY_AGG(ts_campaign IGNORE NULLS ORDER BY event_ts_micros ASC LIMIT 1)[SAFE_OFFSET(0)] AS lnd_campaign
  ```
- **Partition/Cluster:**
  - Events: `event_date` | `["event_name","session_id","user_pseudo_id"]`
  - Sessions: `session_date` | `["session_id","lnd_source","lnd_medium"]`
  - Transactions: `transaction_date` | `["transaction_id","session_id"]`
- **GLS:** `rpt_ga4_intraday_*` as **VIEW** first; flip to **TABLE** if needed.

**Schedule:** hourly (e.g., 08:00–23:00, property TZ).

---

## Phase 2 — Hardening & Performance
- **Keep hourly full-refresh TABLES** (recommended first; today-only scans keep cost bounded).
- If needed later, switch selected models to **incremental (today-only)** keyed by:
  - Sessions: `(user_pseudo_id, session_id, property_id)`
  - Transactions: `transaction_id`
- **Monitor cost:** check bytes on `fact_ga4_intraday_events` per run × runs/day.

---

## Phase 3 — Integrate with Daily Workflow
**Simplest robust union:**
```sql
-- Sessions
SELECT * FROM fact_ga4_sessions WHERE session_date < CURRENT_DATE()
UNION ALL
SELECT * FROM fact_ga4_intraday_sessions WHERE session_date = CURRENT_DATE();

-- Transactions
SELECT * FROM fact_ga4_transactions WHERE transaction_date < CURRENT_DATE()
UNION ALL
SELECT * FROM fact_ga4_intraday_transactions WHERE transaction_date = CURRENT_DATE();
```
- Next morning, once daily exports land, the union naturally stops using yesterday’s intraday.
- Optional: watcher to reprocess “last 1–3 days” after `events_YYYYMMDD` exists.

---

## Implementation Checklist
- [ ] Union-all properties in `fact_ga4_intraday_events` (Superform-style `session_id`).
- [ ] Build `int_*` (sessions/transactions) with **first-by-time traffic_source** logic.
- [ ] Align **final** intraday schemas 1:1 with daily facts.
- [ ] Add `rpt_ga4_intraday_*` for GLS.
- [ ] Schedule hourly; verify job bytes and dashboard latency.

---
