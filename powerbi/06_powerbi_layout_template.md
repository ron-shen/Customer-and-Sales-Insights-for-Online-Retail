# Power BI Layout Template

This file turns [05_powerbi_page_plan.md](/D:/E-commerce/05_powerbi_page_plan.md) into a concrete layout template you can mirror inside Power BI.

Companion theme file:

- [06_powerbi_theme.json](/D:/E-commerce/powerbi/06_powerbi_theme.json)

## Canvas Setup

- Page size: `16:9`
- Custom canvas: `1366 x 768`
- Outer margin: `24 px`
- Gutter between visuals: `16 px`
- Top header band: `48 px`
- KPI card height: `92 px`
- Standard visual background: white
- Standard visual border: `#D9D0C2`
- Page background: `#F6F2E8`

## Global Build Rules

- Put the page title in the top-left.
- Keep no more than 3 slicers in the header row.
- Use KPI cards only for headline metrics.
- Use one dominant visual per page and 2 to 4 supporting visuals.
- Keep detail tables on the lower half of a page.
- Use the same left-to-right reading order on every page:
  - summary
  - trend/comparison
  - detail/explanation

## Color Roles

- Primary positive: `#1F5A45`
- Secondary accent: `#D1A84A`
- Negative / returns: `#B6493A`
- Neutral dark: `#1E2429`
- Neutral border: `#D9D0C2`
- Warm background: `#F6F2E8`

## Page 1: Executive Overview

### Wireframe

```text
+----------------------------------------------------------------------------------------------------------------------+
| Executive Overview                                             [Year] [Month] [Country]                           |
|                                                                                                                      |
| [Net Sales] [Gross Sales] [Return Value] [Return Rate] [Completed Inv.] [Avg Order Value]                         |
|                                                                                                                      |
| [Monthly Revenue Trend.................................................] [Top Countries............................] |
|                                                                                                                      |
| [Monthly Return Pattern................................................] [UK vs RoW] [Insight Notes..............] |
+----------------------------------------------------------------------------------------------------------------------+
```

### Slot Map

| Slot ID | Visual | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| `P1_Title` | Text box | 24 | 16 | 760 | 36 |
| `P1_Slicer_Year` | Slicer | 920 | 16 | 120 | 36 |
| `P1_Slicer_Month` | Slicer | 1056 | 16 | 120 | 36 |
| `P1_Slicer_Country` | Slicer | 1192 | 16 | 150 | 36 |
| `P1_KPI_01` | Card | 24 | 80 | 206 | 92 |
| `P1_KPI_02` | Card | 246 | 80 | 206 | 92 |
| `P1_KPI_03` | Card | 468 | 80 | 206 | 92 |
| `P1_KPI_04` | Card | 690 | 80 | 206 | 92 |
| `P1_KPI_05` | Card | 912 | 80 | 206 | 92 |
| `P1_KPI_06` | Card | 1134 | 80 | 206 | 92 |
| `P1_Trend_Main` | Line chart | 24 | 200 | 820 | 252 |
| `P1_Country_Bar` | Bar chart | 860 | 200 | 482 | 252 |
| `P1_Return_Trend` | Combo or line chart | 24 | 468 | 820 | 236 |
| `P1_Market_Share` | Donut or stacked bar | 860 | 468 | 220 | 236 |
| `P1_Insights` | Text box | 1096 | 468 | 246 | 236 |

### Visual Assignment

- `P1_KPI_01`: `Net Sales`
- `P1_KPI_02`: `Gross Sales`
- `P1_KPI_03`: `Return Value`
- `P1_KPI_04`: `Return Rate`
- `P1_KPI_05`: `Completed Invoices`
- `P1_KPI_06`: `Average Order Value`
- `P1_Trend_Main`: `vw_monthly_sales_trend`
- `P1_Country_Bar`: `vw_sales_line_enriched[invoice_country]` + `Net Sales`
- `P1_Return_Trend`: `vw_monthly_sales_trend`
- `P1_Market_Share`: `vw_market_performance`
- `P1_Insights`: 3 short business takeaways

## Page 2: Customer Insights

### Wireframe

```text
+----------------------------------------------------------------------------------------------------------------------+
| Customer Insights                                               [Country] [RFM Segment]                           |
|                                                                                                                      |
| [Repeat Cust.] [One-time Cust.] [Repeat Rate] [Avg CLV] [Champions]                                                |
|                                                                                                                      |
| [Repeat vs One-time.................] [RFM Segment Distribution....................] [RFM Value Contribution......] |
|                                                                                                                      |
| [Cohort Retention Matrix..........................................................] [Customer Detail Table........] |
+----------------------------------------------------------------------------------------------------------------------+
```

### Slot Map

| Slot ID | Visual | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| `P2_Title` | Text box | 24 | 16 | 820 | 36 |
| `P2_Slicer_Country` | Slicer | 1038 | 16 | 150 | 36 |
| `P2_Slicer_RFM` | Slicer | 1204 | 16 | 138 | 36 |
| `P2_KPI_01` | Card | 24 | 80 | 252 | 92 |
| `P2_KPI_02` | Card | 292 | 80 | 252 | 92 |
| `P2_KPI_03` | Card | 560 | 80 | 252 | 92 |
| `P2_KPI_04` | Card | 828 | 80 | 252 | 92 |
| `P2_KPI_05` | Card | 1096 | 80 | 246 | 92 |
| `P2_Repeat_Donut` | Donut chart | 24 | 200 | 300 | 220 |
| `P2_RFM_Bar` | Bar chart | 340 | 200 | 500 | 220 |
| `P2_RFM_Treemap` | Treemap | 856 | 200 | 486 | 220 |
| `P2_Cohort_Matrix` | Matrix | 24 | 436 | 820 | 268 |
| `P2_Customer_Table` | Table | 860 | 436 | 482 | 268 |

### Visual Assignment

- `P2_KPI_01`: `Repeat Customers`
- `P2_KPI_02`: `One-time Customers`
- `P2_KPI_03`: `Repeat Customer Rate`
- `P2_KPI_04`: `Average Customer Lifetime Value`
- `P2_KPI_05`: `Champions Customers`
- `P2_Repeat_Donut`: `vw_customer_order_segments`
- `P2_RFM_Bar`: `vw_customer_rfm_segments`
- `P2_RFM_Treemap`: `vw_customer_rfm_segments`
- `P2_Cohort_Matrix`: `vw_cohort_retention`
- `P2_Customer_Table`: `vw_customer_rfm_segments`

## Page 3: Product And Geography

### Wireframe

```text
+----------------------------------------------------------------------------------------------------------------------+
| Product And Geography                                            [Country] [StockCode] [Description]              |
|                                                                                                                      |
| [Units Sold] [Net Sales] [UK Net Sales] [RoW Net Sales] [UK Share]                                                 |
|                                                                                                                      |
| [Top Products by Net Revenue....................................] [Country Comparison..............................] |
|                                                                                                                      |
| [Revenue vs Return Scatter......................................] [High-return Products.........] [Detail Table...] |
+----------------------------------------------------------------------------------------------------------------------+
```

### Slot Map

| Slot ID | Visual | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| `P3_Title` | Text box | 24 | 16 | 760 | 36 |
| `P3_Slicer_Country` | Slicer | 920 | 16 | 120 | 36 |
| `P3_Slicer_StockCode` | Slicer | 1056 | 16 | 120 | 36 |
| `P3_Slicer_Description` | Slicer | 1192 | 16 | 150 | 36 |
| `P3_KPI_01` | Card | 24 | 80 | 252 | 92 |
| `P3_KPI_02` | Card | 292 | 80 | 252 | 92 |
| `P3_KPI_03` | Card | 560 | 80 | 252 | 92 |
| `P3_KPI_04` | Card | 828 | 80 | 252 | 92 |
| `P3_KPI_05` | Card | 1096 | 80 | 246 | 92 |
| `P3_Product_Bar` | Bar chart | 24 | 200 | 820 | 236 |
| `P3_Country_Column` | Column chart | 860 | 200 | 482 | 236 |
| `P3_Scatter` | Scatter chart | 24 | 452 | 620 | 252 |
| `P3_Return_Bar` | Bar chart | 660 | 452 | 314 | 252 |
| `P3_Detail_Table` | Table | 990 | 452 | 352 | 252 |

### Visual Assignment

- `P3_KPI_01`: `Units Sold`
- `P3_KPI_02`: `Net Sales`
- `P3_KPI_03`: `UK Net Sales`
- `P3_KPI_04`: `Rest of World Net Sales`
- `P3_KPI_05`: `UK Sales Share`
- `P3_Product_Bar`: `vw_product_performance`
- `P3_Country_Column`: `vw_sales_line_enriched`
- `P3_Scatter`: `vw_product_performance`
- `P3_Return_Bar`: `vw_product_performance`
- `P3_Detail_Table`: `vw_product_performance`

## Page 4: Returns And Risk

### Wireframe

```text
+----------------------------------------------------------------------------------------------------------------------+
| Returns And Risk                                                [Month] [Country] [Cancellation Flag]             |
|                                                                                                                      |
| [Cancelled Inv.] [Cancel Rate] [Return Value] [Return Rate] [Neg Qty Rate]                                         |
|                                                                                                                      |
| [Cancellation Trend............................................................] [High-return Products............] |
|                                                                                                                      |
| [Cancelled vs Completed....................] [Anomaly Table.......................................................] |
|                                                                                                                      |
| [Odd Codes / Service Rows.........................................................................................] |
+----------------------------------------------------------------------------------------------------------------------+
```

### Slot Map

| Slot ID | Visual | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| `P4_Title` | Text box | 24 | 16 | 760 | 36 |
| `P4_Slicer_Month` | Slicer | 920 | 16 | 120 | 36 |
| `P4_Slicer_Country` | Slicer | 1056 | 16 | 120 | 36 |
| `P4_Slicer_Cancel` | Slicer | 1192 | 16 | 150 | 36 |
| `P4_KPI_01` | Card | 24 | 80 | 252 | 92 |
| `P4_KPI_02` | Card | 292 | 80 | 252 | 92 |
| `P4_KPI_03` | Card | 560 | 80 | 252 | 92 |
| `P4_KPI_04` | Card | 828 | 80 | 252 | 92 |
| `P4_KPI_05` | Card | 1096 | 80 | 246 | 92 |
| `P4_Cancel_Trend` | Line chart | 24 | 200 | 820 | 220 |
| `P4_High_Return_Bar` | Bar chart | 860 | 200 | 482 | 220 |
| `P4_Cancel_Stacked` | Stacked column chart | 24 | 436 | 360 | 180 |
| `P4_Anomaly_Table` | Table | 400 | 436 | 942 | 180 |
| `P4_Odd_Codes` | Table | 24 | 632 | 1318 | 72 |

### Visual Assignment

- `P4_KPI_01`: `Cancelled Invoices`
- `P4_KPI_02`: `Cancellation Invoice Rate`
- `P4_KPI_03`: `Return Value`
- `P4_KPI_04`: `Return Rate`
- `P4_KPI_05`: `Negative Quantity Line Rate`
- `P4_Cancel_Trend`: `vw_monthly_sales_trend`
- `P4_High_Return_Bar`: `vw_product_performance`
- `P4_Cancel_Stacked`: `vw_sales_line_enriched`
- `P4_Anomaly_Table`: `vw_sales_line_enriched`
- `P4_Odd_Codes`: `vw_sales_line_enriched`

## Formatting Defaults

- Page title font size: `24`
- Visual title font size: `13`
- KPI callout size: `24`
- KPI label size: `11`
- Table header background: `#EFE7D8`
- Table header text: `#1E2429`
- Data labels:
  - sales visuals: `#1E2429`
  - return visuals: `#B6493A`

## Recommended Manual Tweaks In Power BI

- Turn shadows off for all visuals.
- Use rounded corners only lightly, `4 px` to `6 px`.
- Keep all KPI cards aligned to one row.
- Add a short annotation text box on Page 1 and Page 4.
- Use conditional formatting in the cohort matrix.
- On product visuals, sort by `net_revenue` or `return_rate`, never alphabetically.

## Quick Build Order

1. Import the theme file.
2. Set page size to `1366 x 768`.
3. Add the title and slicers first on each page.
4. Place KPI cards using the coordinates above.
5. Add the primary chart on each page.
6. Add supporting visuals and only then style labels, borders, and titles.
