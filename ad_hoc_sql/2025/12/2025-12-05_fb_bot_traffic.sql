-- 🧠 WSJ + LAW Advanced Bot Detection Model (v6)
-- Adds per-user session frequency anomaly detection (user_z_sessions)
-- Last 30 days of WSJ + LAW GA4 data

WITH session_features AS (
  SELECT
    event_date AS session_date,
    brand,
    user_pseudo_id,
    CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)) AS session_key,
    CASE
      WHEN LOWER(first_source) LIKE '%facebook%'
        OR fbclid IS NOT NULL
        OR LOWER(first_source) LIKE '%audience%'
        THEN 'Facebook'
      ELSE 'Other'
    END AS traffic_type,
    LOWER(device_category) AS device_category,
    LOWER(device_operating_system) AS operating_system,
    LOWER(country) AS country,
    LOWER(region) AS region,
    LOWER(city) AS city,
    COUNT(*) AS event_count,
    COUNTIF(event_name = 'page_view') AS pageviews,
    SUM(CASE WHEN event_name IN (
      'scroll', 'click', 'user_engagement', 'search', 'view_search_results',
      'add_to_cart', 'view_item', 'purchase', 'target_checkout_begin',
      'main_navigation', 'header_logo_click', 'account_nav_click',
      'form_submit', 'email_submit_attentive', 'sms_submit_attentive', 'sign_up'
    ) THEN 1 ELSE 0 END) AS interaction_events,
    COALESCE(SUM(SAFE_DIVIDE(engagement_time_msec, 1000)), 0) AS engagement_seconds,
    MAX(IF(event_name = 'purchase', 1, 0)) AS has_conversion
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE
    brand IN ('WSJ', 'LAW')
    AND event_date BETWEEN '2025-11-15'
                       AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY event_date, brand, user_pseudo_id, session_key, traffic_type,
           device_category, device_operating_system, country, region, city
),

-- 🧮 User Daily Activity (sessions per user per day)
user_daily_activity AS (
  SELECT
    session_date,
    traffic_type,
    brand,
    user_pseudo_id,
    COUNT(DISTINCT session_key) AS user_sessions
  FROM session_features
  GROUP BY session_date, traffic_type, brand, user_pseudo_id
),

-- ⚙️ User baseline (normal session frequency)
user_baseline AS (
  SELECT
    traffic_type,
    brand,
    AVG(user_sessions) AS avg_user_sessions,
    STDDEV(user_sessions) AS std_user_sessions
  FROM user_daily_activity
  WHERE session_date < '2025-11-25'
  GROUP BY traffic_type, brand
),

-- 📈 User session z-score context
user_context AS (
  SELECT
    u.session_date,
    u.traffic_type,
    u.brand,
    u.user_pseudo_id,
    SAFE_DIVIDE(u.user_sessions - b.avg_user_sessions, NULLIF(b.std_user_sessions, 0)) AS user_z_sessions
  FROM user_daily_activity u
  LEFT JOIN user_baseline b USING (traffic_type, brand)
),

-- 🧮 Engagement and event baselines
baseline AS (
  SELECT
    traffic_type,
    AVG(engagement_seconds) AS base_mean_eng,
    STDDEV(engagement_seconds) AS base_std_eng,
    AVG(event_count) AS base_mean_evt,
    STDDEV(event_count) AS base_std_evt,
    AVG(pageviews) AS base_mean_pv,
    STDDEV(pageviews) AS base_std_pv
  FROM session_features
  WHERE session_date < '2025-11-25'
  GROUP BY traffic_type
),

-- 🕐 Daily context (session spikes)
daily AS (
  SELECT session_date, traffic_type, COUNT(DISTINCT session_key) AS sessions
  FROM session_features
  GROUP BY session_date, traffic_type
),
daily_baseline AS (
  SELECT
    traffic_type,
    AVG(sessions) AS avg_sessions,
    STDDEV(sessions) AS std_sessions
  FROM daily
  WHERE session_date < '2025-11-25'
  GROUP BY traffic_type
),
daily_context AS (
  SELECT
    d.session_date,
    d.traffic_type,
    SAFE_DIVIDE(d.sessions - b.avg_sessions, NULLIF(b.std_sessions,0)) AS daily_z_sessions
  FROM daily d
  JOIN daily_baseline b USING (traffic_type)
),

-- 🖥 Device, OS, and Geo baselines
os_baseline AS (
  SELECT traffic_type, operating_system,
         AVG(session_count) AS avg_sessions,
         STDDEV(session_count) AS std_sessions
  FROM (
    SELECT traffic_type, operating_system,
           COUNT(DISTINCT session_key) AS session_count, session_date
    FROM session_features
    WHERE session_date < '2025-11-25'
    GROUP BY 1,2,4
  )
  GROUP BY 1,2
),
os_context AS (
  SELECT s.session_date, s.traffic_type, s.operating_system,
         SAFE_DIVIDE(os_count - o.avg_sessions, NULLIF(o.std_sessions,0)) AS os_z_sessions
  FROM (
    SELECT session_date, traffic_type, operating_system,
           COUNT(DISTINCT session_key) AS os_count
    FROM session_features
    GROUP BY 1,2,3
  ) s
  LEFT JOIN os_baseline o USING (traffic_type, operating_system)
),

device_baseline AS (
  SELECT traffic_type, device_category,
         AVG(session_count) AS avg_sessions,
         STDDEV(session_count) AS std_sessions
  FROM (
    SELECT traffic_type, device_category,
           COUNT(DISTINCT session_key) AS session_count, session_date
    FROM session_features
    WHERE session_date < '2025-11-25'
    GROUP BY 1,2,4
  )
  GROUP BY 1,2
),
device_context AS (
  SELECT s.session_date, s.traffic_type, s.device_category,
         SAFE_DIVIDE(d_count - b.avg_sessions, NULLIF(b.std_sessions,0)) AS device_z_sessions
  FROM (
    SELECT session_date, traffic_type, device_category,
           COUNT(DISTINCT session_key) AS d_count
    FROM session_features
    GROUP BY 1,2,3
  ) s
  LEFT JOIN device_baseline b USING (traffic_type, device_category)
),

geo_baseline AS (
  SELECT traffic_type, city,
         AVG(session_count) AS avg_sessions,
         STDDEV(session_count) AS std_sessions
  FROM (
    SELECT traffic_type, city,
           COUNT(DISTINCT session_key) AS session_count, session_date
    FROM session_features
    WHERE session_date < '2025-11-25'
    GROUP BY 1,2,4
  )
  GROUP BY 1,2
),
geo_context AS (
  SELECT s.session_date, s.traffic_type, s.city,
         SAFE_DIVIDE(g_count - b.avg_sessions, NULLIF(b.std_sessions,0)) AS geo_z_sessions
  FROM (
    SELECT session_date, traffic_type, city,
           COUNT(DISTINCT session_key) AS g_count
    FROM session_features
    GROUP BY 1,2,3
  ) s
  LEFT JOIN geo_baseline b USING (traffic_type, city)
),

-- 🧩 Combine all anomaly signals
scored AS (
  SELECT
    s.*,
    b.base_mean_eng, b.base_std_eng,
    b.base_mean_evt, b.base_std_evt,
    b.base_mean_pv, b.base_std_pv,
    SAFE_DIVIDE(s.engagement_seconds - b.base_mean_eng, NULLIF(b.base_std_eng,0)) AS z_eng,
    SAFE_DIVIDE(s.event_count - b.base_mean_evt, NULLIF(b.base_std_evt,0)) AS z_evt,
    SAFE_DIVIDE(s.pageviews - b.base_mean_pv, NULLIF(b.base_std_pv,0)) AS z_pv,
    COALESCE(dc.daily_z_sessions,0) AS daily_z_sessions,
    COALESCE(oc.os_z_sessions,0) AS os_z_sessions,
    COALESCE(dev.device_z_sessions,0) AS device_z_sessions,
    COALESCE(g.geo_z_sessions,0) AS geo_z_sessions,
    COALESCE(uc.user_z_sessions,0) AS user_z_sessions
  FROM session_features s
  LEFT JOIN baseline b USING (traffic_type)
  LEFT JOIN daily_context dc USING (session_date, traffic_type)
  LEFT JOIN os_context oc USING (session_date, traffic_type, operating_system)
  LEFT JOIN device_context dev USING (session_date, traffic_type, device_category)
  LEFT JOIN geo_context g USING (session_date, traffic_type, city)
  LEFT JOIN user_context uc USING (session_date, traffic_type, brand, user_pseudo_id)
),

-- 🎯 Classification logic
classified AS (
  SELECT
    session_key, session_date, brand, traffic_type,
    device_category, operating_system, country, region, city,
    engagement_seconds, event_count, pageviews, interaction_events, has_conversion,
    daily_z_sessions, os_z_sessions, device_z_sessions, geo_z_sessions, user_z_sessions,
    z_eng, z_evt, z_pv, user_pseudo_id,
    CASE
      WHEN has_conversion = 1 THEN 'Human (Conversion Present)'
      WHEN (traffic_type = 'Facebook'
            AND daily_z_sessions > 1.5
            AND LOWER(operating_system) LIKE '%android%'
            AND interaction_events = 0
            AND engagement_seconds < 30)
        THEN 'High-Confidence Bot (FB Android spike, no interaction)'
      WHEN (traffic_type = 'Facebook'
            AND (user_z_sessions > 2 OR device_z_sessions > 2 OR geo_z_sessions > 2))
        THEN 'Bot (User/Geo/Device anomaly)'
      WHEN (COALESCE(z_eng,-2) < -0.8 AND COALESCE(z_evt,-2) < -0.4)
        THEN 'Bot (Low engagement)'
      WHEN COALESCE(z_eng,0) BETWEEN -1.0 AND -0.3
        THEN 'Suspicious'
      ELSE 'Human'
    END AS session_class
  FROM scored
)

-- 📊 Final output summary
SELECT
  session_date,
  brand,
  traffic_type,
  session_class,
  COUNT(DISTINCT session_key) AS sessions,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(has_conversion = 1) AS purchases,
  ROUND(COUNT(DISTINCT session_key) / SUM(COUNT(DISTINCT session_key)) OVER (PARTITION BY session_date, traffic_type, brand) * 100, 2) AS pct_sessions_within_day,
  ROUND(COUNT(DISTINCT user_pseudo_id) / SUM(COUNT(DISTINCT user_pseudo_id)) OVER (PARTITION BY session_date, traffic_type, brand) * 100, 2) AS pct_users_within_day
FROM classified
GROUP BY session_date, brand, traffic_type, session_class
ORDER BY session_date, brand, traffic_type, session_class;
