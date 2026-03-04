---
name: daily-summary
description: |
  Generate a comprehensive daily work summary from your configured data sources.
  Supports: Git commits, JIRA tickets, Google Calendar, Slack messages, Google Drive,
  and multiple task management systems (Obsidian, JIRA, Google Tasks, Linear).
  Adapts output to whatever sources you have enabled. Run /daily-summary to generate.
  First-time users: run /summary-init to create your config.
author: Will Fanguy
version: 1.0.0
date: 2026-03-04
tags: [productivity, summary, daily, work-log]
user_invocable: true
---

# Daily Summary Generator

## Step 0: Initialize

Get current date/time in user's timezone:

```bash
TZ={timezone from config} date "+%Y-%m-%d %H:%M:%S %Z (%A)"
```

Store the date -- use it for all file naming and "today" references throughout.

## Step 1: Load Configuration

Read the user's config file:

```
~/.config/work-summary/config.json
```

**If the file doesn't exist**, tell the user:
> Your work summary config hasn't been created yet. Run `/summary-init` to set it up.

Then stop.

**Validate required fields**:
- `user.name`, `user.email`, `user.timezone` must be present
- `paths.output_dir` must be present
- At least one data source must have `enabled: true`

**Resolve paths**:
- Expand `~` to the user's home directory in all path fields
- `daily_output_dir`: if relative, resolve against `output_dir`
- `state_file`: if relative, resolve against `output_dir`
- `kit_path`: if not set, try `~/.claude/skills/work-summary-kit`

**Create output directories** if they don't exist:
```bash
mkdir -p {resolved daily_output_dir}
mkdir -p {resolved weekly_output_dir}
```

## Step 2: Load State

Read the state file at `{resolved state_file path}`. If it doesn't exist, create it with defaults:

```json
{
  "lastProcessedCommit": {},
  "lastProcessedDate": "",
  "lastRunTime": "",
  "runCountToday": 0
}
```

If `lastProcessedDate` matches today, increment `runCountToday`. Otherwise reset to 1.

## Step 3: Load Name Mappings

If `config.name_mappings` exists and has entries, use it for name resolution throughout:

1. Check `confirmed` first -- these override any other source
2. Check `unverified` -- use email prefix only
3. Fall back to the name from the data source (Slack profile, calendar attendee, etc.)

## Step 4: Identify Enabled Data Sources

Read `config.data_sources` and build a list of enabled sources:

```
ENABLED_SOURCES = []
for each source in [git, jira, calendar, slack, drive, tasks]:
    if config.data_sources.{source}.enabled == true:
        add to ENABLED_SOURCES
```

Log which sources are enabled. This determines which adapters to load and which output sections to generate.

## Step 5: Collect Data

For each enabled data source, read the corresponding adapter file from `{kit_path}/adapters/` and follow its Collection Steps.

**Important**: Read adapter files using the Read tool. Each adapter is a self-contained instruction set.

### Git (if enabled)

Read `{kit_path}/adapters/git.md` and follow its collection instructions.

Use:
- `config.data_sources.git.repos` for repo paths
- `config.data_sources.git.author_email` (or `config.user.email`) for commit filtering

Store results as `GIT_DATA`.

### JIRA (if enabled)

Read `{kit_path}/adapters/jira.md` and follow its collection instructions.

Use:
- `config.data_sources.jira.*` for API URL, project keys, auth env vars
- Ticket IDs detected by the git adapter (if git is also enabled)

Store results as `JIRA_DATA`.

### Calendar (if enabled)

Read `{kit_path}/adapters/calendar.md` and follow its collection instructions.

Use:
- `config.data_sources.calendar.*` for provider, calendar ID, working hours, categories
- `config.user.email` for the calendar query
- `config.user.timezone` for time conversion

Store results as `CALENDAR_DATA`.

### Slack (if enabled)

Read `{kit_path}/adapters/slack.md` and follow its collection instructions.

Use:
- `config.data_sources.slack.*` for auth, username, channel categories
- `config.name_mappings` for resolving user names

Store results as `SLACK_DATA`.

### Google Drive (if enabled)

Read `{kit_path}/adapters/drive.md` and follow its collection instructions.

Use:
- `config.data_sources.drive.*` for provider settings

Store results as `DRIVE_DATA`.

### Tasks (if enabled and provider != "none")

Based on `config.data_sources.tasks.provider`, read the corresponding adapter:

| Provider | Adapter File |
|----------|-------------|
| `obsidian` | `{kit_path}/adapters/tasks-obsidian.md` |
| `jira` | `{kit_path}/adapters/tasks-jira.md` |
| `google-tasks` | `{kit_path}/adapters/tasks-google.md` |
| `linear` | `{kit_path}/adapters/tasks-linear.md` |

Follow the adapter's collection instructions. Store results as `TASKS_DATA`.

## Step 6: Generate Output

### Load the template

Read the template file:
```
{kit_path}/templates/{config.output.template}.md
```

If the template name contains a `/` or `.`, treat it as a file path instead.

If the template file doesn't exist, fall back to `daily-default.md`.

### Determine active sections

Use `config.output.sections_order` to determine which sections to include and in what order.

For each section in the order list:
1. Check if the section's data source is enabled (see mapping below)
2. If the source is enabled, include the section using the template's format
3. If the source is disabled, skip the section entirely (no heading, no content)

**Section-to-source mapping**:

| Section | Required Source(s) | Notes |
|---------|-------------------|-------|
| `executive_summary` | Any enabled source | Always include if at least one source has data |
| `metrics` | Any enabled source | Only show metrics for enabled sources |
| `plan_vs_actual` | Tasks | Only if a plan file exists for today |
| `code_activity` | Git | |
| `jira_updates` | JIRA | |
| `meetings` | Calendar | |
| `slack_activity` | Slack | |
| `drive_activity` | Drive | |
| `completed_tasks` | Tasks | |
| `tomorrow_focus` | Any enabled source | Synthesize from available data |
| `blockers` | Any enabled source | Only if blockers detected |

### Write the output

Follow the template format specification. Use the collected data to populate each section.

**Project mapping**: When displaying project names, check `config.project_mappings` to convert folder/path names to friendly display names.

**Quality rules**:
- Keep the summary scannable -- use bullet points, short paragraphs
- Lead with outcomes and impact, not process
- Omit sections entirely when there's no data (don't show empty sections)
- Blockers section: only include if actual blockers exist

## Step 7: Write File

### Determine file name

Translate `config.output.file_naming` pattern to an actual filename:

| Pattern | Replacement |
|---------|------------|
| `YYYY` | 4-digit year |
| `MM` | 2-digit month |
| `DD` | 2-digit day |
| `ddd` | 3-letter weekday (Mon, Tue, etc.) |
| `[text]` | Literal text (e.g., `[ - Work]` becomes ` - Work`) |

Default: `YYYY-MM-DD.md` -> `2026-03-04.md`

### Write the file

```
{resolved daily_output_dir}/{filename}
```

**Each run REPLACES the file** -- the summary always reflects the full day, not incremental updates.

## Step 8: Update State

Update the state file:

```json
{
  "lastProcessedCommit": { "repo-name": "latest-hash", ... },
  "lastProcessedDate": "{today}",
  "lastRunTime": "{ISO timestamp}",
  "runCountToday": {incremented count}
}
```

**Only update state after the file is successfully written.** If the write fails, leave state unchanged so the next run reprocesses.

## Step 9: Report

Tell the user:
- Where the file was written
- Which data sources were collected
- Any warnings or errors encountered
- Key highlights from the summary (2-3 top items)

## Quality Validation Rules

These rules apply regardless of which data sources are enabled:

1. **No hallucination**: Only report data that was actually collected from APIs/files. Never infer, guess, or fabricate.
2. **Google Drive**: Report only file metadata (name, type, timestamp, link). Never describe what was changed or why.
3. **Slack users**: Only report users who appear in API responses. Never guess conversation participants.
4. **JIRA status**: Always use the API response, never derive status from other sources.
5. **Name resolution**: Follow the confirmed -> unverified -> source default precedence.
6. **Timezone**: Convert all timestamps to the user's configured timezone before display.
