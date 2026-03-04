---
name: weekly-summary
description: |
  Generate a weekly work summary by aggregating daily summaries. Calculates velocity
  trends, project health, and next-week priorities. Run /weekly-summary at the end
  of the week (typically Friday afternoon). Requires daily summaries to exist.
author: Will Fanguy
version: 1.0.0
date: 2026-03-04
tags: [productivity, summary, weekly, work-log]
user_invocable: true
---

# Weekly Summary Generator

## Step 0: Initialize

Get current date/time:

```bash
TZ={timezone from config} date "+%Y-%m-%d %H:%M:%S %Z (%A)"
```

Calculate the current ISO week number and week date range:

```bash
TZ={timezone} date "+%V"          # ISO week number
TZ={timezone} date -v-Mon "+%Y-%m-%d"  # Monday of this week (macOS)
TZ={timezone} date -v-Fri "+%Y-%m-%d"  # Friday of this week (macOS)
```

For Linux, use `date -d "last monday"` / `date -d "next friday"` equivalents.

## Step 1: Load Configuration

Read `~/.config/work-summary/config.json`.

If missing, tell user to run `/summary-init` first.

Resolve paths (same as daily-summary skill).

## Step 2: Locate Daily Summaries

Find all daily summaries from this week in the configured daily output directory:

```bash
ls {daily_output_dir}/
```

Match files from Monday through Friday (or today if running mid-week).

**If no daily summaries exist**, tell the user:
> No daily summaries found for this week. Run `/daily-summary` first to generate them.

**If only some days have summaries**, note which days are missing and proceed with available data.

## Step 3: Read and Parse Daily Summaries

For each daily summary file, read it and extract:

### Metrics
- Tasks completed count (from Metrics or Completed Tasks section)
- Commit count and line changes (from Code Activity or Metrics)
- JIRA tickets mentioned (from JIRA section)
- Meeting count and total hours (from Meetings section)
- Focus time hours (from Meetings section)
- Slack message count (from Slack section)

### Content
- Accomplishments by project
- Key decisions made
- Blockers (resolved and new)
- Action items

### Parsing approach

Read each section of the daily file. Look for the section headers that match the template format:
- `## Executive Summary` or `## Summary`
- `## Metrics`
- `## Code Activity`
- `## JIRA Ticket Updates`
- `## Meetings` or `## Meetings & Time Allocation`
- `## Slack Activity`
- `## Completed Tasks`
- `## Active Blockers` or `## Blockers`

Extract numbers from metrics lines (regex for digits following labels).

## Step 4: Aggregate Metrics

Sum and average across all daily summaries:

```
total_tasks = sum of daily task counts
total_commits = sum of daily commit counts
total_lines_added = sum of daily additions
total_lines_removed = sum of daily removals
total_meeting_hours = sum of daily meeting hours
total_meeting_count = sum of daily meeting counts
total_focus_hours = sum of daily focus hours
working_days = number of daily summaries found
avg_tasks_per_day = total_tasks / working_days
avg_commits_per_day = total_commits / working_days
```

## Step 5: Compare to Previous Week

Look for the previous week's summary:

```
previous_week_file = {weekly_output_dir}/{previous week filename}
```

If it exists, read it and extract the same metrics for comparison.

Calculate week-over-week changes:
```
change_pct = ((this_week - last_week) / last_week) * 100
```

If no previous week exists, skip the comparison section.

## Step 6: Synthesize Accomplishments

**This is the most important step.** Don't just concatenate daily items.

For each project that appears across multiple days:
1. Collect all accomplishments from each day
2. Identify the narrative arc (started -> worked on -> completed)
3. Write a synthesized 2-3 line summary that captures the full week's progress
4. Add an impact statement

**Example**:
- Monday: "Created prompt template" + Tuesday: "Documented template" + Wednesday: "Launched to team"
- Synthesis: "Prompt template system created, documented, and launched. 80% reduction in setup time."

## Step 7: Assess Project Health

For each project mentioned in daily summaries:

**Strong**: 2+ tasks completed this week, active commits, no open blockers, forward progress
**Needs Attention**: Some progress but challenges noted, approaching deadline
**Blocked**: No tasks completed, explicit blockers, dependency waiting

## Step 8: Generate Output

Load the weekly template:
```
{kit_path}/templates/{config.output.weekly_template}.md
```

Follow the template format to generate the weekly summary with all aggregated data.

## Step 9: Write File

Determine filename from `config.output.weekly_file_naming`:

| Pattern | Replacement |
|---------|------------|
| `YYYY` | 4-digit year |
| `WW` | ISO week number (zero-padded) |
| `[text]` | Literal text |

Default: `YYYY-[W]WW.md` -> `2026-W10.md`

Write to `{weekly_output_dir}/{filename}`.

## Step 10: Update State

Update state file with new `weekStartDate` (next Monday).

## Step 11: Report

Tell the user:
- Where the file was written
- Key highlights: top accomplishments, velocity trend, project health summary
- Any missing daily summaries

## Quality Rules

1. **Synthesize over repeat**: Never just list daily items. Always combine related work into narratives.
2. **Trends matter**: Always compare to previous week when available.
3. **Focus on outcomes**: Lead with impact, not process.
4. **Project-centric**: Organize by project health and momentum.
5. **Forward-looking**: End with next week's priorities.
6. **Keep scannable**: Use consistent formatting, metrics at the top, details below.
