-- temp5_nonclub_orders_oneoff.sql
WITH temp5_sessions AS (
  SELECT DISTINCT session_id
  FROM analytics_unified.fact_ga4_events
  WHERE event_name = 'page_view'
    AND event_date BETWEEN '2024-06-29' AND '2025-06-27'        -- FY-24-25
  QUALIFY
    -- session saw a Temp 5 offer page         
    MAX(REGEXP_CONTAINS(page_location, r'/offer_temp5\.jsp'))
        OVER (PARTITION BY session_id)
    /**AND
    -- and also hit a CLP checkout page in same session
    MAX(REGEXP_CONTAINS(
          page_location,
          r'/checkout/.*(lp-redirect|confirmation\.jsp)'
        )) OVER (PARTITION BY session_id)*/
)

SELECT
  t.brand,
  t.dwi_order_type,                       -- Club vs Non-Club
  COUNT(DISTINCT t.transaction_id) AS orders,
  SUM(t.purchase_revenue)         AS revenue
FROM   temp5_sessions s
JOIN   analytics_reporting.rpt_ga4_sessions_transactions t
       USING (session_id)
GROUP  BY t.brand, t.dwi_order_type;
