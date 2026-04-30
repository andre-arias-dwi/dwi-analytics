WITH session_flags AS (
  SELECT
    d.fiscal_year_end_year,
    d.fiscal_quarter_number,
    d.fiscal_month_name,
    d.fiscal_month_number,
    d.fiscal_week_number,
    d.fiscal_week_end_date,
    e.brand,
    e.event_subcategory AS status,
    e.session_id,

    MAX(CASE WHEN LOWER(e.event_category) = 'cancel membership' THEN 1 ELSE 0 END) AS started_cancel,
    MAX(CASE WHEN LOWER(e.event_category) = 'claim discount' THEN 1 ELSE 0 END) AS claimed_discount,
    MAX(CASE WHEN LOWER(e.event_category) = 'keep membership' THEN 1 ELSE 0 END) AS kept_membership,
    MAX(CASE WHEN LOWER(e.event_category) = 'confirm cancellation' THEN 1 ELSE 0 END) AS confirmed_cancellation

  FROM `tough-healer-395417.analytics_unified.fact_ga4_events` e
  LEFT JOIN `tough-healer-395417.analytics_unified.dim_fiscal_dates` d
    ON e.event_date = d.date

  WHERE LOWER(e.event_name) = 'cancel_membership'
    AND LOWER(e.event_category) IN (
      'cancel membership',
      'claim discount',
      'keep membership',
      'confirm cancellation'
    )
    AND e.brand IN ('WSJ', 'LAW')
    AND e.event_date >= '2026-04-01'

  GROUP BY
    d.fiscal_year_end_year,
    d.fiscal_quarter_number,
    d.fiscal_month_name,
    d.fiscal_month_number,
    d.fiscal_week_number,
    d.fiscal_week_end_date,
    e.brand,
    e.event_subcategory,
    e.session_id
),

final AS (
  SELECT
    fiscal_year_end_year,
    fiscal_quarter_number,
    fiscal_month_name,
    fiscal_month_number,
    fiscal_week_number,
    fiscal_week_end_date,
    brand,
    status,
    'Cancel Membership' AS action,
    'Cancel Starts' AS action_total,
    COUNTIF(started_cancel = 1) AS sessions
  FROM session_flags
  GROUP BY ALL

  UNION ALL

  SELECT
    fiscal_year_end_year,
    fiscal_quarter_number,
    fiscal_month_name,
    fiscal_month_number,
    fiscal_week_number,
    fiscal_week_end_date,
    brand,
    status,
    'Claim Discount' AS action,
    'Save Outcomes' AS action_total,
    COUNTIF(claimed_discount = 1) AS sessions
  FROM session_flags
  GROUP BY ALL

  UNION ALL

  SELECT
    fiscal_year_end_year,
    fiscal_quarter_number,
    fiscal_month_name,
    fiscal_month_number,
    fiscal_week_number,
    fiscal_week_end_date,
    brand,
    status,
    'Keep Membership' AS action,
    'Save Outcomes' AS action_total,
    COUNTIF(kept_membership = 1) AS sessions
  FROM session_flags
  GROUP BY ALL

  UNION ALL

  SELECT
    fiscal_year_end_year,
    fiscal_quarter_number,
    fiscal_month_name,
    fiscal_month_number,
    fiscal_week_number,
    fiscal_week_end_date,
    brand,
    status,
    'Confirm Cancellation' AS action,
    'Confirmed Cancellations' AS action_total,
    COUNTIF(confirmed_cancellation = 1) AS sessions
  FROM session_flags
  GROUP BY ALL

  UNION ALL

  SELECT
    fiscal_year_end_year,
    fiscal_quarter_number,
    fiscal_month_name,
    fiscal_month_number,
    fiscal_week_number,
    fiscal_week_end_date,
    brand,
    status,
    'Abandoned Cancellation' AS action,
    'Save Outcomes' AS action_total,
    COUNTIF(
      started_cancel = 1
      AND claimed_discount = 0
      AND kept_membership = 0
      AND confirmed_cancellation = 0
    ) AS sessions
  FROM session_flags
  GROUP BY ALL
)

SELECT *
FROM final
WHERE NOT (
  (LOWER(action) = 'claim discount' AND LOWER(status) = 'not eligible')
  OR
  (LOWER(action) = 'keep membership' AND LOWER(status) = 'eligible')
);