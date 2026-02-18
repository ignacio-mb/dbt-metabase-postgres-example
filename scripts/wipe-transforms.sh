#!/usr/bin/env bash
set -euo pipefail

METABASE_URL="${METABASE_URL:-http://localhost:3000}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Metabase123!}"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_NAME="${DB_NAME:-analytics}"
DB_USER="${DB_USER:-analytics_user}"
DB_PASS="${DB_PASS:-analytics_pass}"

# ── 1. Delete transforms from Metabase API ────────────────

SESSION=$(curl -s -X POST "${METABASE_URL}/api/session" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

echo "Fetching transforms from Metabase..."
TRANSFORMS=$(curl -s -H "X-Metabase-Session: ${SESSION}" "${METABASE_URL}/api/transform")

COUNT=$(echo "$TRANSFORMS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
echo "Found ${COUNT} transforms"

echo "$TRANSFORMS" | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    print(t['id'])
" | while read -r tid; do
  curl -s -X DELETE -H "X-Metabase-Session: ${SESSION}" "${METABASE_URL}/api/transform/${tid}" > /dev/null
  echo "  Deleted transform id=${tid} from Metabase"
done

# ── 2. Drop transform tables from the database ────────────

echo ""
echo "Dropping transform tables from database..."

SCHEMAS=("transforms_staging" "transforms_intermediate" "transforms_marts" "staging" "intermediate" "marts")

for schema in "${SCHEMAS[@]}"; do
  TABLES=$(PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -A -c "
    SELECT tablename FROM pg_tables WHERE schemaname = '${schema}'
    UNION
    SELECT viewname FROM pg_views WHERE schemaname = '${schema}';
  " 2>/dev/null || true)

  if [ -z "$TABLES" ]; then
    continue
  fi

  echo "  Schema '${schema}':"
  while IFS= read -r table; do
    [ -z "$table" ] && continue
    PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -q -c \
      "DROP TABLE IF EXISTS \"${schema}\".\"${table}\" CASCADE; DROP VIEW IF EXISTS \"${schema}\".\"${table}\" CASCADE;" 2>/dev/null
    echo "    Dropped ${schema}.${table}"
  done <<< "$TABLES"
done

# ── 3. Trigger a Metabase sync so it picks up the changes ─

echo ""
echo "Triggering Metabase database sync..."
DB_ID=$(echo "$TRANSFORMS" | python3 -c "
import sys, json
transforms = json.load(sys.stdin)
ids = {t.get('database_id') for t in transforms if t.get('database_id')}
print(next(iter(ids))) if ids else print('')
" 2>/dev/null || true)

if [ -n "$DB_ID" ]; then
  curl -s -X POST -H "X-Metabase-Session: ${SESSION}" "${METABASE_URL}/api/database/${DB_ID}/sync" > /dev/null
  echo "  Sync triggered for database id=${DB_ID}"
fi

echo ""
echo "✅ All transforms wiped from Metabase and database"
