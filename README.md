# ShopPulse — E-Commerce Analytics Pipeline

![Python](https://img.shields.io/badge/Python-3.12-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-blue)
![PowerBI](https://img.shields.io/badge/PowerBI-Dashboard-yellow)

## Business Problem
UrbanKart, a mid-sized e-commerce platform, was experiencing revenue leakage despite 40% order growth. This project identifies where revenue is lost through customer segmentation, delivery analysis, and product performance tracking.

## Key Findings
- 📦 **96,457** delivered orders analysed across **2016–2018**
- 💰 **R$ 15.4M** total GMV with peak of **R$ 1.15M** in a single month
- ⭐ Delayed orders scored **1.73 points lower** (4.29 → 2.57) — a **40% satisfaction drop**
- 🚚 **8.1%** of orders delayed with avg delivery time of **12.1 days**
- 🏆 **health_beauty** is the #1 revenue category

## Tech Stack
| Tool | Purpose |
|---|---|
| Python 3.12 | Data cleaning, EDA, RFM segmentation |
| PostgreSQL 18 | Database, SQL analysis |
| Pandas / NumPy | Data manipulation |
| Matplotlib / Seaborn | Visualizations |
| Power BI | Executive dashboard |
| SQLAlchemy | Python-PostgreSQL connection |

## Project Structure

shoppulse-analytics/
├── data/
│   ├── raw/          ← original Olist CSVs (not in repo)
│   └── processed/    ← cleaned outputs
├── sql/
│   └── analysis.sql  ← 20 business queries
├── notebooks/
│   ├── 01_data_cleaning.ipynb
│   └── 02_eda.ipynb
├── dashboard/
│   └── ShopPulse_Dashboard.pbix
├── reports/          ← saved chart PNGs
└── README.md

## Dataset
Brazilian E-Commerce dataset by Olist — 100K+ orders, 8 relational tables.
Download: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Setup Instructions
```bash
# Install dependencies
pip install -r requirements.txt

# Set up database connection
# Create .env file with your PostgreSQL credentials

# Run notebooks in order
# 1. notebooks/01_data_cleaning.ipynb
# 2. notebooks/02_eda.ipynb
```

## SQL Analysis
20 business queries covering:
- Monthly GMV trend and MoM growth rate
- RFM customer segmentation
- Delivery SLA by region
- Category revenue ranking
- Review score analysis

## Dashboard
3-page Power BI dashboard:
- **Page 1** — Revenue Overview (GMV, category performance)
- **Page 2** — Customer Intelligence (RFM segments)
- **Page 3** — Operations (delivery SLA, delay impact)

## Key Business Insights
1. **Health & Beauty** drives highest revenue at R$ 1.8M+
2. Delayed orders cause **40% drop** in customer satisfaction
3. **8.1% delay rate** represents significant retention risk
4. Peak revenue month was **September 2016**
5. RFM analysis identified **7,866 Champion customers** worth targeting

## Author
Aditi Rajawat | aditirajawat2911@gmail.com | [Portfolio](https://aditiport.vercel.app)