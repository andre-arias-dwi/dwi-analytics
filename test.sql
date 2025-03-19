SELECT
EXTRACT(YEAR FROM event_date) AS year,
EXTRACT(MONTH FROM event_date) AS month,
  event_params_custom.login_status,
    COUNT(DISTINCT user_pseudo_id) AS users

FROM `tough-healer-395417.superform_outputs_287163560.ga4_events`
    
WHERE event_name = 'page_view'
AND event_date BETWEEN '2023-09-01' AND '2025-03-11'
AND geo.country != 'India'
AND page.hostname = 'www.laithwaites.com'
GROUP BY month, login_status
ORDER BY year, month, login_status