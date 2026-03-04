# Scheduling Automated Summaries

Run your daily and weekly summaries automatically.

## macOS (launchd)

### 1. Copy the template plists

```bash
cp ~/.claude/skills/work-summary-kit/scheduling/launchd-daily.plist.template \
   ~/Library/LaunchAgents/com.user.daily-summary.plist

cp ~/.claude/skills/work-summary-kit/scheduling/launchd-weekly.plist.template \
   ~/Library/LaunchAgents/com.user.weekly-summary.plist
```

### 2. Edit the plists

Open each file and update:
- `CLAUDE_PATH`: Path to your `claude` binary (find with `which claude`)
- `WORKING_DIR`: Your working directory (where claude should run from)
- `TIMEOUT_SCRIPT`: Path to the `run-with-timeout.sh` script
- Schedule times (default: daily at 5:30 PM, weekly Friday at 6:00 PM)

### 3. Make the timeout script executable

```bash
chmod +x ~/.claude/skills/work-summary-kit/scheduling/run-with-timeout.sh
```

### 4. Load the agents

```bash
launchctl load ~/Library/LaunchAgents/com.user.daily-summary.plist
launchctl load ~/Library/LaunchAgents/com.user.weekly-summary.plist
```

### 5. Verify

```bash
launchctl list | grep com.user
```

### Logs

Logs go to `/tmp/daily-summary.log` and `/tmp/weekly-summary.log`.

```bash
tail -f /tmp/daily-summary.log
```

## Linux (cron)

Add to your crontab (`crontab -e`):

```cron
# Daily summary at 5:30 PM on weekdays
30 17 * * 1-5 cd /path/to/workdir && /path/to/run-with-timeout.sh 900 /path/to/claude -p "/daily-summary" >> /tmp/daily-summary.log 2>&1

# Weekly summary at 6:00 PM on Fridays
0 18 * * 5 cd /path/to/workdir && /path/to/run-with-timeout.sh 900 /path/to/claude -p "/weekly-summary" >> /tmp/weekly-summary.log 2>&1
```

Replace paths with your actual paths.

## Important Notes

### Timeout wrapper

Always use `run-with-timeout.sh` to wrap the `claude` command. Without it, if Claude hangs (API timeout, MCP server failure), the process runs indefinitely and blocks future scheduled runs.

Default timeout: 900 seconds (15 minutes). Adjust if your summaries take longer.

### Permissions

The `claude -p` command runs in prompt mode. For headless automation, you may need `--dangerously-skip-permissions` to avoid interactive permission prompts. Only use this if you understand the security implications.

### Environment variables

Make sure your cron/launchd environment has access to the env vars your data sources need (JIRA_USERNAME, JIRA_API_TOKEN, SLACK_TOKEN, etc.).

For launchd on macOS, set them in the plist's `EnvironmentVariables` section or in your shell profile that launchd sources.

For cron on Linux, either set them at the top of the crontab or source your profile:
```cron
30 17 * * 1-5 source ~/.bashrc && cd /path && ./run-with-timeout.sh 900 claude -p "/daily-summary"
```

### Nested session prevention

If you're running Claude Code interactively AND have launchd/cron running `claude -p`, you may hit a "nested sessions" error. Fix: add `unset CLAUDECODE` before the `claude -p` command in your scripts.
