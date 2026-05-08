WITH
  impact_sessions AS (
    SELECT
      session_id,
      array_agg(page_location ORDER BY event_timestamp ASC LIMIT 1)[OFFSET(0)]
        AS first_impact_page_location
    FROM `analytics_unified.fact_ga4_events`
    WHERE
      page_location LIKE '%irpid=%'
      AND page_location LIKE '%clickid=%'
      AND event_date BETWEEN '2025-12-23' AND '2025-12-30'
    GROUP BY session_id
  )
SELECT
  s.brand,
  s.transaction_id,
  s.date,
  s.purchase_revenue,
  i.first_impact_page_location,
  REGEXP_EXTRACT(first_impact_page_location, r'irpid=([^&]+)') AS irpid,
  REGEXP_EXTRACT(first_impact_page_location, r'clickid=([^&]+)') AS clickid,
  REGEXP_EXTRACT(first_impact_page_location, r'afsrc=([^&]+)') AS afsrc
FROM `analytics_reporting.rpt_ga4_sessions_transactions` s
JOIN impact_sessions i
  USING (session_id)
