# GA4 Intraday Pipeline — Phase Plan (Concise)

## Executive Summary
Add **intraday freshness** to GA4 with a tiny Dataform pipeline that mirrors Superform, **unions all properties**, and feeds GLS. Keep it **simple**, use **hourly full‑refresh tables**, align **final** intraday schemas to your daily `analytics_unified` facts, and include a **brand** column end‑to‑end. Intraday reads a rolling **yesterday + today** window because daily exports land unpredictably (≈8am–5pm).

---

## Scope & Ground Rules
- **Sources:** `events_intraday_*` for **yesterday and today** (48‑hour window).
- **Union all properties:** in the first step (events) using your brands list; carry **brand** + `property_id` downstream.
- **Session ID:** `farm_fingerprint(user_pseudo_id || ga_session_id)` (Superform‑style global session id).
- **Attribution (intraday):** from the **first event by time** in a session using `traffic_source.*`, with **NULLs ignored** → “first **non‑null** by time” for `source`, `medium`, `campaign`.
- **Schemas:** only **final** intraday tables match daily (`fact_ga4_sessions`, `fact_ga4_transactions`). Intermediates stay minimal but include **brand** for joins and reporting.

---

## Architecture (Phase 1 → 3)
```
events_intraday_* (per property; yesterday+today)
        └─(UNION ALL across properties; add brand)
            ▼
fact_ga4_intraday_events            [TABLE, hourly, partition: event_date]
    ├─▶ int_ga4_intraday_sessions   [TABLE, partition: session_date]
    │     └─▶ fact_ga4_intraday_sessions   [TABLE, final schema = daily]
    └─▶ int_ga4_intraday_transactions [TABLE, partition: event_date]
          └─▶ fact_ga4_intraday_transactions [TABLE, final schema = daily]

(Optional GLS) ▶ rpt_ga4_intraday_* [VIEW → TABLE if needed]
```

---

## Phase 1 — Standalone Intraday (Ship Fast)
**All models as TABLES** (hourly full refresh). Read **yesterday + today** intraday and **union all properties** (add **brand**).

**Attribution (core idea):**
```sql
-- first-by-time, first NON-NULL in-session
ARRAY_AGG(field IGNORE NULLS ORDER BY event_ts_micros ASC LIMIT 1)[SAFE_OFFSET(0)]
-- apply to traffic_source.source, .medium, .name (campaign)
```

**Partition/Cluster (recommended):**
- Events: `event_date` | `["event_name","session_id","user_pseudo_id","brand"]`
- Sessions: `session_date` | `["session_id","brand","lnd_source","lnd_medium"]`
- Transactions: `transaction_date` | `["transaction_id","session_id","brand"]`

**GLS:** keep `rpt_ga4_intraday_*` as **VIEW** first; flip to **TABLE** if you need extra speed.

**Schedule:** hourly (e.g., 08:00–23:00, property TZ).

---

## Phase 2 — Hardening & Performance
- Keep **hourly full refresh** (bounded scans: yesterday+today). Monitor job bytes on `fact_ga4_intraday_events` × runs/day.
- If needed later, switch to **incremental (yesterday+today only)** with keys:
  - Sessions: `(brand, property_id, user_pseudo_id, session_id)`
  - Transactions: `(brand, property_id, transaction_id)`
- Continue partitioning and clustering as above for predictable cost and fast BI.

---

## Phase 3 — Integrate with Daily Workflow (Incrementality & Late Daily)
Daily tables may arrive late; intraday can span **two days**. Use a **prefer‑final** strategy:

**Simple + robust union (no duplicates):**
1) Take all **final** rows for dates **< (today − 1)**.
2) For **yesterday** and **today**, take **intraday** rows **minus** any session/transaction already present in final.

Conceptually:
```sql
-- sessions
Final (< today-1)
UNION ALL
Intraday (yesterday,today) LEFT ANTI JOIN Final ON (brand, session_id, session_date)
-- transactions: (brand, transaction_id, transaction_date)
```
This naturally stops using yesterday’s intraday as soon as the daily export lands, while keeping today fresh.

(Alternative: at the source, only include yesterday’s `_TABLE_SUFFIX` when its final daily does **not** exist, using INFORMATION_SCHEMA.)

---

## Reporting Time Buckets (Hour / 30‑min)
Use the **final sessions** field `time.session_start_timestamp_utc` for time‑series reports. Derive buckets in the **RPT** layer (keeps final schema stable).

Examples (conceptual):
- **Hour:** `TIMESTAMP_TRUNC(time.session_start_timestamp_utc, HOUR)`  
- **30‑min:** `TIMESTAMP_SECONDS(1800 * DIV(UNIX_SECONDS(time.session_start_timestamp_utc), 1800))`  
- **Local time:** convert using brand timezone (e.g., `'America/New_York'`) before bucketing.

---

## Implementation Checklist
- [ ] Union intraday across properties (carry **brand**, `property_id`).
- [ ] Read **yesterday + today** from `events_intraday_*`.
- [ ] Session attribution = **first non‑null by time** for `source/medium/campaign`.
- [ ] Final intraday schemas mirror daily facts; intermediates minimal.
- [ ] RPT derives **hour/30‑min** buckets from `time.session_start_timestamp_utc` (optionally local TZ).
- [ ] Hourly schedule; watch job bytes; adjust cadence if needed.
