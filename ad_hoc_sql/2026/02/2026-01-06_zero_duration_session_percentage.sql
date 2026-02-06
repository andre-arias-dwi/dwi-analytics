WITH one_page_sessions AS (
  SELECT
    session_id
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE event_date < '2025-12-13'
  GROUP BY session_id
  HAVING MAX(page_number) = 1
),
filtered_sessions AS (
  SELECT
    s.time.session_duration_s
  FROM `tough-healer-395417.analytics_unified.fact_ga4_sessions` s
  JOIN one_page_sessions o
    ON s.session_id = o.session_id
  WHERE s.session_date < '2025-12-13'
)
SELECT
  SAFE_DIVIDE(
    COUNTIF(session_duration_s = 0),
    COUNT(*)
  ) AS zero_duration_session_percentage
FROM filtered_sessions
