-- Do the two sidebars' audiences overlap? WSJ has an Account sidebar and a
-- separate Wine Cellar sidebar. If the sections are effectively separate rooms,
-- crossover will be low and the high-intent pages are hidden from the big audience.
DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH pv AS (
  SELECT session_id,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS path,
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand = 'WSJ' AND event_date BETWEEN d_start AND d_end
    AND event_name = 'page_view'
),
tagged AS (
  SELECT session_id,
    -- Account sidebar pages
    LOGICAL_OR(
      (path LIKE '%account_details.jsp' AND frag IN ('', 'memberships', 'settings',
                                                     'personal-details','payment-methods',
                                                     'email-settings','unlimited-shipping'))
      OR path LIKE '%account_order_history.jsp'
      OR path LIKE '%wp_summary.jsp'
      OR path LIKE '%account_voucher_details.jsp'
      OR path LIKE '%account_subscription.jsp'
    ) AS in_account,
    -- Wine Cellar sidebar pages
    LOGICAL_OR(
      (path LIKE '%account_details.jsp' AND frag IN ('purchased','favorites','top-rated',
                                                     'not-for-me','recommendations','wine-cellar'))
      OR path LIKE '%account_wine_preference.jsp'
      OR path LIKE '%cellar_homepage.jsp'
    ) AS in_cellar
  FROM pv GROUP BY session_id
)
SELECT
  COUNTIF(in_account)                          AS account_sessions,
  COUNTIF(in_cellar)                           AS cellar_sessions,
  COUNTIF(in_account AND in_cellar)            AS both,
  ROUND(100*COUNTIF(in_account AND in_cellar)/NULLIF(COUNTIF(in_account),0), 2) AS pct_of_account_reaching_cellar,
  ROUND(100*COUNTIF(in_account AND in_cellar)/NULLIF(COUNTIF(in_cellar),0), 2)  AS pct_of_cellar_from_account,
  COUNTIF(in_cellar AND NOT in_account)        AS cellar_only
FROM tagged
WHERE in_account OR in_cellar
