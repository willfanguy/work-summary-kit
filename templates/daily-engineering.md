# Daily Engineering Template

Engineering-focused daily summary. Heavy on code activity and technical decisions. Light on meetings and communication. Target: 120-180 lines.

---

## Output Format Specification

### Header

```markdown
# Engineering Summary - {Day of Week}, {Month} {Day}, {Year}
```

### executive_summary

Lead with code and technical accomplishments.

```markdown
## Summary

- {Primary technical accomplishment}
- {N} commits across {repos}: {key feature/fix}
- {JIRA ticket progress if relevant}
- {Blockers or technical decisions}
```

### code_activity

DETAILED commit activity -- this is the centerpiece. Show full commit detail.

```markdown
## Code Activity

### {Feature/Ticket} ({N} commits, +{added}/-{removed})

- [{hash}] {message}
  - Files: {key files changed}
- [{hash}] {message}
  - Files: {key files changed}

**Impact**: {Technical impact statement}
**Review status**: {PR/MR status if applicable}

### {Another Feature} ({N} commits, +{added}/-{removed})

- [{hash}] {message}

---

**Daily Totals**: {N} commits, +{added}/-{removed} lines, {files} files across {repos}
```

### jira_updates

Full JIRA detail with technical context.

```markdown
## JIRA Tickets

### {TICKET-ID} - {Summary}

- **Status**: {status} {change_indicator}
- **Commits**: {linked commit hashes}
- **Technical notes**: {any technical context from commit messages}
- **Next step**: {what's needed to advance}
```

### meetings

Compact -- just a count, hours, and any technical decisions.

```markdown
## Meetings

{N} meetings ({hours}h). Focus time: {hours}h.
{Technical decisions made in meetings, if any.}
```

### completed_tasks

Simple list.

```markdown
## Completed

- {Task/ticket}
- {Task/ticket}
```

### blockers

Same as default.

### Sections NOT included

- plan_vs_actual (keep it lean)
- slack_activity (fold technical decisions into meetings)
- drive_activity (rarely relevant for engineers)
- tomorrow_focus (fold into executive summary if needed)

### Footer

```markdown
---
Generated: {timestamp} {timezone}
```
