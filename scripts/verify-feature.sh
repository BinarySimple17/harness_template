#!/usr/bin/env bash
# scripts/verify-feature.sh <feature-id> — харнесс-гейт фичи (см. Feature State Rules в AGENTS.md).
#
# Что делает:
#   1. Берёт фичу из feature_list.json по id.
#   2. Проверяет, что она активна (state=active) — skipping states запрещён.
#   3. Прогоняет её verification-команду.
#   4. При exit 0 переводит фичу в state=passing и записывает evidence.
#
# Использование:
#   bash scripts/verify-feature.sh feat-001      # или: make verify-feature F=feat-001
#
# Требования: bash, node (для чтения/обновления feature_list.json).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FL="$ROOT/feature_list.json"
ID="${1:-}"

if [ -z "$ID" ]; then
  echo "Usage: bash scripts/verify-feature.sh <feature-id>"
  echo "Example: bash scripts/verify-feature.sh feat-001"
  exit 2
fi

if [ ! -f "$FL" ]; then
  echo "ERROR: feature_list.json not found at $FL" >&2
  exit 2
fi

command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required (для разбора feature_list.json)." >&2; exit 2; }

STATE="$(node -e '
  const fs = require("fs");
  const fl = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const f = (fl.features || []).find(x => x.id === process.argv[2]);
  console.log(f ? (f.state || "") : "__MISSING__");
' "$FL" "$ID")"

if [ "$STATE" = "__MISSING__" ]; then
  echo "ERROR: feature '$ID' not found in feature_list.json" >&2
  exit 2
fi

if [ "$STATE" = "passing" ]; then
  echo "OK: feature $ID is already passing."
  exit 0
fi

if [ "$STATE" != "active" ]; then
  echo "BLOCKED: feature $ID has state='$STATE'."
  echo "Only an active feature can be verified. Set state=active first (not_started → active → passing, no skipping)."
  exit 2
fi

CMD="$(node -e '
  const fs = require("fs");
  const fl = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const f = (fl.features || []).find(x => x.id === process.argv[2]);
  console.log((f && f.verification) || "");
' "$FL" "$ID")"

if [ -z "$CMD" ]; then
  echo "ERROR: feature $ID has no 'verification' command in feature_list.json." >&2
  exit 2
fi

echo "=== Verifying feature $ID: $CMD ==="
RC=0
bash -c "$CMD" || RC=$?

if [ "$RC" -ne 0 ]; then
  echo ""
  echo "FAIL: verification for $ID exited with code $RC. State stays 'active'."
  echo "--- How to fix (repair hint from feature_list.json) ---"
  node -e '
    const fs = require("fs");
    const fl = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const f = (fl.features || []).find(x => x.id === process.argv[2]);
    const l = (f && Array.isArray(f.layers) && f.layers.find(x => x && x.repair)) || {};
    console.log(l.repair || "No repair hint recorded. Fix the failing output above and re-run.");
  ' "$FL" "$ID"
  exit 1
fi

TS="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
node -e '
  const fs = require("fs");
  const [, flPath, id, cmd, ts] = process.argv;
  const fl = JSON.parse(fs.readFileSync(flPath, "utf8"));
  const f = (fl.features || []).find(x => x.id === id);
  if (!f) { console.error("feature not found: " + id); process.exit(1); }
  f.state = "passing";
  f.status = "done";
  f.evidence = "command \u00ab" + cmd + "\u00bb exited 0 at " + ts + " (scripts/verify-feature.sh)";
  fs.writeFileSync(flPath, JSON.stringify(fl, null, 2) + "\n");
' "$FL" "$ID" "$CMD" "$TS"

echo ""
echo "PASS: feature $ID → state=passing."
echo "Evidence recorded in feature_list.json. Не забудьте обновить progress.md (End of Session)."
