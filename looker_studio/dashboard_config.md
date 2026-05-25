# Looker Studio Dashboard Configuration

This document is detailed enough that someone can rebuild the dashboard from scratch without referencing any other file in this repo.

---

## Data Source

- **Source type:** BigQuery
- **Project:** your-gcp-project-id
- **Dataset:** `retail`
- **Table:** `transactions`
- **Credentials:** Use a service account with BigQuery Data Viewer role
- **Schema:** See `data/data_dictionary.md` for full column descriptions

Load the cleaned CSV to BigQuery first:
```bash
bq load --autodetect --source_format=CSV retail.transactions data/cleaned/retail_cleaned.csv
```

---

## Dashboard Pages

### Page 1: Executive Summary

**Purpose:** One-screen overview for a manager who wants to see whether this month is up or down.

**Charts to build:**

1. **Scorecard — Total Revenue (YTD)**
   - Metric: `SUM(Revenue)`
   - Filter: `Is_Return = false`, `Price > 0`
   - Comparison period: Previous year same period
   - Format: GBP currency, 0 decimal places

2. **Scorecard — Active Customers (MTD)**
   - Metric: `COUNT_DISTINCT(Customer_ID)`
   - Filter: `Customer_ID IS NOT NULL`
   - Comparison period: Previous month

3. **Scorecard — Average Order Value**
   - Metric: Calculated field: `SUM(Invoice_Total) / COUNT_DISTINCT(Invoice)`
   - Filter: `Quantity > 0`

4. **Line Chart — Monthly Revenue Trend**
   - Dimension: `YearMonth`
   - Metric: `SUM(Revenue)`
   - Filter: `Is_Return = false`, `Price > 0`
   - Sort: YearMonth ascending
   - Date range: Full dataset (Dec 2009 – Dec 2011)
   - Style: Single line, dots at data points, reference line at dataset average

5. **Bar Chart — Revenue by Country (Top 10)**
   - Dimension: `Country`
   - Metric: `SUM(Revenue)`
   - Filter: `Country != 'Unspecified'`, `Quantity > 0`
   - Sort: Descending by revenue
   - Limit: 10 rows
   - Note: UK will dominate (~84%) — consider a separate chart excluding UK to show non-UK market distribution clearly

6. **Date Range Control** (top-right of page)
   - Field: `InvoiceDate`
   - Default: Full dataset range
   - Applied to: All charts on this page

---

### Page 2: Product Performance

**Purpose:** Procurement and category managers — which products to reorder, which to phase out.

**Charts to build:**

1. **Table — Top 20 Products by Revenue**
   - Dimensions: `StockCode`, `Description`
   - Metrics: `SUM(Revenue)`, `SUM(Quantity)`, `COUNT_DISTINCT(Invoice)`
   - Filter: `Quantity > 0`, `Price > 0`
   - Sort: SUM(Revenue) descending
   - Add bar sparkline to Revenue column
   - Conditional formatting: highlight top 5 rows in light green

2. **Bar Chart — Revenue by Product (Top 20)**
   - Dimension: `Description`
   - Metric: `SUM(Revenue)`
   - Filter: `Quantity > 0`
   - Sort: Descending
   - Limit: 20
   - Orientation: Horizontal (easier to read product names)

3. **Pie Chart — Revenue Share: Top 10 vs. Rest**
   - Calculated field: `IF(Revenue_Rank <= 10, Description, 'All Other Products')`
   - Note: Create Revenue_Rank as a calculated field using RANK() or use a blended source
   - This visually communicates product concentration — a key finding

4. **Scatter Plot — Units Sold vs. Revenue per Product**
   - X-axis: `SUM(Quantity)` 
   - Y-axis: `SUM(Revenue)`
   - Dimension: `Description`
   - Filter: Top 100 products by revenue
   - This reveals high-volume/low-margin vs. low-volume/high-margin products

**Filters on this page:**
- Country dropdown (multi-select)
- Date range control

---

### Page 3: Returns & Quality

**Purpose:** Operations team tracking return patterns — seasonal vs. structural issues.

**Charts to build:**

1. **Line Chart — Monthly Return Rate (%)**
   - Metric: Calculated field: `SUM(IF(Is_Return = true, ABS(Revenue), 0)) / SUM(IF(Is_Return = false, Revenue, 0)) * 100`
   - Dimension: `YearMonth`
   - Style: Area chart, filled, threshold line at 8% in red
   - Date range: Full period

2. **Table — Return Rate by Country**
   - Dimensions: `Country`
   - Metrics: Gross Sales, Return Value, Return Rate %
   - Sort: Return Rate % descending
   - Filter: `Country != 'Unspecified'`, gross sales > £1,000 (to exclude tiny markets)

3. **Bar Chart — Monthly Returns vs. Gross Sales**
   - Dimension: `YearMonth`
   - Metric 1: `SUM(IF(Quantity > 0, Revenue, 0))` labelled "Gross Sales"
   - Metric 2: `SUM(IF(Quantity < 0, ABS(Revenue), 0))` labelled "Returns"
   - Chart type: Stacked bar
   - This makes the Jan-Feb return spike visually obvious

**Filters on this page:**
- Date range control
- Country dropdown

---

### Page 4: Customer Analysis

**Purpose:** Sales team — who to prioritise for retention and growth outreach.

**Charts to build:**

1. **Table — Customer Segments**
   - Dimensions: `Customer_Segment` (from BigQuery view or calculated field)
   - Metrics: Count of customers, Total Revenue, Average Order Value, Average Orders per Customer
   - Filter: `Customer_ID IS NOT NULL`

2. **Bar Chart — Revenue by Customer Segment**
   - Dimension: `Customer_Segment`
   - Metric: `SUM(Revenue)`

3. **Table — Inactive Customers (Churn Signal)**
   - Based on a separate BigQuery view: customers in `buyers_2010` not in `buyers_2011`
   - Columns: Customer_ID, Country, Last Order Date, Total Spend 2010
   - Sort: Total Spend descending
   - Limit: 100 rows (the full list can be exported via BQ directly)

4. **Geo Map — Revenue by Country**
   - Dimension: `Country`
   - Metric: `SUM(Revenue)`
   - Filter: `Country != 'Unspecified'`
   - Color scale: light to dark blue

---

## Dashboard-Level Settings

- **Theme:** Clean/minimal — white background, dark grey text, GBP currency formatting throughout
- **Locale:** United Kingdom (for £ symbol and DD/MM/YYYY date formatting)
- **Default date range:** 2009-12-01 to 2011-12-31 (full dataset)
- **Canvas size:** 1280 × 900px (desktop standard)

---

## Screenshot

> **[Add dashboard screenshot here]**
>
> Once the dashboard is built in Looker Studio, export a full-page screenshot and save it as `looker_studio/dashboard_screenshot.png`. Embed in README.md with:
> ```markdown
> ![Dashboard Screenshot](looker_studio/dashboard_screenshot.png)
> ```
