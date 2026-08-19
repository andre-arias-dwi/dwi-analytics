WITH adobe_experiments AS (
  SELECT DISTINCT
    event_date,
    brand,
    user_pseudo_id,
    session_id,
    device_category,
    SAFE_CAST(REGEXP_EXTRACT(experiment_name, r'DWCX-(\d+)') AS INT64) AS experiment_id,
    CASE experiment_experience
    WHEN 'Experience A' THEN 'control'
    WHEN 'Experience B' THEN 'test'
    ELSE 'unknown'
END AS experiment_group,
    promo_code AS experiment_promo_code
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE event_name = 'target_experiment_started'
    AND experiment_name LIKE 'DWCX-481%'
    AND event_date >= '2026-05-01'
)

SELECT
e.event_date,
e.brand,
e.user_pseudo_id,
e.session_id,
e.device_category,
t.transaction_id,
t.ecommerce.purchase_revenue,
e.experiment_id,
m.experiment_name,
e.experiment_group,
e.experiment_promo_code,
m.experiment_category,
m.experiment_medium,
'adobe_target' AS experiment_source
FROM adobe_experiments e
LEFT JOIN `tough-healer-395417.analytics_unified.fact_ga4_transactions` t
  ON e.session_id = t.session_id AND e.brand = t.brand AND t.transaction_date >= '2026-05-01'
left join `tough-healer-395417.analytics_unified.dim_experiment_group_mapping`m
on e.experiment_id = m.experiment_id
and e.experiment_group = m.experiment_group
and e.experiment_promo_code = m.landing_page_promocode
and e.brand = m.brand
WHERE m.experiment_id IS NOT NULL



UNION all

SELECT
    s.session_date,
    s.brand,
    s.user_pseudo_id,
    s.session_id,
    s.device.category AS device_category,
    t.transaction_id,
    t.ecommerce.purchase_revenue,
    m.experiment_id,
    m.experiment_name,
    m.experiment_group,
    m.landing_page_promocode AS experiment_promo_code,
    m.experiment_category,
    m.experiment_medium,
    'preassigned_split' AS experiment_source
FROM `tough-healer-395417.analytics_unified.fact_ga4_sessions` s
LEFT JOIN `tough-healer-395417.analytics_unified.fact_ga4_transactions` t
  ON s.session_id = t.session_id
  AND s.brand = t.brand
  and t.transaction_date >= '2025-07-01'
LEFT JOIN `tough-healer-395417.analytics_unified.dim_experiment_group_mapping` m
  ON s.brand = m.brand
  AND s.landing_page_type = m.landing_page_type
  AND s.landing_page_promocode = m.landing_page_promocode
WHERE s.session_date >= '2025-07-01'
  AND m.experiment_id IS NOT NULL
