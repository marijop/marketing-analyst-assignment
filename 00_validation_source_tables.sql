-- =============================================================================
-- File:        00_validation_source_tables.sql
-- Purpose:     Initial exploration of the three source tables loaded from CSVs.
--              Used to validate row counts, date ranges, and aggregate totals
--              before designing the unified schema.
-- Dataset:     intrepid-fiber-494520-q0.marketing_ads
-- Author:      Maria Jose Placido
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Query 1: Facebook Ads — exploration
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*)                          AS total_rows,
  MIN(date)                         AS first_date,
  MAX(date)                         AS last_date,
  COUNT(DISTINCT campaign_id)       AS distinct_campaigns,
  COUNT(DISTINCT ad_set_id)         AS distinct_ad_sets,
  ROUND(SUM(spend), 2)              AS total_spend,
  SUM(impressions)                  AS total_impressions,
  SUM(clicks)                       AS total_clicks,
  SUM(conversions)                  AS total_conversions
FROM `intrepid-fiber-494520-q0.marketing_ads.facebook_ads`;


-- -----------------------------------------------------------------------------
-- Query 2: Google Ads — exploration
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*)                          AS total_rows,
  MIN(date)                         AS first_date,
  MAX(date)                         AS last_date,
  COUNT(DISTINCT campaign_id)       AS distinct_campaigns,
  COUNT(DISTINCT ad_group_id)       AS distinct_ad_groups,
  ROUND(SUM(cost), 2)               AS total_cost,
  ROUND(SUM(conversion_value), 2)   AS total_revenue,
  SUM(impressions)                  AS total_impressions,
  SUM(clicks)                       AS total_clicks,
  SUM(conversions)                  AS total_conversions
FROM `intrepid-fiber-494520-q0.marketing_ads.google_ads`;


-- -----------------------------------------------------------------------------
-- Query 3: TikTok Ads — exploration
-- -----------------------------------------------------------------------------
SELECT
  COUNT(*)                          AS total_rows,
  MIN(date)                         AS first_date,
  MAX(date)                         AS last_date,
  COUNT(DISTINCT campaign_id)       AS distinct_campaigns,
  COUNT(DISTINCT adgroup_id)        AS distinct_adgroups,
  ROUND(SUM(cost), 2)               AS total_cost,
  SUM(impressions)                  AS total_impressions,
  SUM(clicks)                       AS total_clicks,
  SUM(conversions)                  AS total_conversions,
  SUM(video_views)                  AS total_video_views
FROM `intrepid-fiber-494520-q0.marketing_ads.tiktok_ads`;


-- -----------------------------------------------------------------------------
-- Query 4: Cross-platform date range consistency check
-- -----------------------------------------------------------------------------
-- Confirms all three platforms share the same temporal coverage (Jan 1–30, 2024).
-- A mismatch here would indicate incomplete data and require remediation
-- before unification.
WITH date_ranges AS (
  SELECT 'Facebook' AS platform, MIN(date) AS first_date, MAX(date) AS last_date
  FROM `intrepid-fiber-494520-q0.marketing_ads.facebook_ads`
  UNION ALL
  SELECT 'Google', MIN(date), MAX(date)
  FROM `intrepid-fiber-494520-q0.marketing_ads.google_ads`
  UNION ALL
  SELECT 'TikTok', MIN(date), MAX(date)
  FROM `intrepid-fiber-494520-q0.marketing_ads.tiktok_ads`
)
SELECT * FROM date_ranges ORDER BY platform;
