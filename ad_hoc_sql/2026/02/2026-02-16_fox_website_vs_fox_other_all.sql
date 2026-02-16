-- FOX brand only: fox/website vs FOX other sources, ALL SESSIONS
WITH sessions_cohort AS (
  SELECT
    session_date,
    session_id,
    IF(
      lnd_source = 'fox' AND lnd_medium = 'website',
      'FOX fox/website',
      'FOX other sources'
    ) AS cohort,
    IFNULL(time.engagement_time_msec, 0) AS session_engagement_time_msec,
    landing_page.landing_page_referrer AS landing_referrer,
    geo.city AS geo_city,
    device.operating_system AS device_operating_system
  FROM `tough-healer-395417.analytics_unified.fact_ga4_sessions`
  WHERE session_date > DATE '2025-08-01'
    AND brand = 'FOX'
    AND landing_page.landing_page_path LIKE '%/jsp/newlandingpage/us/home.jsp%'
),

profile AS (
  SELECT
    e.event_date AS session_date,
    e.session_id,
    COUNT(*) AS events,
    COUNTIF(e.event_name = 'page_view') AS pageviews,
    COUNTIF(e.event_name = 'user_engagement') AS user_engagement_events,
    TIMESTAMP_DIFF(MAX(e.event_timestamp_utc), MIN(e.event_timestamp_utc), SECOND) AS event_span_s,
    MAX(IF(e.event_name = 'purchase' OR e.ecommerce.transaction_id IS NOT NULL, 1, 0)) AS did_purchase,
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events` e
  JOIN sessions_cohort s
    ON s.session_date = e.event_date
   AND s.session_id = e.session_id
  WHERE e.event_date > DATE '2025-08-01'
  GROUP BY 1,2
),

joined AS (
  SELECT
    p.*,
    s.cohort,
    s.session_engagement_time_msec,
    s.landing_referrer,
    s.geo_city,
    s.device_operating_system
  FROM profile p
  JOIN sessions_cohort s
    ON s.session_date = p.session_date
   AND s.session_id = p.session_id
)

SELECT
  cohort,
  COUNT(*) AS sessions,
  SAFE_DIVIDE(COUNTIF(event_span_s = 0), COUNT(*)) AS pct_session_duration_0s,
  SAFE_DIVIDE(COUNTIF(user_engagement_events = 0), COUNT(*)) AS pct_no_user_engagement_event,
  SAFE_DIVIDE(COUNTIF(did_purchase = 0), COUNT(*)) AS pct_no_purchase,
  SAFE_DIVIDE(COUNTIF(pageviews = 1), COUNT(*)) AS pct_1_pageview,
  SAFE_DIVIDE(COUNTIF(events BETWEEN 3 AND 5), COUNT(*)) AS pct_events_3_5,
  SAFE_DIVIDE(COUNTIF(session_engagement_time_msec = 0), COUNT(*)) AS pct_session_engagement_0ms,
  SAFE_DIVIDE(COUNTIF(landing_referrer IS NULL OR landing_referrer = ''), COUNT(*)) AS pct_no_referrer,
  SAFE_DIVIDE(COUNTIF(geo_city IS NULL OR geo_city = ''), COUNT(*)) AS pct_no_geo_city,
  -- Device mix (sessions-table)
  SAFE_DIVIDE(COUNTIF(LOWER(device_operating_system) = 'ios'), COUNT(*)) AS pct_ios,
  SAFE_DIVIDE(COUNTIF(LOWER(device_operating_system) = 'macintosh'), COUNT(*)) AS pct_macintosh
FROM joined
GROUP BY cohort
ORDER BY cohort
