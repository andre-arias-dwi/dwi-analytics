select
s.date,
s.brand,
s.transaction_id,
i.item_id,
i.item_name,
s.landing_page_location,
s.lnd_source_medium,
s.lnd_campaign,
d.ReportingSalesActivity,
d.media,
d.DWResponseCode,
from tough-healer-395417.analytics_reporting.rpt_ga4_sessions_transactions s
left join tough-healer-395417.analytics_reporting.rpt_ga4_transactions_items i
using (transaction_id)
left join tough-healer-395417.analytics_unified.dim_order_details d
on s.transaction_id = d.ATGSalesOrderNumber
where (s.landing_page_location like '%AGYL001%'
or s.landing_page_location like '%AHHR001%')
and s.date >= '2025-06-01'
and s.transaction_id is not null
order by date