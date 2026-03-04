---
name: summary-init
description: |
  Interactive setup wizard for work-summary-kit. Walks you through configuring
  your data sources, paths, and preferences. Generates ~/.config/work-summary/config.json.
  Run /summary-init to set up or reconfigure your work summary system.
author: Will Fanguy
version: 1.0.0
date: 2026-03-04
tags: [productivity, setup, configuration]
user_invocable: true
---

# Work Summary Kit Setup Wizard

## Overview

This wizard creates your personal config at `~/.config/work-summary/config.json`. It will:

1. Gather your basic info (name, email, timezone)
2. Ask which data sources you use
3. Configure each enabled source
4. Verify prerequisites (env vars, MCP servers)
5. Generate the config file
6. Create output directories
7. Run a quick validation

## Step 1: Check for Existing Config

```bash
test -f ~/.config/work-summary/config.json && echo "exists" || echo "none"
```

If a config already exists, ask the user:
> You already have a config at `~/.config/work-summary/config.json`. Do you want to reconfigure from scratch or update specific settings?

If reconfiguring, read the existing config as defaults for the questions below.

## Step 2: Basic Info

Ask the user for:

1. **Name**: "What name should appear in your summaries?"
2. **Email**: "What's your primary work email?" (used for git filtering, calendar queries)
3. **Timezone**: "What's your timezone?" Detect system timezone as default:
   ```bash
   readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || echo "America/Chicago"
   ```
   Offer detected timezone as default, let user override.

## Step 3: Data Sources

Ask the user which data sources they want to enable. Present as a multi-select:

> Which data sources do you want to include in your summaries?
>
> - **Git** -- Commit activity from your repos (recommended for everyone)
> - **JIRA** -- Ticket status and progress tracking
> - **Google Calendar** -- Meeting tracking and focus time analysis
> - **Slack** -- Message activity and key discussions
> - **Google Drive** -- File modification tracking
> - **Task Management** -- Track task completions (Obsidian, JIRA, Google Tasks, or Linear)

## Step 4: Configure Each Enabled Source

### Git Configuration

Ask:
1. "What git repos should I track? Provide the absolute path to each."
   - Help: "You can add multiple repos. I'll scan them for your commits."
   - For each repo, detect the name from the directory and default branch:
     ```bash
     basename {path}
     cd {path} && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
     ```
2. "What email do you use for git commits?" (default to the email from Step 2)
   - Verify: `cd {first_repo} && git log --author="{email}" -1 --oneline` to confirm commits exist

### JIRA Configuration

Ask:
1. "What's your JIRA instance URL?" (e.g., https://company.atlassian.net)
2. "Which JIRA project keys should I track?" (e.g., ENG, PLAT, FE)
3. "What email do you use for JIRA?" (default to primary email)

Check env vars:
```bash
test -n "$JIRA_USERNAME" && echo "JIRA_USERNAME is set" || echo "WARNING: JIRA_USERNAME not set"
test -n "$JIRA_API_TOKEN" && echo "JIRA_API_TOKEN is set" || echo "WARNING: JIRA_API_TOKEN not set"
```

If not set, tell the user:
> Set these in your shell profile (~/.zshrc or ~/.bashrc):
> ```
> export JIRA_USERNAME="your-email@company.com"
> export JIRA_API_TOKEN="your-api-token"
> ```
> Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

Use defaults for status mappings (done, in-progress, handed-off). Mention the user can customize these later.

### Google Calendar Configuration

Requires the Google Workspace MCP server. Check if it's available:

Tell the user:
> Calendar integration requires the Google Workspace MCP server for Claude Code.
> Make sure it's configured in your Claude Code settings.

Use defaults: `calendar_id: "primary"`, working hours 9-6, standard meeting categories.

### Slack Configuration

Ask:
1. "What's your Slack username?"

Check env var:
```bash
test -n "$SLACK_TOKEN" && echo "SLACK_TOKEN is set" || echo "WARNING: SLACK_TOKEN not set"
```

If not set, tell the user:
> Set your Slack user token in your shell profile:
> ```
> export SLACK_TOKEN="xoxp-your-token-here"
> ```
> You need a user token (xoxp) with `search:read` scope. Create one at:
> https://api.slack.com/apps (create an app, add OAuth scopes, install to workspace)

Ask about channel categories:
> Want to set up channel categories? (Optional -- helps group Slack activity in summaries)
> - Project channels (e.g., eng-*, proj-*)
> - Coordination channels (e.g., general, engineering)
> - Support channels (e.g., ask-*, help-*)

### Google Drive Configuration

Requires the Google Workspace MCP server (same as Calendar). No additional config needed.

### Task Management Configuration

Ask:
> Which task management system do you use?
> - **None** -- Skip task tracking
> - **JIRA** -- Use JIRA tickets as your task system (uses same JIRA config)
> - **Obsidian** -- Obsidian Task Notes (markdown files with YAML frontmatter)
> - **Google Tasks** -- Google Tasks lists
> - **Linear** -- Linear issues

Based on selection:

**JIRA**: Ask for assignee email (default to JIRA email). Uses same auth as JIRA data source.

**Obsidian**: Ask for the absolute path to the Task Notes directory. Explain the expected format:
> Obsidian Task Notes should be markdown files with YAML frontmatter containing:
> - `status`: open, in-progress, blocked, done
> - `completedDate`: YYYY-MM-DD (set when done)
> - `project`: project name
> - `priority`: priority level

**Google Tasks**: Ask for list ID or use default (@default). Requires Google Workspace MCP.

**Linear**: Ask for team key. Check LINEAR_API_TOKEN env var.

## Step 5: Output Preferences

Ask:
1. "Where should summaries be saved?" (default: ~/work-summaries)
2. "Which template do you prefer?"
   - **default** -- Full detailed summary with all sections
   - **compact** -- Quick snapshot: summary, metrics, blockers only
   - **engineering** -- Heavy on code, light on meetings (coming soon)
   - **manager** -- Heavy on meetings/decisions (coming soon)

Use defaults for file naming and sections order. Mention these are customizable in the config.

## Step 6: Optional Settings

Ask:
> Do you want to set up project name mappings? (Maps folder names to friendly display names)

If yes, help them define a few mappings.

Ask:
> Do you want to set up name mappings? (Override display names for colleagues)

If yes, help them define a few confirmed mappings.

## Step 7: Generate Config

Assemble the config JSON from all collected answers. Use defaults for anything not explicitly configured.

```bash
mkdir -p ~/.config/work-summary
```

Write the config to `~/.config/work-summary/config.json`.

Also detect and set `kit_path`:
```bash
# Try to find the kit installation
SKILL_DIR=$(dirname "$(dirname "$(dirname "$0")")")
# Or use the known skill directory structure
KIT_PATH="${HOME}/.claude/skills/work-summary-kit"
```

## Step 8: Create Output Directories

```bash
mkdir -p {output_dir}/daily
mkdir -p {output_dir}/weekly
```

## Step 9: Validate

Run quick checks:

1. **Config readable**: Read back the config and confirm it parses
2. **Git repos accessible**: For each repo, verify the path exists and is a git repo
3. **Env vars set**: Check all required env vars are non-empty
4. **Output dir writable**: Touch a test file and remove it

Report results:
> Setup complete! Your config is at ~/.config/work-summary/config.json
>
> Enabled sources: Git, JIRA, Calendar
> Output directory: ~/work-summaries/
> Template: daily-default
>
> To generate your first daily summary, run: /daily-summary
> To set up automated scheduling, see: {kit_path}/scheduling/README.md
>
> Warnings:
> - SLACK_TOKEN not set (Slack will be skipped until configured)

## Step 10: Offer Test Run

Ask:
> Want me to run a quick test summary now? I'll generate today's summary with your new config.

If yes, invoke the daily-summary skill.
