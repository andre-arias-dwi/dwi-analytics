WITH presale_visits AS (
  SELECT
    brand,
    event_date,
    session_id,
    user_pseudo_id
  FROM `analytics_unified.fact_ga4_events`
  WHERE event_date >= '2025-06-10'
    AND REGEXP_CONTAINS(page_location, r'/newlandingpage/|/offer_temp5\.jsp')
    AND REGEXP_CONTAINS(page_location, r'AGXN003|AGXP003')
  GROUP BY 1,2,3,4
)

SELECT
  v.*,
  t.transaction_id,
  t.ecommerce.purchase_revenue
FROM presale_visits v
LEFT JOIN `analytics_unified.fact_ga4_transactions`           t
       USING (session_id)
LEFT JOIN `analytics_reporting.rpt_ga4_transactions_items`   i
       ON  t.transaction_id = i.transaction_id
       AND i.item_id       = '20200SV'   -- <<< filter lives in ON clause
WHERE t.transaction_id IS NULL           -- keep all non-buyers
   OR i.item_id       = '20200SV';       -- keep only Magpie buyers