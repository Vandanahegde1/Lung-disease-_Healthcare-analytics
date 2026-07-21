# Lung Disease Patient Analysis — SQL & Power BI

## Business Problem
Respiratory disease outcomes vary across patient demographics, treatment types, and lifestyle factors, and hospital administrators or clinical teams often need a clear picture of where recovery rates are strongest and weakest to prioritize resources and treatment protocols. This analysis identifies which disease types, treatment approaches, and patient groups have the best and worst recovery outcomes, and flags where data quality issues (like missing outcomes) could be distorting the picture — enabling more informed clinical and operational decisions.

This project also intentionally started from a messy, unclean dataset rather than a tidy one, to demonstrate a full real-world pipeline: clean it, model it, query it, and visualize it.

## Dataset
- **Source:** Kaggle
- **Size:** 5,200 raw patient records → 5,109 rows after cleaning
- **Conditions covered:** Asthma, Bronchitis, COPD, Lung Cancer, Pneumonia
- **Key variables:** age, gender, smoking status, lung capacity, disease type, treatment type, hospital visits, recovery outcome

## Tools & Technologies
- **Power Query (Power BI)** — data cleaning
- **PostgreSQL** — schema design and SQL analysis
- **Power BI** — dashboard and DAX measures

## Data Cleaning
The raw dataset had no patient ID, roughly 6% missing values scattered across every column, and 91 exact duplicate rows. Cleaning decisions were made deliberately rather than uniformly:

- **Removed 91 exact duplicate rows**, identified by matching across all 8 columns (there was no ID to check against).
- **Numeric fields** (`Age`, `Lung Capacity`, `Hospital Visits`) — missing values (~5.7% per column) filled with the **median**, which resists outliers better than the mean and avoids discarding otherwise-complete rows.
- **Categorical fields** (`Gender`, `Smoking Status`, `Disease Type`, `Treatment Type`) — missing values filled with  **"Not Recorded"** rather than guessed, since there's no fair way to impute a category.
- **`Recovered` (the outcome column)** — **never imputed.** Guessing recovery status would corrupt the core metric of the whole analysis. These rows were labeled "Unknown" and excluded from every recovery rate calculation.
- Added a **Patient_ID** index column post-cleaning to serve as a stable primary key.

**Final cleaned dataset: 5,109 rows.**

## Key Questions Answered
The SQL analysis was structured across three tiers, from basic aggregation to window functions and CTEs:

**Tier 1 — Foundational**
1. Overall recovery rate across all patients
2. Recovery rate by disease type
3. Average lung capacity by disease type
4. Smoking status distribution by disease type

**Tier 2 — Intermediate**
5. Disease type with the highest average hospital visits, and whether that tracks with recovery rate
6. Recovery rate by treatment type within each disease type
7. Recovery rate by age group
8. Smoker vs. non-smoker recovery rate, controlling for disease type

**Tier 3 — Advanced**
9. Ranking diseases by recovery rate (most to least treatable), using window functions
10. Top 3 age groups by hospital visit volume within each disease type, using a CTE
11. Running/cumulative average of lung capacity ordered by age
12. Comparing recovery rate with and without "Unknown" outcome rows included

All queries live in the `/sql` folder, split by tier.

## Key Findings
- **Overall recovery rate: 50.84%**, calculated only across patients with a recorded outcome (Yes/No) — "Unknown" rows are deliberately excluded, not treated as failures.
- **COPD has the highest recovery rate (53.72%)**; **Bronchitis has the lowest (47.75%)** — a modest but consistent gap across the five conditions.
- **5.87% of patients have no recorded recovery outcome at all** — a real finding in itself, since it shows how much of the picture is missing before any recovery rate can be trusted.
- **Treatment effectiveness varies noticeably by disease.** COPD patients with an unrecorded treatment type show a surprisingly high 68% recovery rate — likely a data quality artifact rather than a genuine treatment effect, since "no recorded treatment" isn't a treatment at all.
- **Recovery rate trends upward with age**, rising from the 20–40 group toward the 80+ group — noted as a pattern, not a causal claim, since the dataset doesn't capture severity at diagnosis.

## Business Recommendations
1. **Investigate Bronchitis treatment protocols** — its recovery rate lags the other four conditions by 3–6 points; a closer review of treatment mix and hospital visit patterns for this group could surface actionable gaps.
2. **Improve outcome-recording compliance.** Nearly 6% of patients have no recorded recovery status; tightening this at the point of data entry would materially strengthen the reliability of every downstream recovery metric.
3. **Flag the COPD/unrecorded-treatment anomaly for data quality review** before treating it as a clinical signal — a 68% recovery rate tied to "no treatment recorded" is far more likely a charting/documentation gap than a real effect.

## Dashboard / Visualisations
Two pages, kept intentionally focused:

**Page 1 — Patient Overview**: KPI summary (total patients, recovery rate, avg lung capacity, avg hospital visits), recovery rate by disease type, disease type distribution, and smoking status breakdown by disease — with slicers for gender, smoking status, and age group.

**Page 2 — Clinical Deep-Dive**: recovery rate matrix (treatment type × disease type) with conditional-formatting heatmap shading, lung capacity by age group and disease type, recovery rate by age group, and a callout on missing-outcome data.

[Screenshot or link to live Power BI dashboard]

## A Note on Methodology
The biggest judgment call in this project wasn't a chart choice — it was deciding how to handle the ~300 rows missing a recovery outcome. Imputing "No" for all of them would have been easy but would have quietly built a false narrative into every recovery number downstream. Flagging them as "Unknown" and surfacing that percentage directly on the dashboard was the more honest choice, even at the cost of one less complete-looking metric.
