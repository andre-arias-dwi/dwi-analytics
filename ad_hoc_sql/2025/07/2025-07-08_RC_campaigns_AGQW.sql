with page as (
SELECT distinct
user_pseudo_id,
session_id,
page_location,
promo_code

FROM tough-healer-395417.analytics_unified.fact_ga4_events

where promo_code like '%AGQW%'
and page_location like '%offer_temp5.jsp%'
and event_date between '2025-05-12' and '2025-07-08'
)

select
p.promo_code,
count(distinct p.user_pseudo_id) as users,
count(distinct p.session_id) as sessions,
count(distinct t.transaction_id) as transactions,
sum(t.ecommerce.purchase_revenue) as revenue
from page p
left join tough-healer-395417.analytics_unified.fact_ga4_transactions t
on p.session_id = t.session_id
group by 1