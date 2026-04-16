#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — Inject a simulated failure scenario via the API
# Usage: ./scripts/simulate.sh [scenario] [backend_url]
#
# Available scenarios:
#   postgres_refused    image_pull_backoff
#   oom_kill            test_failure
#   secret_leak
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCENARIO="${1:-postgres_refused}"
BACKEND="${2:-http://localhost:8000}"

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

info()  { echo -e "${BOLD}[simulate]${RESET} $*"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
fatal() { echo -e "${RED}✗ $*${RESET}"; exit 1; }

command -v curl >/dev/null 2>&1 || fatal "curl is required"

VALID_SCENARIOS=(postgres_refused oom_kill test_failure secret_leak image_pull_backoff)
valid=false
for s in "${VALID_SCENARIOS[@]}"; do
  [[ "$SCENARIO" == "$s" ]] && valid=true && break
done
$valid || fatal "Unknown scenario: $SCENARIO. Valid: ${VALID_SCENARIOS[*]}"

info "Injecting scenario '${SCENARIO}' into ${BACKEND}..."

RESPONSE=$(curl -sf -X POST "${BACKEND}/webhook/simulate" \
  -H "Content-Type: application/json" \
  -d "{\"scenario\": \"${SCENARIO}\"}" \
  || fatal "Request failed — is the backend running?")

INCIDENT_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['incident_id'])")

ok "Incident created: ${INCIDENT_ID}"
echo ""
echo "  Dashboard: http://localhost:3000/incidents/${INCIDENT_ID}"
echo "  SSE stream: ${BACKEND}/stream/${INCIDENT_ID}"
