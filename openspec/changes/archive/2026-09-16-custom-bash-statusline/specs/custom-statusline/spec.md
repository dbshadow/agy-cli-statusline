## Purpose

Provides a fast, native Bash statusline for the Antigravity CLI in Linux/WSL environments featuring bilingual text labeling, adaptive line-packing, system resource telemetry, and modular configuration.

## ADDED Requirements

### Requirement: Stdin processing with timeout guard
The statusline SHALL read JSON telemetry payloads from standard input with a bounded 0.25-second timeout, falling back gracefully to a minimal valid payload if input is delayed or pipe stalls.

#### Scenario: Successful payload ingestion
- **WHEN** Antigravity CLI sends a valid JSON telemetry payload to standard input
- **THEN** the statusline extracts session, model, VCS, context, and quota metrics without hanging

#### Scenario: Stdin timeout protection
- **WHEN** standard input hangs or is stalled for longer than 0.25 seconds
- **THEN** the statusline terminates the read, avoids blocking the CLI terminal, and outputs fallback statusline content

### Requirement: Bilingual text labeling
The statusline SHALL render human-readable textual labels in either Traditional Chinese (`zh-tw`) or English (`en`) according to the active configuration, avoiding ambiguous standalone icons.

#### Scenario: Traditional Chinese output
- **WHEN** configuration sets `LANGUAGE="zh-tw"` or `--lang zh-tw` is supplied
- **THEN** all badge headers and state names are rendered using Traditional Chinese text labels (e.g. `[就緒]`, `模型:`, `專案:`, `脈絡用量:`, `產出檔案:`)

#### Scenario: English output
- **WHEN** configuration sets `LANGUAGE="en"` or `--lang en` is supplied
- **THEN** all badge headers and state names are rendered using English text labels (e.g. `[READY]`, `Model:`, `Project:`, `Context:`, `Artifacts:`)

### Requirement: Dynamic line packing and box framing
The statusline SHALL package Line 1 core session badges with a header border (`╭─`) and greedily pack subsequent telemetry badges within terminal column boundaries using box-drawing lines (`├─`, `╰─`).

#### Scenario: Wide terminal layout
- **WHEN** terminal width is sufficiently wide (e.g. >= 120 columns)
- **THEN** all enabled telemetry badges fit into a compact two-row layout bounded by `╭─` and `╰─`

#### Scenario: Narrow terminal responsive packing
- **WHEN** terminal width is reduced (e.g. 70-80 columns)
- **THEN** badges automatically flow across 3 or more lines with `├─` dividers without horizontal wrapping or clipping

### Requirement: Host and conversation telemetry
The statusline SHALL extract host real-time CPU usage percentage from `/proc/stat`, system RAM utilization percentage from `/proc/meminfo`, context window token ratio, API quota limits, and artifact/subagent/task counters.

#### Scenario: System resource telemetry
- **WHEN** `/proc/meminfo` and `/proc/stat` are accessible
- **THEN** the statusline renders current system RAM percentage and CPU usage percentage

#### Scenario: Zero-count badge suppression
- **WHEN** active subagents or background tasks count is zero
- **THEN** the statusline automatically hides the respective subagents and tasks badges to conserve screen space

### Requirement: Unified configuration management
The statusline SHALL source configuration from `statusline.conf` (or `~/.config/antigravity-statusline/statusline.conf`), allowing users to toggle badges, reorder badges, and select language, with `conv_id` disabled by default and Vim mode / Tailscale excluded.

#### Scenario: Default configuration state
- **WHEN** running with default settings
- **THEN** `conv_id`, `vim_mode`, and `tailscale` badges are omitted, while `state`, `git`, `model`, `project`, `context`, `quota`, `ram`, and `artifacts` are active

#### Scenario: Custom badge reordering
- **WHEN** user modifies `BADGE_ITEMS` array in `statusline.conf`
- **THEN** the statusline renders badges in the exact custom order defined by the user

### Requirement: Automated installation and removal lifecycle
The statusline SHALL provide `install.sh` to safely configure `statusLine` in `~/.gemini/antigravity-cli/settings.json` with an atomic backup, and `uninstall.sh` to restore settings and remove deployed scripts.

#### Scenario: Clean installation
- **WHEN** running `./install.sh`
- **THEN** dependencies are checked, script and config templates are deployed, and CLI `settings.json` is safely updated

#### Scenario: Clean uninstallation
- **WHEN** running `./uninstall.sh`
- **THEN** `statusLine` configuration is safely removed from `settings.json` and deployed executable is deleted
