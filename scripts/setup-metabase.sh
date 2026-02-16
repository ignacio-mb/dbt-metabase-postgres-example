#!/usr/bin/env bash
# ============================================================
# setup-metabase.sh
#
# Automates Metabase first-time setup:
#   1. Waits for Metabase to be healthy
#   2. Creates admin account
#   3. Adds the analytics database
#   4. Prints connection info for the migration tool
# ============================================================
set -euo pipefail

METABASE_URL="${METABASE_URL:-http://localhost:3000}"
SETUP_TOKEN="249fa03d-fd94-4d5b-b94f-b4ebf3df681f"

# Admin credentials (change if you like)
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="Metabase123!"
ADMIN_FIRST="Admin"
ADMIN_LAST="User"

echo "═══════════════════════════════════════════════"
echo "  Metabase Setup Script"
echo "═══════════════════════════════════════════════"

# ── 1. Wait for Metabase ──────────────────────
echo -n "Waiting for Metabase to be ready"
for i in $(seq 1 60); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${METABASE_URL}/api/health" 2>/dev/null || true)
    if [ "$STATUS" = "200" ]; then
        echo " ✓"
        break
    fi
    echo -n "."
    sleep 5
done

# Verify it's actually up
curl -sf "${METABASE_URL}/api/health" > /dev/null || {
    echo " ✗ Metabase not reachable at ${METABASE_URL}"
    echo "   Make sure 'docker compose up' is running."
    exit 1
}

# ── 2. Check if already set up ────────────────
SETUP_CHECK=$(curl -s "${METABASE_URL}/api/session/properties" | python3 -c "
import sys, json
props = json.load(sys.stdin)
print('true' if props.get('has-user-setup') else 'false')
" 2>/dev/null || echo "false")

if [ "$SETUP_CHECK" = "true" ]; then
    echo "Metabase is already set up. Logging in..."
    SESSION=$(curl -s -X POST "${METABASE_URL}/api/session" \
        -H "Content-Type: application/json" \
        -d "{\"username\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")

    if [ -z "$SESSION" ]; then
        echo "✗ Login failed. Check credentials."
        exit 1
    fi
    echo "✓ Logged in."
else
    # ── 3. Run initial setup ──────────────────
    echo "Running first-time setup..."

    # Get a setup token
    PROPERTIES=$(curl -s "${METABASE_URL}/api/session/properties")
    REAL_TOKEN=$(echo "$PROPERTIES" | python3 -c "
import sys, json
props = json.load(sys.stdin)
print(props.get('setup-token', ''))
")

    if [ -z "$REAL_TOKEN" ]; then
        echo "✗ Could not get setup token. Metabase may already be configured."
        exit 1
    fi

    SETUP_RESPONSE=$(curl -s -X POST "${METABASE_URL}/api/setup" \
        -H "Content-Type: application/json" \
        -d "{
            \"token\": \"${REAL_TOKEN}\",
            \"user\": {
                \"email\": \"${ADMIN_EMAIL}\",
                \"password\": \"${ADMIN_PASSWORD}\",
                \"first_name\": \"${ADMIN_FIRST}\",
                \"last_name\": \"${ADMIN_LAST}\",
                \"site_name\": \"dbt Test Instance\"
            },
            \"prefs\": {
                \"site_name\": \"dbt Test Instance\",
                \"site_locale\": \"en\",
                \"allow_tracking\": false
            }
        }")

    SESSION=$(echo "$SETUP_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")

    if [ -z "$SESSION" ]; then
        echo "✗ Setup failed:"
        echo "$SETUP_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$SETUP_RESPONSE"
        exit 1
    fi

    echo "✓ Admin account created: ${ADMIN_EMAIL}"
fi

AUTH_HEADER="X-Metabase-Session: ${SESSION}"

# ── 4. Add analytics database ─────────────────
echo "Adding analytics database..."

# Check if it already exists
EXISTING_DBS=$(curl -s -H "$AUTH_HEADER" "${METABASE_URL}/api/database")
EXISTING_ID=$(echo "$EXISTING_DBS" | python3 -c "
import sys, json
dbs = json.load(sys.stdin).get('data', [])
for db in dbs:
    details = db.get('details', {})
    if details.get('host') == 'analytics-db' and details.get('dbname') == 'analytics':
        print(db['id'])
        break
" 2>/dev/null || echo "")

if [ -n "$EXISTING_ID" ]; then
    echo "✓ Analytics database already connected (id=${EXISTING_ID})"
    DB_ID="$EXISTING_ID"
else
    DB_RESPONSE=$(curl -s -X POST "${METABASE_URL}/api/database" \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d '{
            "engine": "postgres",
            "name": "Analytics (dbt)",
            "details": {
                "host": "analytics-db",
                "port": 5432,
                "dbname": "analytics",
                "user": "analytics_user",
                "password": "analytics_pass",
                "schema-filters-type": "all",
                "ssl": false,
                "tunnel-enabled": false
            },
            "is_full_sync": true,
            "auto_run_queries": true
        }')

    DB_ID=$(echo "$DB_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")

    if [ -z "$DB_ID" ]; then
        echo "✗ Failed to add database:"
        echo "$DB_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$DB_RESPONSE"
        exit 1
    fi
    echo "✓ Analytics database added (id=${DB_ID})"
fi

# ── 5. Trigger a sync ─────────────────────────
echo "Triggering database sync..."
curl -s -X POST "${METABASE_URL}/api/database/${DB_ID}/sync" \
    -H "$AUTH_HEADER" > /dev/null
echo "✓ Sync triggered"

# ── 6. Print summary ──────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════"
echo ""
echo "  Metabase URL:      ${METABASE_URL}"
echo "  Admin email:       ${ADMIN_EMAIL}"
echo "  Admin password:    ${ADMIN_PASSWORD}"
echo "  Session token:     ${SESSION}"
echo "  Analytics DB ID:   ${DB_ID}"
echo ""
echo "  ── Analytics DB (direct access) ──"
echo "  Host: localhost:5433"
echo "  DB:   analytics"
echo "  User: analytics_user"
echo "  Pass: analytics_pass"
echo ""
echo "  ── For dbt-to-metabase config.yaml ──"
echo "  metabase:"
echo "    url: \"${METABASE_URL}\""
echo "    database_id: ${DB_ID}"
echo "    username: \"${ADMIN_EMAIL}\""
echo "    password: \"${ADMIN_PASSWORD}\""
echo ""
echo "═══════════════════════════════════════════════"
