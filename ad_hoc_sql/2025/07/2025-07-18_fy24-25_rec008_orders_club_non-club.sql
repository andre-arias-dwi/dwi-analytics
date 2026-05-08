SELECT
  t.brand,
  t.dwi_order_type,                       -- Club vs Non-Club
  COUNT(DISTINCT t.transaction_id) AS orders,
  SUM(t.purchase_revenue)         AS revenue
FROM   analytics_reporting.rpt_ga4_sessions_transactions t
WHERE date BETWEEN '2024-06-29' AND '2025-06-27'
GROUP  BY t.brand, t.dwi_order_type;
