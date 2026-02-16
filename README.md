# Local Test Environment: dbt + Metabase + Postgres

A docker-compose environment for testing the `dbt-to-metabase` migration tool.

## Architecture

```
┌──────────────────────────────────────────────────┐
│                 docker compose                   │
│                                                  │
│  ┌──────────────┐   ┌────────────────────────┐   │
│  │ metabase-db  │   │     analytics-db       │   │
│  │  (postgres)  │   │      (postgres)        │   │
│  │  port: 5434  │   │     port: 5433         │   │
│  │              │   │                        │   │
│  │  Metabase    │   │  raw.*        (source) │   │
│  │  app state   │   │  staging.*   (dbt/MB)  │   │
│  └──────┬───────┘   │  marts.*     (dbt/MB)  │   │
│         │           └──────────┬─────────────┘   │
│  ┌──────┴───────┐              │                 │
│  │   metabase   │──────────────┘                 │
│  │  port: 3000  │                                │
│  └──────────────┘                                │
│                                                  │
│  ┌──────────────┐                                │
│  │ dbt-runner   │──── runs dbt seed + run ──────▶│
│  │  (one-shot)  │    against analytics-db        │
│  └──────────────┘                                │
└──────────────────────────────────────────────────┘
```

## What's included

| Component | Description |
|---|---|
| `analytics-db` | PostgreSQL 16 with `raw` schema + sample data (customers, products, orders, payments) |
| `metabase-db` | PostgreSQL 16 for Metabase's own application data |
| `metabase` | Metabase instance connected to `analytics-db` |
| `dbt-runner` | One-shot container that runs `dbt seed && dbt run` |
| `dbt_project/` | Complete dbt project with staging views + mart tables |

### dbt model DAG

```
raw.customers ──▶ stg_customers ──▶ dim_customers
raw.products  ──▶ stg_products      │
raw.orders    ──▶ stg_orders    ──▶ fct_orders ──▶ monthly_revenue
raw.order_items▶ stg_order_items──┘      │
raw.payments  ──▶ stg_payments  ─────────┘
```

## Usage

### 1. Start everything

```bash
docker compose up -d
```

This starts both Postgres databases and Metabase. The dbt container will automatically run once analytics-db is healthy.

### 2. Set up Metabase

Wait ~60 seconds for Metabase to fully start, then:

```bash
bash scripts/setup-metabase.sh
```

This creates an admin account and adds the analytics database. It prints the connection details you'll need.

### 3. Run dbt (if it didn't run automatically)

```bash
docker compose run --rm dbt sh -c "dbt seed && dbt run"
```

### 4. Verify

- **Metabase UI**: http://localhost:3000 (login: `admin@example.com` / `Metabase123!`)
- **Analytics DB**: `psql -h localhost -p 5433 -U analytics_user -d analytics`

Check that dbt created the views/tables:

```bash
docker compose exec analytics-db psql -U analytics_user -d analytics -c "
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname IN ('raw', 'staging', 'marts')
    UNION ALL
    SELECT schemaname, viewname
    FROM pg_views
    WHERE schemaname IN ('staging', 'marts')
    ORDER BY 1, 2;
"
```

If you need to reseed, you can run:

```bash
docker compose run --rm dbt sh -c "dbt seed && dbt run"
```

### 5. Test the migration tool

Push the `dbt_project/` folder to a GitHub repo, then:

```bash
# Update config.local.yaml with your GitHub repo and the DB ID from setup script

cd ../dbt-to-metabase
pip install -e .

# Validate the setup
dbt-to-metabase validate --config ../dbt-metabase-local/config.local.yaml

# Preview what will happen
dbt-to-metabase plan --config ../dbt-metabase-local/config.local.yaml --stdout

# Run the migration
dbt-to-metabase migrate --config ../dbt-metabase-local/config.local.yaml
```

## Ports

| Service | Port | Purpose |
|---|---|---|
| Metabase | `localhost:3000` | Web UI |
| Analytics DB | `localhost:5433` | Direct SQL access |
| Metabase DB | `localhost:5434` | Metabase internals (rarely needed) |

## Tear down

```bash
# Stop and remove containers
docker compose down

# Also remove data volumes (fresh start)
docker compose down -v
```

## Sample data

The analytics database is seeded with:

- **8 customers** with names and emails
- **8 products** across Electronics and Furniture categories ($29.99 – $1,299)
- **12 orders** with various statuses (completed, returned, processing, cancelled)
- **19 line items** linking orders to products
- **12 payment records** with different methods and statuses
