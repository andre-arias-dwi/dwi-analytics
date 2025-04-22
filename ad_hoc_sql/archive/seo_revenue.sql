SELECT SUM(t.ecommerce.purchase_revenue) AS revenue
FROM `tough-healer-395417.BI.LAW_ga4_sessions` s
LEFT JOIN `tough-healer-395417.BI.LAW_ga4_transactions` t
ON s.session_id = t.session_id
WHERE (s.medium = 'organic' OR (s.source IS NULL AND s.medium IS NULL))
    AND (REGEXP_CONTAINS(s.landing_page_location, r"/(product|wines|wine|search|wine-blog|advent|gifts)(\/.*|\?.*|\/$|$)")
        AND s.landing_page_location NOT LIKE '%promoCode%')
    AND s.hostname = 'www.laithwaites.com'
    AND s.country != 'India'
    AND s.session_date BETWEEN '2025-02-08' AND '2025-02-14'