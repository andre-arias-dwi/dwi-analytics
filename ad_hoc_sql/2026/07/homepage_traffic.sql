/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

select --page_path,
    count(distinct user_pseudo_id) as users,
    count(distinct session_id) as sessions,
    count(if(event_name = 'page_view', 1, null)) as pageviews
from analytics_unified.fact_ga4_events
where event_date between '2026-06-29' and '2026-08-10'
    and page_type = 'homepage'
    and brand = 'LAW' --group by page_path