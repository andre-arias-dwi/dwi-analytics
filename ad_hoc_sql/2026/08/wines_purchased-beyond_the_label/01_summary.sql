-- Executive summary rows, structured to mirror the UK Adobe workbook:
-- Account benchmark, then the two focus pages, plus Order History as the
-- "is this redundant?" comparator. US total and per brand.
DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH ev AS (
  SELECT brand, session_id, user_pseudo_id, event_name, hit_number, page_number,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS path,
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand IN ('WSJ','LAW') AND event_date BETWEEN d_start AND d_end
),
labelled AS (
  SELECT brand, session_id, user_pseudo_id, hit_number, page_number,
    CASE
      WHEN path LIKE '%account_details.jsp'    AND frag = 'beyond-the-label' THEN 'Beyond the Label'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag = 'purchased'        THEN 'Wines Purchased'
      WHEN path LIKE '%account_details.jsp'    AND frag = 'purchased'        THEN 'Wines Purchased'
      WHEN path LIKE '%account_order_history.jsp' THEN 'Order History'
      WHEN path LIKE '%/jsp/account/%' OR path LIKE '%/jsp/mytaste/%' THEN 'Account (any page)'
    END AS page_label
  FROM ev WHERE event_name = 'page_view'
),
-- 'Account (any page)' must also include the focus pages themselves
expanded AS (
  SELECT brand, session_id, user_pseudo_id, hit_number, page_number, page_label
  FROM labelled WHERE page_label IS NOT NULL
  UNION ALL
  SELECT brand, session_id, user_pseudo_id, hit_number, page_number, 'Account (any page)'
  FROM labelled WHERE page_label IN ('Beyond the Label','Wines Purchased','Order History')
),
sig AS (
  SELECT brand, session_id,
    ARRAY_AGG(IF(event_name='view_item',   page_number, NULL) IGNORE NULLS) AS pdp_pages,
    ARRAY_AGG(IF(event_name='add_to_cart', page_number, NULL) IGNORE NULLS) AS atc_pages,
    MAX(IF(event_name='view_item',   hit_number, NULL)) AS last_pdp_hit,
    MAX(IF(event_name='add_to_cart', hit_number, NULL)) AS last_atc_hit
  FROM ev WHERE event_name IN ('view_item','add_to_cart') GROUP BY brand, session_id
),
txn AS (
  SELECT brand, session_id, COUNT(DISTINCT transaction_id) AS transactions,
         SUM(ecommerce.purchase_revenue) AS revenue
  FROM `tough-healer-395417.analytics_unified.fact_ga4_transactions`
  WHERE brand IN ('WSJ','LAW') AND transaction_date BETWEEN d_start AND d_end
  GROUP BY brand, session_id
),
sp AS (
  SELECT brand, page_label, session_id,
    ANY_VALUE(user_pseudo_id) AS user_pseudo_id,
    MIN(hit_number) AS first_hit,
    ARRAY_AGG(DISTINCT page_number) AS pages
  FROM expanded GROUP BY brand, page_label, session_id
),
flagged AS (
  SELECT sp.brand, sp.page_label, sp.session_id, sp.user_pseudo_id,
    EXISTS (SELECT 1 FROM UNNEST(sp.pages) p WHERE p+1 IN UNNEST(COALESCE(s.pdp_pages, []))) AS next_pdp,
    EXISTS (SELECT 1 FROM UNNEST(sp.pages) p WHERE p+1 IN UNNEST(COALESCE(s.atc_pages, []))) AS next_atc,
    COALESCE(s.last_pdp_hit > sp.first_hit, FALSE) AS eventual_pdp,
    COALESCE(s.last_atc_hit > sp.first_hit, FALSE) AS eventual_atc,
    COALESCE(t.transactions,0) AS transactions,
    COALESCE(t.revenue,0)      AS revenue
  FROM sp
  LEFT JOIN sig s USING (brand, session_id)
  LEFT JOIN txn t USING (brand, session_id)
),
scoped AS (
  SELECT 'US total' AS scope, page_label, session_id, user_pseudo_id,
         next_pdp, next_atc, eventual_pdp, eventual_atc, transactions, revenue
  FROM flagged
  UNION ALL
  SELECT brand, page_label, session_id, user_pseudo_id,
         next_pdp, next_atc, eventual_pdp, eventual_atc, transactions, revenue
  FROM flagged
),
agg AS (
  SELECT scope, page_label,
    COUNT(DISTINCT session_id) AS visits,
    COUNT(DISTINCT user_pseudo_id) AS users,
    SUM(transactions) AS transactions,
    ROUND(SUM(revenue),0) AS revenue,
    ROUND(100*COUNTIF(transactions>0)/COUNT(*),2) AS conv_pct,
    ROUND(100*COUNTIF(next_pdp)/COUNT(*),2)     AS pdp_next_pct,
    ROUND(100*COUNTIF(eventual_pdp)/COUNT(*),2) AS pdp_eventual_pct,
    ROUND(100*COUNTIF(next_atc)/COUNT(*),2)     AS atb_next_pct,
    ROUND(100*COUNTIF(eventual_atc)/COUNT(*),2) AS atb_eventual_pct
  FROM scoped GROUP BY scope, page_label
)
SELECT
  a.scope, a.page_label, a.visits, a.users,
  ROUND(100*a.visits/b.visits, 2)   AS pct_of_account_visits,
  a.transactions, a.revenue,
  ROUND(100*a.revenue/b.revenue, 2) AS pct_of_account_revenue,
  a.conv_pct, a.pdp_next_pct, a.pdp_eventual_pct, a.atb_next_pct, a.atb_eventual_pct
FROM agg a
JOIN (SELECT scope, visits, revenue FROM agg WHERE page_label='Account (any page)') b
  USING (scope)
ORDER BY
  CASE a.scope WHEN 'US total' THEN 1 WHEN 'WSJ' THEN 2 ELSE 3 END,
  CASE a.page_label WHEN 'Account (any page)' THEN 1 WHEN 'Wines Purchased' THEN 2
                    WHEN 'Beyond the Label' THEN 3 ELSE 4 END
