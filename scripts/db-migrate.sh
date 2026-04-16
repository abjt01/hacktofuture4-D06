#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — Apply database schema and optionally seed vault entries
# Usage: ./scripts/db-migrate.sh [--seed]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$ROOT/.env" ] && export $(grep -v '^#' "$ROOT/.env" | xargs)

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

info()  { echo -e "${BOLD}[db-migrate]${RESET} $*"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
fatal() { echo -e "${RED}✗ $*${RESET}"; exit 1; }

DATABASE_URL="${DATABASE_URL:-}"
[ -z "$DATABASE_URL" ] && fatal "DATABASE_URL is not set. Run: export DATABASE_URL=postgresql://..."

SCHEMA="$ROOT/backend/db/schema.sql"
[ -f "$SCHEMA" ] || fatal "Schema file not found: $SCHEMA"

info "Applying schema to database..."
psql "$DATABASE_URL" -f "$SCHEMA" -q
ok "Schema applied"

# Optional seeding
if [[ "${1:-}" == "--seed" ]]; then
  info "Seeding vault with initial human-approved fixes..."
  cd "$ROOT"
  python3 "$ROOT/backend/db/seed_vault.py"
  ok "Vault seeded"
fi

info "Migration complete."
