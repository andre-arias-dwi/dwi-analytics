--requestor: Nicole
--purpose:state test data by fiscal weeks, excluding excluding newspaper print ads from The New Yorker Magazine, The Wall Street Journal, The NY Times
--output: excel file State_Test_Fiscal_Weeks.xlsx

SELECT
  period,
  state_group,
  order_type,
  week_ending,
  CONCAT(SOURCE,' / ', medium) AS source_medium,
  landing_page_location,
  COUNT(DISTINCT transaction_id) AS orders
FROM
  `tough-healer-395417.GA4_reporting.WSJ_state_level_fiscal_weeks_lp`
WHERE
  customer_status = 'New'
  AND state_group IN ('Control', 'Test')
  AND NOT REGEXP_CONTAINS(landing_page_location, r"promoCode=(AGPJ001|AGNM002|AGLW001)") --response codes from print ads
GROUP BY ALL
ORDER BY
  7 DESC,
  4 DESC,
  3,
  2,
  1