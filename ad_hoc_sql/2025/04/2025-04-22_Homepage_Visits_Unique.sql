WITH  
homepage_sessions AS (
    SELECT 
        EXTRACT(YEAR FROM event_date) AS year, 
        EXTRACT(MONTH FROM event_date) AS month,
        user_pseudo_id,
        session_id,
        MAX(CASE WHEN event_params_custom.login_status IN ('Soft Logged-In', 'Hard Logged-In') THEN 1 ELSE 0 END) AS has_identified,
        MAX(CASE WHEN LOWER(event_params_custom.login_status) = 'unidentified' THEN 1 ELSE 0 END) AS has_unidentified
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_events` 
    WHERE event_name IN ('page_view', 'adobe_page_view')
        AND page.path IN ('/', '/jsp/homepage.jsp') 
        AND event_date BETWEEN DATE '2025-03-01' AND DATE '2025-04-21'
        AND geo.country != 'India' 
        AND page.hostname = 'www.laithwaites.com'
    GROUP BY year, month, user_pseudo_id, session_id
),

session_groups AS (
    SELECT
        year,
        month,
        user_pseudo_id,
        session_id,
        CASE 
            WHEN has_identified = 1 AND has_unidentified = 0 THEN 'Identified ONLY'
            WHEN has_identified = 0 AND has_unidentified = 1 THEN 'Unidentified ONLY'
            WHEN has_identified = 1 AND has_unidentified = 1 THEN 'Identified AND Unidentified'
            ELSE 'Unknown' -- This should not happen based on your data description
        END AS login_status_group
    FROM homepage_sessions
),

all_sessions AS (
    SELECT
        year,
        month,
        user_pseudo_id,
        session_id,
        'All' AS login_status_group
    FROM homepage_sessions
),

transactions AS (
    SELECT DISTINCT 
        session_id, 
        transaction_id, 
        ecommerce.purchase_revenue 
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_transactions` 
)

-- Query for the three mutually exclusive groups
SELECT 
    year, 
    month, 
    login_status_group AS login_status, 
    COUNT(DISTINCT sg.user_pseudo_id) AS users, 
    COUNT(DISTINCT sg.session_id) AS sessions, 
    COUNT(DISTINCT transaction_id) AS transactions, 
    ROUND(SUM(COALESCE(purchase_revenue, 0)), 2) AS revenue
FROM session_groups sg
LEFT JOIN transactions t ON sg.session_id = t.session_id 
GROUP BY year, month, login_status_group

UNION ALL

-- Query for the 'All' group
SELECT 
    year, 
    month, 
    login_status_group AS login_status, 
    COUNT(DISTINCT a.user_pseudo_id) AS users, 
    COUNT(DISTINCT a.session_id) AS sessions, 
    COUNT(DISTINCT transaction_id) AS transactions, 
    ROUND(SUM(COALESCE(purchase_revenue, 0)), 2) AS revenue
FROM all_sessions a
LEFT JOIN transactions t ON a.session_id = t.session_id 
GROUP BY year, month, login_status_group