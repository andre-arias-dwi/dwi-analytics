DECLARE start_date DATE DEFAULT DATE '2023-08-26';
DECLARE end_date DATE DEFAULT DATE '2025-04-25';

WITH all_sessions AS (
  -- CMLP sessions (WSJ + LAW with specific path)
  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'WSJ' AS brand,
    'CMLP' AS segment
  FROM `tough-healer-395417.superform_outputs_287832387.ga4_events`
  WHERE event_name = 'page_view'
    AND geo.country = 'United States'
    AND device.web_info.hostname = 'www.wsjwine.com'
    AND SAFE.REGEXP_CONTAINS(LOWER(page.location), r"/jsp/offer/cm/us/common/cm_template_responsive.jsp.*date=202\d.*(january|february|march|april|may|june|july|august|september|october|november|december).*|/next/(.*-|)sale")
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'LAW' AS brand,
    'CMLP' AS segment
  FROM `tough-healer-395417.superform_outputs_287163560.ga4_events`
  WHERE event_name = 'page_view'
    AND geo.country = 'United States'
    AND device.web_info.hostname = 'www.laithwaites.com'
    AND SAFE.REGEXP_CONTAINS(LOWER(page.location), r"/jsp/offer/cm/us/common/cm_template_responsive.jsp.*date=202\d.*(january|february|march|april|may|june|july|august|september|october|november|december).*|/next/(.*-|)sale")
    AND event_date BETWEEN start_date AND end_date

  -- Total traffic sessions (all brands, no path restriction)
  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'WSJ' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_287832387.ga4_events`
  WHERE geo.country = 'United States'
    AND device.web_info.hostname = 'www.wsjwine.com'
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'LAW' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_287163560.ga4_events`
  WHERE geo.country = 'United States'
    AND device.web_info.hostname = 'www.laithwaites.com'
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'NGO' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_391406454.ga4_events`
  WHERE geo.country = 'United States'
    AND device.web_info.hostname = 'www.natgeowine.com'
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'NPR' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_373836794.ga4_events`
  WHERE geo.country = 'United States'
    AND device.web_info.hostname = 'www.nprwineclub.org'
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'TCM' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_358775017.ga4_events`
  WHERE geo.country = 'United States'
    AND device.web_info.hostname = 'shop.tcmwineclub.com'
    AND event_date BETWEEN start_date AND end_date

  UNION ALL

  SELECT DISTINCT 
    user_pseudo_id, 
    session_id,
    event_date,
    'OSW' AS brand,
    'Total' AS segment
  FROM `tough-healer-395417.superform_outputs_425709539.ga4_events`
  WHERE geo.country != 'United States'
    AND device.web_info.hostname = 'www.omahasteakswine.com'
    AND event_date BETWEEN start_date AND end_date
),

all_transactions AS (
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'WSJ' AS brand FROM `tough-healer-395417.superform_outputs_287832387.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
  UNION ALL
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'LAW' AS brand FROM `tough-healer-395417.superform_outputs_287163560.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
  UNION ALL
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'NGO' AS brand FROM `tough-healer-395417.superform_outputs_391406454.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
  UNION ALL
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'NPR' AS brand FROM `tough-healer-395417.superform_outputs_373836794.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
  UNION ALL
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'TCM' AS brand FROM `tough-healer-395417.superform_outputs_358775017.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
  UNION ALL
  SELECT DISTINCT session_id, transaction_id, ecommerce.purchase_revenue AS revenue, 'OSW' AS brand FROM `tough-healer-395417.superform_outputs_425709539.ga4_transactions` WHERE transaction_date BETWEEN start_date AND end_date
),

fiscal_calendar AS (
  SELECT '23_24' AS fiscal_year, date, fiscal_month FROM `tough-healer-395417.fiscal_calendars.FY23-24`
  UNION ALL
  SELECT '24_25' AS fiscal_year, date, fiscal_month FROM `tough-healer-395417.fiscal_calendars.FY24-25`
)

SELECT
  s.segment,
  s.brand,
  fc.fiscal_year,
  fc.fiscal_month,
  COUNT(DISTINCT s.user_pseudo_id) AS users,
  COUNT(DISTINCT s.session_id) AS sessions,
  COUNT(DISTINCT t.transaction_id) AS transactions,
  ROUND(SUM(t.revenue), 2) AS revenue
FROM all_sessions AS s
LEFT JOIN all_transactions AS t
  ON s.session_id = t.session_id
  AND s.brand = t.brand
LEFT JOIN fiscal_calendar AS fc
  ON s.event_date = fc.date
GROUP BY s.segment, s.brand, fc.fiscal_year, fc.fiscal_month
ORDER BY s.segment, s.brand, fc.fiscal_year, fc.fiscal_month;
