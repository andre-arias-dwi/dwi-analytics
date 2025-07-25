WITH
  order_ids AS (
  SELECT
    *
  FROM
    UNNEST([ 'o5511198784','o5485720342','o5509019096','o5509580106','o5509657076','o5510520106','o5510603127','o5511117160','o5511180101','o5397996430','o5509679722','o5509807920','o5510546718','o5511875054','o5507884495','o5508957313','o5507636888','o5501319704','o5509074184','o5511175406','o5511165123','o5508105862','o5509683392','o5509788818','o5509916002','o5508889473','o5509786173','o5508091166','o5508187910','o5511423228','o5511186672','o5511818514','o5508899599','o5510508748','o5511078775','o5510235535','o5511113923','o5511376889','o5508219327','o5510536943','o5510485814','o5509546317','o5512826646','o5515689068','o5513002673','o5511204287','o5511206544','o5510726773','o5509105259','o5513663674','o5516578896','o5516646334','o5517357839','o5517482921','o5517737871','o5511281824','o5511925390','o5514471528','o5511454403','o5514695368','o5512222795','o5512927425','o5514316342','o5511941536','o5513579365','o5463410806','o5513002748','o5514531895','o5512992945','o5511444257','o5512004495','o5513811971','o5514597357','o5517222043','o5512135307','o5511588414','o5511210074','o5514456202','o5512122970','o5513734567','o5514284448','o5504714493','o5514649838','o5508972600','o5511347344','o5512270130','o5515655281','o5518592374','o5514827134','o5518642010','o5512002178','o5522427123','o5523052406','o5520309603','o5522769256','o5521654538','o5522894046','o5522929350','o5519121612','o5520811127','o5525432537','o5522684675','o5522895918','o5524812835','o5521802735','o5524760176','o5522622422','o5523823234','o5523000516','o5519280401','o5519258185','o5519278218','o5522629081','o5522664067','o5519373573','o5446777239','o5522879073','o5522481949','o5525033463','o5511456085','o5509905532','o5522708931','o5519895179','o5518534603','o5525355178','o5521494743','o5527599356','o5525627381','o5522792535','o5527999441','o5527427111','o5527907090','o5525552581','o5527121430' ]) AS order_id ),
  order_items AS (
  SELECT
    oi.transaction_id,
    oi.item_id,
    oi.item_name,
    oi.session_id
  FROM
    order_ids AS o
  JOIN
    `analytics_reporting.rpt_ga4_transactions_items` AS oi
  ON
    oi.transaction_id = o.order_id
  WHERE
    date >= '2025-06-01' ),
  line_flags AS (
  SELECT
    *,
    CASE
      WHEN item_id IN ('20197SV', '20225SV') THEN 1
      ELSE 0
  END
    AS is_advent_sku
  FROM
    order_items ),
  flagged_orders AS (
  SELECT
    *,
    MAX(is_advent_sku) OVER (PARTITION BY transaction_id) AS has_advent_sku
  FROM
    line_flags ),
  advent_sessions AS (
  SELECT
    DISTINCT session_id,
  FROM
    `analytics_unified.fact_ga4_events`
  WHERE
    page_location LIKE '%AH2Z%'
    AND event_date >= '2025-06-01' )
SELECT
  o.AXSAlesOrderNumber,
  st.session_date,
  oi.transaction_id,
  oi.item_id,
  oi.item_name,
  REGEXP_REPLACE( st.landing_page.landing_page_location, r'^https?://(?:www\.)?laithwaites\.com', '' ) AS landing_page_path_query,
    st.lnd_source_medium,
  IF
    ( ai.session_id IS NOT NULL, 'Yes', 'No' ) AS visited_advent_page,
    CASE
      WHEN oi.has_advent_sku = 1 THEN 'Yes'
      ELSE 'No'
  END
    AS purchased_advent_item
  FROM
    flagged_orders AS oi
  LEFT JOIN
    `analytics_unified.fact_ga4_sessions` AS st
  USING
    (session_id)
  LEFT JOIN
    advent_sessions AS ai
  USING
    (session_id)
  LEFT JOIN
    tough-healer-395417.analytics_unified.dim_order_details o
  ON
    oi.transaction_id = o.ATGSalesOrderNumber
  WHERE
    session_date >= '2025-06-01'