#!/usr/bin/env python3
"""
REKALL — Vault Seed Script

Creates 5 human-approved vault entries for the 5 demo simulator scenarios.
Vault signatures match what DiagnosticAgent produces for these failure types.

Run with:
    python scripts/seed-vault.py
    # or
    make seed
"""

import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path

# Ensure project root is on path
sys.path.insert(0, str(Path(__file__).parent.parent))

# ── Vault path ────────────────────────────────────────────────────────────────

VAULT_PATH = os.environ.get("VAULT_PATH", "vault")


def _sanitize_filename(sig: str) -> str:
    """Mirror the same logic in vault/store.py."""
    import re
    safe = re.sub(r"[/\\<>\"'|?*\s]+", "_", sig)
    return safe.strip("_")[:200]


def write_entry(entry: dict, scope: str = "local") -> None:
    """Write a vault entry JSON file atomically."""
    scope_dir = Path(VAULT_PATH) / scope
    scope_dir.mkdir(parents=True, exist_ok=True)

    sig = entry["failure_signature"]
    filename = f"{_sanitize_filename(sig)}.json"
    path = scope_dir / filename

    # Don't overwrite existing entries (preserves learned reward_scores)
    if path.exists():
        print(f"  SKIP (already exists): {filename}")
        return

    entry.setdefault("id", str(uuid.uuid4()))
    entry.setdefault("created_at", datetime.utcnow().isoformat())
    entry.setdefault("updated_at", datetime.utcnow().isoformat())
    entry.setdefault("retrieval_count", 0)
    entry.setdefault("success_count", 0)
    entry.setdefault("reward_score", 0.0)

    path.write_text(json.dumps(entry, indent=2), encoding="utf-8")
    print(f"  WROTE: {filename}")


# ── Vault entries — one per simulator scenario ────────────────────────────────

ENTRIES = [
    # 1. postgres_refused → infra:postgres:econnrefused
    {
        "failure_signature": "infra:postgres:econnrefused",
        "failure_type": "infra",
        "source": "human",
        "confidence": 0.92,
        "fix_description": (
            "PostgreSQL connection refused on port 5432. "
            "The database pod is down or the service name has changed. "
            "Restart the database deployment and verify the service endpoint."
        ),
        "fix_commands": [
            "kubectl rollout restart deployment/postgres -n database",
            "kubectl rollout status deployment/postgres -n database",
            "kubectl get svc postgres -n database",
        ],
        "fix_diff": None,
    },

    # 2. oom_kill → oom:java:heapspace
    {
        "failure_signature": "oom:java:heapspace",
        "failure_type": "oom",
        "source": "human",
        "confidence": 0.89,
        "fix_description": (
            "Java heap space exhausted — container OOM killed. "
            "Increase JVM heap size via JAVA_OPTS and raise the container memory limit."
        ),
        "fix_commands": [
            "export JAVA_OPTS='-Xms512m -Xmx2g -XX:+UseG1GC'",
            "kubectl set resources deployment/api --limits=memory=3Gi --requests=memory=1Gi",
            "kubectl rollout restart deployment/api",
        ],
        "fix_diff": None,
    },

    # 3. test_failure → test:jest:assertion_error
    {
        "failure_signature": "test:jest:assertion_error",
        "failure_type": "test",
        "source": "human",
        "confidence": 0.85,
        "fix_description": (
            "Jest assertion failure in CI. "
            "Update the failing snapshot or fix the assertion. "
            "Run tests locally first to verify the fix."
        ),
        "fix_commands": [
            "npm test -- --updateSnapshot",
            "npm test -- --verbose 2>&1 | tail -50",
        ],
        "fix_diff": None,
    },

    # 4. secret_leak → security:secret:api_key_exposed
    {
        "failure_signature": "security:secret:api_key_exposed",
        "failure_type": "security",
        "source": "human",
        "confidence": 0.95,
        "fix_description": (
            "API key or secret token detected in commit history or log output. "
            "Rotate the credential immediately, scrub from git history, "
            "and move to a secrets manager."
        ),
        "fix_commands": [
            "git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch .env' HEAD",
            "git push origin --force --all",
            "# Rotate the exposed credential in your secrets manager",
            "kubectl create secret generic api-credentials --from-literal=API_KEY=<new-key> --dry-run=client -o yaml | kubectl apply -f -",
        ],
        "fix_diff": None,
    },

    # 5. image_pull_backoff → deploy:image:pull_backoff
    {
        "failure_signature": "deploy:image:pull_backoff",
        "failure_type": "deploy",
        "source": "human",
        "confidence": 0.88,
        "fix_description": (
            "ImagePullBackOff — Kubernetes cannot pull the container image. "
            "Check image name/tag, ensure registry credentials are valid, "
            "and verify network access from the cluster."
        ),
        "fix_commands": [
            "kubectl describe pod -l app=api | grep -A 10 'Events'",
            "kubectl get secret regcred -o yaml",
            "docker pull <image:tag>  # verify locally",
            "kubectl delete pod -l app=api  # force re-pull after creds fix",
        ],
        "fix_diff": None,
    },
]


def main() -> None:
    print(f"\n🌱 REKALL Vault Seeder")
    print(f"   Vault path: {VAULT_PATH}/local/\n")

    for entry in ENTRIES:
        write_entry(entry, scope="local")

    # Print summary
    vault_dir = Path(VAULT_PATH) / "local"
    count = len(list(vault_dir.glob("*.json")))
    print(f"\n✅ Done — {count} entries in vault/local/")
    print("\nSignatures seeded:")
    for e in ENTRIES:
        print(f"  • {e['failure_signature']} ({e['failure_type']}, confidence={e['confidence']})")

    print(
        "\n💡 The pipeline will hit T1 for these scenarios. "
        "Delete a .json file to force T3 (RLM REPL) synthesis.\n"
    )


if __name__ == "__main__":
    main()
