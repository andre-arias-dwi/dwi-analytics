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

-- Placement traffic summary (Homepage / PDP / PLP), unfiltered (analytics_staging.int_ga4_events).
-- "Unfiltered" = bypasses int_ga4_sessions_filters (no country/hostname/bot/referral exclusions) —
-- see fact_ga4_events.sqlx for the standard exclusions this query intentionally skips.
--
-- Note: the N06265 PDP / LAW row is included for completeness but has no matching traffic
-- (N06265 is WSJ-only); it will return zero users/sessions/pageviews.

WITH placements AS (
  SELECT * FROM UNNEST([
    STRUCT('Homepage'             AS placement, 'WSJ' AS brand, DATE('2026-05-08') AS start_date, DATE('2026-06-19') AS end_date, 'homepage' AS page_type, CAST(NULL AS STRING) AS sku),
    STRUCT('Homepage',                          'WSJ', DATE('2026-06-29'), DATE('2026-08-10'), 'homepage', NULL),
    STRUCT('Homepage',                          'LAW', DATE('2026-06-29'), DATE('2026-08-10'), 'homepage', NULL),
    STRUCT('N06264 PDP',                        'LAW', DATE('2026-06-25'), DATE('2026-08-19'), 'pdp',      'N06264'),
    STRUCT('N06265 PDP',                        'LAW', DATE('2026-03-18'), DATE('2026-08-19'), 'pdp',      'N06265'),
    STRUCT('N06264 PDP',                        'WSJ', DATE('2026-06-25'), DATE('2026-08-19'), 'pdp',      'N06264'),
    STRUCT('N06265 PDP',                        'WSJ', DATE('2026-03-18'), DATE('2026-08-19'), 'pdp',      'N06265'),
    STRUCT('Mixed Wine Cases PLP',              'LAW', DATE('2026-05-08'), DATE('2026-08-19'), 'plp',      NULL),
    STRUCT('Mixed Wine Cases PLP',              'WSJ', DATE('2026-05-08'), DATE('2026-08-19'), 'plp',      NULL),
    STRUCT('Mixed Wine Cases PLP (N06264)',     'LAW', DATE('2026-06-25'), DATE('2026-08-19'), 'plp',      NULL),
    STRUCT('Mixed Wine Cases PLP (N06265)',     'LAW', DATE('2026-03-18'), DATE('2026-08-19'), 'plp',      NULL),
    STRUCT('Mixed Wine Cases PLP (N06264)',     'WSJ', DATE('2026-06-25'), DATE('2026-08-19'), 'plp',      NULL),
    STRUCT('Mixed Wine Cases PLP (N06265)',     'WSJ', DATE('2026-03-18'), DATE('2026-08-19'), 'plp',      NULL)
  ])
)
SELECT
  p.placement,
  p.brand,
  p.start_date AS start_date,
  p.end_date   AS end_date,
  COUNT(DISTINCT e.user_pseudo_id) AS users,
  COUNT(DISTINCT e.session_id) AS sessions,
  COUNTIF(e.event_name = 'page_view') AS pageviews
FROM placements p
LEFT JOIN analytics_staging.int_ga4_events e
  ON e.brand = p.brand
  AND e.event_date BETWEEN p.start_date AND p.end_date
  AND (
    (p.page_type = 'homepage' AND e.page_path IN ('/', '/jsp/homepage.jsp'))
    OR (p.page_type = 'pdp' AND e.page_path LIKE '%product%' AND e.page_path LIKE CONCAT('%', p.sku, '%'))
    OR (p.page_type = 'plp' AND e.page_path LIKE '/wine/mixed-wine-cases%')
  )
GROUP BY p.placement, p.brand, p.start_date, p.end_date
ORDER BY p.placement, p.brand, p.start_date
