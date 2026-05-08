-- Stakeholder pack (FOX only): daily KPIs split by referrer group + sessions engagement_time_msec
WITH
  sessions_fox AS (
    SELECT
      session_date,
      session_id,
      IF(
        landing_page.landing_page_referrer IS NULL
          OR landing_page.landing_page_referrer = '',
        'referrer_null',
        'referrer_present') AS referrer_group,
      IFNULL(time.engagement_time_msec, 0) AS session_engagement_time_msec,
      geo.city AS geo_city,

      -- add device fields (keep names as they exist in your table)
      device.operating_system AS device_operating_system
    FROM tough-healer-395417.analytics_unified.fact_ga4_sessions
    WHERE
      session_date > DATE '2025-08-01'
      AND brand = 'FOX'
      AND lnd_source = 'fox'
      AND lnd_medium = 'website'
      AND landing_page.landing_page_path
        LIKE '%/jsp/newlandingpage/us/home.jsp%'
  ),

  lp_sessions AS (
    SELECT session_date AS session_date, session_id
    FROM tough-healer-395417.analytics_unified.fact_ga4_sessions
    WHERE
      session_date > DATE '2025-08-01'
      AND landing_page.landing_page_path
        LIKE '%/jsp/newlandingpage/us/home.jsp%'
    GROUP BY 1, 2
  ),

  profile AS (
    SELECT
      e.event_date AS session_date,
      e.session_id,
      COUNT(*) AS events,
      COUNTIF(e.event_name = 'page_view') AS pageviews,
      COUNTIF(e.event_name = 'user_engagement') AS user_engagement_events,
      TIMESTAMP_DIFF(
        MAX(e.event_timestamp_utc), MIN(e.event_timestamp_utc), SECOND)
        AS event_span_s,
      MAX(
        IF(
          e.event_name = 'purchase' OR e.ecommerce.transaction_id IS NOT NULL,
          1,
          0)) AS did_purchase
    FROM tough-healer-395417.analytics_unified.fact_ga4_events e
    JOIN lp_sessions s
      ON s.session_date = e.event_date AND s.session_id = e.session_id
    GROUP BY 1, 2
  ),

  scored AS (
    SELECT
      f.session_date,
      f.session_id,
      f.referrer_group,
      f.session_engagement_time_msec,
      f.geo_city,
      f.device_operating_system,
      p.pageviews,
      p.did_purchase,
      p.events,
      p.event_span_s,
      p.user_engagement_events,
      IF(
        p.pageviews = 1
          AND p.did_purchase = 0
          AND p.event_span_s = 0
          AND p.user_engagement_events = 0
          AND p.events BETWEEN 3 AND 5,
        1,
        0) AS suspected_bot
    FROM sessions_fox f
    JOIN profile p
      ON p.session_date = f.session_date AND p.session_id = f.session_id
  )

SELECT
  session_date,
  d.fiscal_week_end_date,
  referrer_group,
  COUNT(*) AS total_sessions,

  -- Base population (controlled)
  COUNTIF(pageviews = 1 AND did_purchase = 0)
    AS sessions_same_lp_1pv_non_purchase,

  -- Bot KPI
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND suspected_bot = 1)
    AS suspected_bot_sessions,

  -- Supporting signals (event-derived)
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND event_span_s = 0) AS session_duration_0s,
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND event_span_s <= 3) AS session_duration_le_3s,
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND user_engagement_events = 0)
    AS no_user_engagement_event,

  -- Supporting signals (sessions-table)
  COUNTIF(
    pageviews = 1 AND did_purchase = 0 AND session_engagement_time_msec = 0)
    AS session_engagement_0ms,

  COUNTIF(pageviews = 1 AND did_purchase = 0 AND (geo_city IS NULL OR geo_city = ''))
    AS no_geo_city,

  -- Device counts (compute % in Excel using sessions_same_lp_1pv_non_purchase as denominator)
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND LOWER(device_operating_system) = 'ios')
    AS ios_sessions,
  COUNTIF(pageviews = 1 AND did_purchase = 0 AND LOWER(device_operating_system) = 'macintosh')
    AS macintosh_sessions

FROM scored s
LEFT JOIN `analytics_unified.dim_fiscal_dates` d
  ON s.session_date = d.date
GROUP BY 1, 2, 3
ORDER BY session_date
