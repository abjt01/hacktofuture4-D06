#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# REKALL — dev startup script
# Usage: bash scripts/dev-start.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo ""
echo "🚀 REKALL dev startup"
echo "────────────────────────────────────────────"

# ── 0. Load env vars ──────────────────────────────────────────────────────────
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs) 2>/dev/null || true
  echo "✅ .env loaded"
else
  echo "⚠️  No .env found — create one with GROQ_API_KEY"
fi

if [ -z "${GROQ_API_KEY:-}" ]; then
  echo "❌ GROQ_API_KEY is not set. Export it or add to .env"
  exit 1
fi
echo "✅ GROQ_API_KEY = ${GROQ_API_KEY:0:16}..."

# ── 1. Install Python deps ─────────────────────────────────────────────────────
echo ""
echo "📦 Installing Python engine deps..."
pip install -q -r engine/requirements.txt
echo "✅ Python deps installed"

# ── 2. Seed the vault ─────────────────────────────────────────────────────────
echo ""
echo "🗄️  Seeding vault..."
python3 scripts/seed-vault.py
echo "✅ Vault seeded"

# ── 3. Build Go backend ────────────────────────────────────────────────────────
echo ""
echo "🔨 Building Go backend..."
cd backend
go build -o bin/rekall-backend ./cmd/server/
echo "✅ Go backend built → backend/bin/rekall-backend"
cd "$ROOT"

# ── 4. Install frontend deps ───────────────────────────────────────────────────
echo ""
echo "🌐 Installing frontend deps..."
cd frontend
npm install --silent 2>/dev/null || true
cd "$ROOT"
echo "✅ Frontend deps installed"

echo ""
echo "────────────────────────────────────────────"
echo "✅ Ready! Now open 3 terminals:"
echo ""
echo "  Terminal 1 — Python engine:"
echo "    cd engine && uvicorn main:app --port 8002 --reload"
echo ""
echo "  Terminal 2 — Go backend:"
echo "    cd backend && ./bin/rekall-backend"
echo ""
echo "  Terminal 3 — Next.js frontend:"
echo "    cd frontend && npm run dev"
echo ""
echo "  Then open: http://localhost:3000"
echo "  Test:      curl -X POST http://localhost:8000/webhook/simulate \\"
echo "             -H 'Content-Type: application/json' \\"
echo "             -d '{\"scenario\": \"postgres_refused\"}'"
echo "────────────────────────────────────────────"
