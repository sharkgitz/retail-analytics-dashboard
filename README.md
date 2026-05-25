# Retail Analytics Dashboard

I picked this dataset because I wanted to practice working with messy, real-world transaction data rather than pre-cleaned tutorial datasets. The UCI Online Retail II dataset covers about two years of wholesale transactions from a UK-based online retailer — the kind of data that actually has missing customer IDs, inconsistent date formats across export batches, and return transactions mixed in with normal orders as negative quantities rather than flagged separately.

The question I started with was: why do some product categories show inconsistent revenue even during months when overall transaction volume is high? I'd seen this pattern described in BI courses but never actually traced it through raw transaction data to a concrete explanation.

I framed the analysis through a MENA distribution lens — specifically the questions a UAE-based regional distributor would ask about a European supplier: which products have strong demand signals in which markets, what the seasonal patterns look like, and which customer accounts show signs of disengaging. This isn't because the data is from UAE, but because those business questions transfer directly, and it's the context I was trying to build intuition for.

What surprised me most was the revenue concentration. I expected a long tail of products contributing roughly equally. What I found was that the top 50 products (out of roughly 4,000 distinct SKUs) account for about 38% of total gross revenue — and the top 200 cover nearly 70%. That's not unusual for retail in theory, but seeing it in actual numbers is different from reading about the Pareto principle. It also changes the procurement conversation: if you're a distributor, you're really managing a core list of 50–100 SKUs and everything else is secondary.

One thing that didn't work the way I expected: I initially tried to segment by invoice date to track customer seasonality, but found the date formatting was inconsistent across batches — some records parsed differently depending on which of the two Excel sheets they came from in the original download. I spent longer than I'd like to admit on that before standardising everything with `pd.to_datetime(df['InvoiceDate'], dayfirst=False)`. There's a note about it in the notebook where it happened.

---

**Tools used:** Python (pandas, openpyxl, matplotlib, seaborn), SQL (BigQuery dialect), Excel via openpyxl, Looker Studio

**Data source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) — 1M+ transactions, December 2009 to December 2011

**To run this project:**

1. Download the dataset from the UCI link above. You'll get a ZIP containing `online_retail_II.xlsx`. Place it in `data/raw/` — the notebook reads both `.xlsx` and `.csv`.

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Open and run `notebooks/eda.ipynb` end-to-end. It handles cleaning and saves the output to `data/cleaned/retail_cleaned.csv`.

4. Generate the Excel workbook:
   ```bash
   python excel/excel_builder.py
   ```
   This creates `excel/retail_analysis.xlsx` with four sheets and conditional formatting.

5. The SQL files in `/sql` are written for BigQuery. Load `data/cleaned/retail_cleaned.csv` into a BigQuery table called `retail.transactions` before running them. The Looker Studio config in `/looker_studio/dashboard_config.md` assumes this table name.

**What I'd do differently:** I'd spend more time cleaning the `StockCode` column. There are system-level codes like `POST`, `D`, `M`, and `BANK CHARGES` mixed in with real product codes — I filtered them out but didn't dig into whether they carry any business signal. Some of them might.
