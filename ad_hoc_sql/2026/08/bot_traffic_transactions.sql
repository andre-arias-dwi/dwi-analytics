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

select
brand,
date,
--lnd_source_medium,
lnd_campaign,
count(distinct session_id) as sessions,
count(distinct transaction_id) as transactions
--transaction_id,

--landing_page_promocode,
-- DWResponseCode
from tough-healer-395417.analytics_reporting.rpt_ga4_unfiltered_sessions_transactions s
left join tough-healer-395417.analytics_unified.dim_order_details o
on s.transaction_id = o.ATGSalesOrderNumber

where lnd_campaign IN (
    'us_dw_wsjwine_social_meta_offers_std_adv',
    'us_dw_lw_social_meta_15_gold_medal_std',
    'us_dw_lw_std_sommtv_cvr'
)
and lnd_source IN (
    'fb', 'facebook'
)
and date between '2025-11-15' and '2025-12-21'
and transaction_id is not null
group by all
