## Why

The user wants a customized Antigravity CLI statusline that runs efficiently in WSL-Ubuntu-22.04. Existing community solutions (AndyAWD and Weby Homelab) have distinct trade-offs: Weby provides adaptive dynamic line-packing and visual box framing but relies on cryptic Nerd Font icons, hardcoded configurations, and lacks bilingual text; AndyAWD offers clear text labels, fine-grained modular configuration, and accurate quota polling, but lacks Weby's compact line-packing engine. This change builds a native Bash-based statusline combining the strengths of both: clear bilingual text labels (Traditional Chinese and English), no cryptic icons, configurable badge toggling via a unified config, Linux system telemetry (CPU load and RAM), and automated installation scripts.

## What Changes

- Implement `statusline.sh`: A high-performance, native Bash statusline script with 0.25s stdin timeout guard, single-pass `jq` parsing, and greedy line-packing.
- Support bilingual dictionary (`zh-tw` and `en`) with clear, human-readable text labels instead of obscure glyphs.
- Support system telemetry (CPU 1-min load from `/proc/loadavg` and RAM from `/proc/meminfo`).
- Remove noise metrics: Exclude Vim mode and Tailscale IP; default `conv_id` to disabled.
- Implement unified configuration file (`statusline.conf`): Allows users to toggle, reorder, and configure statusline badges and display language.
- Implement `install.sh` and `uninstall.sh`: Non-destructive installation, symlink support, config initialization, and safe `settings.json` integration.
- Implement test suite: Verification scripts using real JSON payloads to ensure resilient rendering across terminal widths.

## Capabilities

### New Capabilities
- `custom-statusline`: Custom Bash statusline rendering engine, bilingual dictionary support, Linux host telemetry, unified modular configuration, and installation lifecycle.

### Modified Capabilities
<!-- No existing capabilities to modify -->

## Impact

- Target environment: Linux / WSL-Ubuntu-22.04.
- External dependencies: `/usr/bin/bash`, `/usr/bin/jq`, Git (optional), Linux `/proc` filesystem.
- Settings: Modifies `~/.gemini/antigravity-cli/settings.json` (`statusLine` block) with automated backup.
