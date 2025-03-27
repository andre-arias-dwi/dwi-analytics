WITH sessions AS (
  SELECT
    EXTRACT(YEAR FROM s.session_date) AS year,
    EXTRACT(MONTH FROM s.session_date) AS month,
    CASE
      WHEN s.geo.region IN ('Texas', 'Florida', 'Illinois', 'New Jersey', 'Ohio') THEN 'Test Group'
      WHEN s.geo.region IN ('California', 'New York', 'Michigan', 'Massachusetts', 'Virginia') THEN 'Control Group'
      ELSE 'All Other States'
    END AS state_group,
    CASE 
      WHEN s.session_date BETWEEN '2024-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) 
      THEN 'Current Year'
      ELSE 'Previous Year'
    END AS period,
    s.user_pseudo_id,
    s.session_id,
    t.transaction_id,
    t.ecommerce.purchase_revenue
  FROM `tough-healer-395417.superform_outputs_287832387.ga4_sessions` s
  LEFT JOIN `tough-healer-395417.superform_outputs_287832387.ga4_transactions` t
  ON s.session_id = t.session_id
  WHERE
    s.geo.country = 'United States'
    AND s.device.web_info.hostname = 'www.wsjwine.com'
    AND (
      s.session_date BETWEEN '2024-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- Current Year
      OR
      s.session_date BETWEEN '2023-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR) -- Previous Year
    )
),

aggregated AS (
  SELECT
    month,
    CASE 
      WHEN month >= 9 THEN month - 8   -- Shifts September (9) to 1, October (10) to 2, etc.
      ELSE month + 4                   -- Shifts January (1) to 5, February (2) to 6, etc.
    END AS month_order,
    state_group,

    -- Pre-calculate metrics for Current Year
    COUNT(DISTINCT IF(period = 'Current Year', user_pseudo_id, NULL)) AS users_current,
    COUNT(DISTINCT IF(period = 'Current Year', session_id, NULL)) AS sessions_current,
    COUNT(DISTINCT IF(period = 'Current Year', transaction_id, NULL)) AS transactions_current,
    ROUND(SUM(IF(period = 'Current Year', purchase_revenue, NULL)), 2) AS revenue_current,

    -- Pre-calculate metrics for Previous Year
    COUNT(DISTINCT IF(period = 'Previous Year', user_pseudo_id, NULL)) AS users_previous,
    COUNT(DISTINCT IF(period = 'Previous Year', session_id, NULL)) AS sessions_previous,
    COUNT(DISTINCT IF(period = 'Previous Year', transaction_id, NULL)) AS transactions_previous,
    ROUND(SUM(IF(period = 'Previous Year', purchase_revenue, NULL)), 2) AS revenue_previous
  FROM sessions
  GROUP BY month, state_group
)

SELECT
  
  month,
  state_group,

  -- Directly use pre-calculated values
  users_current,
  users_previous,
  sessions_current,
  sessions_previous,
  transactions_current,
  transactions_previous,
  revenue_current,
  revenue_previous,
  SAFE_DIVIDE(transactions_current, users_current) AS conversion_rate_current,
  SAFE_DIVIDE(transactions_previous, users_previous) AS conversion_rate_previous,
  SAFE_DIVIDE(revenue_current, transactions_current) AS average_order_value_current,
  SAFE_DIVIDE(revenue_previous, transactions_previous) AS average_order_value_previous,

  -- Calculate YoY Change using pre-aggregated metrics
  SAFE_DIVIDE(users_current - users_previous, users_previous) * 100 AS users_yoy_change,
  SAFE_DIVIDE(sessions_current - sessions_previous, sessions_previous) * 100 AS sessions_yoy_change,
  SAFE_DIVIDE(transactions_current - transactions_previous, transactions_previous) * 100 AS transactions_yoy_change,
  SAFE_DIVIDE(revenue_current - revenue_previous, revenue_previous) * 100 AS revenue_yoy_change,

  -- Correct CVR & AOV YoY Change (recalculate directly in SELECT)
  SAFE_DIVIDE(
    SAFE_DIVIDE(transactions_current, users_current) - SAFE_DIVIDE(transactions_previous, users_previous),
    SAFE_DIVIDE(transactions_previous, users_previous)
  ) * 100 AS conversion_rate_yoy_change,

  SAFE_DIVIDE(
    SAFE_DIVIDE(revenue_current, transactions_current) - SAFE_DIVIDE(revenue_previous, transactions_previous),
    SAFE_DIVIDE(revenue_previous, transactions_previous)
  ) * 100 AS average_order_value_yoy_change

FROM aggregated
ORDER BY month_order, state_group DESC;