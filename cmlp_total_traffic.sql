WITH sessions AS(
    SELECT DISTINCT
    user_pseudo_id, 
    session_id
    FROM `tough-healer-395417.superform_outputs_287832387.ga4_events`
    WHERE 
        event_date BETWEEN '2023-12-30' AND '2024-01-26'
    AND
        event_name = 'page_view' -- Ensuring we filter only page view events
    AND
        geo.country != 'India'
    AND
        device.web_info.hostname = 'www.wsjwine.com'
    AND 
        (REGEXP_CONTAINS(page.location, r"/cm_template_responsive|/next/sale")) 
    AND 
        NOT REGEXP_CONTAINS(page.location, r"(?i)date=gifting")
)

    SELECT
    COUNT(DISTINCT s.user_pseudo_id) as users,
    COUNT(DISTINCT s.session_id) as sessions,
    COUNT(DISTINCT t.transaction_id) as transactions,
    SUM(t.ecommerce.purchase_revenue) as revenue
    FROM sessions s
    LEFT JOIN `tough-healer-395417.superform_outputs_287832387.ga4_transactions` t
    ON s.session_id = t.session_id
    AND t.transaction_date BETWEEN '2023-12-30' AND '2024-01-26'
