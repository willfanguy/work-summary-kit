# Daily Compact Template

Slim daily summary: executive summary, key metrics, and blockers only. Target: 50-80 lines. Use this when you want a quick snapshot without full detail.

---

## Output Format Specification

### Header

```markdown
# Daily Summary - {Day of Week}, {Month} {Day}, {Year}
```

### executive_summary

3-5 bullet summary. Same as default template.

```markdown
## Summary

- {Most impactful accomplishment}
- {Code activity one-liner: N commits, key feature}
- {Meeting summary: N meetings, Xh, notable outcome}
- {Task completion: N tasks done}
- {Blockers if any, or focus time stat}
```

### metrics

Inline metrics, not a separate section. Fold into summary bullets above.

### code_activity

Commit count and top feature only. No individual commit listing.

```markdown
## Code

{N} commits across {repos} (+{added}/-{removed} lines). Main work: {one-line description of biggest feature group}.
```

### meetings

Count and hours only, plus any notable outcomes.

```markdown
## Meetings

{N} meetings ({hours}h). Focus time: {hours}h ({percentage}%).
{One notable meeting outcome if relevant.}
```

### completed_tasks

Simple list, no project grouping.

```markdown
## Done

- {Task 1}
- {Task 2}
```

### blockers

Same as default.

```markdown
## Blockers

- {Blocker description}: {status}
```

Or omit section entirely if no blockers.

### Footer

```markdown
---
Generated: {timestamp} {timezone}
```

### Sections NOT included in compact

These sections are intentionally omitted from the compact template:
- plan_vs_actual
- jira_updates (fold notable changes into summary)
- slack_activity (fold key decisions into summary)
- drive_activity
- tomorrow_focus
