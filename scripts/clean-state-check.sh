#!/usr/bin/env bash
# scripts/clean-state-check.sh — идемпотентная проверка чистого состояния
# перед завершением сессии (End of Session / Clock-out; L12 Clean State Protocol).
#
# Использование:
#   bash scripts/clean-state-check.sh                       # строгий режим (или: make clean-check)
#   bash scripts/clean-state-check.sh . feat-002,feat-003   # allowlist: фичи, сознательно остающиеся
#                                                           # active между сессиями многосессионной фичи
# Exit 0 — все проверки чистого состояния пройдены.
# ЗАПОЛНИТЬ: расширьте CHECK_DEBUG своими паттернами debug-артефактов проекта.

set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ALLOW="${2:-}"
cd "$ROOT"

PASS=0
FAIL=0

report() {
  if [ "$2" -eq 0 ]; then
    echo "  [PASS] $1"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $1"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Clean State Check ($ROOT) ==="

# 1. Инструкции для агента на месте
[ -f AGENTS.md ] || [ -f CLAUDE.md ]; report "Instructions file exists (AGENTS.md / CLAUDE.md)" $?

# 2. Стейт-артефакты на месте
[ -f feature_list.json ]; report "feature_list.json exists" $?
[ -f progress.md ]; report "progress.md exists" $?

# 3. feature_list.json валиден; активные фичи закрыты или в allowlist (многосессионная фича)
if command -v node >/dev/null 2>&1 && [ -f feature_list.json ]; then
  node -e '
    const fs = require("fs");
    const fl = JSON.parse(fs.readFileSync("feature_list.json", "utf8"));
    if (!Array.isArray(fl.features)) { console.error("invalid: features[] missing"); process.exit(1); }
    const active = fl.features.filter(f => f.state === "active");
    const allow = (process.argv[1] || "").split(",").map(s => s.trim()).filter(Boolean);
    const unallowed = active.filter(f => !allow.includes(f.id));
    if (unallowed.length > 0) {
      console.error("active feature(s) without planned continuation: " + unallowed.map(f => f.id).join(", "));
      console.error("close via make verify-feature F=<id>, or allow-list a multi-session feature:");
      console.error("  bash scripts/clean-state-check.sh . <id1,id2>");
      process.exit(1);
    }
    if (active.length > 0) {
      console.log("continuation planned for: " + active.map(f => f.id).join(", ") + " (multi-session feature)");
    }
  ' "$ALLOW"
  report "feature_list.json valid; active features closed or allow-listed" $?
else
  report "feature_list.json valid; active features closed or allow-listed" 1
fi

# 4. progress.md обновлялся (Last Updated не остался заглушкой)
if [ -f progress.md ] && ! grep -q '\*\*Last Updated:\*\* YYYY-MM-DD' progress.md; then
  report "progress.md has been updated (Last Updated is not a placeholder)" 0
else
  report "progress.md has been updated (Last Updated is not a placeholder)" 1
fi

# 5. Debug-артефакты (эвристика — дополните под свой проект)
CHECK_DEBUG=(-name '*.orig' -o -name '*.rej' -o -name '*.tmp' -o -name '*.log')
FOUND="$(find . -maxdepth 2 -not -path './.git/*' -not -path './node_modules/*' -not -path './target/*' -not -path './build/*' \( "${CHECK_DEBUG[@]}" \) -print -quit 2>/dev/null)"
[ -z "$FOUND" ]; report "no debug artifacts left (*.orig, *.rej, *.tmp, *.log)" $?

# 6. Стандартный путь верификации работает (главный критерий чистого состояния)
echo "  --- running ./init.sh (startup + verification path) ---"
bash ./init.sh >/dev/null 2>&1; report "./init.sh exits 0 (startup path works)" $?

echo ""
echo "Clean state: $PASS passed, $FAIL failed."
if [ "$FAIL" -eq 0 ]; then
  echo "Session state is clean — можно коммитить (см. templates/clean-state-checklist.md)."
  exit 0
else
  echo "Session state is NOT clean — устраните FAIL выше перед коммитом."
  exit 1
fi
