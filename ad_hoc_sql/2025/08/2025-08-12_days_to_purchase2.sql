-- Purpose: New-recruit purchases with first-touch attribution, days-to-purchase,
--          and a count of all sessions up to (and including) the purchase.
-- Strategy:
--   1) Build first-touch with "best of both worlds" (prefer ga_session_number; fallback to earliest timestamp)
--   2) Build a per-transaction purchase snapshot (timestamp, revenue, etc.)
--   3) Count all sessions per user with session_start_timestamp_utc <= purchase_ts
--   4) Join everything; exclude users with multiple "new orders" (dup ambiguity)

WITH
  -- 1) New orders pulled from DWI
  new_orders AS (
    SELECT
      OrderDate,
      ATGSalesOrderNumber
    FROM `tough-healer-395417.analytics_unified.dim_order_details`
    WHERE OrderDate >= DATE '2025-01-01'
      AND Customer_Status = 'New Recruit'
      AND SALESSTATUS = 'Invoiced'
  ),

  -- 2) Users who appear on multiple "new orders" (exclude to avoid ambiguity)
  dups AS (
    SELECT
      user_pseudo_id
    FROM new_orders o
    JOIN `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` s
      ON o.ATGSalesOrderNumber = s.transaction_id
    GROUP BY user_pseudo_id
    HAVING COUNT(*) > 1
  ),

  -- 3) Build first-touch candidates per user from the full sessions table
  first_candidates AS (
    SELECT
      user_pseudo_id,

      -- First by session number (tie-break: timestamp, then session_id)
      ARRAY_AGG(STRUCT(
          session_id,
          ga_session_number,
          session_start_timestamp_utc,
          date,
          lnd_source_medium
        )
        ORDER BY ga_session_number ASC, session_start_timestamp_utc ASC, session_id ASC
        LIMIT 1
      )[OFFSET(0)] AS by_num,

      -- First by chronological start time (tie-break: session number, then session_id)
      ARRAY_AGG(STRUCT(
          session_id,
          ga_session_number,
          session_start_timestamp_utc,
          date,
          lnd_source_medium
        )
        ORDER BY session_start_timestamp_utc ASC, ga_session_number ASC, session_id ASC
        LIMIT 1
      )[OFFSET(0)] AS by_time

    FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions`
    WHERE session_start_timestamp_utc IS NOT NULL
    GROUP BY user_pseudo_id
  ),

  -- 4) Prefer numbered pick when it matches the time-ordered pick; else use time-ordered
  first_touch AS (
    SELECT
      user_pseudo_id,
      IF(by_num.session_id = by_time.session_id, by_num, by_time) AS ft,
      by_num.session_id != by_time.session_id AS first_touch_disagrees
    FROM first_candidates
  ),

  -- 5) Build a single purchase snapshot per (user, transaction)
  --    (We join DWI orders to keep only invoiced New Recruits; exclude "dup" users later.)
  purchase_sessions AS (
    SELECT
      s.brand,
      s.user_pseudo_id,
      s.transaction_id,
      -- purchase session info
      MIN(s.date)                         AS purchase_date,
      ANY_VALUE(s.ga_session_number)      AS purchase_session_number,
      ANY_VALUE(s.lnd_source_medium)      AS purchase_lnd_source_medium,
      MIN(s.session_start_timestamp_utc)      AS purchase_ts,
      -- revenue can exist on multiple rows of the purchase session → sum it
      SUM(s.purchase_revenue)             AS revenue
    FROM new_orders o
    JOIN `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` s
      ON o.ATGSalesOrderNumber = s.transaction_id
    GROUP BY s.brand, s.user_pseudo_id, s.transaction_id
  ),

  -- 6) Count all sessions for the user with start <= purchase_ts (bounded count)
  sessions_until_purchase AS (
    SELECT
      p.user_pseudo_id,
      p.transaction_id,
      COUNT(DISTINCT s2.session_id) AS sessions_until_purchase
    FROM purchase_sessions p
    JOIN `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` s2
      ON s2.user_pseudo_id = p.user_pseudo_id
     AND s2.session_start_timestamp_utc IS NOT NULL
     AND s2.session_start_timestamp_utc <= p.purchase_ts  -- bound by purchase timestamp
    GROUP BY p.user_pseudo_id, p.transaction_id
  )

-- 7) Final: join purchase snapshot + first touch + bounded session count; exclude dup users
SELECT
  p.brand,
  p.user_pseudo_id,
  p.transaction_id,

  -- Purchase metrics
  p.revenue,
  p.purchase_date,
  p.purchase_session_number,
  p.purchase_lnd_source_medium,

  -- First-session touchpoint (resolved with fallback logic)
  ft.ft.date                    AS first_session_date,
  ft.ft.lnd_source_medium       AS first_session_lnd_source_medium,

  -- Days from first session to purchase session (timestamp-based for accuracy)
  TIMESTAMP_DIFF(p.purchase_ts, ft.ft.session_start_timestamp_utc, DAY) AS days_to_purchase,

  -- Bounded session count (all sessions up to and including purchase)
  stp.sessions_until_purchase,

  -- Optional QA flag: when ga_session_number and time order disagree for first touch
  ft.first_touch_disagrees

FROM purchase_sessions p
JOIN first_touch ft
  ON ft.user_pseudo_id = p.user_pseudo_id
LEFT JOIN sessions_until_purchase stp
  ON stp.user_pseudo_id = p.user_pseudo_id
 AND stp.transaction_id = p.transaction_id
LEFT JOIN dups d
  ON d.user_pseudo_id = p.user_pseudo_id           -- anti-join style
WHERE d.user_pseudo_id IS NULL
ORDER BY
  p.purchase_date ASC;
