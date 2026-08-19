-- Where do visitors go NEXT from the gateway pages the "Taste Preferences"
-- dropdown link lands on? Sizes the cost of landing on a preferences form.
DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH pv AS (
  SELECT brand, session_id, page_number,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS path,
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand IN ('WSJ','LAW') AND event_date BETWEEN d_start AND d_end
    AND event_name = 'page_view'
),
keyed AS (
  SELECT brand, session_id, page_number,
    CASE
      WHEN brand='WSJ' AND path LIKE '%account_wine_preference.jsp'        THEN 'WSJ gateway: Wine Preferences'
      WHEN brand='LAW' AND path LIKE '%/jsp/mytaste/index.jsp' AND frag='' THEN 'LAW gateway: My Taste landing'
    END AS gateway,
    CASE
      WHEN path LIKE '%account_details.jsp'    AND frag='purchased'        THEN 'Wines Purchased'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag='purchased'        THEN 'Wines Purchased'
      WHEN path LIKE '%account_details.jsp'    AND frag='beyond-the-label' THEN 'Beyond the Label'
      WHEN path LIKE '%account_details.jsp'    AND frag='favorites'        THEN 'Favorites'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag='favorites'        THEN 'Favorites'
      WHEN path LIKE '%account_details.jsp'    AND frag='wine-cellar'      THEN 'My Wine Cellar'
      WHEN path LIKE '%account_details.jsp'    AND frag='top-rated'        THEN 'Top-Rated Wines'
      WHEN path LIKE '%account_details.jsp'    AND frag='recommendations'  THEN 'Recommendations'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag='justforyou'       THEN 'Recommendations'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag='preferences'      THEN 'Preferences form'
      WHEN path LIKE '%account_wine_preference.jsp'                        THEN 'Preferences form (repeat)'
      WHEN path LIKE '%/jsp/mytaste/index.jsp' AND frag=''                 THEN 'My Taste landing (repeat)'
      WHEN path LIKE '%account_order_history.jsp'                          THEN 'Order History'
      WHEN path LIKE '%account_details.jsp'                                THEN 'Account (other)'
      WHEN path LIKE '/product%'                                           THEN 'Product page'
      WHEN path = '/'                                                      THEN 'Homepage'
      WHEN path LIKE '%/jsp/checkout/%'                                    THEN 'Basket / checkout'
      ELSE 'Other site page'
    END AS dest
  FROM pv
)
SELECT
  g.gateway,
  COALESCE(n.dest, '>> LEFT THE SITE (no further pageview)') AS next_page,
  COUNT(*) AS pageviews,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY g.gateway), 1) AS pct
FROM keyed g
LEFT JOIN keyed n
  ON n.brand = g.brand AND n.session_id = g.session_id
 AND n.page_number = g.page_number + 1
WHERE g.gateway IS NOT NULL
GROUP BY g.gateway, next_page
HAVING pageviews >= 40
ORDER BY g.gateway, pageviews DESC
