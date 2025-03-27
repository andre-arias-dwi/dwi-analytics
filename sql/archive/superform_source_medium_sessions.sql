SELECT
CONCAT(
  COALESCE(last_non_direct_traffic_source.source, '(not set)'),
   " / ",
  COALESCE(last_non_direct_traffic_source.medium, '(not set)')
  ) as source_medium,
COUNT(distinct s.user_pseudo_id) AS users,
COUNT(distinct s.session_id) AS sessions,
COUNT(distinct t.transaction_id) AS transactions,
COALESCE(SUM(t.ecommerce.purchase_revenue), 0) AS revenue

FROM `tough-healer-395417.superform_outputs_287832387.ga4_sessions` s
LEFT JOIN `tough-healer-395417.superform_outputs_287832387.ga4_transactions` t
USING(session_id)
WHERE 
  session_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY source_medium
ORDER BY users DESC