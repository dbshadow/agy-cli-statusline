## 1. Configuration & Dictionaries

- [x] 1.1 Create `statusline.conf` containing default settings: `LANGUAGE="zh-tw"`, `conv_id` commented/disabled, and clean badge ordering. Verify configuration syntax by sourcing it in Bash.
- [x] 1.2 Implement bilingual dictionary mappings for Traditional Chinese (`zh-tw`) and English (`en`) for all badge labels and agent states. Verify dictionary lookup returns expected strings for both languages.

## 2. Core Statusline Engine

- [x] 2.1 Implement `statusline.sh` stdin reader with 0.25s timeout guard and single-pass `jq` extraction for session, model, context, quota, and conversation counters. Verify ingestion with `weby-homelab-antigravity-cli-statusline/tests/fixtures/full_payload.json`.
- [x] 2.2 Implement host telemetry extraction for RAM percentage from `/proc/meminfo` and CPU 1-min load average from `/proc/loadavg`. Verify telemetry values are correctly extracted on WSL.
- [x] 2.3 Implement Line 1 session header assembly (State, Git branch with dirty indicator, Model, Project path) with clear text labels and ANSI colors. Verify output contains no cryptic icons.
- [x] 2.4 Implement Line 2+ dynamic greedy line-packing engine with context/quota progress bars (`[██░░]`), box borders (`╭─`, `├─`, `╰─`), and zero-count badge suppression. Verify responsive line wrapping under 80 and 120 column simulations.

## 3. Installation & Lifecycle Scripts

- [x] 3.1 Implement `install.sh` to check dependencies (`bash`, `jq`), deploy `statusline.sh` to `~/.antigravity/`, seed `~/.config/antigravity-statusline/statusline.conf`, and safely update `~/.gemini/antigravity-cli/settings.json` with backup preservation. Verify installation script syntax and permission flags.
- [x] 3.2 Implement `uninstall.sh` to safely remove `statusLine` from `settings.json` and delete deployed executables while offering to preserve user config. Verify uninstallation script cleans up without affecting unrelated settings.

## 4. Verification & Testing Suite

- [x] 4.1 Create test runner `tests/run_tests.sh` with JSON test fixtures to validate bilingual rendering (`zh-tw` and `en`), terminal width wrapping (80 vs 140 columns), and stdin timeout fallback. Verify all tests pass cleanly.
