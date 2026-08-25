/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

WITH sessions AS (
  SELECT
    s.session_date AS date,
    s.lnd_campaign,
    s.session_id,
    s.brand,
    s.time.engagement_time_msec AS engagement_time_msec,
    s.device.operating_system AS operating_system,
    s.device.mobile_model_name AS mobile_model_name
  FROM `tough-healer-395417.analytics_staging.int_ga4_sessions` s
  WHERE s.lnd_campaign IN (
      'us_dw_wsjwine_social_meta_offers_std_adv',
      'us_dw_lw_social_meta_15_gold_medal_std',
      'us_dw_lw_std_sommtv_cvr'
  )
  AND s.lnd_source IN ('fb', 'facebook')
  AND s.session_date BETWEEN '2025-11-15' AND '2025-12-21'
),

transactions AS (
  SELECT brand, session_id, transaction_id
  FROM `tough-healer-395417.analytics_staging.int_ga4_transactions`
  WHERE transaction_date BETWEEN '2025-11-15' AND '2025-12-22'
),

session_events AS (
  SELECT
    e.brand,
    e.session_id,
    SUM(CASE WHEN e.event_name = 'page_view' THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN e.event_name IN (
      'add_to_cart',
      'main_navigation', 'account_nav_click', 'header_logo_click',
      'search', 'cart_icon',
      'purchase',
      'login_button', 'target_login_design_btn_click', 'logout',
      'cancel_membership', 'state_selector', 'not_you',
      'email_submit_attentive', 'sms_submit_attentive',
      'password_reset_confirmation', 'reset_password_confirmation', 'sign_up',
      'click', 'cmlp_clicks', 'homepage_clicks',
      'target-cta-click', 'target-place-order-btn-click',
      'target_checkout_begin', 'expand_attentive',
      'close_attentive', 'rotating_banner'
    ) THEN 1 ELSE 0 END) AS interaction_events
  FROM `tough-healer-395417.analytics_staging.int_ga4_events` e
  WHERE e.event_date BETWEEN '2025-11-15' AND '2025-12-21'
  GROUP BY ALL
)

SELECT
  s.lnd_campaign,
  s.date,
  COUNT(DISTINCT s.session_id) AS sessions,
  COUNT(DISTINCT t.transaction_id) AS transactions,
  ROUND(AVG(COALESCE(s.engagement_time_msec, 0)) / 1000, 2) AS avg_engagement_time_sec,
  ROUND(COUNT(DISTINCT IF(s.operating_system = 'Android', s.session_id, NULL)) / COUNT(DISTINCT s.session_id), 3) AS pct_android_sessions,
  --COUNT(DISTINCT s.mobile_model_name) AS distinct_mobile_models,
  --ROUND(COUNT(DISTINCT s.session_id) / NULLIF(COUNT(DISTINCT s.mobile_model_name), 0), 1) AS sessions_per_distinct_mobile_model,
  ROUND(COUNT(DISTINCT IF(se.page_views >= 2 AND se.interaction_events = 0, s.session_id, NULL)) / COUNT(DISTINCT s.session_id), 3) AS pct_multi_pageview_zero_interaction
FROM sessions s
LEFT JOIN transactions t
  ON s.brand = t.brand
  AND s.session_id = t.session_id
LEFT JOIN session_events se
  ON s.brand = se.brand
  AND s.session_id = se.session_id
GROUP BY ALL
ORDER BY date, lnd_campaign
