SELECT 
brand,
landing_page_path,
landing_page_type,
lnd_medium,
ROUND(SUM(purchase_revenue), 2) AS revenue
FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions`
WHERE (lnd_medium = 'organic' OR lnd_source_medium = 'none / none')
AND REGEXP_CONTAINS(landing_page_location, r'\/(product|wines|wine|search|wine-blog|advent|gifts|wine-club|wine-club-subscription|wineclub|vineyard-partners)(\/|\?|$)')
AND landing_page_location NOT LIKE '%promoCode%'
AND date BETWEEN '2024-06-29' and '2025-06-06'
GROUP BY 1, 2, 3, 4
ORDER BY brand, revenue DESC