SELECT
  coalesce(t.transaction_id, o.ATGSalesOrderNumber) AS transaction_id,
  coalesce(t.transaction_date, o.OrderDate) AS order_date,
  coalesce(o.DWResponseCode, 'not found in gms') AS gms_response_code,
  coalesce(s.lnd_source_medium, 'not found in ga4') AS source_medium,
  coalesce(s.lnd_campaign, 'not found in ga4') AS campaign,
  coalesce(s.lnd_content, 'not found in ga4') AS content
FROM `tough-healer-395417.analytics_unified.fact_ga4_transactions` t
FULL JOIN `analytics_unified.dim_order_details` o
  ON
    t.transaction_id = o.ATGSalesOrderNumber
    AND t.transaction_date > '2025-11-19'
LEFT JOIN analytics_unified.fact_ga4_sessions s
  ON
    t.session_id = s.session_id
    AND s.session_date > '2025-11-19'
    AND s.brand = 'WSJ'
WHERE
  o.DWResponseCode IN ('AHGP007', 'AHGP002')
  OR (
    lnd_source_medium = 'cm_dm / postcard'
    AND lnd_campaign = 'nov2025_react')
