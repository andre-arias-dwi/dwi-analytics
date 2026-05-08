SELECT
brand,
EXTRACT(MONTH FROM date) AS month,
EXTRACT(YEAR FROM date) AS year,
COUNT(DISTINCT user_pseudo_id) AS users,
COUNT(DISTINCT session_id) AS sessions,
COUNT(DISTINCT transaction_id)  AS transactions,
SUM(purchase_revenue) AS purchase_revenue,

FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` 
WHERE brand IN ('WSJ', 'LAW')
AND date BETWEEN '2025-01-01' AND '2025-04-21'
GROUP BY brand, month, year
ORDER BY brand, year, month