# Cross-Channel Marketing Performance Dashboard

**Senior Marketing Analyst — Technical Assignment**

A unified, end-to-end analytics solution that ingests advertising data from Facebook Ads, Google Ads, and TikTok Ads, normalizes it inside a cloud data warehouse, and surfaces actionable cross-channel insights through an executive dashboard.

---

## Author

**Maria Jose Placido**
Tableau Public profile: https://public.tableau.com/app/profile/maria.jose.placido/viz/marketing-analyst-assignment/MarketingDashboard [public.tableau.com/app/profile/maria.jose.placido](https://public.tableau.com/app/profile/maria.jose.placido)

---

## Deliverables

| Item | Link |
|---|---|
| Live dashboard (Tableau Public) | [Cross-Channel Marketing Performance — January 2024](https://public.tableau.com/app/profile/maria.jose.placido/viz/marketing-analyst-assignment/MarketingDashboard) |
| Video walkthrough | `[INSERT VIDEO LINK HERE]` |
| Source code repository | This repository |

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Architecture](#3-architecture)
4. [Data Setup in BigQuery](#4-data-setup-in-bigquery)
5. [Tableau Connection](#5-tableau-connection)
6. [Calculated Fields in Tableau](#6-calculated-fields-in-tableau)
7. [Dashboard Walkthrough](#7-dashboard-walkthrough)
8. [Key Findings and Recommendations](#8-key-findings-and-recommendations)
9. [Methodological Decisions and Limitations](#9-methodological-decisions-and-limitations)
10. [Future Work](#10-future-work)
11. [How to Reproduce](#11-how-to-reproduce)

---

## 1. Project Overview

### Business problem

Marketing teams running campaigns across multiple platforms face a recurring analytical challenge: each ad platform reports performance using its own schema, terminology, and metric definitions. Comparing the efficiency of Facebook, Google, and TikTok investments — or even computing a simple cross-channel CPA — requires upstream data engineering before any analysis is possible.

This project simulates that real-world scenario. The deliverable transforms three raw CSV exports into a unified analytical layer and a one-page executive dashboard that supports cross-channel performance decisions.

### Scope

- Time period: January 1–30, 2024 (30 days)
- Platforms: Facebook Ads, Google Ads, TikTok Ads
- Source records: 330 daily rows (110 per platform, 4 campaigns per platform)
- Total ad spend analyzed: $130,244.90
- Total conversions analyzed: 13,363

### Stack

| Layer | Tool |
|---|---|
| Cloud database | Google BigQuery (sandbox tier) |
| Transformation | SQL (BigQuery standard) |
| BI / Visualization | Tableau Desktop Professional 2026.1.1 |
| Publishing | Tableau Public |
| Version control | Git / GitHub |

---

## 2. Repository Structure

```
marketing-analyst-assignment/
├── README.md                              This document
├── data/
│   ├── 01_facebook_ads.csv                Raw Facebook source data
│   ├── 02_google_ads.csv                  Raw Google source data
│   └── 03_tiktok_ads.csv                  Raw TikTok source data
└── sql/
    ├── 00_validation_source_tables.sql    Exploratory queries on source CSVs
    ├── 01_create_unified_ads.sql          Unification logic (UNION ALL)
    └── 02_validate_unified_ads.sql        Post-unification validation queries
```

---

## 3. Architecture

The solution follows a three-layer pattern: raw ingestion, transformation in cloud, and visualization. Each layer has a single responsibility.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          LAYER 1 — RAW                              │
│                                                                     │
│   01_facebook_ads.csv     02_google_ads.csv     03_tiktok_ads.csv   │
│         (110 rows)            (110 rows)            (110 rows)      │
│                                                                     │
└─────────────────────────┬───────────────────────────────────────────┘
                          │  Manual upload via BigQuery console
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  LAYER 2 — CLOUD WAREHOUSE (BigQuery)               │
│                                                                     │
│   Project:  intrepid-fiber-494520-q0                                │
│   Dataset:  marketing_ads                                           │
│                                                                     │
│   ┌─────────────┐  ┌────────────┐  ┌─────────────┐                  │
│   │facebook_ads │  │google_ads  │  │tiktok_ads   │                  │
│   │  (raw)      │  │  (raw)     │  │  (raw)      │                  │
│   └──────┬──────┘  └─────┬──────┘  └──────┬──────┘                  │
│          │               │                │                         │
│          └───────────────┴────────────────┘                         │
│                          │                                          │
│                          ▼  CREATE OR REPLACE TABLE … AS UNION ALL  │
│                  ┌───────────────────┐                              │
│                  │   unified_ads     │   ← Single source of truth   │
│                  │   (330 rows)      │                              │
│                  └─────────┬─────────┘                              │
│                            │                                        │
└────────────────────────────┼────────────────────────────────────────┘
                             │  OAuth connection + Extract
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  LAYER 3 — VISUALIZATION (Tableau)                  │
│                                                                     │
│   Calculated fields:  CTR, CPC, CPA, CPM, CVR, ROAS                 │
│   Worksheets:         9 (4 KPIs + 5 charts/tables)                  │
│   Dashboard:          1 executive page (1300 × 900)                 │
│   Hosting:            Tableau Public                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

The choice to perform unification inside BigQuery rather than in Tableau is deliberate: SQL is the appropriate tool for schema reconciliation and produces a reusable artifact (`unified_ads`) that any downstream consumer — Tableau, Looker, dbt models, ad-hoc analysts — can query without redoing the transformation.

---

## 4. Data Setup in BigQuery

### 4.1 Source dataset characteristics

The three CSVs cover an identical time window (January 1–30, 2024) with 110 daily rows each and 4 campaigns per platform. While the temporal alignment is convenient, the schemas diverge meaningfully:

| Concept | Facebook column | Google column | TikTok column |
|---|---|---|---|
| Cost | `spend` | `cost` | `cost` |
| Group level below campaign | `ad_set_id` / `ad_set_name` | `ad_group_id` / `ad_group_name` | `adgroup_id` / `adgroup_name` |
| Revenue | not reported | `conversion_value` | not reported |
| Engagement metric | `engagement_rate`, `reach`, `frequency` | `quality_score`, `search_impression_share` | `likes`, `shares`, `comments`, `video_watch_25/50/75/100` |
| Video metric | `video_views` | not reported | `video_views` plus quartile completion |

The two structural challenges this introduces:

1. Inconsistent column names for semantically identical fields (cost, group hierarchy).
2. Asymmetric metric coverage — most importantly, only Google reports a revenue figure, which has direct implications for which efficiency metrics can be computed cross-channel (see [Section 9](#9-methodological-decisions-and-limitations)).

### 4.2 Loading the CSVs into BigQuery

A new project (`marketing-analyst-assignment`, internal ID `intrepid-fiber-494520-q0`) was created on the BigQuery free sandbox tier. A dataset `marketing_ads` was created in the US multi-region.

Each CSV was uploaded through the BigQuery console using the **Create table** workflow with these settings:

- Source: file upload (CSV)
- Destination: `marketing_ads.<table_name>`
- Schema: auto-detected
- Header rows to skip: 1
- Partitioning and clustering: none (the dataset is too small to benefit from either)

This produced three tables:

- `marketing_ads.facebook_ads` (13 columns, 110 rows)
- `marketing_ads.google_ads` (14 columns, 110 rows)
- `marketing_ads.tiktok_ads` (17 columns, 110 rows)

Auto-detection correctly inferred all field types, including `DATE` for the `date` column — important for downstream Tableau date functions.

### 4.3 SQL unification logic

The full unification script lives at [`sql/01_create_unified_ads.sql`](sql/01_create_unified_ads.sql). Its core structure is a `CREATE OR REPLACE TABLE` statement built from three `SELECT` blocks joined by `UNION ALL`. Each block:

1. Adds a hardcoded `'Facebook'` / `'Google'` / `'TikTok'` literal as the new `platform` column. This is the discriminator that powers every cross-channel filter and grouping in Tableau.
2. Renames divergent columns to a common vocabulary: `spend` becomes `cost`, and the three group-level identifiers all become `group_id` / `group_name`.
3. Casts platform-specific columns that the current platform does not report as `NULL` of the correct type (`CAST(NULL AS FLOAT64)`, `CAST(NULL AS INT64)`).

The third point matters: emitting typed nulls keeps the unified table's column types consistent, which prevents Tableau from inferring a generic STRING type and avoids brittle implicit casts later.

### 4.4 Schema normalization decisions

The unified schema is designed around three principles:

**1. Common columns are renamed to platform-agnostic names.**
This makes the table queryable without conditional logic. `SUM(cost)` works regardless of which platform contributed the row.

**2. Platform-specific columns are preserved, not dropped.**
Engagement metrics like `quality_score` (Google) and `video_watch_100` (TikTok) carry analytical signal even though they are not cross-channel. Rather than discarding them, they live as nullable columns. This trades some schema width for analytical optionality — a worthwhile trade for a 24-column table.

**3. NULL is information, not error.**
A NULL in `conversion_value` for a Facebook row is not missing data — it is an explicit declaration that Facebook does not report this metric in the source. Any downstream metric that depends on `conversion_value` (such as ROAS) is therefore mathematically definable only on Google rows. This constraint is honored throughout the dashboard.

The resulting `unified_ads` table has 24 columns and 330 rows. It is the single source of truth that Tableau consumes.

### 4.5 Validation

Three validation queries (in [`sql/02_validate_unified_ads.sql`](sql/02_validate_unified_ads.sql)) confirm the unification preserves source-level integrity:

**Per-platform totals (Query 1 results):**

| platform | row_count | first_date | last_date | total_cost | total_conversions | total_revenue |
|---|---|---|---|---|---|---|
| TikTok | 110 | 2024-01-01 | 2024-01-30 | 74,266.70 | 6,750 | NULL |
| Google | 110 | 2024-01-01 | 2024-01-30 | 37,686.20 | 4,218 | 210,900.00 |
| Facebook | 110 | 2024-01-01 | 2024-01-30 | 18,292.00 | 2,395 | NULL |

These figures match the totals computed directly against the source CSVs, confirming the `UNION ALL` is lossless. The `NULL` revenue values for Facebook and TikTok confirm the schema design works as intended.

---

## 5. Tableau Connection

### 5.1 BigQuery to Tableau via OAuth

Tableau Desktop connects to BigQuery using its native connector with OAuth 2.0. The connection flow is:

1. Tableau Desktop → **Connect** → **Google BigQuery**
2. Authentication: OAuth (sign in with the same Google account that owns the BigQuery project)
3. Project selection: `marketing-analyst-assignment`
4. Dataset selection: `marketing_ads`
5. Drag the `unified_ads` table — and only that table — into the canvas.

Importantly, the three raw tables (`facebook_ads`, `google_ads`, `tiktok_ads`) are **not** dragged into Tableau. They serve as upstream sources for the unified table; pulling them into Tableau separately would either duplicate rows (if joined incorrectly) or force Tableau to redo work that BigQuery already handles.

### 5.2 Live versus Extract

The connection is configured as an **Extract**, not a Live connection. Three reasons:

1. **Performance.** With only 330 rows, the extract is essentially instantaneous. A live connection would issue BigQuery queries on every interaction, adding latency without benefit.
2. **Cost predictability.** Extracts query BigQuery once per refresh; live mode queries on every dashboard interaction. For a dashboard published to Tableau Public — which has no scheduled refresh capability — extract is the only sensible mode.
3. **Tableau Public requires it.** Tableau Public does not support live connections to external databases. Publishing requires a packaged workbook with embedded data.

The extract is generated once after connection, embedded in the workbook on save (`.twbx` packaging), and refreshes only when manually triggered.

---

## 6. Calculated Fields in Tableau

Six calculated fields were created in Tableau to produce the standard marketing efficiency metrics. These metrics could have been precomputed as columns in BigQuery, but defining them in Tableau preserves the granularity of the underlying data — Tableau can recompute them at any aggregation level (per campaign, per day, per platform) without losing accuracy.

A critical implementation detail: each metric uses the pattern `SUM(numerator) / SUM(denominator)`, never row-level division. This is the difference between a correct weighted aggregate and a misleading average of ratios.

### 6.1 The metrics and their rationale

| Field | Formula | Question it answers |
|---|---|---|
| **CTR** | `SUM([Clicks]) / SUM([Impressions])` | Of the people who saw the ad, what proportion clicked? — measures creative attractiveness. |
| **CPC** | `SUM([Cost]) / SUM([Clicks])` | What does it cost to bring one visitor to the destination? — measures traffic-acquisition efficiency. |
| **CPA** | `SUM([Cost]) / SUM([Conversions])` | What does it cost to acquire one conversion? — the primary cross-channel efficiency benchmark. |
| **CPM** | `(SUM([Cost]) / SUM([Impressions])) * 1000` | What does it cost to deliver 1,000 impressions? — measures pure visibility cost, useful for awareness campaigns. |
| **CVR** | `SUM([Conversions]) / SUM([Clicks])` | Of the people who clicked, what proportion converted? — measures landing-page and offer effectiveness. |
| **ROAS** | `IFNULL(SUM([Conversion Value]), 0) / SUM([Cost])` | For every dollar spent, how many dollars in revenue did the campaign generate? — only computable for Google. |

### 6.2 Why these six and not others

These six are the universally accepted "core six" of paid media measurement. They span the full performance funnel:

- Awareness layer: CPM
- Engagement layer: CTR, CPC
- Conversion layer: CVR, CPA
- Revenue layer: ROAS

Adding more metrics (frequency, reach, viewability, etc.) is feasible but introduces channel-specific definitions that are not directly comparable across Facebook, Google, and TikTok. The six chosen are platform-agnostic in definition, even when the underlying tracking technology differs.

### 6.3 Number formatting

Each metric was assigned an appropriate display format via Default Properties:

- CTR, CVR — Percentage with 2 decimals
- CPC, CPA, CPM — Currency (custom) with `$` prefix and 2 decimals
- ROAS — Number (custom) with 2 decimals and `x` suffix

Consistent formatting across all charts and tables is what makes the dashboard read as one cohesive product rather than a collection of charts.

---

## 7. Dashboard Walkthrough

The dashboard is organized as a one-page executive briefing, with information density increasing from top to bottom: top-line numbers first, then distribution context, then trend analysis, then deep efficiency analysis, then a granular metrics table, then methodological notes.

### 7.1 Layout philosophy

| Region | Purpose | Cognitive load |
|---|---|---|
| Header | Frame the report | Minimal |
| KPI row | Answer "how big is this and how well are we doing?" in 5 seconds | Low |
| Row 2 | Show distribution of investment and time-based behavior | Medium |
| Row 3 | Compare campaign efficiency in two complementary ways | High |
| Metrics table | Provide the granular data for analysts who want to drill deeper | High |
| Footer | Document the methodological caveat about ROAS | Read-on-demand |

A consistent color palette is used across all charts: Facebook in brand blue (`#1877F2`), Google in brand green (`#34A853`), TikTok in brand red (`#FE2C55`). This means platform identity is communicated by color alone, reducing the need for repeated legends.

### 7.2 Widget-by-widget

#### 7.2.1 KPI Cards — top row

Four executive metrics displayed as large-format tiles:

- **Total Spend** — `$130,245`. Sum of `cost` across all three platforms.
- **Total Conversions** — `13,363`. Sum of `conversions` across all three platforms.
- **Avg CPA (Cross-Channel)** — `$9.75`. Total spend divided by total conversions, computed across all platforms.
- **Google ROAS** — `5.60x`. Filtered to Google only because it is the only platform reporting `conversion_value`. This filter is applied at the worksheet level and clearly labeled.

These four numbers answer the executive's first question: how much did we spend, what did we get, how efficient was it, and where is revenue confirmed?

**Interaction:** none — KPI cards are intentionally non-interactive to keep them as stable reference points.

#### 7.2.2 Spend Share by Platform — donut chart

A donut chart showing the percentage and absolute dollar split of total spend across the three platforms. Each slice shows the platform name, percentage of total, and dollar amount.

**Question answered:** How is the budget allocated?

**Interaction:** hover any slice to see the exact figures.

#### 7.2.3 Daily Spend Trend — line chart

A time-series line chart with three lines (one per platform) showing daily spend across the 30-day window. Min and max values per line are labeled to anchor the eye on inflection points.

**Question answered:** How did spend evolve over time? Were campaigns active throughout the period? Are there step-changes that suggest manual interventions?

**Interaction:** hover any point to see the exact daily spend for that platform on that date.

#### 7.2.4 Campaign Efficiency Matrix — scatter plot

The most analytically dense chart on the dashboard. Each of the 12 campaigns is plotted as a circle with:

- X-axis: CPA (lower is better — leftward is more efficient)
- Y-axis: CVR (higher is better — upward is more effective)
- Color: platform
- Size: total spend (larger circle = more invested)
- Reference lines: cross-channel average CPA (vertical) and CVR (horizontal), dividing the plot into four quadrants

The four quadrants have clear interpretations:

| Quadrant | Position | Interpretation |
|---|---|---|
| Upper-left | Low CPA, high CVR | **Stars** — efficient and effective. Candidates for budget increase. |
| Upper-right | High CPA, high CVR | **Premium** — expensive but converting. Possibly necessary for high-value segments. |
| Lower-left | Low CPA, low CVR | **Cheap traffic** — inexpensive but does not convert. Funnel issue. |
| Lower-right | High CPA, low CVR | **Underperformers** — expensive and ineffective. Candidates for pause or rework. |

**Question answered:** Which campaigns deliver the best return per dollar? Which should we double down on, and which should we cut?

**Interaction:** hover any circle to see the campaign name, platform, and exact CPA/CVR/spend.

#### 7.2.5 Top Campaigns by Conversions — horizontal bar chart

A ranking of all 12 campaigns by absolute conversion volume, with each bar colored by platform. Each bar shows its conversion count.

**Question answered:** Which campaigns generate the most volume, regardless of efficiency?

**Tooltip enrichment:** hover any bar to see Campaign Name, Platform, Conversions, Spend, CPA, and CVR. This rich tooltip lets the analyst quickly correlate volume rank with efficiency without leaving the chart.

This chart deliberately complements the Efficiency Matrix. The matrix tells you *how* efficient a campaign is; the ranking tells you *how big* it is. Reading them together avoids the trap of optimizing for efficiency at the cost of scale, or scaling inefficient campaigns.

#### 7.2.6 Cross-Channel Metrics Table — bottom

A platform-by-platform breakdown of all six calculated metrics: CTR, CPC, CPA, CPM, CVR, ROAS. This is the analytical reference layer of the dashboard.

| Platform | CTR | CPC | CPA | CPM | CVR | ROAS |
|---|---|---|---|---|---|---|
| Facebook | 1.96% | $0.21 | $7.64 | $4.03 | 2.69% | 0.00x |
| Google | 1.90% | $0.27 | $8.93 | $5.22 | 3.07% | 5.60x |
| TikTok | 1.61% | $0.16 | $11.00 | $2.59 | 1.46% | 0.00x |

**Question answered:** Side-by-side, which platform performs best on each individual metric?

**Interaction:** none — this is a reference table.

### 7.3 Footer note

Below the dashboard:

> *ROAS available only for Google Ads — the only platform reporting conversion_value. Cross-channel efficiency is benchmarked via CPA. Recommendation: implement Meta Pixel and TikTok Pixel purchase value tracking for full revenue attribution.*

This note is not decorative. It is the dashboard's explicit acknowledgment of its data limitations and a forward-looking recommendation to address them.

---

## 8. Key Findings and Recommendations

### Finding 1 — Budget allocation is inversely correlated with efficiency

TikTok absorbs 57% of the total budget ($74,267) but produces the worst CPA ($11.00) and worst CVR (1.46%). Facebook receives the smallest allocation (14%, $18,292) but produces the best CPA ($7.64) and second-best CVR (2.69%). The current allocation reflects either historical inertia or a strategic bet on awareness (which TikTok's low CPM of $2.59 supports), but it does not reflect conversion-stage efficiency.

**Recommendation:** Reallocate at least 15–20% of TikTok spend to the Facebook and Google campaigns currently sitting in the Stars quadrant of the Efficiency Matrix. Specifically, `Conversions_Retargeting` (Facebook) and `Search_Brand_Terms` (Google) have the lowest CPAs in the entire portfolio and demonstrated capacity to absorb more volume without degrading efficiency.

### Finding 2 — The largest campaign is also one of the least efficient

`Influencer_Collab` (TikTok) is the largest single line item by spend (it is the largest bubble in the Efficiency Matrix) and ranks #1 in absolute conversions, but lives in the underperformer quadrant: high CPA, low CVR. Its scale produces the volume but at the worst per-unit economics in the portfolio.

**Recommendation:** Audit `Influencer_Collab` creative and targeting. The high CPM of TikTok suggests this is a viewability-driven play, but if the goal is conversion, the campaign objective and bidding strategy may be misaligned. A 30-day pause and replatform test (running a comparable budget on Facebook retargeting) would establish whether the volume can be replicated more efficiently elsewhere.

### Finding 3 — A coordinated activation occurred mid-month

All three platforms hit their daily-spend peaks on January 24, simultaneously. Additionally, TikTok shows a clear step-change around January 10, jumping from a $1,800 baseline to a $2,800 daily spend. This pattern is consistent with either a coordinated promotional push or a significant manual intervention in budget pacing.

**Recommendation:** Confirm with the campaign manager whether January 10 and January 24 were intentional pushes. If yes, document the trigger and outcome for institutional memory. If no, investigate whether automated bidding strategies are producing unintended pacing behavior.

### Finding 4 — Google delivers confirmed revenue, the others do not

Google generated $210,900 in tracked revenue against $37,686 in spend (5.60x ROAS), an excellent return. Facebook and TikTok generated revenue too — every conversion implies some downstream economic value — but neither platform's tracking captures it.

**Recommendation:** Implement Meta Pixel `Purchase` event with `value` parameter and TikTok Pixel `CompletePayment` event with `value` parameter. Until these are in place, ROAS comparisons across platforms remain methodologically impossible and the dashboard's cross-channel view is artificially limited to CPA-based efficiency.

---

## 9. Methodological Decisions and Limitations

### 9.1 ROAS is reported only for Google

The most consequential methodological decision in this project. Three alternatives were considered:

| Option | Approach | Outcome |
|---|---|---|
| A | Apply Google's implicit AOV ($210,900 ÷ 4,218 conversions ≈ $50) to Facebook and TikTok conversions to estimate revenue | Rejected — ticket sizes vary significantly by audience and intent. Applying a Google-derived AOV to TikTok GenZ traffic would inflate that platform's apparent revenue and produce a misleading ROAS. |
| B | Compute ROAS as `total_revenue / total_spend` across all three platforms, treating Facebook and TikTok revenue as $0 | Rejected — this artificially penalizes platforms that simply do not report revenue, treating them as if they generated none. |
| C | Report ROAS only where it is directly measurable, document the constraint, and recommend instrumentation to remove it | **Selected** — methodologically honest, treats data limitations as a finding rather than hiding them. |

The selected approach is reflected in the Google ROAS KPI tile (filtered to Google) and the dashboard footer note.

### 9.2 CPA is the cross-channel efficiency metric of record

Because ROAS is not universally available, CPA serves as the comparable efficiency metric across all three platforms. CPA captures the cost side of the funnel (which all platforms report) without requiring revenue attribution. Every cross-channel efficiency claim in this dashboard is grounded in CPA.

### 9.3 Time window

The analysis covers 30 days of data. This is sufficient to identify within-month patterns and rank campaigns relative to each other, but it is too short to:

- Characterize seasonality
- Establish a stable baseline for anomaly detection
- Distinguish creative fatigue from random variance
- Assess the medium-term effect of the January 10 TikTok step-change

Conclusions in this report should be read as a snapshot, not as a long-run characterization.

### 9.4 No attribution model is applied

The conversion counts reported by each platform reflect that platform's own attribution methodology — typically last-click within their own pixel, with various lookback windows. There is no de-duplication across platforms. A user who saw a Facebook ad, then clicked a Google ad, then converted, will be counted by Google. Cross-channel conversion totals therefore have an unknown level of double-counting. A multi-touch attribution model (data-driven or rule-based) would be required to resolve this and is out of scope for this assignment.

### 9.5 Group-level granularity is preserved but not visualized

The unified table preserves `group_id` and `group_name` (the level below campaign — ad sets in Facebook, ad groups in Google, ad groups in TikTok). The dashboard does not currently surface this granularity. Users who want to drill below the campaign level can do so via the underlying data source in Tableau.

---

## 10. Future Work

Concrete next steps that would extend this analysis if more time and access were available:

1. **Implement Pixel revenue tracking.** Highest-priority gap. Without `purchase_value` from Meta and TikTok Pixels, cross-channel ROAS remains unmeasurable.

2. **Add a multi-touch attribution layer.** Fold platform conversions into a single attribution model (e.g., position-based or data-driven) to resolve cross-channel double-counting.

3. **Extend the time window.** Repeat the analysis on 90 days of data to characterize seasonality and stabilize campaign-level CPA estimates.

4. **Productionize the pipeline.** The current SQL is run manually. Wrapping the unification logic in a scheduled tool (Airflow, dbt, BigQuery scheduled queries) would enable daily refresh of the dashboard against new data.

5. **Add anomaly detection.** With more historical data, statistical control limits (mean ± 2σ on daily spend or daily CPA) could flag unusual days automatically and feed an alerting layer.

6. **Drill-down dashboards.** A second-page dashboard at the campaign level, with creative-level breakouts where available, would let campaign managers act on the dashboard's recommendations.

7. **Cohort analysis on conversion lag.** Many conversions on day N originate from impressions on day N–k. A lag-aware view would refine attribution for short-window campaigns.

---

## 11. How to Reproduce

To recreate the analysis from this repository:

### Prerequisites

- A Google Cloud account with BigQuery enabled (sandbox tier is sufficient — no billing required)
- Tableau Desktop or Tableau Public Desktop (the latter is free)

### Steps

1. Clone this repository.

2. Create a BigQuery project and a dataset called `marketing_ads` in any region.

3. Upload the three CSVs from `data/` into the `marketing_ads` dataset, naming the tables `facebook_ads`, `google_ads`, and `tiktok_ads`. Use auto-detect schema and skip 1 header row.

4. In the BigQuery SQL editor, open `sql/01_create_unified_ads.sql`. Replace the project ID `intrepid-fiber-494520-q0` with your own project ID (three occurrences in the source `FROM` clauses, plus one in the `CREATE OR REPLACE TABLE` target). Execute the query.

5. Run `sql/02_validate_unified_ads.sql` to confirm the unification produced the expected totals.

6. In Tableau, connect to BigQuery via OAuth, navigate to your project and the `marketing_ads` dataset, and drag `unified_ads` into the canvas. Switch the connection to Extract.

7. Recreate the six calculated fields described in [Section 6](#6-calculated-fields-in-tableau).

8. Build the worksheets and assemble them into the dashboard following the structure in [Section 7](#7-dashboard-walkthrough).

9. Publish to Tableau Public via **File → Save to Tableau Public As…** (Tableau Public Desktop only — Tableau Desktop Professional cannot publish to Tableau Public directly).
