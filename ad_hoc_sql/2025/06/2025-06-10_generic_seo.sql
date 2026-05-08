SELECT 
brand,
--landing_page_type,
ROUND(SUM(purchase_revenue), 2) AS revenue
FROM `tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions`
WHERE landing_page_type IN (
      "advent", "product detail", "product listing", "blog", "gifts",
      "wine club", "vineyard partners", "free shipping", "content template", "next template", "cmlp sale", "offer template", "cm template", "category temp1", "clp expired", "clp temp offer",
      "customer service"
    )
    AND (
      (lnd_medium = 'organic')
      OR (
        lnd_source_medium = 'none / none'
        AND (landing_page_location NOT LIKE '%promoCode=%'
          OR landing_page_location NOT LIKE '%cid=%')
      )
      
    )
    AND date BETWEEN '2024-06-29' AND '2025-06-06'
GROUP BY all
ORDER BY brand, revenue DESC