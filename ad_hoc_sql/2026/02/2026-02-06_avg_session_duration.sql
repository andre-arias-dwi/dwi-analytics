with events as (
  SELECT
  session_id
FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
WHERE event_date > '2025-12-13'
group by session_id
having max(page_number) = 1
)

SELECT
  avg(time.session_duration_s) avg_session_duration
FROM `tough-healer-395417.analytics_unified.fact_ga4_sessions` s
join events e on s.session_id = e.session_id
WHERE session_date > '2025-12-13'
