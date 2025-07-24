 with visits as (
  select
  brand,
  event_date,
  session_id,
  user_pseudo_id
  from tough-healer-395417.analytics_unified.fact_ga4_events
  where regexp_contains(page_location, r'/newlandingpage/|/offer_temp5\.jsp')
  and regexp_contains(page_location, r'AGXN003|AGXP003')
  and event_date >= '2025-06-10'
  group by all
  ),
  
  transactions as(
    select distinct
    v.session_id,
    t.transaction_id,
    t.ecommerce.purchase_revenue
    from visits v
    left join tough-healer-395417.analytics_unified.fact_ga4_transactions t
    using (session_id)
  ),
  
  filtered_transactions as (
  select distinct
  t.*
  from transactions t
  left join tough-healer-395417.analytics_reporting.rpt_ga4_transactions_items i
  using (transaction_id)
  where i.item_id = '20200SV'
  )
  select
  v.*,
  f.transaction_id,
  f.purchase_revenue
  from visits v
  left join filtered_transactions f
  using (session_id)