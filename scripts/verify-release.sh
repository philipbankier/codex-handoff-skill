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

run_install_verifier_smoke() {
  tmp_home="$(mktemp -d)"
  verify_log="$tmp_home/verify-install-negative.log"
  mkdir -p "$tmp_home/.claude/skills" "$tmp_home/.claude/commands"

  if HOME="$tmp_home" bash scripts/verify-install.sh >"$verify_log" 2>&1; then
    fail "verify-install returned zero with missing Claude links"
  elif grep -q "skill not installed" "$verify_log" \
    && grep -q "command not installed" "$verify_log"; then
    ok "verify-install fails when required Claude links are missing"
  else
    fail "verify-install negative case did not report missing Claude links"
  fi

  rm -rf "$tmp_home"
  tmp_home="$(mktemp -d)"

  if HOME="$tmp_home" bash install.sh --platform=all >/dev/null 2>&1; then
    ok "temp install --platform=all"
  else
    fail "temp install --platform=all"
    rm -rf "$tmp_home"
    return
  fi

  if HOME="$tmp_home" bash scripts/verify-install.sh >/dev/null 2>&1; then
    ok "verify-install passes after temp install"
  else
    fail "verify-install after temp install"
  fi

  if HOME="$tmp_home" bash uninstall.sh --platform=all >/dev/null 2>&1; then
    if [ -L "$tmp_home/.claude/skills/codex-handoff" ] \
      || [ -L "$tmp_home/.claude/commands/codex-handoff.md" ] \
      || [ -L "$tmp_home/.openclaw/skills/codex-handoff" ]; then
      fail "temp uninstall left codex-handoff symlinks"
    else
      ok "temp uninstall removes symlinks"
    fi
  else
    fail "temp uninstall --platform=all"
  fi

  rm -rf "$tmp_home"
}

run_codex_plugin_smoke() {
  if ! command -v codex >/dev/null 2>&1; then
    fail "codex missing; cannot verify plugin install"
    return
  fi

  tmp_codex_home="$(mktemp -d)"
  plugin_list="$tmp_codex_home/plugin-list.json"

  if CODEX_HOME="$tmp_codex_home" codex plugin marketplace add ./ >/dev/null 2>&1; then
    ok "Codex plugin marketplace add"
  else
    fail "Codex plugin marketplace add"
    rm -rf "$tmp_codex_home"
    return
  fi

  if CODEX_HOME="$tmp_codex_home" codex plugin add codex-handoff-codex@codex-handoff-local --json >/dev/null 2>&1; then
    ok "Codex plugin add"
  else
    fail "Codex plugin add"
    rm -rf "$tmp_codex_home"
    return
  fi

  if CODEX_HOME="$tmp_codex_home" codex plugin list --json >"$plugin_list" 2>/dev/null \
    && python3 - "$plugin_list" "$VERSION" <<'PY'
import json
import sys

path, version = sys.argv[1], sys.argv[2]
data = json.load(open(path, encoding="utf-8"))
for plugin in data.get("installed", []):
    if (
        plugin.get("pluginId") == "codex-handoff-codex@codex-handoff-local"
        and plugin.get("version") == version
        and plugin.get("enabled") is True
    ):
        sys.exit(0)
sys.exit(1)
PY
  then
    ok "Codex plugin list shows ${VERSION} enabled"
  else
    fail "Codex plugin list missing enabled ${VERSION} install"
  fi

  rm -rf "$tmp_codex_home"
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
stale_files="$(mktemp)"
stale_output="$(mktemp)"
git ls-files README.md CHANGELOG.md openclaw.yaml commands scripts skills plugins evals docs examples implementation-planning-notes.html >"$stale_files"

if xargs rg -n "$stale_pattern" <"$stale_files" >"$stale_output"; then
  cat "$stale_output"
  fail "stale workflow pattern found"
else
  stale_rc=$?
  if [ "$stale_rc" -eq 1 ]; then
    ok "stale workflow pattern scan"
  else
    cat "$stale_output"
    fail "stale workflow pattern scan errored"
  fi
fi
rm -f "$stale_files" "$stale_output"

secret_output="$(mktemp)"
if rg -n "(BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,})" \
  README.md CHANGELOG.md openclaw.yaml commands scripts skills plugins evals docs examples >"$secret_output"; then
  cat "$secret_output"
  fail "possible secret pattern found"
else
  secret_rc=$?
  if [ "$secret_rc" -eq 1 ]; then
    ok "secret pattern scan"
  else
    cat "$secret_output"
    fail "secret pattern scan errored"
  fi
fi
rm -f "$secret_output"

run_install_verifier_smoke
run_codex_plugin_smoke

echo "==================================="
if [ "$errors" -eq 0 ]; then
  echo "All release checks passed."
else
  echo "$errors release issue(s) found."
  exit 1
fi
