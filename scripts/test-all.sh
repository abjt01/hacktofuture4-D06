#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — Run the full test suite across all layers
# Usage: ./scripts/test-all.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

PASS=0; FAIL=0

run_suite() {
  local name="$1"; shift
  echo -e "${BOLD}── $name ─────────────────────────────${RESET}"
  if "$@"; then
    echo -e "${GREEN}✓ $name passed${RESET}\n"
    ((PASS++))
  else
    echo -e "${RED}✗ $name failed${RESET}\n"
    ((FAIL++))
  fi
}

# Go tests
run_suite "Go backend" bash -c "cd '$ROOT/backend' && go test -race ./..."

# Python engine tests
run_suite "Python engine" bash -c "cd '$ROOT/engine' && python3 -m pytest tests/ -q"

# Frontend unit tests
run_suite "Frontend unit (Jest)" bash -c "cd '$ROOT/frontend' && npm test -- --passWithNoTests --ci 2>/dev/null"

echo "──────────────────────────────────────"
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}"
[[ $FAIL -eq 0 ]]
