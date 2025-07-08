WITH
  free_shipping AS(
  SELECT
    'free shipping upsell' as segment,
    e.brand,
    DATE_TRUNC(event_date, YEAR) AS year,
    DATE_TRUNC(event_date, MONTH) AS month,
    COUNT(DISTINCT e.user_pseudo_id) AS users,
    COUNT(DISTINCT e.session_id) AS sessions,
    COUNT(DISTINCT t.transaction_id) AS transactions,
    SUM(t.ecommerce.purchase_revenue) AS revenue  
  FROM
    `tough-healer-395417.analytics_unified.fact_ga4_events` e
    LEFT JOIN tough-healer-395417.analytics_unified.fact_ga4_transactions t
    USING (session_id)
  WHERE
    event_name = 'mini_cart'
    AND event_category = 'add on'
    AND event_class LIKE 'Free Shipping%'
    AND event_date BETWEEN '2023-09-01' AND '2024-08-31'
    GROUP BY ALL  
    ),
    
  deployed AS(
  SELECT
    'deployed' as segment,
    e.brand,
    DATE_TRUNC(event_date, YEAR) AS year,
    DATE_TRUNC(event_date, MONTH) AS month,
    COUNT(DISTINCT e.user_pseudo_id) AS users,
    COUNT(DISTINCT e.session_id) AS sessions,
    COUNT(DISTINCT t.transaction_id) AS transactions,
    SUM(t.ecommerce.purchase_revenue) AS revenue 
  FROM
    `tough-healer-395417.analytics_unified.fact_ga4_events` e
    LEFT JOIN tough-healer-395417.analytics_unified.fact_ga4_transactions t
    USING (session_id)
  WHERE
    event_name = 'mini_cart'
    AND event_category = 'deployed'
    AND event_date BETWEEN '2023-09-01' AND '2024-08-31'
    GROUP BY ALL  
    )

select * from free_shipping
union all
select * from deployed
order by year, month


