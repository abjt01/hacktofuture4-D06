#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — Check the health of all running services
# Usage: ./scripts/health-check.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKEND="${BACKEND_URL:-http://localhost:8000}"
ENGINE="${ENGINE_URL:-http://localhost:8002}"
FRONTEND="${FRONTEND_URL:-http://localhost:3000}"
CHROMA="${CHROMA_URL:-http://localhost:8001}"

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

pass()  { echo -e "  ${GREEN}✓${RESET} $1 — $2"; }
fail()  { echo -e "  ${RED}✗${RESET} $1 — $2"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $1 — $2"; }

check_http() {
  local name="$1"
  local url="$2"
  local code
  code=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    pass "$name" "$url"
    return 0
  else
    fail "$name" "$url (HTTP $code)"
    return 1
  fi
}

echo -e "${BOLD}REKALL service health check${RESET}"
echo "──────────────────────────────────"

FAILURES=0
check_http "Go backend"     "${BACKEND}/health"                   || ((FAILURES++))
check_http "Engine service" "${ENGINE}/health"                    || ((FAILURES++))
check_http "Frontend"       "${FRONTEND}"                         || ((FAILURES++)) || true
check_http "ChromaDB"       "${CHROMA}/api/v1/heartbeat"         || ((FAILURES++)) || true

echo "──────────────────────────────────"
if [[ $FAILURES -eq 0 ]]; then
  echo -e "${GREEN}All services healthy${RESET}"
else
  echo -e "${RED}${FAILURES} service(s) unhealthy${RESET}"
  exit 1
fi
