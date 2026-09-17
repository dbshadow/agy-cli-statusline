#!/usr/bin/env bash
# ==============================================================================
# Antigravity CLI Custom Statusline Uninstaller
# Cleanly restores settings.json and removes deployed statusline files.
# ==============================================================================

set -euo pipefail

INSTALL_DIR="${HOME}/.antigravity"
CONFIG_DIR="${HOME}/.config/antigravity-statusline"
CLI_SETTINGS="${HOME}/.gemini/antigravity-cli/settings.json"

C_GREEN="\033[1;32m"
C_BLUE="\033[1;34m"
C_YELLOW="\033[1;33m"
REMOVE_CONFIG=false

for arg in "$@"; do
  case "$arg" in
    -a|--all)
      REMOVE_CONFIG=true
      ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -a, --all    Also remove configuration directory (~/.config/antigravity-statusline)"
      echo "  -h, --help   Show this help message"
      exit 0
      ;;
  esac
done

echo -e "${C_BLUE}==>${C_RESET} 開始解除安裝 Antigravity CLI 狀態列..."

# 1. 還原 settings.json
if [ -f "${CLI_SETTINGS}" ] && command -v jq >/dev/null 2>&1; then
  BAK_FILE="${CLI_SETTINGS}.bak.uninstall.$(date +%Y%m%d%H%M%S)"
  cp "${CLI_SETTINGS}" "${BAK_FILE}"
  
  TMP_SETTINGS=$(mktemp "${CLI_SETTINGS}.tmp.XXXXXX")
  jq 'del(.statusLine)' "${CLI_SETTINGS}" > "${TMP_SETTINGS}"
  mv "${TMP_SETTINGS}" "${CLI_SETTINGS}"
  echo -e "${C_GREEN}✓${C_RESET} 已從 settings.json 移除 statusLine 設定 (備份於: ${BAK_FILE})"
fi

# 2. 移除安裝檔
if [ -f "${INSTALL_DIR}/statusline.sh" ]; then
  rm -f "${INSTALL_DIR}/statusline.sh"
  echo -e "${C_GREEN}✓${C_RESET} 已刪除 ${INSTALL_DIR}/statusline.sh"
fi

if [ -f "${INSTALL_DIR}/uninstall.sh" ]; then
  rm -f "${INSTALL_DIR}/uninstall.sh"
  echo -e "${C_GREEN}✓${C_RESET} 已刪除 ${INSTALL_DIR}/uninstall.sh"
fi

# 3. 個人設定檔處理
if [ "$REMOVE_CONFIG" = true ]; then
  if [ -d "${CONFIG_DIR}" ]; then
    rm -rf "${CONFIG_DIR}"
    echo -e "${C_GREEN}✓${C_RESET} 已刪除個人設定檔目錄: ${CONFIG_DIR}"
  fi
elif [ -d "${CONFIG_DIR}" ]; then
  echo -e "${C_YELLOW}!${C_RESET} 保留個人設定檔目錄: ${CONFIG_DIR}"
  echo -e "  若未來不再使用，可手動刪除: rm -rf ${CONFIG_DIR}"
fi

echo -e "\n${C_GREEN}✓ 解除安裝成功完成！${C_RESET}\n"
