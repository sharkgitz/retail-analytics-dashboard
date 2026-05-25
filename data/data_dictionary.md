# Data Dictionary — Retail Analytics Dashboard

Source: UCI Online Retail II Dataset (December 2009 – December 2011)  
Table name in BigQuery: `retail.transactions`

---

## Original Columns

| Column | Type | Description |
|--------|------|-------------|
| `Invoice` | STRING | 6-digit invoice number identifying a single transaction. Invoices starting with `C` (e.g. `C536379`) indicate a cancellation or return — the corresponding Quantity will be negative. |
| `StockCode` | STRING | 5-digit product code. Numeric codes represent real products. Non-numeric codes (`POST`, `D`, `M`, `BANK CHARGES`, `DOT`, `PADS`) are system entries for postage, discounts, and manual adjustments — these are filtered out in the cleaned dataset. |
| `Description` | STRING | Free-text product name. Can be null (~3,900 records in the raw data). Occasionally inconsistent casing or typos across batches — treated as informational only, not used for category grouping. |
| `Quantity` | INTEGER | Units per transaction line. **Negative values indicate returns or cancellations** — they are not flagged separately. A transaction with Quantity = -12 means 12 units were returned on that invoice. |
| `InvoiceDate` | DATETIME | Transaction date and time. Originally stored as mixed-format strings in the source Excel file (two sheets, each with slightly different parsing behaviour). Standardised to ISO datetime during cleaning. |
| `Price` | FLOAT | Unit price in GBP (£). Rows with `Price <= 0` in the raw data represent samples, manual adjustments, or data entry errors — excluded from all revenue calculations. |
| `Customer ID` | FLOAT (raw) / STRING (cleaned) | Unique 5-digit customer identifier. **Approximately 24.9% of records have no Customer ID** — these are guest/unregistered purchases. Any query requiring customer-level tracking (segments, churn) excludes these. See note below on the handling decision. |
| `Country` | STRING | Country from which the order was placed. United Kingdom accounts for ~84% of all transactions. About 400 records have `Country = 'Unspecified'` — excluded from geographic analysis. |

---

## Derived Columns (added during cleaning)

| Column | Type | How it's calculated | Why it was added |
|--------|------|---------------------|-----------------|
| `Revenue` | FLOAT | `Quantity * Price` | Core metric for all revenue analysis. Negative for return transactions. Used in every SQL query and the Excel pivot sheets. |
| `Is_Return` | BOOLEAN | `True` when `Quantity < 0` | Cleaner filter than relying on the 'C' invoice prefix, which isn't consistently applied in edge cases. |
| `YearMonth` | STRING | `InvoiceDate` formatted as `YYYY-MM` | Aggregation key for monthly trend analysis. Avoids ambiguity between year-level and quarter-level grouping. |
| `Invoice_Total` | FLOAT | Sum of `Revenue` across all lines on the same `Invoice` | Used for order-size bucketing in `order_size_distribution.sql`. Computed at invoice level, not line level. |
| `Customer_Tier` | STRING | Segment label based on purchase frequency and total spend vs. dataset median | Derived in `customer_segments.sql`. Four values: `High Frequency, High Value`, `High Frequency, Low Value`, `Occasional, High Value`, `Low Frequency, Low Value`. |

---

## Note on Missing Customer IDs

Of the ~1.07 million rows in the raw dataset, approximately 135,080 have no `Customer ID`. The decision in this project was to **retain these rows for product and revenue analysis but exclude them from any customer-level analysis** (segmentation, churn detection, repeat purchase rates).

Dropping them entirely would have understated gross revenue figures. Imputing them would have been meaningless — a guest checkout in 2009 has no connection to a guest checkout in 2011. The `Is_Return` and `Revenue` columns are still valid for these rows.

---

## System Stock Codes (excluded from cleaned data)

| StockCode | Meaning |
|-----------|---------|
| `POST` | Postage charge |
| `D` | Discount applied manually |
| `M` | Manual transaction entry |
| `BANK CHARGES` | Bank fee |
| `DOT` | Dotcom fee or adjustment |
| `PADS` | Pads — unclear, excluded as likely system entry |
| `C2` | Carriage charge |
