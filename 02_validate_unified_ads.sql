-- =============================================================================
-- File:        02_validate_unified_ads.sql
-- Purpose:     Post-unification validation queries. Confirms that the unified
--              table preserves source-level totals and that schema-level
--              constraints behave as expected.
-- Source:      intrepid-fiber-494520-q0.marketing_ads.unified_ads
-- Author:      Maria Jose Placido
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Query 1: Per-platform totals
-- -----------------------------------------------------------------------------
-- Validates that the unification preserves all rows and aggregate metrics
-- from the source tables. Each platform should report 110 rows and totals
-- matching the original CSVs.
--
-- Expected results:
--   TikTok    | 110 rows | 2024-01-01 to 2024-01-30 | $74,266.70 | 6,750 conv | NULL revenue
--   Google    | 110 rows | 2024-01-01 to 2024-01-30 | $37,686.20 | 4,218 conv | $210,900.00 revenue
--   Facebook  | 110 rows | 2024-01-01 to 2024-01-30 | $18,292.00 | 2,395 conv | NULL revenue
SELECT
  platform,
  COUNT(*)                                AS row_count,
  MIN(date)                               AS first_date,
  MAX(date)                               AS last_date,
  ROUND(SUM(cost), 2)                     AS total_cost,
  SUM(conversions)                        AS total_conversions,
  ROUND(SUM(conversion_value), 2)         AS total_revenue
FROM `intrepid-fiber-494520-q0.marketing_ads.unified_ads`
GROUP BY platform
ORDER BY total_cost DESC;


-- -----------------------------------------------------------------------------
-- Query 2: Cross-channel rollup
-- -----------------------------------------------------------------------------
-- Confirms total spend across the three platforms matches the expected
-- $130,244.90 figure used in the dashboard's KPI tile.
SELECT
  COUNT(*)                                AS total_rows,
  COUNT(DISTINCT platform)                AS platforms,
  COUNT(DISTINCT campaign_id)             AS distinct_campaigns,
  ROUND(SUM(cost), 2)                     AS total_spend,
  SUM(impressions)                        AS total_impressions,
  SUM(clicks)                             AS total_clicks,
  SUM(conversions)                        AS total_conversions,
  ROUND(SUM(conversion_value), 2)         AS total_revenue_google_only
FROM `intrepid-fiber-494520-q0.marketing_ads.unified_ads`;


-- -----------------------------------------------------------------------------
-- Query 3: NULL distribution check
-- -----------------------------------------------------------------------------
-- Confirms that platform-specific metrics are NULL where expected.
-- Facebook and TikTok rows must report NULL for `conversion_value`.
-- Google rows must report NULL for video and engagement metrics.
-- This validates schema integrity post-unification.
SELECT
  platform,
  COUNTIF(conversion_value IS NULL)       AS null_conversion_value,
  COUNTIF(engagement_rate IS NULL)        AS null_engagement_rate,
  COUNTIF(quality_score IS NULL)          AS null_quality_score,
  COUNTIF(video_watch_100 IS NULL)        AS null_video_watch_100,
  COUNTIF(likes IS NULL)                  AS null_likes
FROM `intrepid-fiber-494520-q0.marketing_ads.unified_ads`
GROUP BY platform
ORDER BY platform;


-- -----------------------------------------------------------------------------
-- Query 4: Top campaigns by efficiency (preview of dashboard logic)
-- -----------------------------------------------------------------------------
-- Cross-channel CPA ranking. Replicated in Tableau as the Efficiency Matrix.
-- Useful for sanity-checking dashboard numbers against direct SQL output.
SELECT
  platform,
  campaign_name,
  SUM(impressions)                                                     AS impressions,
  SUM(clicks)                                                          AS clicks,
  SUM(conversions)                                                     AS conversions,
  ROUND(SUM(cost), 2)                                                  AS spend,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)                   AS cpa,
  ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)) * 100, 2)           AS cvr_pct,
  ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)) * 100, 2)           AS ctr_pct
FROM `intrepid-fiber-494520-q0.marketing_ads.unified_ads`
GROUP BY platform, campaign_name
ORDER BY cpa ASC;
