# Metabase + dbt Local Example

A self-contained Docker environment demonstrating a dbt analytics project connected to Metabase for BI.

## Architecture

```
raw (Postgres)  →  staging (views)  →  intermediate (ephemeral)  →  marts (tables)  →  Metabase
```

### Source tables (raw schema)
`customers`, `products`, `categories`, `suppliers`, `orders`, `order_items`, `payments`, `inventory`, `reviews`, `order_events`

### Mart models
| Model | Type | Description |
|-------|------|-------------|
| `dim_dates` | dimension | Date spine with calendar attributes |
| `dim_customers` | dimension | Customer lifetime metrics, segmentation, revenue tier |
| `dim_products` | dimension | Product catalog with sales, reviews, inventory status |
| `fct_orders` | fact | Order-grain with totals, margins, payment details |
| `fct_reviews` | fact | Reviews with sentiment, NPS category, purchase context |
| `fct_order_events` | fact (incremental) | Order lifecycle events with timing |
| `fct_daily_sales` | fact | Daily sales joined to date spine with rolling metrics |
| `monthly_revenue` | aggregate | Monthly revenue summary |

## Quick start
```bash
# 1. Start everything (Postgres, Metabase, dbt)
docker compose up --build

# 2. Wait for dbt-runner to finish ("✅ dbt pipeline complete")
#    and Metabase to be healthy (may take ~60s on first launch)

# 3. In a separate terminal, run the Metabase setup script
chmod +x scripts/setup-metabase.sh
./scripts/setup-metabase.sh
```

### What each step does

**`docker compose up --build`** starts four services:
1. `analytics-db` — Postgres with raw seed data (`init-analytics.sql`)
2. `metabase-db` — Postgres for Metabase's internal state
3. `metabase` — Metabase on `http://localhost:3000`
4. `dbt` — one-shot container: `deps → seed → run → test`, then exits

**`setup-metabase.sh`** automates Metabase first-time configuration:
1. Waits for Metabase to be reachable
2. Creates the admin account (`admin@example.com` / `Metabase123!`)
3. Connects the analytics database so Metabase can see the dbt marts
4. Triggers a schema sync
5. Prints connection details and the `database_id` for `config.local.yaml`

After setup, open `http://localhost:3000` and log in with the credentials above. The marts tables (`dim_customers`, `fct_orders`, etc.) will be available to query.

> **Note:** The script requires `curl` and `python3` on your host machine (both are pre-installed on macOS). You can override the Metabase URL with `METABASE_URL=http://your-host:3000 ./scripts/setup-metabase.sh`.

## Project structure

```
dbt_project/
├── macros/
│   ├── generate_schema_name.sql   # Writes to exact schema names (no prefix)
│   └── utils.sql                  # safe_divide, days_between helpers
├── models/
│   ├── staging/                   # 1:1 source mirrors (views)
│   ├── intermediate/              # Business logic (ephemeral)
│   └── marts/                     # Final tables for BI
├── seeds/                         # Reference data (payment_methods, order_statuses)
├── tests/                         # Singular data quality tests
├── dbt_project.yml
├── packages.yml                   # dbt_utils
└── profiles.yml
```
