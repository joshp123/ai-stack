---
name: session-analyzer
description: Analyze pi/codex/claude session transcripts to discover patterns, skills, and model performance correlations. Mines usage history for automation opportunities and tracks model quality by time of day.
---

# Session Analyzer

Two tools for session analysis:

## 1. Model Performance Analysis

Analyzes frustration signals across all sessions (pi, codex, claude) correlated with time of day and model.

```bash
# Run analysis (outputs to ./model-performance-analysis/)
~/code/research/pi-skills/session-analyzer/model-performance.js

# Custom output directory
~/code/research/pi-skills/session-analyzer/model-performance.js /path/to/output
```

**Outputs:**
- `report.md` — full analysis with ASCII charts
- `chart.html` — interactive browser charts
- `data.csv` — raw data for external graphing
- `model-stats.json` — aggregated stats per model

**Key metrics:**
- Frustration rate by hour (CET)
- PST vs non-PST hours comparison
- Model comparison (codex vs opus vs sonnet)
- Worst days analysis

## 2. Pattern Discovery (Original)

Extracts transcripts and optionally spawns subagents to find automation opportunities.

```bash
# Extract transcripts for current directory
~/code/research/pi-skills/session-analyzer/analyze.js

# Extract transcripts for specific directory
~/code/research/pi-skills/session-analyzer/analyze.js /path/to/project

# Extract + analyze with subagents
~/code/research/pi-skills/session-analyzer/analyze.js --analyze

# Custom output directory
~/code/research/pi-skills/session-analyzer/analyze.js --output ./my-analysis --analyze
```

## What It Does

1. **Extract**: Reads all session files for the given working directory from `~/.pi/agent/sessions/`
2. **Split**: Chunks transcripts into ~100k char files (fits in context window)
3. **Analyze** (optional): Spawns pi subagents to identify:
   - **AGENTS.md patterns**: Coding style rules, conventions you repeat
   - **Skill patterns**: Multi-step workflows you do often
   - **Prompt templates**: Reusable prompts for common tasks

## Output

Without `--analyze`:
```
session-transcripts/
├── session-transcripts-000.txt
├── session-transcripts-001.txt
└── ...
```

With `--analyze`:
```
session-transcripts/
├── session-transcripts-000.txt
├── session-transcripts-000.summary.txt  # Pattern analysis
├── session-transcripts-001.txt
├── session-transcripts-001.summary.txt
└── FINAL-SUMMARY.txt                    # Aggregated findings
```

## Setup

Install dependencies (run once):
```bash
cd ~/code/research/pi-skills/session-analyzer
npm install
```

## When to Use

- After working on a project for a while, to discover what rules/skills would help
- Periodically to find new automation opportunities
- When you notice you keep giving similar instructions

---

_Source: [ferologics/pi-skills](https://github.com/ferologics/pi-skills/tree/master/session-analyzer)_
_Originally adapted from [badlogic/pi-mono gist](https://gist.github.com/badlogic/55d996b4afc4bd084ce55bb8ddd34594)_
