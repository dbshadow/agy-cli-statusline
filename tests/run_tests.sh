#!/usr/bin/env bash
# ==============================================================================
# Automated Test Suite for Custom Statusline
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATUSLINE="${PROJECT_ROOT}/statusline.sh"
FIXTURE_FULL="${SCRIPT_DIR}/fixtures/full_payload.json"
FIXTURE_MIN="${SCRIPT_DIR}/fixtures/minimal_payload.json"

PASS_COUNT=0
FAIL_COUNT=0

strip_ansi() {
  printf '%s' "$1" | sed -E $'s/\e\\[[0-9;]*[a-zA-Z]//g'
}

assert_contains() {
  local title="$1"
  local raw_output="$2"
  local pattern="$3"
  local clean_output
  clean_output=$(strip_ansi "$raw_output")
  
  if echo "$clean_output" | grep -Fq -- "$pattern"; then
    echo -e "\033[32m✓\033[0m PASS: ${title}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "\033[31m✗\033[0m FAIL: ${title} (expected to contain '${pattern}')"
    echo -e "Output was:\n$clean_output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_not_contains() {
  local title="$1"
  local raw_output="$2"
  local pattern="$3"
  local clean_output
  clean_output=$(strip_ansi "$raw_output")
  
  if ! echo "$clean_output" | grep -Fq -- "$pattern"; then
    echo -e "\033[32m✓\033[0m PASS: ${title}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "\033[31m✗\033[0m FAIL: ${title} (expected NOT to contain '${pattern}')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "================================================================================"
echo "Running Custom Statusline Test Suite..."
echo "================================================================================"

# 1. Traditional Chinese rendering test
out_zhtw=$("${STATUSLINE}" --test "${FIXTURE_FULL}" --lang zh-tw --cols 120)
assert_contains "Traditional Chinese: State badge" "$out_zhtw" "[處理中]"
assert_contains "Traditional Chinese: Model label" "$out_zhtw" "模型: Gemini 2.0 Flash"
assert_contains "Traditional Chinese: Context label" "$out_zhtw" "脈絡用量:"
assert_contains "Traditional Chinese: Quota label" "$out_zhtw" "5小時配額:"
assert_contains "Traditional Chinese: Artifacts count" "$out_zhtw" "產出檔案: 3"
assert_contains "Traditional Chinese: Subagents count" "$out_zhtw" "子代理: 2"
assert_contains "Traditional Chinese: Tasks count" "$out_zhtw" "背景任務: 2"
assert_contains "Traditional Chinese: Box border header" "$out_zhtw" "╭─"
assert_contains "Traditional Chinese: Box border footer" "$out_zhtw" "╰─"

# 2. English rendering test
out_en=$("${STATUSLINE}" --test "${FIXTURE_FULL}" --lang en --cols 120)
assert_contains "English: State badge" "$out_en" "[WORKING]"
assert_contains "English: Model label" "$out_en" "Model: Gemini 2.0 Flash"
assert_contains "English: Context label" "$out_en" "Context:"
assert_contains "English: Quota label" "$out_en" "5H Quota:"
assert_contains "English: Artifacts count" "$out_en" "Artifacts: 3"
assert_contains "English: Subagents count" "$out_en" "Subagents: 2"
assert_contains "English: Tasks count" "$out_en" "Tasks: 2"

# 3. Minimal payload zero-suppression test
out_min=$("${STATUSLINE}" --test "${FIXTURE_MIN}" --lang zh-tw)
assert_contains "Minimal: Idle state" "$out_min" "[就緒]"
assert_not_contains "Minimal: Subagents hidden when zero" "$out_min" "子代理:"
assert_not_contains "Minimal: Tasks hidden when zero" "$out_min" "背景任務:"
assert_not_contains "Minimal: Artifacts hidden when zero" "$out_min" "產出檔案:"

# 4. Narrow terminal wrapping test (cols = 75)
out_narrow=$("${STATUSLINE}" --test "${FIXTURE_FULL}" --cols 75)
line_count=$(echo "$out_narrow" | wc -l)
if [ "$line_count" -ge 3 ]; then
  echo -e "\033[32m✓\033[0m PASS: Narrow terminal wrapped across multiple lines (count: $line_count)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "\033[31m✗\033[0m FAIL: Narrow terminal did not wrap properly"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 5. Stdin timeout guard test via FIFO
FIFO=$(mktemp -u)
mkfifo "$FIFO"
( sleep 5 > "$FIFO" ) 2>/dev/null &
WRITER_PID=$!

start_s=$(date +%s%N)
out_timeout=$("${STATUSLINE}" < "$FIFO" 2>&1 || true)
end_s=$(date +%s%N)
elapsed_ms=$(( (end_s - start_s) / 1000000 ))

kill "$WRITER_PID" 2>/dev/null || true
wait "$WRITER_PID" 2>/dev/null || true
rm -f "$FIFO"

if [ "$elapsed_ms" -lt 1500 ]; then
  echo -e "\033[32m✓\033[0m PASS: Stdin timeout guard terminated within deadline (${elapsed_ms}ms < 1500ms)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "\033[31m✗\033[0m FAIL: Stdin timeout took too long (${elapsed_ms}ms)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo "================================================================================"
echo "Test Summary: ${PASS_COUNT} Passed, ${FAIL_COUNT} Failed"
echo "================================================================================"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi

exit 0
