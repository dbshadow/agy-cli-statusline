#!/usr/bin/env bash
# ==============================================================================
# Antigravity CLI Custom Statusline Installer
# Safe, non-destructive installation for Linux / WSL.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.antigravity"
CONFIG_DIR="${HOME}/.config/antigravity-statusline"
CLI_SETTINGS="${HOME}/.gemini/antigravity-cli/settings.json"
USE_SYMLINK=false

# Print with colors
C_GREEN="\033[1;32m"
C_BLUE="\033[1;34m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_RESET="\033[0m"

for arg in "$@"; do
  case "$arg" in
    -s|--symlink)
      USE_SYMLINK=true
      ;;
    -h|--help)
      echo "Usage: ./install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -s, --symlink    Create symlink to current repo instead of copying files"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
  esac
done

echo -e "${C_BLUE}==>${C_RESET} 檢查環境依賴..."

if ! command -v bash >/dev/null 2>&1; then
  echo -e "${C_RED}錯誤: 未找到 bash。${C_RESET}"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo -e "${C_RED}錯誤: 未找到 jq 工具。請先安裝: sudo apt install -y jq${C_RESET}"
  exit 1
fi

echo -e "${C_GREEN}✓${C_RESET} 依賴檢查通過 (bash, jq)"

# 1. 建立目標資料夾
echo -e "${C_BLUE}==>${C_RESET} 建立設定與執行檔目錄..."
mkdir -p "${INSTALL_DIR}"
mkdir -p "${CONFIG_DIR}"
mkdir -p "$(dirname "${CLI_SETTINGS}")"

# 2. 部署設定檔
if [ ! -f "${CONFIG_DIR}/statusline.conf" ]; then
  echo -e "${C_BLUE}==>${C_RESET} 初始化設定檔至 ${CONFIG_DIR}/statusline.conf"
  cp "${SCRIPT_DIR}/statusline.conf" "${CONFIG_DIR}/statusline.conf"
else
  echo -e "${C_YELLOW}!${C_RESET} 已存在個人設定檔 ${CONFIG_DIR}/statusline.conf，保留現有設定不予覆蓋。"
fi

# 3. 部署 statusline.sh 與 uninstall.sh
TARGET_SCRIPT="${INSTALL_DIR}/statusline.sh"
TARGET_UNINSTALL="${INSTALL_DIR}/uninstall.sh"

if [ "$USE_SYMLINK" = true ]; then
  echo -e "${C_BLUE}==>${C_RESET} 建立軟連結至 ${TARGET_SCRIPT} (開發模式)"
  ln -sf "${SCRIPT_DIR}/statusline.sh" "${TARGET_SCRIPT}"
  ln -sf "${SCRIPT_DIR}/uninstall.sh" "${TARGET_UNINSTALL}"
else
  echo -e "${C_BLUE}==>${C_RESET} 複製腳本至 ${TARGET_SCRIPT}"
  cp "${SCRIPT_DIR}/statusline.sh" "${TARGET_SCRIPT}"
  cp "${SCRIPT_DIR}/uninstall.sh" "${TARGET_UNINSTALL}"
fi

chmod +x "${TARGET_SCRIPT}" "${TARGET_UNINSTALL}"

# 4. 更新 settings.json
echo -e "${C_BLUE}==>${C_RESET} 更新 Antigravity CLI 設定檔 (${CLI_SETTINGS})..."
if [ -f "${CLI_SETTINGS}" ]; then
  BAK_FILE="${CLI_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  cp "${CLI_SETTINGS}" "${BAK_FILE}"
  echo -e "${C_GREEN}✓${C_RESET} 已備份原有設定檔至: ${BAK_FILE}"
else
  echo "{}" > "${CLI_SETTINGS}"
fi

TMP_SETTINGS=$(mktemp "${CLI_SETTINGS}.tmp.XXXXXX")
jq --arg cmd "${TARGET_SCRIPT}" '
  .statusLine = {
    "type": "command",
    "command": $cmd,
    "enabled": true
  }
' "${CLI_SETTINGS}" > "${TMP_SETTINGS}"
mv "${TMP_SETTINGS}" "${CLI_SETTINGS}"

echo -e "${C_GREEN}✓${C_RESET} 成功寫入 statusLine 配置至 settings.json"

# 5. 測試自檢
echo -e "\n${C_BLUE}==>${C_RESET} 執行狀態列自檢預覽:"
echo "--------------------------------------------------------------------------------"
if [ -f "${SCRIPT_DIR}/weby-homelab-antigravity-cli-statusline/tests/fixtures/full_payload.json" ]; then
  "${TARGET_SCRIPT}" --test "${SCRIPT_DIR}/weby-homelab-antigravity-cli-statusline/tests/fixtures/full_payload.json"
else
  printf '{"agent_state":"ready","terminal_width":80}' | "${TARGET_SCRIPT}"
fi
echo "--------------------------------------------------------------------------------"

echo -e "\n${C_GREEN}🎉 安裝完成！${C_RESET}"
echo -e "你可以隨時編輯個人設定檔: ${C_YELLOW}${CONFIG_DIR}/statusline.conf${C_RESET}"
echo -e "若要解除安裝，請執行: ${C_YELLOW}${TARGET_UNINSTALL}${C_RESET}\n"
