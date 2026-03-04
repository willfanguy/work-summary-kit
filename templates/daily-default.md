# Daily Default Template

This template defines the full daily summary format. Claude reads this as a specification and produces matching output. All sections are conditional -- only included if the corresponding data source is enabled AND listed in `config.output.sections_order`.

---

## Output Format Specification

### Header

```markdown
# Daily Work Summary - {Day of Week}, {Month} {Day}, {Year}
```

### executive_summary

A 3-5 bullet executive summary of the day's highlights. Lead with the most impactful item. Include key metrics inline.

```markdown
## Executive Summary

- Completed {N} tasks across {projects} -- {brief highlight of most notable}
- {N} commits: {one-line summary of main code work}
- {N} meetings ({total_hours}h): {notable meeting outcome if any}
- {Any blockers resolved or created}
- Focus time: {hours}h ({percentage}% of working day)
```

If a data source is disabled, omit its bullet. Always include at least 2 bullets.

### metrics

A compact metrics block with counts from all enabled sources.

```markdown
## Metrics

- Tasks Completed: {N} ({by project breakdown if available})
- Commits: {N} across {repo_count} repos (+{added}/-{removed} lines)
- JIRA Tickets: {N} tracked ({status changes if any})
- Meetings: {N} ({total_hours}h, {percentage}% of day)
- Focus Time: {hours}h ({percentage}% of day)
- Slack: {N} messages across {channel_count} conversations
- Drive: {N} files modified
```

Only show lines for enabled data sources. Omit lines where the count is zero.

### plan_vs_actual

Compare the morning plan against actual work. Only show this section if a plan file exists for today.

```markdown
## Plan vs. Actual

**Planned priorities**:
- [x] {Completed planned item}
- [ ] {Incomplete planned item} -- {reason if known}

**Unplanned work completed**:
- {Emergent item not in the plan}

**Plan accuracy**: {completed}/{total} priorities ({percentage}%)
```

### code_activity

Git commit activity grouped by feature/ticket. See git adapter for grouping logic.

```markdown
## Code Activity

### {Feature/Ticket Group} ({N} commits, +{added}/-{removed})

- [{hash}] {message}
- [{hash}] {message}

**Impact**: {One-line summary}

---

**Daily Totals**: {N} commits (+{added}/-{removed} lines, {files} files)
```

### jira_updates

JIRA ticket status tracking. One subsection per ticket found in commits, tasks, or explicitly tracked.

```markdown
## JIRA Ticket Updates

### {TICKET-ID} - {Summary}

- **Status**: {current_status} {change_indicator if changed}
- **Priority**: {priority}
- **Activity**: {commits linked, comments, etc.}
- **Sprint/Deadline**: {sprint name or due date}

### {TICKET-ID} - {Summary}

- **Status**: {current_status}
- ...
```

### meetings

Calendar meetings with time allocation analysis.

```markdown
## Meetings & Time Allocation

**Meeting Breakdown** ({N} meetings, {total_hours}h total):

- {emoji} {start}-{end} ({duration}) {title}
- {emoji} {start}-{end} ({duration}) {title}

**Time Analysis**:

- Meeting Time: {hours}h ({percentage}% of day)
- Focus Time: {hours}h ({percentage}% of day)
- Deep Work Blocks: {count} ({description of longest blocks})
- Focus Quality: {assessment}
```

Meeting emoji by category: standup=, planning=, review=, interview=, one_on_one=, social=, other=

Focus quality: High (6+h, 1-2 blocks), Moderate (4-6h), Low (<4h or fragmented)

### slack_activity

Slack message activity grouped by channel category.

```markdown
## Slack Activity

**Overview**: {N} messages across {channel_count} channels

### {Category} ({N} messages)

- **#{channel}** ({N} messages): {Brief summary of topics}

### Key Decisions

- {Decision made in Slack}

### Action Items from Slack

- [ ] {Action item identified}
```

### drive_activity

Google Drive file modifications. CRITICAL: Report only factual metadata. Never infer what was changed or why.

```markdown
## Google Drive Activity

**Files Modified Today** ({N} files):

- **[{filename}]({link})** ({file_type})
  - Modified: {timestamp}
```

No narrative descriptions. No inferred activity. Metadata only.

### completed_tasks

Tasks completed today from the configured task system.

```markdown
## Completed Tasks

### {Project Name}

- {Task title} {(JIRA ticket if linked)}

### {Another Project}

- {Task title}

**Total**: {N} tasks completed
```

### tomorrow_focus

Forward-looking section with priority items for tomorrow.

```markdown
## Tomorrow's Focus

**Priority items**:
1. {Highest priority item with context}
2. {Next priority}
3. {Third priority}

**Watch list**:
- {Item that needs monitoring}

**Blockers to resolve**:
- {Any active blockers}
```

### blockers

Active blockers. Only show this section if blockers exist.

```markdown
## Active Blockers

- **{Blocker description}**: {status, who can unblock, estimated resolution}
```

### Footer

Always include a footer with generation metadata.

```markdown
---

Generated: {timestamp} {timezone} | Run: {run_count} today
Data Sources: {comma-separated list of enabled sources that were queried}
```
