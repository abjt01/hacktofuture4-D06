#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — Start all development services concurrently
# Usage: ./scripts/dev.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$ROOT/.env" ] && export $(grep -v '^#' "$ROOT/.env" | xargs)

BOLD="\033[1m"
CYAN="\033[36m"
MAGENTA="\033[35m"
YELLOW="\033[33m"
RESET="\033[0m"

info() { echo -e "${BOLD}[rekall]${RESET} $*"; }

# Trap to kill all child processes on exit
cleanup() {
  info "Shutting down all services..."
  kill 0
}
trap cleanup SIGINT SIGTERM EXIT



# ── Go backend ────────────────────────────────────────────────────────────────
info "Starting Go backend on :8000"
(
  cd "$ROOT/backend"
  GOCACHE="$ROOT/.gocache" GOMODCACHE="$ROOT/.gomodcache" GIN_MODE=debug go run ./cmd/server/main.go 2>&1 | sed "s/^/${CYAN}[go]${RESET} /"
) &

sleep 1

# ── Python engine service ─────────────────────────────────────────────────────
info "Starting Python engine service on :8002"
(
  cd "$ROOT/engine"
  [ -f ".venv/bin/activate" ] && source .venv/bin/activate
  python3 -m uvicorn main:app --host 0.0.0.0 --port 8002 --reload 2>&1 \
    | sed "s/^/${MAGENTA}[engine]${RESET} /"
) &

# ── Next.js frontend ──────────────────────────────────────────────────────────
info "Starting Next.js frontend on :3000"
(
  cd "$ROOT/frontend"
  npm run dev 2>&1 | sed "s/^/${YELLOW}[next]${RESET} /"
) &

info "All services started. Press Ctrl+C to stop."
wait
