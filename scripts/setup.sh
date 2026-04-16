#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — First-time setup script
# Run once to bootstrap the entire development environment.
# Usage: ./scripts/setup.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()  { echo -e "${BOLD}[rekall]${RESET} $*"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠ $*${RESET}"; }
fatal() { echo -e "${RED}✗ $*${RESET}"; exit 1; }

# ── Prerequisites check ───────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v go      >/dev/null 2>&1 || fatal "Go not found. Install from https://go.dev/dl"
command -v node    >/dev/null 2>&1 || fatal "Node.js not found. Install from https://nodejs.org"
command -v python3 >/dev/null 2>&1 || fatal "Python 3 not found."
command -v docker  >/dev/null 2>&1 || warn  "Docker not found — needed for docker-compose workflow"

ok "Prerequisites satisfied"

# ── .env ─────────────────────────────────────────────────────────────────────
if [ ! -f "$ROOT/.env" ]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  warn ".env created from .env.example — fill in ANTHROPIC_API_KEY and DATABASE_URL"
else
  ok ".env already exists"
fi

# ── Go backend ───────────────────────────────────────────────────────────────
info "Downloading Go dependencies..."
cd "$ROOT/backend"
go mod download
ok "Go modules ready"

# ── Python engine service ────────────────────────────────────────────────────
info "Setting up Python engine service..."
cd "$ROOT/engine"
if command -v uv >/dev/null 2>&1; then
  uv pip install --system -r requirements.txt
else
  python3 -m pip install --quiet -r requirements.txt
fi
ok "Python dependencies installed"

# ── Frontend ─────────────────────────────────────────────────────────────────
info "Installing frontend dependencies..."
cd "$ROOT/frontend"
npm install --silent
ok "Frontend dependencies installed"

# ── Done ─────────────────────────────────────────────────────────────────────
cd "$ROOT"
echo ""
info "Setup complete! Next steps:"
echo "  1. Edit .env — add ANTHROPIC_API_KEY + DATABASE_URL"
echo "  2. ./scripts/db-migrate.sh        — create database schema"
echo "  3. ./scripts/dev.sh               — start all services"
echo "  4. Open http://localhost:3000"
