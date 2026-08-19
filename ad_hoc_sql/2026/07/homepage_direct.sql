select
--page_path,
count(distinct session_id) as sessions,
count(if(event_name = 'page_view', 1, null)) as pageviews,
count(distinct user_pseudo_id) as users,
--from analytics_reporting.rpt_ga4_sessions_transactions
from analytics_unified.fact_ga4_events
where event_date between '2026-05-08' and '2026-06-19'
--and channel_category = 'Direct'
and page_type = 'homepage'
and brand = 'WSJ'
--group by page_path