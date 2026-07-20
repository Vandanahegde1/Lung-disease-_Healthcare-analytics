# Lung Disease Patient Analysis — SQL & Power BI

## Why I built this

I wanted a project that went a step beyond just building charts on top of clean data. So instead of starting with a tidy dataset, I picked one that was genuinely messy around 6% missing values scattered across every column, 91 exact duplicate rows, and no patient ID to begin with  and walked it through a real pipeline: clean it, model it, query it, and finally visualize it.

The dataset covers 5,200 patients across five respiratory conditions (Asthma, Bronchitis, COPD, Lung Cancer, Pneumonia), with fields on age, gender, smoking status, lung capacity, treatment type, hospital visits, and recovery outcome.

## Tools used

- **Power Query (Power BI)** — data cleaning
- **PostgreSQL** — schema design and analysis queries
- **Power BI** — dashboard and DAX measures

## Data cleaning

This dataset didn't come pre-cleaned, so a good chunk of the work happened before a single chart got built.

- **Removed 91 exact duplicate rows** — found by comparing all 8 columns together, since there was no patient ID to check against. With no single field matching by chance across 8 columns, these were confidently treated as true duplicates.
- **Handled missing values deliberately, not uniformly.** Each column had roughly 300 missing values (about 5.7%), but I didn't treat them all the same way:
  - `Age`, `Lung Capacity`, and `Hospital Visits` were filled with the **median** of each column — a safer choice than the mean since it isn't pulled around by outliers, and a far better choice than deleting the row outright, which would have thrown away seven other perfectly good fields just because one was blank.
  - `Gender`, `Smoking Status`, `Disease Type`, and `Treatment Type` were filled with **"Unknown"** or **"Not Recorded"** rather than guessing a value — there's no fair way to impute a categorical field like gender or disease type.
  - `Recovered` (the outcome column) was **never imputed**. Guessing a patient's actual recovery status would have quietly corrupted the one metric the whole analysis revolves around. Instead, these rows were labeled "Unknown" and explicitly excluded from every recovery rate calculation — see the note on this below.
- Added a **Patient_ID** index column afterward, since the raw data didn't include one and every table benefits from a stable primary key.

**Final cleaned dataset: 5,109 rows.**

## The SQL analysis

I structured 12 questions across three tiers, going from basic aggregation up to window functions and CTEs — partly to actually answer interesting questions about the data, and partly to show a range of SQL skills in one place rather than just a flat list of SELECT statements.

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
12. Comparing recovery rate with and without the "Unknown" outcome rows included

All queries live in the `/sql` folder, split by tier.

## Key findings

- **Overall recovery rate: 50.84%**, calculated only across patients with a recorded outcome (Yes/No) — the "Unknown" rows are deliberately excluded from this figure, not treated as failures or successes.
- **COPD had the highest recovery rate (53.72%)**, while **Bronchitis had the lowest (47.75%)** — a modest but consistent gap across the five conditions.
- **5.87% of patients had no recorded recovery outcome at all.** This isn't just a data-cleaning footnote — it's a real finding in itself, since it shows how much of the picture is missing before any recovery rate can be trusted. The dashboard surfaces this number directly rather than burying it.
- **Treatment effectiveness varies noticeably by disease.** COPD patients with an unrecorded treatment type showed a surprisingly high 68% recovery rate — likely a data quality artifact worth flagging rather than a genuine treatment effect, since "no recorded treatment" isn't really a treatment at all.
- **Recovery rate trends upward with age**, rising from the 20-40 group toward the 80+ group — worth noting as a pattern rather than a causal claim, since this dataset doesn't capture severity at diagnosis.

## The dashboard

Two pages, kept intentionally focused rather than padded out:

**Page 1 — Patient Overview**: KPI summary (total patients, recovery rate, avg lung capacity, avg hospital visits), recovery rate by disease type, disease type distribution, and smoking status breakdown by disease — with slicers for gender, smoking status, and age group.

**Page 2 — Clinical Deep-Dive**: a recovery rate matrix (treatment type × disease type) with conditional-formatting heatmap shading to make the strongest and weakest combinations visible at a glance, lung capacity by age group and disease type, recovery rate by age group, and a callout on the missing-outcome data.

## A note on methodology

The biggest judgment call in this project wasn't a chart choice — it was deciding how to handle the ~300 rows missing a recovery outcome. It would have been easy to just impute "No" for all of them and move on, but that would have quietly built a false narrative into every recovery number downstream. Flagging them as "Unknown" and showing that percentage on the dashboard felt like the more honest choice, even though it meant one less complete-looking metric.
