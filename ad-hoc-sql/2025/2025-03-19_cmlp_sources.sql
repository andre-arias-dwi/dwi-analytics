--purpose: get fiscal month ecommerce data for cmlp visitors, split by ecommerce channels
--output: excel file

with fiscal_calendar as(
    SELECT '23-24' AS fiscal_year, date, fiscal_month, month_number,
    CASE WHEN month_number IN (1, 2, 3) THEN 1
        WHEN month_number IN (4, 5, 6) THEN 2
        WHEN month_number IN (7, 8, 9) THEN 3
        ELSE 4 END AS quarter_number
    FROM `tough-healer-395417.fiscal_calendars.FY23-24`

    UNION ALL

    SELECT '24-25' AS fiscal_year, date, fiscal_month, month_number,
    CASE WHEN month_number IN (1, 2, 3) THEN 1
        WHEN month_number IN (4, 5, 6) THEN 2
        WHEN month_number IN (7, 8, 9) THEN 3
        ELSE 4 END AS quarter_number
    FROM `tough-healer-395417.fiscal_calendars.FY24-25`
),

sessions as(
    select DISTINCT
    user_pseudo_id,
    session_id,
    event_date,
    'WSJ' as brand
    from `tough-healer-395417.superform_outputs_287832387.ga4_events` e
    JOIN fiscal_calendar fc
    ON e.event_date = fc.date
    WHERE event_name = 'page_view'
        AND geo.country != 'India'
        AND device.web_info.hostname = 'www.wsjwine.com'
        --AND SAFE.REGEXP_CONTAINS(page.location, r"/cm_template_responsive|/next/sale")
        AND SAFE.REGEXP_CONTAINS(page.location, r"/jsp/offer/cm/us/common/cm_template_responsive.jsp.*date=202\d.*(january|february|march|april|may|june|july|august|september|october|november|december).*|/next/sale")
        --AND NOT SAFE.REGEXP_CONTAINS(page.location, r"(?i)date=gifting")
        AND event_date between '2024-12-28' and '2025-01-24'

    UNION ALL

    select DISTINCT
    user_pseudo_id,
    session_id,
    event_date,
    'LAW' as brand
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_events` e
    JOIN fiscal_calendar fc
    ON e.event_date = fc.date
    WHERE event_name = 'page_view'
        AND geo.country != 'India'
        AND device.web_info.hostname = 'www.laithwaites.com'
        --AND SAFE.REGEXP_CONTAINS(page.location, r"/cm_template_responsive|/next/sale")
        AND SAFE.REGEXP_CONTAINS(page.location, r"/jsp/offer/cm/us/common/cm_template_responsive.jsp.*date=202\d.*(january|february|march|april|may|june|july|august|september|october|november|december).*|/next/sale")
        --AND NOT SAFE.REGEXP_CONTAINS(page.location, r"(?i)date=gifting")
        AND event_date between '2024-12-28' and '2025-01-24'
),

transactions AS(
    SELECT DISTINCT
    session_id,
    transaction_id,
    ecommerce.purchase_revenue AS revenue,
    'WSJ' as brand
    FROM `tough-healer-395417.superform_outputs_287832387.ga4_transactions`

    UNION ALL

    SELECT DISTINCT
    session_id, 
    transaction_id,
    ecommerce.purchase_revenue AS revenue,
    'LAW' as brand
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_transactions`
)

SELECT
s.brand,
fc.fiscal_year,
fc.fiscal_month,
fc.month_number,
fc.quarter_number,
COUNT(DISTINCT s.user_pseudo_id) as users,
COUNT(DISTINCT s.session_id) as sessions,
COUNT(DISTINCT t.transaction_id) as transactions,
ROUND(SUM(t.revenue), 2) as revenue
FROM sessions s
LEFT JOIN transactions t
ON s.session_id = t.session_id
LEFT JOIN fiscal_calendar fc
ON s.event_date = fc.date
GROUP BY 1, 2, 3, 4, 5