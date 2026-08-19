-- Account-section page performance, WSJ + LAW, FY25/26 (2025-07-01 .. 2026-06-30)
--
-- Scope: /jsp/account/ plus /jsp/mytaste/ (LAW's equivalent of WSJ's account_details
--        SPA sub-routes: purchased / favorites / preferences live there, not under
--        /jsp/account/). Including it is what makes the two brands comparable.
--
-- Page identity = page_path || normalised page_fragment (hash routes fire own page_view).
-- "Next step" = view_item / add_to_cart on page_number + 1 (the very next pageview).
-- "Eventual"  = view_item / add_to_cart at any later hit_number in the session.
-- Revenue/transactions are PARTICIPATION metrics: full session value credited to every
-- account page the session touched, so page rows sum to more than the section total.

DECLARE d_start DATE DEFAULT '2025-07-01';
DECLARE d_end   DATE DEFAULT '2026-06-30';

WITH ev AS (
  SELECT
    brand,
    session_id,
    user_pseudo_id,
    event_name,
    hit_number,
    page_number,
    REGEXP_REPLACE(page_path, r';jsessionid=.*$', '') AS page_path,
    -- NULL / '#' / '#/' -> ''  |  '#/beyond-the-label?utm_..' -> 'beyond-the-label'
    COALESCE(LOWER(REGEXP_EXTRACT(page_fragment, r'^#?/?([^?&]*)')), '') AS frag,
    -- Narvar shipment-notification email deep-links land with utm in the fragment
    COALESCE(LOWER(page_fragment) LIKE '%narvar%', FALSE) AS is_narvar_link
  FROM `tough-healer-395417.analytics_unified.fact_ga4_events`
  WHERE brand IN ('WSJ', 'LAW')
    AND event_date BETWEEN d_start AND d_end
),

acct AS (
  SELECT
    brand, session_id, user_pseudo_id, hit_number, page_number, is_narvar_link,
    CASE
      -- account_details.jsp (WSJ + LAW) and mytaste/index.jsp (LAW) are hash-routed SPAs
      WHEN page_path LIKE '%account_details.jsp' OR page_path LIKE '%/jsp/mytaste/index.jsp' THEN
        CASE frag
          WHEN 'beyond-the-label' THEN 'Beyond the Label'
          WHEN 'purchased'        THEN "Wines I've Purchased"
          WHEN 'favorites'        THEN 'Favorites'
          WHEN 'wine-cellar'      THEN 'My Wine Cellar'
          WHEN 'top-rated'        THEN 'Top-Rated Wines'
          WHEN 'not-for-me'       THEN 'Not For Me List'
          WHEN 'disliked'         THEN 'Not For Me List'
          WHEN 'recommendations'  THEN 'Recommendations'
          WHEN 'justforyou'       THEN 'Recommendations'
          WHEN 'preferences'      THEN 'Wine Preferences'
          WHEN 'settings'         THEN 'Change Password / Settings'
          WHEN 'memberships'      THEN 'Memberships'
          WHEN 'order-history'    THEN 'Order History'
          WHEN '' THEN IF(page_path LIKE '%/jsp/mytaste/index.jsp',
                          'MyTaste home', 'Account (details home)')
          ELSE CONCAT('Account SPA other: ', frag)
        END
      WHEN page_path LIKE '%account_order_history.jsp'   THEN 'Order History'
      WHEN page_path LIKE '%wp_summary.jsp'              THEN 'My Clubs'
      WHEN page_path LIKE '%account_voucher_details.jsp' THEN 'Gift Cards / My Wine Credits'
      WHEN page_path LIKE '%account_subscription.jsp'    THEN 'Advantage'
      WHEN page_path LIKE '%account_wine_preference.jsp' THEN 'Wine Preferences'
      WHEN page_path LIKE '%account_lists.jsp'           THEN 'Account Lists'
      WHEN page_path LIKE '%cellar_homepage.jsp'         THEN 'Cellar Homepage'
      WHEN page_path LIKE '%account_refer_friend.jsp'    THEN 'Refer a Friend'
      ELSE 'Other account page'
    END AS page_label
  FROM ev
  WHERE event_name = 'page_view'
    AND (page_path LIKE '%/jsp/account/%' OR page_path LIKE '%/jsp/mytaste/%')
),

sig AS (
  SELECT
    brand, session_id,
    ARRAY_AGG(IF(event_name = 'view_item',   page_number, NULL) IGNORE NULLS) AS pdp_pages,
    ARRAY_AGG(IF(event_name = 'add_to_cart', page_number, NULL) IGNORE NULLS) AS atc_pages,
    MAX(IF(event_name = 'view_item',   hit_number, NULL)) AS last_pdp_hit,
    MAX(IF(event_name = 'add_to_cart', hit_number, NULL)) AS last_atc_hit
  FROM ev
  WHERE event_name IN ('view_item', 'add_to_cart')
  GROUP BY brand, session_id
),

txn AS (
  SELECT
    brand, session_id,
    COUNT(DISTINCT transaction_id)  AS transactions,
    SUM(ecommerce.purchase_revenue) AS revenue
  FROM `tough-healer-395417.analytics_unified.fact_ga4_transactions`
  WHERE brand IN ('WSJ', 'LAW')
    AND transaction_date BETWEEN d_start AND d_end
  GROUP BY brand, session_id
),

sess_page AS (
  SELECT
    brand, page_label, session_id,
    ANY_VALUE(user_pseudo_id)  AS user_pseudo_id,
    MIN(hit_number)            AS first_hit,
    LOGICAL_OR(is_narvar_link) AS via_narvar,
    ARRAY_AGG(DISTINCT page_number) AS acct_pages
  FROM acct
  GROUP BY brand, page_label, session_id
),

flagged AS (
  SELECT
    sp.brand, sp.page_label, sp.session_id, sp.user_pseudo_id, sp.via_narvar,
    EXISTS (SELECT 1 FROM UNNEST(sp.acct_pages) ap
            WHERE ap + 1 IN UNNEST(COALESCE(s.pdp_pages, []))) AS next_pdp,
    EXISTS (SELECT 1 FROM UNNEST(sp.acct_pages) ap
            WHERE ap + 1 IN UNNEST(COALESCE(s.atc_pages, []))) AS next_atc,
    COALESCE(s.last_pdp_hit > sp.first_hit, FALSE) AS eventual_pdp,
    COALESCE(s.last_atc_hit > sp.first_hit, FALSE) AS eventual_atc,
    COALESCE(t.transactions, 0) AS transactions,
    COALESCE(t.revenue, 0)      AS revenue
  FROM sess_page sp
  LEFT JOIN sig s USING (brand, session_id)
  LEFT JOIN txn t USING (brand, session_id)
),

totals AS (
  SELECT brand, COUNT(DISTINCT session_id) AS all_acct_sessions
  FROM acct GROUP BY brand
)

SELECT
  f.brand,
  f.page_label,
  -- Beyond the Label is split by arrival route; every other page is 'All'
  IF(f.page_label = 'Beyond the Label',
     IF(f.via_narvar, 'via Narvar email', 'organic'), 'All') AS arrival,
  COUNT(DISTINCT f.session_id)                                       AS sessions,
  COUNT(DISTINCT f.user_pseudo_id)                                   AS users,
  ROUND(100 * COUNT(DISTINCT f.session_id) / t.all_acct_sessions, 2) AS pct_of_acct_sessions,
  SUM(f.transactions)                                                AS transactions,
  ROUND(SUM(f.revenue), 0)                                           AS revenue,
  ROUND(100 * COUNTIF(f.transactions > 0) / COUNT(*), 2)             AS conv_rate_pct,
  ROUND(100 * COUNTIF(f.next_pdp)     / COUNT(*), 2)                 AS next_step_pdp_pct,
  ROUND(100 * COUNTIF(f.eventual_pdp) / COUNT(*), 2)                 AS eventual_pdp_pct,
  ROUND(100 * COUNTIF(f.next_atc)     / COUNT(*), 2)                 AS next_step_atc_pct,
  ROUND(100 * COUNTIF(f.eventual_atc) / COUNT(*), 2)                 AS eventual_atc_pct
FROM flagged f
JOIN totals t USING (brand)
GROUP BY f.brand, f.page_label, arrival, t.all_acct_sessions
HAVING sessions >= 150
ORDER BY f.brand, sessions DESC
