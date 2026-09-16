## Context

Antigravity CLI (agy) periodically executes the command configured in `statusLine.command` and streams a JSON payload to its standard input. The user runs in WSL-Ubuntu-22.04 and requires high execution speed, zero visual clutter, and clean bilingual text labels. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**
- Deliver sub-10ms execution latency per invocation using native Bash and single-pass `jq`.
- Provide unambiguous, human-readable text labels in Traditional Chinese (`zh-tw`) and English (`en`).
- Provide an intuitive configuration file (`statusline.conf`) where users can reorder or toggle badges via simple array definitions.
- Implement responsive multi-line box framing (`╭─`, `├─`, `╰─`) with greedy badge packing that adapts to terminal width.
- Support host RAM percentage and CPU 1-min load average with zero subshell overhead via `/proc`.
- Provide atomic, safe `install.sh` and `uninstall.sh` managing `~/.gemini/antigravity-cli/settings.json`.

**Non-Goals:**
- Support for Windows-native PowerShell (specifically optimized for Linux/WSL).
- Standalone Nerd Font glyph mode (the focus is on clear textual labels).
- Vim editor mode or Tailscale IP resolution (explicitly excluded).

## Decisions

### 1. Bash + `jq` Implementation Architecture
- **Rationale**: In WSL-Ubuntu, Bash starts in under 2ms. Coupled with a single-pass `jq` execution, total statusline execution time remains under 8-12ms, eliminating cursor flicker in the terminal.
- **Alternatives Considered**: 
  - *Python (`uv run python`)*: High startup latency (50-100ms) causes noticeable cursor stutter in interactive CLI prompts.
  - *Node.js*: Moderate startup latency (~30ms) and extra platform overhead.

### 2. Sourceable Bash Configuration (`statusline.conf`)
- **Rationale**: Using a Bash-formatted configuration file allows `statusline.sh` to simply `source "$CONF_PATH"`. Array variables like `LINE1_ITEMS` and `BADGE_ITEMS` are instantly loaded in under 0.1ms without process spawning.
- **Alternatives Considered**:
  - *JSON config*: Requires an additional `jq` call to parse user settings, doubling parser overhead.

### 3. Single-Pass JSON Payload Extraction
- **Rationale**: Rather than multiple `jq` calls for each metric, a single multi-line `jq -r` filter outputs all relevant values separated by newlines, which Bash assigns directly via a compound `read` loop.

### 4. Greedy Line-Packing with ANSI Stripping
- **Rationale**: Badges are treated as modular strings. Before placing a badge on the current row, the script calculates its visible character length (stripping ANSI escape sequences). If placing the badge exceeds terminal columns, it pushes the current row to the output buffer and starts a new row.

### 5. Multi-Lingual Dictionary Mapping
- **Rationale**: Text labels, state descriptions, and progress bar units are looked up from an associative dictionary based on `LANGUAGE="zh-tw"` or `"en"`.

## Risks / Trade-offs

- **[Risk]** `jq` command missing on system → **Mitigation**: `install.sh` and `statusline.sh` test for `jq` presence early and print clear instructions (`sudo apt install -y jq`) before graceful exit.
- **[Risk]** Stdin pipe hangs if the CLI process pauses → **Mitigation**: 0.25-second timeout guard using Linux `timeout` (or bounded subshell timer) to prevent freezing the CLI prompt.
- **[Risk]** Overwriting custom `settings.json` keys → **Mitigation**: `install.sh` operates non-destructively using `jq` to patch only the `statusLine` object, while preserving a dated backup.

## Migration Plan

1. User runs `./install.sh`.
2. Script verifies prerequisites (`bash`, `jq`).
3. Script creates `~/.antigravity/` and symlinks/copies `statusline.sh`.
4. Script copies `statusline.conf` to `~/.config/antigravity-statusline/statusline.conf` if not present.
5. Script updates `~/.gemini/antigravity-cli/settings.json` and runs a dry-run test with fixture data.
6. Rollback: Run `./uninstall.sh` to remove statusline and restore `settings.json`.
