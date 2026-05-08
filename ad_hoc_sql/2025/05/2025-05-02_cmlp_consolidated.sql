/* -----------------------------------------------------------
   CMLP homepage sessions – fiscal month, WSJ + LAW
   -----------------------------------------------------------
   – requestor : Tom
   – purpose   : fiscal‑month e‑commerce data for CMLP visitors,
                 split by login‑status groups and brand
----------------------------------------------------------------*/

/* 1️⃣  Fiscal calendar ---------------------------------------- */
WITH fiscal_calendar AS (
    SELECT '23-24' AS fiscal_year,
           date    AS calendar_date,
           fiscal_month,
           month_number,
           CASE WHEN month_number IN (1,2,3)   THEN 1
                WHEN month_number IN (4,5,6)   THEN 2
                WHEN month_number IN (7,8,9)   THEN 3
                ELSE                               4
           END AS quarter_number
    FROM `tough-healer-395417.fiscal_calendars.FY23-24`
    UNION ALL
    SELECT '24-25',
           date,
           fiscal_month,
           month_number,
           CASE WHEN month_number IN (1,2,3)   THEN 1
                WHEN month_number IN (4,5,6)   THEN 2
                WHEN month_number IN (7,8,9)   THEN 3
                ELSE                               4
           END
    FROM `tough-healer-395417.fiscal_calendars.FY24-25`
),

/* 2️⃣  Homepage‑session universe for both brands -------------- */
homepage_sessions AS (
    -- ---------- WSJ ----------
    SELECT
        'WSJ'            AS brand,
        fc.fiscal_year,
        fc.fiscal_month,
        fc.month_number,
        fc.quarter_number,
        user_pseudo_id,
        session_id,
        MAX(CASE WHEN event_params_custom.login_status IN ('Soft Logged-In','Hard Logged-In') THEN 1 ELSE 0 END) AS has_identified,
        MAX(CASE WHEN LOWER(event_params_custom.login_status) = 'unidentified'                 THEN 1 ELSE 0 END) AS has_unidentified
    FROM `tough-healer-395417.superform_outputs_287832387.ga4_events` e
    JOIN fiscal_calendar fc ON e.event_date = fc.calendar_date
    WHERE event_name IN ('page_view','adobe_page_view')
      AND page.path IN ('/','/jsp/homepage.jsp')
      AND e.event_date BETWEEN DATE '2025-03-01' AND DATE '2025-04-21'
      AND geo.country  != 'India'
      AND page.hostname = 'www.wsjwine.com'
    GROUP BY
        brand, fc.fiscal_year, fc.fiscal_month, fc.month_number, fc.quarter_number,
        user_pseudo_id, session_id
    
    UNION ALL
    
    -- ---------- LAW ----------
    SELECT
        'LAW'            AS brand,
        fc.fiscal_year,
        fc.fiscal_month,
        fc.month_number,
        fc.quarter_number,
        user_pseudo_id,
        session_id,
        MAX(CASE WHEN event_params_custom.login_status IN ('Soft Logged-In','Hard Logged-In') THEN 1 ELSE 0 END) AS has_identified,
        MAX(CASE WHEN LOWER(event_params_custom.login_status) = 'unidentified'                 THEN 1 ELSE 0 END) AS has_unidentified
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_events` e
    JOIN fiscal_calendar fc ON e.event_date = fc.calendar_date
    WHERE event_name IN ('page_view','adobe_page_view')
      AND page.path IN ('/','/jsp/homepage.jsp')
      AND e.event_date BETWEEN DATE '2025-03-01' AND DATE '2025-04-21'
      AND geo.country  != 'India'
      AND page.hostname = 'www.laithwaites.com'
    GROUP BY
        brand, fc.fiscal_year, fc.fiscal_month, fc.month_number, fc.quarter_number,
        user_pseudo_id, session_id
),

/* 3️⃣  Mutually‑exclusive login‑status buckets ---------------- */
session_groups AS (
    SELECT
        brand,
        fiscal_year,
        fiscal_month,
        month_number,
        quarter_number,
        user_pseudo_id,
        session_id,
        CASE
            WHEN has_identified = 1 AND has_unidentified = 0 THEN 'Identified ONLY'
            WHEN has_identified = 0 AND has_unidentified = 1 THEN 'Unidentified ONLY'
            WHEN has_identified = 1 AND has_unidentified = 1 THEN 'Identified AND Unidentified'
            ELSE 'Unknown'
        END AS login_status_group
    FROM homepage_sessions
),

/* 4️⃣  “All” bucket ------------------------------------------- */
all_sessions AS (
    SELECT
        brand,
        fiscal_year,
        fiscal_month,
        month_number,
        quarter_number,
        user_pseudo_id,
        session_id,
        'All' AS login_status_group
    FROM homepage_sessions
),

/* 5️⃣  Transactions (both brands) ----------------------------- */
transactions AS (
    SELECT DISTINCT
        'WSJ' AS brand,
        session_id,
        transaction_id,
        ecommerce.purchase_revenue
    FROM `tough-healer-395417.superform_outputs_287832387.ga4_transactions`
    
    UNION ALL
    
    SELECT DISTINCT
        'LAW' AS brand,
        session_id,
        transaction_id,
        ecommerce.purchase_revenue
    FROM `tough-healer-395417.superform_outputs_287163560.ga4_transactions`
)

/* 6️⃣  Output – exclusive buckets ----------------------------- */
SELECT
    sg.brand,
    sg.fiscal_year,
    sg.fiscal_month,
    sg.month_number,
    sg.quarter_number,
    sg.login_status_group            AS login_status,
    COUNT(DISTINCT sg.user_pseudo_id)      AS users,
    COUNT(DISTINCT sg.session_id)          AS sessions,
    COUNT(DISTINCT t.transaction_id)       AS transactions,
    ROUND(SUM(COALESCE(t.purchase_revenue,0)),2) AS revenue
FROM session_groups sg
LEFT JOIN transactions t
  ON sg.brand      = t.brand
 AND sg.session_id = t.session_id
GROUP BY
    sg.brand,
    sg.fiscal_year,
    sg.fiscal_month,
    sg.month_number,
    sg.quarter_number,
    sg.login_status_group

UNION ALL

/* 7️⃣  Output – “All” bucket ---------------------------------- */
SELECT
    a.brand,
    a.fiscal_year,
    a.fiscal_month,
    a.month_number,
    a.quarter_number,
    a.login_status_group             AS login_status,
    COUNT(DISTINCT a.user_pseudo_id)      AS users,
    COUNT(DISTINCT a.session_id)          AS sessions,
    COUNT(DISTINCT t.transaction_id)      AS transactions,
    ROUND(SUM(COALESCE(t.purchase_revenue,0)),2) AS revenue
FROM all_sessions a
LEFT JOIN transactions t
  ON a.brand      = t.brand
 AND a.session_id = t.session_id
GROUP BY
    a.brand,
    a.fiscal_year,
    a.fiscal_month,
    a.month_number,
    a.quarter_number,
    a.login_status_group;
