-- =============================================================================
-- File:        01_create_unified_ads.sql
-- Purpose:     Creates the unified cross-channel advertising table by combining
--              Facebook, Google, and TikTok source tables into a single
--              normalized schema.
-- Output:      intrepid-fiber-494520-q0.marketing_ads.unified_ads
-- Author:      Maria Jose Placido
--
-- Schema normalization decisions:
--   - Cost field: Facebook uses `spend`; Google and TikTok use `cost`.
--     Standardized to `cost` across all platforms.
--   - Group hierarchy: Facebook uses `ad_set_id/name`; Google uses
--     `ad_group_id/name`; TikTok uses `adgroup_id/name`.
--     Standardized to `group_id/group_name`.
--   - Platform discriminator: a hardcoded `platform` column is added to
--     every row, enabling cross-channel filtering and grouping in Tableau.
--   - Platform-specific columns: preserved as nullable fields cast to the
--     correct type. NULL values are explicit and intentional, indicating
--     the metric is not reported by that platform (e.g., `conversion_value`
--     is only available for Google).
-- =============================================================================


CREATE OR REPLACE TABLE
  `intrepid-fiber-494520-q0.marketing_ads.unified_ads`
AS

-- -----------------------------------------------------------------------------
-- FACEBOOK ADS
-- -----------------------------------------------------------------------------
SELECT
  'Facebook'                          AS platform,
  date,
  campaign_id,
  campaign_name,
  ad_set_id                           AS group_id,
  ad_set_name                         AS group_name,
  impressions,
  clicks,
  spend                               AS cost,
  conversions,
  CAST(NULL AS FLOAT64)               AS conversion_value,
  video_views,
  engagement_rate,
  reach,
  frequency,
  CAST(NULL AS INT64)                 AS quality_score,
  CAST(NULL AS FLOAT64)               AS search_impression_share,
  CAST(NULL AS INT64)                 AS video_watch_25,
  CAST(NULL AS INT64)                 AS video_watch_50,
  CAST(NULL AS INT64)                 AS video_watch_75,
  CAST(NULL AS INT64)                 AS video_watch_100,
  CAST(NULL AS INT64)                 AS likes,
  CAST(NULL AS INT64)                 AS shares,
  CAST(NULL AS INT64)                 AS comments
FROM
  `intrepid-fiber-494520-q0.marketing_ads.facebook_ads`

UNION ALL

-- -----------------------------------------------------------------------------
-- GOOGLE ADS
-- -----------------------------------------------------------------------------
SELECT
  'Google'                            AS platform,
  date,
  campaign_id,
  campaign_name,
  ad_group_id                         AS group_id,
  ad_group_name                       AS group_name,
  impressions,
  clicks,
  cost,
  conversions,
  conversion_value,
  CAST(NULL AS INT64)                 AS video_views,
  CAST(NULL AS FLOAT64)               AS engagement_rate,
  CAST(NULL AS INT64)                 AS reach,
  CAST(NULL AS FLOAT64)               AS frequency,
  quality_score,
  search_impression_share,
  CAST(NULL AS INT64)                 AS video_watch_25,
  CAST(NULL AS INT64)                 AS video_watch_50,
  CAST(NULL AS INT64)                 AS video_watch_75,
  CAST(NULL AS INT64)                 AS video_watch_100,
  CAST(NULL AS INT64)                 AS likes,
  CAST(NULL AS INT64)                 AS shares,
  CAST(NULL AS INT64)                 AS comments
FROM
  `intrepid-fiber-494520-q0.marketing_ads.google_ads`

UNION ALL

-- -----------------------------------------------------------------------------
-- TIKTOK ADS
-- -----------------------------------------------------------------------------
SELECT
  'TikTok'                            AS platform,
  date,
  campaign_id,
  campaign_name,
  adgroup_id                          AS group_id,
  adgroup_name                        AS group_name,
  impressions,
  clicks,
  cost,
  conversions,
  CAST(NULL AS FLOAT64)               AS conversion_value,
  video_views,
  CAST(NULL AS FLOAT64)               AS engagement_rate,
  CAST(NULL AS INT64)                 AS reach,
  CAST(NULL AS FLOAT64)               AS frequency,
  CAST(NULL AS INT64)                 AS quality_score,
  CAST(NULL AS FLOAT64)               AS search_impression_share,
  video_watch_25,
  video_watch_50,
  video_watch_75,
  video_watch_100,
  likes,
  shares,
  comments
FROM
  `intrepid-fiber-494520-q0.marketing_ads.tiktok_ads`;
