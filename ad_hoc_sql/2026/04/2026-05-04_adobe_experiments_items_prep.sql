SELECT
    t.transaction_date,
    t.brand,
    t.user_pseudo_id,
    t.session_id,
    s.device_category,
    t.transaction_id,
    i.item_id,
    i.item_name,
    i.price,
    i.quantity,
    i.item_revenue,
    s.experiment_id,
    s.experiment_name,
    s.experiment_group,
    s.experiment_promo_code,
    s.experiment_category,
    s.experiment_medium,
    s.experiment_source,
    s.is_final

FROM tough-healer-395417.analytics_unified.fact_ga4_transactions t 
  JOIN UNNEST(t.items) AS i
  JOIN tough-healer-395417.analytics_reporting.rpt_experiment_sessions s
  ON t.session_id = s.session_id
   and t.brand = s.brand
WHERE t.transaction_date >= '2026-01-01'