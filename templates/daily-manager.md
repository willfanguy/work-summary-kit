# Daily Manager Template

Manager-focused daily summary. Heavy on meetings, decisions, team coordination, and action items. Light on individual code commits. Target: 100-150 lines.

---

## Output Format Specification

### Header

```markdown
# Daily Update - {Day of Week}, {Month} {Day}, {Year}
```

### executive_summary

Lead with team coordination and decisions.

```markdown
## Summary

- {Key decision or outcome from today}
- {Team coordination highlight}
- {Project status/milestone update}
- {Action items count: N new, N completed}
- Meetings: {N} ({hours}h), Focus: {hours}h
```

### meetings

DETAILED meeting breakdown -- this is the centerpiece. Include attendees, outcomes, decisions.

```markdown
## Meetings & Decisions

### {Meeting Title} ({time}, {duration})

**Attendees**: {names}
**Key discussion**: {1-2 sentence summary}
**Decisions**:
- {Decision made}
**Action items**:
- [ ] {Action item} ({owner})

### {Meeting Title} ({time}, {duration})

**Key discussion**: {summary}
**Outcome**: {result}

---

**Day total**: {N} meetings, {hours}h ({percentage}% of day)
```

### slack_activity

Focus on team coordination, not individual messages.

```markdown
## Team Communication

**Key threads**:
- **#{channel}**: {Decision or coordination outcome}
- **DM with {Name}**: {Topic and outcome}

**Action items from Slack**:
- [ ] {Action item}
```

### completed_tasks

Grouped by project with team context.

```markdown
## Progress

### {Project}
- {Completed item} {(team member if delegated)}
- {Status update on in-flight work}

### {Project}
- {Completed item}
```

### blockers

Expanded with ownership and resolution plans.

```markdown
## Blockers & Risks

- **{Blocker}**: {Who's affected}, {resolution plan}, {estimated unblock}
```

### tomorrow_focus

Prominent section for managers.

```markdown
## Tomorrow's Plan

**Priority meetings**:
- {Time}: {Meeting} ({what to prepare})

**Follow-ups needed**:
- {Person}: {Topic}

**Decisions to make**:
- {Decision pending}
```

### Sections de-emphasized

- code_activity: Show only commit count and top-level summary, not individual commits
- jira_updates: Fold into project progress section
- drive_activity: Skip unless significant document activity
- metrics: Fold into executive summary

### Footer

```markdown
---
Generated: {timestamp} {timezone}
```
