-- Focus pages by acquisition channel: TOTAL plus a source/medium breakdown,
-- so the traffic mix is visible rather than assumed.
DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH ev AS (
  SELECT
    brand, session_id, user_pseudo_id, event_name, hit_number, page_number,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS path,
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand IN ('WSJ','LAW') AND event_date BETWEEN d_start AND d_end
),
focus AS (
  SELECT brand, session_id, user_pseudo_id, hit_number, page_number,
    CASE
      WHEN path LIKE '%account_details.jsp'   AND frag = 'beyond-the-label' THEN 'Beyond the Label'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag = 'purchased'       THEN "Wines I've Purchased"
      WHEN path LIKE '%account_details.jsp'   AND frag = 'purchased'        THEN "Wines I've Purchased"
    END AS page_label
  FROM ev WHERE event_name = 'page_view'
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
  SELECT brand, session_id,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(ecommerce.purchase_revenue) AS revenue
  FROM `tough-healer-395417.analytics_unified.fact_ga4_transactions`
  WHERE brand IN ('WSJ','LAW') AND transaction_date BETWEEN d_start AND d_end
  GROUP BY brand, session_id
),
src AS (
  SELECT brand, session_id, channel_category, lnd_source_medium
  FROM `tough-healer-395417.analytics_unified.fact_ga4_sessions`
  WHERE brand IN ('WSJ','LAW') AND session_date BETWEEN d_start AND d_end
),
sp AS (
  SELECT brand, page_label, session_id,
    ANY_VALUE(user_pseudo_id) AS user_pseudo_id,
    MIN(hit_number) AS first_hit,
    ARRAY_AGG(DISTINCT page_number) AS pages
  FROM focus WHERE page_label IS NOT NULL
  GROUP BY brand, page_label, session_id
),
flagged AS (
  SELECT sp.brand, sp.page_label, sp.session_id, sp.user_pseudo_id,
    COALESCE(sc.channel_category, '(unknown)')  AS channel_category,
    COALESCE(sc.lnd_source_medium, '(unknown)') AS source_medium,
    EXISTS (SELECT 1 FROM UNNEST(sp.pages) p WHERE p+1 IN UNNEST(COALESCE(s.pdp_pages, []))) AS next_pdp,
    EXISTS (SELECT 1 FROM UNNEST(sp.pages) p WHERE p+1 IN UNNEST(COALESCE(s.atc_pages, []))) AS next_atc,
    COALESCE(s.last_pdp_hit > sp.first_hit, FALSE) AS eventual_pdp,
    COALESCE(s.last_atc_hit > sp.first_hit, FALSE) AS eventual_atc,
    COALESCE(t.transactions, 0) AS transactions,
    COALESCE(t.revenue, 0) AS revenue
  FROM sp
  LEFT JOIN sig s USING (brand, session_id)
  LEFT JOIN txn t USING (brand, session_id)
  LEFT JOIN src sc USING (brand, session_id)
)
SELECT
  brand, page_label, grouping_level, channel, sessions, users, transactions, revenue,
  conv_rate_pct, next_step_pdp_pct, eventual_pdp_pct, next_step_atc_pct, eventual_atc_pct
FROM (
  -- TOTAL row
  SELECT brand, page_label, 'TOTAL' AS grouping_level, 'All traffic' AS channel,
    COUNT(DISTINCT session_id) AS sessions, COUNT(DISTINCT user_pseudo_id) AS users,
    SUM(transactions) AS transactions, ROUND(SUM(revenue),0) AS revenue,
    ROUND(100*COUNTIF(transactions>0)/COUNT(*),2) AS conv_rate_pct,
    ROUND(100*COUNTIF(next_pdp)/COUNT(*),2)     AS next_step_pdp_pct,
    ROUND(100*COUNTIF(eventual_pdp)/COUNT(*),2) AS eventual_pdp_pct,
    ROUND(100*COUNTIF(next_atc)/COUNT(*),2)     AS next_step_atc_pct,
    ROUND(100*COUNTIF(eventual_atc)/COUNT(*),2) AS eventual_atc_pct,
    1 AS ord, 0 AS sortkey
  FROM flagged GROUP BY brand, page_label

  UNION ALL
  -- by channel category
  SELECT brand, page_label, 'CHANNEL', channel_category,
    COUNT(DISTINCT session_id), COUNT(DISTINCT user_pseudo_id),
    SUM(transactions), ROUND(SUM(revenue),0),
    ROUND(100*COUNTIF(transactions>0)/COUNT(*),2),
    ROUND(100*COUNTIF(next_pdp)/COUNT(*),2),
    ROUND(100*COUNTIF(eventual_pdp)/COUNT(*),2),
    ROUND(100*COUNTIF(next_atc)/COUNT(*),2),
    ROUND(100*COUNTIF(eventual_atc)/COUNT(*),2),
    2, COUNT(DISTINCT session_id)
  FROM flagged GROUP BY brand, page_label, channel_category

  UNION ALL
  -- by source / medium
  SELECT brand, page_label, 'SOURCE_MEDIUM', source_medium,
    COUNT(DISTINCT session_id), COUNT(DISTINCT user_pseudo_id),
    SUM(transactions), ROUND(SUM(revenue),0),
    ROUND(100*COUNTIF(transactions>0)/COUNT(*),2),
    ROUND(100*COUNTIF(next_pdp)/COUNT(*),2),
    ROUND(100*COUNTIF(eventual_pdp)/COUNT(*),2),
    ROUND(100*COUNTIF(next_atc)/COUNT(*),2),
    ROUND(100*COUNTIF(eventual_atc)/COUNT(*),2),
    3, COUNT(DISTINCT session_id)
  FROM flagged GROUP BY brand, page_label, source_medium
)
WHERE sessions >= 40
ORDER BY brand, page_label, ord, sortkey DESC
