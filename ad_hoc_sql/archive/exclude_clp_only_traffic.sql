--Exclude sessions that contain only CLP page.locations i.e., temp6 > temp6 thank you page OR temp6 only
--These sessions visited a page in the main site at least once and therefore saw the main navigation
WITH sessions AS (
  SELECT
    EXTRACT(MONTH FROM event_date) AS month,
    EXTRACT(YEAR FROM event_date) AS year,
    user_pseudo_id,
    session_id,
    --page.location
  FROM `tough-healer-395417.superform_outputs_287163560.ga4_events`
  WHERE
    event_date BETWEEN "2023-09-01" AND '2024-05-31'
    AND geo.country != 'India' -- Exclude devs
    AND device.web_info.hostname = 'www.laithwaites.com' -- Filter for the correct website
  GROUP BY
    month, year, user_pseudo_id, session_id
  HAVING
  --keep the sesion if at least one page.location does NOT match any of the CLP 
    COUNTIF(
      NOT REGEXP_CONTAINS(
        page.location,
        r'/offer_temp(4|5|6)\.jsp|lp-redirect=|/confirmation\.jsp|/template\.jsp|/confirmation_lp\.jsp|/template.jsp|offers.laithwaites.com|splash_template.jsp|/jsp/ExpiryPage.jsp')
    ) > 0
)

SELECT
  year, month,
  COUNT(distinct user_pseudo_id) AS users,
  COUNT(distinct session_id) AS sessions
FROM sessions
