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

# ── 0. Verify psql is available ───────────────────────────────────────────────
if ! command -v psql &>/dev/null; then
  echo "ERROR: psql not found in PATH. Install postgresql-client and retry." >&2
  echo "  On Debian/Ubuntu: sudo apt-get install -y postgresql-client" >&2
  echo "  On macOS:         brew install libpq && brew link --force libpq" >&2
  exit 1
fi

# Verify DB connection up-front so any failure is visible (not silently swallowed)
echo "Verifying database connection (${DB_HOST}:${DB_PORT}/${DB_NAME})..."
PGPASSWORD="${DB_PASS}" psql \
  -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
  -c "SELECT 1" -q --no-psqlrc > /dev/null
echo "  Connected"

# ── 1. Delete transforms from Metabase API ────────────────────────────────────
SESSION=$(curl -sf -X POST "${METABASE_URL}/api/session" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Authenticated with Metabase"

echo ""
echo "Fetching transforms from Metabase..."
TRANSFORMS=$(curl -sf -H "X-Metabase-Session: ${SESSION}" "${METABASE_URL}/api/transform")

COUNT=$(echo "${TRANSFORMS}" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
echo "Found ${COUNT} transforms"

DB_ID=$(echo "${TRANSFORMS}" | python3 -c "
import sys, json
transforms = json.load(sys.stdin)
ids = {t.get('database_id') for t in transforms if t.get('database_id')}
print(next(iter(ids))) if ids else print('')
" 2>/dev/null || true)

echo "${TRANSFORMS}" | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    print(t['id'])
" | while read -r tid; do
  curl -sf -X DELETE -H "X-Metabase-Session: ${SESSION}" \
    "${METABASE_URL}/api/transform/${tid}" > /dev/null
  echo "  Deleted transform id=${tid}"
done

# ── 2. Drop transform tables from the database ────────────────────────────────
echo ""
echo "Dropping transform tables from database..."

SCHEMAS=("transforms_staging" "transforms_intermediate" "transforms_marts" "staging" "intermediate" "marts")

for schema in "${SCHEMAS[@]}"; do
  TABLES=$(PGPASSWORD="${DB_PASS}" psql \
    -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
    -t -A -c "
      SELECT tablename FROM pg_tables WHERE schemaname = '${schema}'
      UNION
      SELECT viewname  FROM pg_views  WHERE schemaname = '${schema}';
    ")

  if [ -z "${TABLES}" ]; then
    continue
  fi

  echo "  Schema '${schema}':"
  while IFS= read -r table; do
    [ -z "${table}" ] && continue
    PGPASSWORD="${DB_PASS}" psql \
      -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
      -q --no-psqlrc \
      -c "DROP TABLE IF EXISTS \"${schema}\".\"${table}\" CASCADE;
          DROP VIEW  IF EXISTS \"${schema}\".\"${table}\" CASCADE;"
    echo "    Dropped ${schema}.${table}"
  done <<< "${TABLES}"
done

# ── 3. Retire stale Metabase catalog entries ──────────────────────────────────
#
# Deleting a transform removes the transform record but leaves the target table
# entry in Metabase's metadata catalog (marked active=false).  The Create
# Transform API returns 403 "A table with that name already exists" if ANY
# catalog entry — active or not — matches the target schema+name.  We must
# retire those stale entries so the next migration can create fresh transforms.
#
if [ -n "${DB_ID}" ]; then
  echo ""
  echo "Retiring stale Metabase catalog entries for database id=${DB_ID}..."

  STALE_SCHEMAS="staging intermediate marts transforms_staging transforms_intermediate transforms_marts"

  ALL_TABLES=$(curl -sf -H "X-Metabase-Session: ${SESSION}" \
    "${METABASE_URL}/api/database/${DB_ID}/metadata" \
    | python3 -c "
import sys, json
meta = json.load(sys.stdin)
for t in meta.get('tables', []):
    print(t['id'], t.get('schema','').lower())
" 2>/dev/null || true)

  if [ -n "${ALL_TABLES}" ]; then
    echo "${ALL_TABLES}" | while read -r table_id schema_lc; do
      for s in ${STALE_SCHEMAS}; do
        if [ "${schema_lc}" = "${s}" ]; then
          curl -sf -X PUT \
            -H "X-Metabase-Session: ${SESSION}" \
            -H "Content-Type: application/json" \
            "${METABASE_URL}/api/table/${table_id}" \
            -d '{"active": false}' > /dev/null
          echo "  Retired catalog entry: table_id=${table_id} schema=${schema_lc}"
          break
        fi
      done
    done
  else
    echo "  No catalog entries found (or DB not yet synced)"
  fi
fi

# ── 4. Trigger Metabase sync and wait for completion ─────────────────────────
#
# The sync is async.  We poll until it finishes so the catalog reflects the
# dropped tables before the next migration run begins.
#
if [ -n "${DB_ID}" ]; then
  echo ""
  echo "Triggering Metabase database sync for database id=${DB_ID}..."
  # Try sync_schema first (full re-scan); fall back to the lighter /sync endpoint
  curl -sf -X POST -H "X-Metabase-Session: ${SESSION}" \
    "${METABASE_URL}/api/database/${DB_ID}/sync_schema" > /dev/null \
    || curl -sf -X POST -H "X-Metabase-Session: ${SESSION}" \
         "${METABASE_URL}/api/database/${DB_ID}/sync" > /dev/null \
    || true

  echo "  Waiting for sync to complete (up to 60 s)..."
  SYNCED=false
  for i in $(seq 1 12); do
    sleep 5
    STATUS=$(curl -sf -H "X-Metabase-Session: ${SESSION}" \
      "${METABASE_URL}/api/database/${DB_ID}" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('initial_sync_status','complete'))" \
      2>/dev/null || echo "complete")
    if [ "${STATUS}" = "complete" ]; then
      echo "  Sync complete"
      SYNCED=true
      break
    fi
    echo "  Still syncing... (${i}/12)"
  done
  if [ "${SYNCED}" = "false" ]; then
    echo "  WARNING: sync did not report completion within 60 s; proceeding anyway"
  fi
fi

echo ""
echo "All transforms wiped from Metabase and database"
