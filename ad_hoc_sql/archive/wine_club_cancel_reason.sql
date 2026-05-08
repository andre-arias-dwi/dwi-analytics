WITH filtered_events AS (
  -- WSJ Data
  SELECT 
    'WSJ' AS brand,
    event_name,
    event_date,
    event_params_custom.page_fragment,
    event_params_custom.event_order,
    event_params_custom.event_category,
    event_params_custom.event_label
  FROM `tough-healer-395417.superform_outputs_287832387.ga4_events`
  WHERE event_name = 'cancel_membership'
    AND event_date BETWEEN '2024-06-29' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- Dynamic date
    AND geo.country NOT IN ('India') 
    AND device.web_info.hostname = 'www.wsjwine.com'

  UNION ALL

  -- LAW Data
  SELECT 
    'LAW' AS brand,
    event_name,
    event_date,
    event_params_custom.page_fragment,
    event_params_custom.event_order,
    event_params_custom.event_category,
    event_params_custom.event_label
  FROM `tough-healer-395417.superform_outputs_287163560.ga4_events`
  WHERE event_name = 'cancel_membership'
    AND event_date BETWEEN '2024-06-29' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) 
    AND geo.country NOT IN ('India') 
    AND device.web_info.hostname = 'www.laithwaites.com'
),

cancel AS (
  SELECT 
    brand,
    event_date,
    page_fragment,
    event_order
  FROM filtered_events
  WHERE event_category = 'CONFIRM CANCELLATION'
),

reason AS (
  SELECT 
    brand,
    page_fragment,
    UPPER(event_label) AS event_label
  FROM filtered_events
  WHERE event_category = 'SUBMIT FEEDBACK'
)

SELECT 
  c.brand,
  c.event_order AS club,
  c.event_date AS date,
  SPLIT(c.page_fragment, '/')[SAFE_OFFSET(2)] AS subscription_id,
  COALESCE(r.event_label, 'ABANDONED') AS cancel_reason -- Only applies 'ABANDONED' when no match (user did not submit feedback)
FROM cancel c
LEFT JOIN reason r USING (brand, page_fragment);