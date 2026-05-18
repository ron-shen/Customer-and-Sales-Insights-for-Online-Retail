# Retail Sales Analytics Project

End-to-end retail analytics project using SQL and Power BI. The project turns transactional e-commerce data into a relational sales model, reusable reporting views, and an interactive Power BI report for understanding revenue, returns, customers, products, and geography.

## Goal

The goal was to analyze historical online retail transactions for a UK-based non-store retailer and build a dashboard-ready analytics layer that answers:

- How are gross sales, returns, and net sales trending over time?
- Which markets, countries, and products contribute the most revenue?
- How much revenue is lost to cancellations and returns?
- Which customers are one-time buyers, repeat buyers, or high-value RFM segments?
- What does customer retention look like by purchase cohort?

## Data Source

Dataset: [Online Retail II - UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii)

Citation: Chen, D. (2012). *Online Retail II* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5CG6D

The original UCI dataset contains two years of transactions for a UK-based online retail business from 2009-12-01 to 2011-12-09. It includes invoice number, stock code, product description, quantity, invoice date, unit price, customer ID, and country.

This repository uses a cleaned analysis file derived from the UCI workbook:

- `dataset/online_retail_II.xlsx`
- `dataset/online_retail_II_combined.csv`
- `dataset/online_retail_II_combined_cleaned.csv`

## What I Did

- Prepared a cleaned transaction file for analysis.
- Designed a normalized MySQL schema with customers, products, invoices, and invoice lines.
- Loaded the cleaned retail data into the relational model.
- Handled repeated customer-country and product-description values by selecting canonical values with SQL window functions.
- Built SQL analysis queries for:
  - monthly sales trends and seasonality
  - UK vs rest-of-world performance
  - top products by net revenue and return rate
  - repeat vs one-time customer analysis
  - RFM customer segmentation
  - cohort retention
  - cancellation, duplicate-line, odd-code, and missingness checks
- Created Power BI reporting views for dashboard consumption.
- Built a Power BI report with pages for executive performance, customer insights, product/geography analysis, and returns/risk.

## Project Structure

```text
dataset/
  online_retail_II.xlsx
  online_retail_II_combined.csv
  online_retail_II_combined_cleaned.csv

sql/
  01_schema.sql
  02_load_from_online_retail.sql
  03_analysis_queries.sql
  04_reporting_views.sql

powerbi/
  06_powerbi_theme.json
  06_powerbi_layout_template.md

Database ER diagram (crow's foot).pdf
report.pbix
```

## Result

Using `dataset/online_retail_II_combined_cleaned.csv`, the analysis covers 811,893 cleaned transaction rows from 2009-12-01 to 2011-12-04.

Key results:

- 44,278 invoices, 5,924 customers, 4,645 product codes, and 41 countries analyzed.
- Gross sales: GBP 17.32M.
- Return value: GBP 0.92M.
- Net sales: GBP 16.40M.
- Return rate: 5.32% of gross sales.
- Average order value: GBP 475.14.
- United Kingdom net sales: GBP 13.60M.
- Rest-of-world net sales: GBP 2.80M.
- Repeat customers: 4,221.
- One-time customers: 1,642.
- Repeat customer rate: 71.99%.
- Highest net sales month: 2010-11, with GBP 1.13M in net sales.
- Top product by net revenue: `22423` - `REGENCY CAKESTAND 3 TIER`, with GBP 265.85K in net revenue.

The final deliverable is `report.pbix`, supported by SQL reporting views that can be refreshed from the relational model.

## How To Reproduce

1. Load `dataset/online_retail_II_combined_cleaned.csv` into a staging table named `ecommerce.online_retail`.
2. Run `sql/01_schema.sql` to create the normalized `retail_sales` database.
3. Run `sql/02_load_from_online_retail.sql` to populate the normalized tables.
4. Run `sql/04_reporting_views.sql` to create the Power BI reporting views.
5. Open `report.pbix` and connect or refresh against the reporting views.

## Dashboard Pages

The Power BI report is organized into four pages:

- Executive Overview: headline KPIs, monthly revenue, return trends, country performance, and market split.
- Customer Insights: repeat vs one-time customers, RFM segments, customer value, and cohort retention.
- Product And Geography: top products, country comparison, product return rates, and product detail.
- Returns And Risk: cancellation trends, high-return products, negative quantities, odd stock codes, and anomaly checks.
