-- Purpose: For first-time customers (new recruits) with invoiced orders since 2025-01-01,
--          return purchase revenue, first-session touchpoint, and purchase-session touchpoint.

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

  -- 3) First touch per user by lowest ga_session_number
  --    (tie-breaks by date and session_id for determinism)
  first_touch AS (
    SELECT
      user_pseudo_id,
      ARRAY_AGG(
        STRUCT(ga_session_number, date, lnd_source_medium)
        ORDER BY ga_session_number ASC, date ASC, session_id ASC
        LIMIT 1
      )[OFFSET(0)] AS ft
    FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions`
    WHERE ga_session_number IS NOT NULL
    GROUP BY user_pseudo_id
  )

-- 4) Join purchase sessions to first touch; exclude dup users
SELECT
  s.brand,
  s.user_pseudo_id,
  s.transaction_id,

  -- Purchase metrics (these rows are limited to the purchase session via the join on transaction_id)
  SUM(s.purchase_revenue)                          AS revenue,
  MIN(s.date)                                      AS purchase_date,
  ANY_VALUE(s.ga_session_number)                   AS purchase_session_number,
  ANY_VALUE(s.lnd_source_medium)                   AS purchase_lnd_source_medium,

  -- First-session touchpoint (from the user-level first_touch CTE)
  ft.ft.date                                       AS first_session_date,
  ft.ft.lnd_source_medium                          AS first_session_lnd_source_medium

FROM new_orders o
JOIN `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` s
  ON o.ATGSalesOrderNumber = s.transaction_id      -- keeps only the purchase session rows
JOIN first_touch ft
  ON ft.user_pseudo_id = s.user_pseudo_id
LEFT JOIN dups d
  ON d.user_pseudo_id = s.user_pseudo_id           -- anti-join pattern to exclude dup users
WHERE d.user_pseudo_id IS NULL
GROUP BY
  s.brand,
  s.user_pseudo_id,
  s.transaction_id,
  ft.ft.date,
  ft.ft.lnd_source_medium
ORDER BY
  purchase_date ASC;
