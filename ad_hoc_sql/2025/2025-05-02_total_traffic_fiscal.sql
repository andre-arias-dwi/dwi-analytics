SELECT
brand,
fiscal_year,
fiscal_month_name,
fiscal_month_number,
fiscal_month_name,
'Total Website Traffic' AS segment,
COUNT(DISTINCT user_pseudo_id) AS users,
COUNT(DISTINCT session_id) AS sessions,
COUNT(DISTINCT transaction_id)  AS transactions,
SUM(purchase_revenue) AS purchase_revenue,

FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions` 
WHERE brand IN ('WSJ', 'LAW')
AND date BETWEEN '2023-08-26' AND '2025-04-25'
GROUP BY all
ORDER BY 1, 2, 4