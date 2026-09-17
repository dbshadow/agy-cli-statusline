# Antigravity CLI Custom Statusline

English | [繁體中文](README.zh-TW.md)

A fast, modular, and responsive statusline for [Antigravity CLI](https://github.com/google/antigravity) (`agy`) optimized for Linux and WSL-Ubuntu environments. It provides real-time telemetry—including agent states, model info, Git branches, context window consumption, API quotas, system resources (CPU and RAM), and session artifacts—all rendered with clean text labels, adaptive box-framed line-packing, and zero CLI latency.

![Antigravity CLI Statusline Snapshot](snapshot.png)

---

## Key Features

- **Blazing Fast & Lightweight**: Written in native Bash with single-pass `jq` metric parsing, executing in under 10ms with zero prompt stutter or cursor lag.
- **Bilingual Support**: Built-in dictionary supporting both **English (`en`)** and **Traditional Chinese (`zh-tw`)**.
- **Human-Readable Text Labels**: Avoids cryptic icon guessing and font incompatibilities. All metrics display clear labels and clean progress bars (`[██░░]`).
- **Adaptive Dynamic Line-Packing**: Badges dynamically flow across boxed rows (`╭─`, `├─`, `╰─`) based on terminal width, ensuring no clipping or unwanted line breaks.
- **Live System Telemetry**:
  - **CPU Usage**: Real-time CPU utilization percentage computed from `/proc/stat` deltas.
  - **RAM Utilization**: System memory usage extracted directly from `/proc/meminfo`.
- **Accurate Token & Quota Metrics**:
  - Context window usage with integer percentages and token counters (`used / limit`).
  - Active 5-hour and weekly quota progress bars with countdown timers.
- **Zero-Noise Auto-Suppression**: Dynamically hides subagents, background tasks, or artifacts badges when their counts are zero.
- **Modular Configuration**: A simple, sourceable Bash config (`statusline.conf`) lets you reorder or toggle badges without modifying any core script code.
- **Safe Installation & Rollback**: `install.sh` atomically updates `~/.gemini/antigravity-cli/settings.json` while preserving backups, with full rollback via `uninstall.sh`.

---

## Prerequisites

- **OS**: Linux or WSL (Windows Subsystem for Linux, e.g. Ubuntu 22.04)
- **Shell**: `bash` (4.0+)
- **JSON Processor**: `jq` (Install with: `sudo apt install -y jq`)
- **Git** (optional, for branch and dirty status tracking)

---

## Installation

Clone the repository and run the installer:

```bash
cd agy-cli-statusline

# Development mode (recommended: creates a symlink so edits take effect immediately)
./install.sh -s

# Or standard copy mode
./install.sh
```

The installer will:
1. Check for `bash` and `jq` prerequisites.
2. Deploy the executable to `~/.antigravity/statusline.sh`.
3. Initialize the default configuration at `~/.config/antigravity-statusline/statusline.conf`.
4. Safely configure `statusLine` in `~/.gemini/antigravity-cli/settings.json` (with automatic `.bak` backup).
5. Run a self-test preview to verify rendering.

Restart or press Enter in Antigravity CLI to view the statusline immediately.

---

## Configuration

Your personal configuration file is located at:
```text
~/.config/antigravity-statusline/statusline.conf
```

### 1. Language Setting
Switch between English and Traditional Chinese:
```bash
LANGUAGE="en"      # "en" for English, "zh-tw" for Traditional Chinese
```

### 2. Line 1: Header Items
Customize the core session bar items and their order:
```bash
LINE1_ITEMS=(
  "state"         # Agent state ([READY], [THINKING], [WORKING], [TOOL])
  "git"           # Git branch and dirty marker (*dirty)
  "model"         # Active AI model name
  "project"       # Shortened project directory path
  # "conv_id"     # Conversation ID (disabled by default)
)
```

### 3. Line 2+: Telemetry Badges
Control which badges appear and adjust their display order:
```bash
BADGE_ITEMS=(
  "context"       # Context window usage bar and tokens
  "quota_5h"      # 5-hour API quota bar with reset countdown
  "quota_weekly"  # Weekly API quota bar with reset countdown
  "ram"           # System RAM utilization percentage
  "cpu"           # Real-time CPU usage percentage
  "artifacts"     # Generated file artifacts counter
  "subagents"     # Active background subagents counter
  "bg_tasks"      # Running background tasks counter
)
```

#### Context Window Token Display

The `context` badge presents token metrics in a compact format:
```text
Context: [█░░░░░░░] 20% (210K/1.0M | Σ1.3M)
```

| Field | Meaning | Description |
| :--- | :--- | :--- |
| `210K` | **Active Tokens** | The active tokens currently held in the conversation context window for the ongoing turn. |
| `1.0M` | **Context Window Limit** | The maximum context capacity of the active model (e.g. 1,048,576 tokens for Gemini). |
| `Σ1.3M` | **Session Total** | Cumulative API tokens consumed across the entire conversation session (all prompt + completion turns). |

### 4. Visual Styles & Thresholds
```bash
SHOW_BOX_BORDER=true        # Use tree borders (╭─, ├─, ╰─)
PROGRESS_BAR_STYLE="block"  # "block" ([██░░]) or "ascii" ([##--])
SYS_RAM_WARN_PCT=80         # RAM threshold percentage for warning color
GIT_MAX_BRANCH_LEN=24       # Truncation length for Git branch name
PROJECT_MAX_LEN=28          # Truncation length for project path
```

---

## CLI Options & Testing

You can run `statusline.sh` directly to test layouts or override configurations:

```bash
# Preview with a test payload fixture
./statusline.sh --test ./tests/fixtures/full_payload.json

# Test in English mode
./statusline.sh --test ... --lang en

# Test under custom terminal widths
./statusline.sh --test ... --cols 80
./statusline.sh --test ... --cols 140

# Check version
./statusline.sh --version
```

### Automated Test Suite
Run the comprehensive test suite (22 assertions verifying bilingual output, terminal wrapping, and timeout handling):

```bash
./tests/run_tests.sh
```

---

## Uninstallation

To restore your original configuration and remove deployed files:

```bash
./uninstall.sh
```

This will:
- Restore `~/.gemini/antigravity-cli/settings.json` by cleanly removing the `statusLine` block.
- Remove `~/.antigravity/statusline.sh`.
- Retain your custom settings at `~/.config/antigravity-statusline/statusline.conf` for future use.

---

## License

MIT License.
