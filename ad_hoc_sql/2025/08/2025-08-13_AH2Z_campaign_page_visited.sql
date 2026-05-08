-- AH2Z pageview flag per *order* (transaction), counting only pageviews before the purchase
with users as (
  SELECT 
  user_pseudo_id, 
  transaction_id,
  transaction_date,
  time.event_timestamp
  from tough-healer-395417.analytics_unified.fact_ga4_transactions
  where transaction_id IN ( --transactions provided by CM relevant to the promo code
    'o5511198784', 'o5485720342', 'o5509019096', 'o5509580106', 'o5509657076', 'o5510520106', 'o5510603127', 'o5511117160', 'o5511180101', 'o5397996430', 'o5509679722', 'o5509807920', 'o5510546718', 'o5511875054', 'o5507884495', 'o5508957313', 'o5507636888', 'o5501319704', 'o5509074184', 'o5511175406', 'o5511165123', 'o5508105862', 'o5509683392', 'o5509788818', 'o5509916002', 'o5508889473', 'o5509786173', 'o5508091166', 'o5508187910', 'o5511423228', 'o5511186672', 'o5511818514', 'o5508899599', 'o5510508748', 'o5511078775', 'o5510235535', 'o5511113923', 'o5511376889', 'o5508219327', 'o5510536943', 'o5510485814', 'o5509546317', 'o5512826646', 'o5515689068', 'o5513002673', 'o5511204287', 'o5511206544', 'o5510726773', 'o5509105259', 'o5513663674', 'o5516578896', 'o5516646334', 'o5517357839', 'o5517482921', 'o5517737871', 'o5511281824', 'o5511925390', 'o5514471528', 'o5511454403', 'o5514695368', 'o5512222795', 'o5512927425', 'o5514316342', 'o5511941536', 'o5513579365', 'o5463410806', 'o5513002748', 'o5514531895', 'o5512992945', 'o5511444257', 'o5512004495', 'o5513811971', 'o5514597357', 'o5517222043', 'o5512135307', 'o5511588414', 'o5511210074', 'o5514456202', 'o5512122970', 'o5513734567', 'o5514284448', 'o5504714493', 'o5514649838', 'o5508972600', 'o5511347344', 'o5512270130', 'o5515655281', 'o5518592374', 'o5514827134', 'o5518642010', 'o5512002178', 'o5522427123', 'o5523052406', 'o5520309603', 'o5522769256', 'o5521654538', 'o5522894046', 'o5522929350', 'o5519121612', 'o5520811127', 'o5525432537', 'o5522684675', 'o5522895918', 'o5524812835', 'o5521802735', 'o5524760176', 'o5522622422', 'o5523823234', 'o5523000516', 'o5519280401', 'o5519258185', 'o5519278218', 'o5522629081', 'o5522664067', 'o5519373573', 'o5446777239', 'o5522879073', 'o5522481949', 'o5525033463', 'o5511456085', 'o5509905532', 'o5522708931', 'o5519895179', 'o5518534603', 'o5525355178', 'o5521494743', 'o5527599356', 'o5525627381', 'o5522792535', 'o5527999441', 'o5527427111', 'o5527907090', 'o5525552581', 'o5527121430'
  )
)

select distinct
u.user_pseudo_id,
u.transaction_id,
u.transaction_date,

-- Window over each order so every joined event row for the same order gets the same flag.
logical_or(REGEXP_CONTAINS(e.page_location, r'(?i)AH2Z')) OVER (PARTITION BY u.transaction_id) as ah2z_flag,
-- Windowed MIN over only AH2Z matches → earliest AH2Z pageview *before* purchase.
    MIN(IF(REGEXP_CONTAINS(e.page_location, r'(?i)AH2Z'), e.event_date, NULL)) OVER (PARTITION BY u.transaction_id) AS page_visited_date
FROM users u
left join `tough-healer-395417.analytics_unified.fact_ga4_events` e
on u.user_pseudo_id = e.user_pseudo_id 
and event_name = 'page_view'
and event_date between '2024-01-01' and '2025-07-21' -- partition pruning
and e.event_timestamp < u.event_timestamp -- only events *before* the purchase
