/**
pre_operations {
  DECLARE date_checkpoint DATE;
  SET date_checkpoint = (
    ${when(incremental(),
      `SELECT COALESCE(MAX(session_date) + 1, DATE('${ga4_config.START_DATE}'))
       FROM ${self()}
       WHERE is_final = TRUE`,
      `SELECT DATE('${ga4_config.START_DATE}')`
    )}
  );

  ${when(incremental(),
    `DELETE FROM ${self()} WHERE session_date >= date_checkpoint`
  )}
}
**/
-- Layered CTEs for classification logic
WITH with_channel AS (
  SELECT
    *,
    
    CASE
        -- PAID SEARCH
        WHEN url_gclid IS NOT NULL
          OR url_wbraid IS NOT NULL
          OR ( 
          REGEXP_CONTAINS(lnd_source_medium, r'(\d|_)(google|bing|yahoo)(\d|_)')
          AND REGEXP_CONTAINS(lnd_source_medium, r'(\d|_)(cpc|search.?engine|search|sem)(\d|_)')
          )
        THEN 'Paid Search'

        -- PAID SOCIAL
        WHEN (
          url_fbclid IS NOT NULL
          OR REGEXP_CONTAINS(lnd_source_medium, r'\d(fb|facebook|ig|instagram|paidsocial|meta|paid[-_]?social)(\d|_)')
          )
          AND NOT REGEXP_CONTAINS(lnd_source_medium, r'(referral|organic)')
        THEN 'Paid Social'

        -- DIRECT
        WHEN lnd_source = 'none'
          AND lnd_medium = 'none'
          AND url_dwi_campaign_id IS NULL
        THEN 'Direct'

        ELSE 'Other'

    END
 AS channel_category
  FROM `tough-healer-395417.analytics_staging.int_ga4_sessions`
),

with_campaign AS (
  SELECT
    *,
    
  CASE
    -- PAID SEARCH
    WHEN channel_category = 'Paid Search'
      AND REGEXP_CONTAINS(LOWER(session_traffic_source_last_click.google_ads_campaign.campaign_name), r'_br|brand|-b-|- b -') THEN 'Branded Search'
    
    WHEN channel_category = 'Paid Search'
      AND REGEXP_CONTAINS(LOWER(session_traffic_source_last_click.google_ads_campaign.campaign_name), r'_nb|generic|-g-|- g -') THEN 'Generic Search'

    WHEN channel_category = 'Paid Search'
      AND REGEXP_CONTAINS(LOWER(session_traffic_source_last_click.google_ads_campaign.campaign_name), r'pmax|performance max') THEN 'Performance Max'

    WHEN channel_category = 'Paid Search'
      AND LOWER(session_traffic_source_last_click.google_ads_campaign.campaign_name) LIKE '%shopping%' THEN 'Shopping'

    WHEN channel_category = 'Paid Search'
      AND REGEXP_CONTAINS(LOWER(session_traffic_source_last_click.google_ads_campaign.campaign_name), r'-yt-|- yt -|demand gen') THEN 'Demand Gen'
    
    WHEN channel_category = 'Paid Search' THEN 'Other'

    -- PAID SOCIAL
    WHEN channel_category = 'Paid Social'
      AND REGEXP_CONTAINS(lnd_campaign, r'(retargeting|reengagement)') THEN 'Retargeting'

    WHEN channel_category = 'Paid Social'
      AND REGEXP_CONTAINS(lnd_campaign, r'_std')
      AND NOT REGEXP_CONTAINS(lnd_campaign, r'(event|sweepstakes|retargeting|reengagement)') THEN 'Standard'

    WHEN channel_category = 'Paid Social'
      AND NOT REGEXP_CONTAINS(lnd_campaign, r'(event|sweepstakes|retargeting|reengagement)')
      AND NOT lnd_campaign = 'none' THEN 'Club'

    WHEN channel_category = 'Paid Social' THEN 'Other'

    ELSE 'General'
  END
 AS campaign_category
  FROM with_channel
),

with_fiscal AS (
  SELECT
  c.*,
  d.fiscal_year,
  d.fiscal_quarter_number,
  d.fiscal_month_number,
  d.fiscal_month_name,
  d.fiscal_week_number,
  d.fiscal_week_start_date,
  d.fiscal_week_end_date
  FROM with_campaign c
  LEFT JOIN `tough-healer-395417.analytics_unified.dim_fiscal_dates` d
    ON c.session_date = d.date
)

SELECT
  f.*,
  COALESCE(m.funnel_category, 'Unmapped') AS funnel_category,
  COALESCE(m.marketing_category, 'Unmapped') AS marketing_category,
  m.marketing_group_id,
  m.campaign_group_type
FROM with_fiscal f
LEFT JOIN `tough-healer-395417.analytics_unified.dim_channel_map` m
  ON f.channel_category = m.channel_category
 AND f.campaign_category = m.campaign_category
--WHERE session_date >= date_checkpoint