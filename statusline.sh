#!/usr/bin/env bash
# ==============================================================================
# Antigravity CLI Custom Statusline (Linux / WSL)
# Fast, bilingual (zh-tw / en), configurable, and clean statusline.
# ==============================================================================

set -u
export LC_NUMERIC=C

# ------------------------------------------------------------------------------
# 1. Defaults & CLI Arguments Parsing
# ------------------------------------------------------------------------------
VERSION="1.0.0"
CONFIG_FILE="${HOME}/.config/antigravity-statusline/statusline.conf"
CLI_LANG_OVERRIDE=""
CLI_COLS_OVERRIDE=""
TEST_INPUT_PAYLOAD=""

for ((i = 1; i <= $#; i++)); do
  arg="${!i}"
  case "$arg" in
    --version|-v)
      echo "Antigravity CLI Custom Statusline v${VERSION}"
      exit 0
      ;;
    --lang)
      next_idx=$((i + 1))
      if [ $next_idx -le $# ]; then
        CLI_LANG_OVERRIDE="${!next_idx}"
        i=$next_idx
      fi
      ;;
    --cols)
      next_idx=$((i + 1))
      if [ $next_idx -le $# ]; then
        CLI_COLS_OVERRIDE="${!next_idx}"
        i=$next_idx
      fi
      ;;
    --config)
      next_idx=$((i + 1))
      if [ $next_idx -le $# ]; then
        CONFIG_FILE="${!next_idx}"
        i=$next_idx
      fi
      ;;
    --test)
      next_idx=$((i + 1))
      if [ $next_idx -le $# ]; then
        TEST_INPUT_PAYLOAD="${!next_idx}"
        i=$next_idx
      fi
      ;;
  esac
done

# Load configuration file
LANGUAGE="zh-tw"
SHOW_BOX_BORDER=true
PROGRESS_BAR_STYLE="block"
LINE1_ITEMS=("state" "git" "model" "project")
BADGE_ITEMS=("context" "quota_5h" "quota_weekly" "ram" "cpu" "artifacts" "subagents" "bg_tasks")
SYS_RAM_WARN_PCT=80
SYS_LOAD_WARN=8.0
GIT_MAX_BRANCH_LEN=24
PROJECT_MAX_LEN=28
MODEL_MAX_LEN=26

# Search for config file: 1. user passed, 2. ~/.config, 3. script directory
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
elif [ -f "$(dirname "$0")/statusline.conf" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/statusline.conf"
fi

# CLI arguments override config
if [ -n "$CLI_LANG_OVERRIDE" ]; then
  LANGUAGE="$CLI_LANG_OVERRIDE"
fi

# ------------------------------------------------------------------------------
# 2. Bilingual Dictionary
# ------------------------------------------------------------------------------
get_text() {
  local key="$1"
  if [ "$LANGUAGE" = "en" ]; then
    case "$key" in
      state_ready)        echo "[READY]" ;;
      state_thinking)     echo "[THINKING]" ;;
      state_working)      echo "[WORKING]" ;;
      state_tool)         echo "[TOOL]" ;;
      state_unknown)      echo "[UNKNOWN]" ;;
      label_git)          echo "Git:" ;;
      label_dirty)        echo "*dirty" ;;
      label_clean)        echo "" ;;
      label_model)        echo "Model:" ;;
      label_project)      echo "Project:" ;;
      label_conv)         echo "Conv:" ;;
      label_context)      echo "Context:" ;;
      label_quota_5h)     echo "5H Quota:" ;;
      label_quota_weekly) echo "Weekly Quota:" ;;
      label_ram)          echo "RAM:" ;;
      label_cpu)          echo "CPU:" ;;
      label_artifacts)    echo "Artifacts:" ;;
      label_subagents)    echo "Subagents:" ;;
      label_tasks)        echo "Tasks:" ;;
      label_reset_in)     echo "reset in" ;;
      label_now)          echo "now" ;;
      *)                  echo "$key" ;;
    esac
  else
    case "$key" in
      state_ready)        echo "[就緒]" ;;
      state_thinking)     echo "[思考中]" ;;
      state_working)      echo "[處理中]" ;;
      state_tool)         echo "[工具執行]" ;;
      state_unknown)      echo "[未知]" ;;
      label_git)          echo "分支:" ;;
      label_dirty)        echo "*有變更" ;;
      label_clean)        echo "" ;;
      label_model)        echo "模型:" ;;
      label_project)      echo "專案:" ;;
      label_conv)         echo "對話:" ;;
      label_context)      echo "脈絡用量:" ;;
      label_quota_5h)     echo "5小時配額:" ;;
      label_quota_weekly) echo "每週配額:" ;;
      label_ram)          echo "RAM:" ;;
      label_cpu)          echo "CPU:" ;;
      label_artifacts)    echo "產出檔案:" ;;
      label_subagents)    echo "子代理:" ;;
      label_tasks)        echo "背景任務:" ;;
      label_reset_in)     echo "倒數" ;;
      label_now)          echo "即將重置" ;;
      *)                  echo "$key" ;;
    esac
  fi
}

# ------------------------------------------------------------------------------
# 3. ANSI Color Palettes & Helpers
# ------------------------------------------------------------------------------
C_RESET=$'\e[0m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'
C_GRAY=$'\e[90m'
C_WHITE=$'\e[97m'

# Four-tier truecolor styling
C_BLUE=$'\e[38;2;87;202;255m'
C_GREEN=$'\e[38;2;92;219;109m'
C_YELLOW=$'\e[38;2;255;212;39m'
C_RED=$'\e[38;2;255;125;175m'
C_CYAN=$'\e[38;2;116;220;220m'
C_MAGENTA=$'\e[38;2;210;140;255m'

# Strip ANSI escapes and calculate terminal display column width
visible_len() {
  local s="$1"
  s=$(printf '%s' "$s" | sed -E $'s/\e\\[[0-9;]*[a-zA-Z]//g')
  printf '%s' "$s" | wc -L
}

# Shorten string if length exceeds max_len
truncate_str() {
  local str="$1"
  local max_l="$2"
  if [ "${#str}" -gt "$max_l" ] && [ "$max_l" -gt 3 ]; then
    echo "${str:0:$((max_l - 3))}..."
  else
    echo "$str"
  fi
}

# Shorten path (e.g. ~/projects/...)
shorten_path() {
  local p="${1:-}"
  [ -z "$p" ] && return
  p="${p/#$HOME/\~}"
  if [ "${#p}" -gt "$PROJECT_MAX_LEN" ]; then
    echo ".../$(basename "$p")"
  else
    echo "$p"
  fi
}

# Human format for token counters (e.g., 149.3K, 1.0M)
format_tokens() {
  local n="${1:-0}"
  if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -le 0 ]; then
    echo "0"
    return
  fi
  if [ "$n" -ge 1000000 ]; then
    echo "$(( (n + 50000) / 1000000 )).$((( (n + 50000) % 1000000 ) / 100000 ))M"
  elif [ "$n" -ge 1000 ]; then
    echo "$(( (n + 50) / 1000 )).$((( (n + 50) % 1000 ) / 100 ))K"
  else
    echo "$n"
  fi
}

# Format seconds to human time (e.g., 2h15m, 3d)
format_reset_time() {
  local sec="${1:-0}"
  if ! [[ "$sec" =~ ^[0-9]+$ ]] || [ "$sec" -le 0 ]; then
    get_text "label_now"
    return
  fi
  local d=$(( sec / 86400 ))
  local rem=$(( sec % 86400 ))
  local h=$(( rem / 3600 ))
  rem=$(( rem % 3600 ))
  local m=$(( rem / 60 ))

  if [ "$d" -gt 0 ]; then
    [ "$h" -gt 0 ] && echo "${d}d ${h}h" || echo "${d}d"
  elif [ "$h" -gt 0 ]; then
    [ "$m" -gt 0 ] && echo "${h}h ${m}m" || echo "${h}h"
  elif [ "$m" -gt 0 ]; then
    echo "${m}m"
  else
    echo "<1m"
  fi
}

# Generate visual progress bar [██░░░░░░░░]
render_bar() {
  local pct="${1:-0}"       # 0 - 100 integer
  local bar_len="${2:-8}"   # number of bar segments
  local is_quota="${3:-0}"  # 0: context (higher is bad), 1: quota (higher is good)

  # Color logic
  local bar_color="$C_GREEN"
  if [ "$is_quota" -eq 1 ]; then
    if [ "$pct" -lt 25 ]; then bar_color="$C_RED";
    elif [ "$pct" -lt 50 ]; then bar_color="$C_YELLOW";
    elif [ "$pct" -lt 75 ]; then bar_color="$C_GREEN";
    else bar_color="$C_BLUE"; fi
  else
    if [ "$pct" -ge 85 ]; then bar_color="$C_RED";
    elif [ "$pct" -ge 65 ]; then bar_color="$C_YELLOW";
    elif [ "$pct" -ge 40 ]; then bar_color="$C_GREEN";
    else bar_color="$C_BLUE"; fi
  fi

  local filled=$(( pct * bar_len / 100 ))
  [ "$filled" -gt "$bar_len" ] && filled=$bar_len

  local bar=""
  if [ "$PROGRESS_BAR_STYLE" = "ascii" ]; then
    for ((b = 0; b < bar_len; b++)); do
      if [ "$b" -lt "$filled" ]; then bar="${bar}#"; else bar="${bar}-"; fi
    done
    printf "[%s%s%s]" "${bar_color}" "${bar}" "${C_RESET}"
  else
    for ((b = 0; b < bar_len; b++)); do
      if [ "$b" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
    done
    printf "[%s%s%s]" "${bar_color}" "${bar}" "${C_RESET}"
  fi
}

# ------------------------------------------------------------------------------
# 4. Ingest Stdin with 0.25s Timeout Protection
# ------------------------------------------------------------------------------
run_with_timeout() {
  local timeout_sec="0.25"
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_sec" "$@"
    return $?
  fi
  "$@" <&0 &
  local pid=$!
  (
    sleep "$timeout_sec" 2>/dev/null || sleep 1
    kill -TERM "$pid" 2>/dev/null || true
  ) >/dev/null 2>&1 &
  local timer_pid=$!
  wait "$pid" 2>/dev/null
  local res=$?
  kill -TERM "$timer_pid" 2>/dev/null || true
  return $res
}

my_in=$(readlink /proc/self/fd/0 2>/dev/null || true)
if [ -n "$TEST_INPUT_PAYLOAD" ] && [ -f "$TEST_INPUT_PAYLOAD" ]; then
  INPUT_JSON=$(cat "$TEST_INPUT_PAYLOAD" 2>/dev/null || echo "{}")
else
  INPUT_JSON=$(run_with_timeout cat 2>/dev/null || true)
  exec 0</dev/null
  if [ -z "$INPUT_JSON" ]; then
    if [[ "$my_in" =~ ^pipe: ]]; then
      for cpid in $(cat "/proc/$PPID/task/$PPID/children" 2>/dev/null); do
        if [ "$cpid" != "$$" ] && [ "$(readlink "/proc/$cpid/fd/1" 2>/dev/null)" = "$my_in" ]; then
          kill "$cpid" 2>/dev/null || true
        fi
      done
    fi
    INPUT_JSON="{}"
  fi
fi

# ------------------------------------------------------------------------------
# 5. Extract Metrics via Single-Pass jq
# ------------------------------------------------------------------------------
if command -v jq >/dev/null 2>&1; then
  # Parse all values in a single execution
  {
    read -r AGENT_STATE
    read -r MODEL_ID
    read -r MODEL_DISPLAY
    read -r CWD
    read -r CONV_ID
    read -r VCS_BRANCH
    read -r VCS_DIRTY
    read -r CTX_USED_PCT
    read -r CTX_USED_TOKENS
    read -r CTX_LIMIT_TOKENS
    read -r CTX_TOTAL_TOKENS
    read -r Q_GEMINI_5H
    read -r Q_GEMINI_5H_R
    read -r Q_GEMINI_WK
    read -r Q_GEMINI_WK_R
    read -r Q_3P_5H
    read -r Q_3P_5H_R
    read -r Q_3P_WK
    read -r Q_3P_WK_R
    read -r ARTIFACTS
    read -r SUBAGENTS
    read -r BG_TASKS
    read -r COLS
  } <<< "$(
    printf '%s' "$INPUT_JSON" | jq -r '
      (.agent_state // "idle"),
      (.model.id // ""),
      (.model.display_name // ""),
      (.cwd // ""),
      (.conversation_id // ""),
      (.vcs.branch // ""),
      (.vcs.dirty // false),
      (if (.context_window.used_percentage | type == "number") then (.context_window.used_percentage | round) else 0 end),
      (if (.context_window.used_percentage | type == "number") and .context_window.used_percentage > 0 and (.context_window.context_window_size // 0) > 0 then
        ((.context_window.used_percentage * .context_window.context_window_size / 100) | round)
      elif (.context_window.total_tokens | type == "number") and .context_window.total_tokens > 0 then
        .context_window.total_tokens
      else
        ((if (.context_window.total_input_tokens | type == "number") then .context_window.total_input_tokens else 0 end) +
         (if (.context_window.total_output_tokens | type == "number") then .context_window.total_output_tokens else 0 end))
      end),
      (.context_window.context_window_size // 0),
      (if (.context_window.total_tokens | type == "number") and .context_window.total_tokens > 0 then
        .context_window.total_tokens
      else
        ((if (.context_window.total_input_tokens | type == "number") then .context_window.total_input_tokens else 0 end) +
         (if (.context_window.total_output_tokens | type == "number") then .context_window.total_output_tokens else 0 end))
      end),
      (if .quota["gemini-5h"].remaining_fraction != null then (.quota["gemini-5h"].remaining_fraction * 100 | round) else -1 end),
      (.quota["gemini-5h"].reset_in_seconds // -1),
      (if .quota["gemini-weekly"].remaining_fraction != null then (.quota["gemini-weekly"].remaining_fraction * 100 | round) else -1 end),
      (.quota["gemini-weekly"].reset_in_seconds // -1),
      (if .quota["3p-5h"].remaining_fraction != null then (.quota["3p-5h"].remaining_fraction * 100 | round) else -1 end),
      (.quota["3p-5h"].reset_in_seconds // -1),
      (if .quota["3p-weekly"].remaining_fraction != null then (.quota["3p-weekly"].remaining_fraction * 100 | round) else -1 end),
      (.quota["3p-weekly"].reset_in_seconds // -1),
      (.artifact_count // 0),
      (if .subagents | type == "array" then (.subagents | length) else 0 end),
      (.task_count // 0),
      (.terminal_width // 80)
    ' 2>/dev/null || printf "idle\n\n\n\n\n\nfalse\n0\n0\n0\n0\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n0\n0\n0\n80\n"
  )"
else
  AGENT_STATE="idle"
  MODEL_ID=""
  MODEL_DISPLAY=""
  CWD=""
  CONV_ID=""
  VCS_BRANCH=""
  VCS_DIRTY="false"
  CTX_USED_PCT="0"
  CTX_USED_TOKENS="0"
  CTX_LIMIT_TOKENS="0"
  CTX_TOTAL_TOKENS="0"
  Q_GEMINI_5H="-1"
  Q_GEMINI_5H_R="-1"
  Q_GEMINI_WK="-1"
  Q_GEMINI_WK_R="-1"
  Q_3P_5H="-1"
  Q_3P_5H_R="-1"
  Q_3P_WK="-1"
  Q_3P_WK_R="-1"
  ARTIFACTS="0"
  SUBAGENTS="0"
  BG_TASKS="0"
  COLS="80"
fi

# Override columns if set
if [ -n "$CLI_COLS_OVERRIDE" ]; then
  COLS="$CLI_COLS_OVERRIDE"
elif [ -n "${COLUMNS:-}" ] && [ "$COLUMNS" -gt 0 ] 2>/dev/null; then
  COLS="$COLUMNS"
fi
if ! [[ "$COLS" =~ ^[0-9]+$ ]] || [ "$COLS" -lt 40 ]; then COLS=80; fi

# ------------------------------------------------------------------------------
# 6. Local Telemetry (/proc & git fallback)
# ------------------------------------------------------------------------------
# System RAM from /proc/meminfo
MEM_PCT=""
if [ -f /proc/meminfo ]; then
  mem_total=0
  mem_avail=0
  while read -r name val unit; do
    if [ "$name" = "MemTotal:" ]; then mem_total=$val;
    elif [ "$name" = "MemAvailable:" ]; then mem_avail=$val; break; fi
  done < /proc/meminfo
  if [ "$mem_total" -gt 0 ]; then
    MEM_PCT=$(( (mem_total - mem_avail) * 100 / mem_total ))
  fi
fi

# CPU Usage Percentage from /proc/stat delta
CPU_PCT=""
if [ -f /proc/stat ]; then
  cpu_cache="/tmp/agy_cpu_stat"
  read -r _ u n s id io irq sirq st rest < /proc/stat
  cur_total=$(( u + n + s + id + io + irq + sirq + st ))
  cur_idle=$(( id + io ))
  if [ -f "$cpu_cache" ]; then
    read -r prev_total prev_idle < "$cpu_cache" 2>/dev/null || true
    diff_total=$(( cur_total - prev_total ))
    diff_idle=$(( cur_idle - prev_idle ))
    if [ "$diff_total" -gt 0 ]; then
      CPU_PCT=$(( (diff_total - diff_idle) * 100 / diff_total ))
    else
      CPU_PCT=0
    fi
  else
    CPU_PCT=0
  fi
  echo "$cur_total $cur_idle" > "$cpu_cache" 2>/dev/null || true
fi

# Git Fallback
if [ -z "$VCS_BRANCH" ]; then
  git_dir="${CWD:-.}"
  b=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [ -n "$b" ]; then
    VCS_BRANCH="$b"
    if git -C "$git_dir" status --porcelain 2>/dev/null | grep -q .; then
      VCS_DIRTY="true"
    else
      VCS_DIRTY="false"
    fi
  fi
fi

# Model priority selection for Quota
MODEL_NAME="${MODEL_DISPLAY:-$MODEL_ID}"
IS_3P=false
case "$MODEL_ID" in
  *[Cc][Ll][Aa][Uu][Dd][Ee]*|*[Gg][Pp][Tt]*|*3[Pp]*|*[Oo]1*|*[Oo]3*|*[Aa][Nn][Tt][Hh][Rr][Oo][Pp][Ii][Cc]*)
    IS_3P=true
    ;;
esac

if [ "$IS_3P" = true ] && [ "$Q_3P_5H" != "-1" ]; then
  Q_5H="$Q_3P_5H"; Q_5H_R="$Q_3P_5H_R"
  Q_WK="$Q_3P_WK"; Q_WK_R="$Q_3P_WK_R"
elif [ "$Q_GEMINI_5H" != "-1" ]; then
  Q_5H="$Q_GEMINI_5H"; Q_5H_R="$Q_GEMINI_5H_R"
  Q_WK="$Q_GEMINI_WK"; Q_WK_R="$Q_GEMINI_WK_R"
elif [ "$Q_3P_5H" != "-1" ]; then
  Q_5H="$Q_3P_5H"; Q_5H_R="$Q_3P_5H_R"
  Q_WK="$Q_3P_WK"; Q_WK_R="$Q_3P_WK_R"
else
  Q_5H="-1"; Q_5H_R="-1"
  Q_WK="-1"; Q_WK_R="-1"
fi

# ------------------------------------------------------------------------------
# 7. Assemble LINE 1 (Core Session Bar)
# ------------------------------------------------------------------------------
LINE1_PARTS=()

for item in "${LINE1_ITEMS[@]}"; do
  case "$item" in
    state)
      state_label=""
      state_color="$C_GREEN"
      case "$AGENT_STATE" in
        idle|ready)
          state_label=$(get_text "state_ready")
          state_color="$C_GREEN"
          ;;
        thinking)
          state_label=$(get_text "state_thinking")
          state_color="$C_YELLOW"
          ;;
        working)
          state_label=$(get_text "state_working")
          state_color="$C_CYAN"
          ;;
        tool_use|tool)
          state_label=$(get_text "state_tool")
          state_color="$C_MAGENTA"
          ;;
        *)
          state_label=$(get_text "state_unknown")
          state_color="$C_GRAY"
          ;;
      esac
      LINE1_PARTS+=("${state_color}${C_BOLD}${state_label}${C_RESET}")
      ;;

    git)
      if [ -n "$VCS_BRANCH" ]; then
        b_disp=$(truncate_str "$VCS_BRANCH" "$GIT_MAX_BRANCH_LEN")
        if [ "$VCS_DIRTY" = "true" ]; then
          dirty_str=$(get_text "label_dirty")
          [ -n "$dirty_str" ] && dirty_str=" ${dirty_str}"
          LINE1_PARTS+=("${C_WHITE}$(get_text "label_git") ${C_RED}${C_BOLD}${b_disp}${dirty_str}${C_RESET}")
        else
          LINE1_PARTS+=("${C_WHITE}$(get_text "label_git") ${C_BLUE}${C_BOLD}${b_disp}${C_RESET}")
        fi
      fi
      ;;

    model)
      if [ -n "$MODEL_NAME" ]; then
        m_disp=$(truncate_str "$MODEL_NAME" "$MODEL_MAX_LEN")
        LINE1_PARTS+=("${C_WHITE}$(get_text "label_model") ${C_CYAN}${C_BOLD}${m_disp}${C_RESET}")
      fi
      ;;

    project)
      p_disp=$(shorten_path "$CWD")
      if [ -n "$p_disp" ]; then
        LINE1_PARTS+=("${C_WHITE}$(get_text "label_project") ${C_BOLD}${p_disp}${C_RESET}")
      fi
      ;;

    conv_id)
      if [ -n "$CONV_ID" ]; then
        LINE1_PARTS+=("${C_GRAY}$(get_text "label_conv") ${CONV_ID:0:8}${C_RESET}")
      fi
      ;;
  esac
done

# Join Line 1 with Dim Separators
LINE1_CONTENT=""
sep=" ${C_GRAY}│${C_RESET} "
for part in "${LINE1_PARTS[@]}"; do
  if [ -z "$LINE1_CONTENT" ]; then
    LINE1_CONTENT="$part"
  else
    LINE1_CONTENT="${LINE1_CONTENT}${sep}${part}"
  fi
done

# ------------------------------------------------------------------------------
# 8. Assemble LINE 2+ Badges (Dynamic Line Packing)
# ------------------------------------------------------------------------------
ACTIVE_BADGES=()

for badge_name in "${BADGE_ITEMS[@]}"; do
  case "$badge_name" in
    context)
      # Context Progress Bar
      ctx_int=${CTX_USED_PCT%.*}
      ctx_int=${ctx_int:-0}
      bar_str=$(render_bar "$ctx_int" 8 0)
      
      tok_str=""
      if [ "$CTX_USED_TOKENS" -gt 0 ] 2>/dev/null && [ "$CTX_LIMIT_TOKENS" -gt 0 ] 2>/dev/null; then
        if [ "${CTX_TOTAL_TOKENS:-0}" -gt 0 ] 2>/dev/null; then
          tok_str=" (${C_GRAY}$(format_tokens "$CTX_USED_TOKENS")/$(format_tokens "$CTX_LIMIT_TOKENS") | Σ$(format_tokens "$CTX_TOTAL_TOKENS")${C_RESET})"
        else
          tok_str=" (${C_GRAY}$(format_tokens "$CTX_USED_TOKENS")/$(format_tokens "$CTX_LIMIT_TOKENS")${C_RESET})"
        fi
      fi
      
      ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_context") ${bar_str} ${C_BOLD}${ctx_int}%${C_RESET}${tok_str}")
      ;;

    quota_5h)
      if [ -n "$Q_5H" ] && [ "$Q_5H" != "-1" ]; then
        q_int=${Q_5H%.*}
        bar_str=$(render_bar "$q_int" 8 1)
        r_str=""
        if [ "$Q_5H_R" != "-1" ] && [ "$Q_5H_R" -gt 0 ]; then
          r_str=" (${C_GRAY}$(get_text "label_reset_in") ${C_BLUE}$(format_reset_time "$Q_5H_R")${C_RESET})"
        fi
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_quota_5h") ${bar_str} ${C_BOLD}${q_int}%${C_RESET}${r_str}")
      fi
      ;;

    quota_weekly)
      if [ -n "$Q_WK" ] && [ "$Q_WK" != "-1" ]; then
        qw_int=${Q_WK%.*}
        bar_str=$(render_bar "$qw_int" 8 1)
        r_str=""
        if [ "$Q_WK_R" != "-1" ] && [ "$Q_WK_R" -gt 0 ]; then
          r_str=" (${C_GRAY}$(get_text "label_reset_in") ${C_BLUE}$(format_reset_time "$Q_WK_R")${C_RESET})"
        fi
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_quota_weekly") ${bar_str} ${C_BOLD}${qw_int}%${C_RESET}${r_str}")
      fi
      ;;

    ram)
      if [ -n "$MEM_PCT" ]; then
        ram_c="$C_GREEN"
        if [ "$MEM_PCT" -ge "$SYS_RAM_WARN_PCT" ]; then ram_c="$C_RED";
        elif [ "$MEM_PCT" -ge 60 ]; then ram_c="$C_YELLOW"; fi
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_ram") ${ram_c}${C_BOLD}${MEM_PCT}%${C_RESET}")
      fi
      ;;

    cpu)
      if [ -n "$CPU_PCT" ]; then
        cpu_c="$C_GREEN"
        if [ "$CPU_PCT" -ge 85 ]; then cpu_c="$C_RED";
        elif [ "$CPU_PCT" -ge 60 ]; then cpu_c="$C_YELLOW"; fi
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_cpu") ${cpu_c}${C_BOLD}${CPU_PCT}%${C_RESET}")
      fi
      ;;

    artifacts)
      if [ "${ARTIFACTS:-0}" -gt 0 ] 2>/dev/null; then
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_artifacts") ${C_CYAN}${C_BOLD}${ARTIFACTS}${C_RESET}")
      fi
      ;;

    subagents)
      if [ "${SUBAGENTS:-0}" -gt 0 ] 2>/dev/null; then
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_subagents") ${C_YELLOW}${C_BOLD}${SUBAGENTS}${C_RESET}")
      fi
      ;;

    bg_tasks)
      if [ "${BG_TASKS:-0}" -gt 0 ] 2>/dev/null; then
        ACTIVE_BADGES+=("${C_WHITE}$(get_text "label_tasks") ${C_MAGENTA}${C_BOLD}${BG_TASKS}${C_RESET}")
      fi
      ;;
  esac
done

# Greedy Line-Packing for Badges
PACKED_LINES=()
curr_line=""
curr_vis=0
max_vis=$(( COLS - 4 ))
[ "$max_vis" -lt 40 ] && max_vis=40

for badge in "${ACTIVE_BADGES[@]}"; do
  [ -z "$badge" ] && continue
  b_vis=$(visible_len "$badge")
  
  if [ -z "$curr_line" ]; then
    curr_line="$badge"
    curr_vis=$b_vis
  elif [ $(( curr_vis + 3 + b_vis )) -le "$max_vis" ]; then
    curr_line="${curr_line}   ${badge}"
    curr_vis=$(( curr_vis + 3 + b_vis ))
  else
    PACKED_LINES+=("$curr_line")
    curr_line="$badge"
    curr_vis=$b_vis
  fi
done
[ -n "$curr_line" ] && PACKED_LINES+=("$curr_line")

# ------------------------------------------------------------------------------
# 9. Output Rendering
# ------------------------------------------------------------------------------
if [ "$SHOW_BOX_BORDER" = "true" ]; then
  # Header
  printf "%s╭─%s %s\n" "${C_GRAY}" "${C_RESET}" "${LINE1_CONTENT}"
  
  total_packed=${#PACKED_LINES[@]}
  for ((idx = 0; idx < total_packed; idx++)); do
    if [ "$((idx + 1))" -eq "$total_packed" ]; then
      printf "%s╰─%s %s\n" "${C_GRAY}" "${C_RESET}" "${PACKED_LINES[idx]}"
    else
      printf "%s├─%s %s\n" "${C_GRAY}" "${C_RESET}" "${PACKED_LINES[idx]}"
    fi
  done
else
  printf "%s\n" "${LINE1_CONTENT}"
  for pline in "${PACKED_LINES[@]}"; do
    printf "%s\n" "${pline}"
  done
fi

exit 0
