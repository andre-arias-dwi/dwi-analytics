-- Where do people arrive at the two focus pages FROM?
-- Preceding pageview (page_number - 1) within the same session.
DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH pv AS (
  SELECT
    brand, session_id, page_number,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS path,
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand IN ('WSJ','LAW')
    AND event_date BETWEEN d_start AND d_end
    AND event_name = 'page_view'
),
keyed AS (
  SELECT brand, session_id, page_number, path, frag,
    CASE
      WHEN path LIKE '%account_details.jsp' AND frag = 'beyond-the-label' THEN 'Beyond the Label'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag = 'purchased'     THEN "Wines I've Purchased"
      WHEN path LIKE '%account_details.jsp' AND frag = 'purchased'        THEN "Wines I've Purchased"
    END AS focus_page,
    -- readable label for the PREVIOUS page
    CASE
      WHEN path LIKE '%account_wine_preference.jsp'  THEN 'Wine Preferences (Wine Cellar gateway)'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag = '' THEN 'My Taste landing'
      WHEN path LIKE '%/jsp/mytaste/index.jsp'       THEN CONCAT('My Taste - ', frag)
      WHEN path LIKE '%account_details.jsp' AND frag = '' THEN 'Account home'
      WHEN path LIKE '%account_details.jsp'          THEN CONCAT('Account - ', frag)
      WHEN path LIKE '%account_order_history.jsp'    THEN 'Order History'
      WHEN path LIKE '%wp_summary.jsp'               THEN 'My Clubs'
      WHEN path LIKE '%cellar_homepage.jsp'          THEN 'Cellar Homepage'
      WHEN path LIKE '%account_lists.jsp'            THEN 'Account Lists'
      WHEN path = '/'                                THEN 'Homepage'
      WHEN path LIKE '/product%'                     THEN 'PDP'
      WHEN path LIKE '%/authn/%'                     THEN 'Login'
      ELSE 'Other site page'
    END AS prev_label
  FROM pv
)
SELECT
  f.brand,
  f.focus_page,
  COALESCE(p.prev_label, '(session entry - no prior page)') AS arrived_from,
  COUNT(*) AS pageviews,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY f.brand, f.focus_page), 1) AS pct
FROM keyed f
LEFT JOIN keyed p
  ON  p.brand = f.brand
  AND p.session_id = f.session_id
  AND p.page_number = f.page_number - 1
WHERE f.focus_page IS NOT NULL
GROUP BY f.brand, f.focus_page, arrived_from
HAVING pageviews >= 30
ORDER BY f.brand, f.focus_page, pageviews DESC
