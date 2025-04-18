  SELECT
    EXTRACT(MONTH FROM s.session_date) AS month,
    CASE 
      WHEN EXTRACT(MONTH FROM s.session_date) BETWEEN 7 AND 9 THEN 1  -- Q1 (Jul-Sep)
      WHEN EXTRACT(MONTH FROM s.session_date) BETWEEN 10 AND 12 THEN 2 -- Q2 (Oct-Dec)
      WHEN EXTRACT(MONTH FROM s.session_date) BETWEEN 1 AND 3 THEN 3  -- Q3 (Jan-Mar)
      WHEN EXTRACT(MONTH FROM s.session_date) BETWEEN 4 AND 6 THEN 4  -- Q4 (Apr-Jun)
    END AS quarter,
    DATE_TRUNC(s.session_date, MONTH) AS year_month,
    CASE
      WHEN s.geo.region IN ('Texas', 'Florida', 'Illinois', 'New Jersey', 'Ohio') THEN 'Test'
      WHEN s.geo.region IN ('California', 'New York', 'Michigan', 'Massachusetts', 'Virginia') THEN 'Control'
      ELSE 'All Other'
    END AS state_group,
    s.geo.region AS state,
    CASE 
      WHEN s.session_date BETWEEN '2024-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) 
      THEN 'Current Year'
      ELSE 'Previous Year'
    END AS period,
    s.user_pseudo_id,
    s.session_id,
    s.last_non_direct_traffic_source.source,
    s.last_non_direct_traffic_source.medium,
    s.last_non_direct_traffic_source.campaign,
    s.landing_page.landing_page_location,
    s.landing_page.landing_page_referrer,
    t.transaction_id,
    t.ecommerce.purchase_revenue,

    CASE
      WHEN s.last_non_direct_traffic_source.source IS NULL 
          AND s.last_non_direct_traffic_source.medium IS NULL 
          AND NOT REGEXP_CONTAINS(IFNULL(LOWER(s.landing_page.landing_page_location), ''), r"promoCode=|splash_template.jsp|gclid=|fbclid=")
          THEN 'Direct'

      WHEN LOWER(s.last_non_direct_traffic_source.medium) = 'organic' THEN 'Organic'

      WHEN (
        REGEXP_CONTAINS(LOWER(s.last_non_direct_traffic_source.source), r"google|bing|sa360|search|sem")
        AND REGEXP_CONTAINS(LOWER(s.last_non_direct_traffic_source.medium), r"cpc|web_search|sa360|sem")
      ) OR LOWER(s.landing_page.landing_page_location) LIKE '%gclid%' THEN 'Paid Search'

     WHEN (
        REGEXP_CONTAINS(LOWER(CONCAT(s.last_non_direct_traffic_source.source, s.last_non_direct_traffic_source.medium)), r"facebook|instagram|paidsocial|paid-social|fb")
        OR LOWER(s.landing_page.landing_page_location) LIKE '%fbclid%'
      )
      AND NOT REGEXP_CONTAINS(IFNULL(LOWER(s.last_non_direct_traffic_source.medium), ''), r"referral|organic")
      THEN 'Paid Social'

      ELSE 'Other'
    END AS channel,

    CASE
      WHEN r.Customer_Status = 'Existing Customer' THEN 'Existing'
      WHEN r.Customer_Status IN ('New Recruit', 'Re-Recruit') THEN 'New'
      END AS customer_status,
    CASE
      WHEN r.ORDERTYPE = 'Wine Club' THEN 'Club'
      WHEN r.ORDERTYPE = 'Non-Wine Club' THEN 'Standard'
      END AS order_type,
    r.COUPON_CODE as coupon_code
  FROM `tough-healer-395417.superform_outputs_287832387.ga4_sessions` s
  LEFT JOIN `tough-healer-395417.superform_outputs_287832387.ga4_transactions` t
  ON s.session_id = t.session_id
  LEFT JOIN `tough-healer-395417.DWI_DB.REC008_website_orders` r
  ON t.transaction_id = r.ATGSalesOrderNumber
  WHERE
    s.geo.country = 'United States'
    AND s.device.web_info.hostname = 'www.wsjwine.com'
    AND --(
      s.session_date BETWEEN '2025-04-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- Current Year
      --OR
      --s.session_date BETWEEN '2023-09-01' AND DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 DAY) -- Previous Year
    --)