#!/usr/bin/env bash
set -euo pipefail

VERSION="1.2.0"
errors=0

fail() {
  echo "[!!] $1"
  errors=$((errors + 1))
}

ok() {
  echo "[OK] $1"
}

check_file() {
  if [ -f "$1" ]; then
    ok "found $1"
  else
    fail "missing $1"
  fi
}

check_contains() {
  file="$1"
  pattern="$2"
  label="$3"
  if grep -Eq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_frontmatter() {
  file="$1"
  first_line="$(sed -n '1p' "$file")"
  if [ "$first_line" = "---" ]; then
    ok "frontmatter: $file"
  else
    fail "missing YAML frontmatter: $file"
  fi
}

echo "codex-handoff release verification"
echo "==================================="

bytes="$(wc -c < skills/codex-handoff/SKILL.md | tr -d ' ')"
if [ "$bytes" -lt 5120 ]; then
  ok "stable SKILL.md under 5KB ($bytes bytes)"
else
  fail "stable SKILL.md too large ($bytes bytes)"
fi

lines="$(wc -l < commands/codex-handoff.md | tr -d ' ')"
if [ "$lines" -lt 15 ]; then
  ok "command file under 15 lines ($lines lines)"
else
  fail "command file too long ($lines lines)"
fi

check_frontmatter "skills/codex-handoff/SKILL.md"
check_frontmatter "commands/codex-handoff.md"
check_frontmatter "plugins/codex-handoff-codex/skills/codex-handoff-direct/SKILL.md"

bash -n install.sh uninstall.sh scripts/verify-install.sh scripts/verify-release.sh
ok "shell syntax"

check_contains "skills/codex-handoff/SKILL.md" "version: ${VERSION}" "stable skill version ${VERSION}"
check_contains "openclaw.yaml" "version: ${VERSION}" "OpenClaw version ${VERSION}"
check_contains "README.md" "version-${VERSION}-blue" "README badge ${VERSION}"
check_contains "CHANGELOG.md" "\\[${VERSION}\\]" "changelog ${VERSION}"
check_contains "plugins/codex-handoff-codex/.codex-plugin/plugin.json" "\"version\": \"${VERSION}\"" "Codex plugin version ${VERSION}"

check_file "plugins/codex-handoff-codex/.codex-plugin/plugin.json"
check_file "plugins/codex-handoff-codex/skills/codex-handoff-direct/SKILL.md"
check_file "plugins/codex-handoff-codex/skills/codex-handoff-direct/agents/openai.yaml"
check_file ".agents/plugins/marketplace.json"
check_file "evals/evals.json"
check_file "docs/releases/1.2.0-verification.md"

if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool plugins/codex-handoff-codex/.codex-plugin/plugin.json >/dev/null
  python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
  python3 -m json.tool evals/evals.json >/dev/null
  ok "JSON files parse"
else
  fail "python3 missing; cannot validate JSON files"
fi

flag_prefix="full"
flag_suffix="auto"
model_prefix="o4"
model_suffix="mini"
npm_install="npm install"
global_flag="-g"
codex_token_prefix="CODEX"
phase_token_prefix="PHASE"
complete_token_suffix="COMPLETE"
codex_dir="\\.codex"
agents_file="AGENTS"
stale_pattern="${flag_prefix}-${flag_suffix}|${model_prefix}-${model_suffix}|${npm_install} ${global_flag}|${codex_token_prefix}_${complete_token_suffix}|${phase_token_prefix}_${complete_token_suffix}|${codex_dir}/${agents_file}"

if rg -n "$stale_pattern" \
  README.md skills/codex-handoff commands scripts plugins evals examples/simple/README.md; then
  fail "stale workflow pattern found"
else
  ok "stale workflow pattern scan"
fi

if rg -n "(BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,})" \
  README.md CHANGELOG.md openclaw.yaml commands scripts skills plugins evals docs examples; then
  fail "possible secret pattern found"
else
  ok "secret pattern scan"
fi

echo "==================================="
if [ "$errors" -eq 0 ]; then
  echo "All release checks passed."
else
  echo "$errors release issue(s) found."
  exit 1
fi
