WITH
  addon AS(
  SELECT
    DISTINCT brand,
    event_name,
    event_category,
    event_subcategory,
    event_class
  FROM
    `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE
    event_name = 'mini_cart'
    AND event_category = 'add on'AND event_class LIKE 'Free Shipping%' ),
  deployed AS(
  SELECT
    DISTINCT brand,
    event_name,
    event_category,
    event_subcategory,
    event_class
  FROM
    `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE
    event_name = 'mini_cart'
    AND event_category = 'deployed' )
SELECT
  COUNT(*)
FROM
  deployed