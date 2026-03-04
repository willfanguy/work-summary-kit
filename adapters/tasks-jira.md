# JIRA Tasks Adapter

Uses JIRA as your primary task/todo system. Tracks tickets assigned to you as your task list.

## Prerequisites

- Same as the JIRA adapter: JIRA Cloud instance, credentials in env vars
- Configured in `config.data_sources.tasks` with `provider: "jira"`
- JIRA data source (`config.data_sources.jira`) should also be enabled for shared auth

## Config Fields

```json
{
  "data_sources": {
    "tasks": {
      "enabled": true,
      "provider": "jira",
      "jira_tasks": {
        "assignee_email": "you@company.com",
        "active_statuses": ["To Do", "In Progress", "In Development", "In Review"]
      }
    }
  }
}
```

Uses the same auth credentials as `config.data_sources.jira`.

## Collection Steps

### Step 1: Get credentials

Use the same env vars as the JIRA data source adapter:
- Username: `${config.data_sources.jira.username_env}`
- Token: `${config.data_sources.jira.token_env}`
- Base URL: `${config.data_sources.jira.base_url}`

### Step 2: Query assigned tickets

Search for tickets assigned to the user:

```bash
curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --get \
  --data-urlencode "jql=assignee='${ASSIGNEE_EMAIL}' AND status in (${ACTIVE_STATUSES}) AND project in (${PROJECT_KEYS}) ORDER BY priority ASC, updated DESC" \
  --data-urlencode "fields=summary,status,priority,updated,duedate" \
  --data-urlencode "maxResults=50" \
  "${BASE_URL}/rest/api/3/search"
```

Use `config.data_sources.tasks.jira_tasks.assignee_email` for the assignee.
Use `config.data_sources.tasks.jira_tasks.active_statuses` for the status filter.
Use `config.data_sources.jira.project_keys` for the project filter.

### Step 3: Query recently completed tickets

Search for tickets completed today:

```bash
curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --get \
  --data-urlencode "jql=assignee='${ASSIGNEE_EMAIL}' AND status in (${DONE_STATUSES}) AND status changed to (${DONE_STATUSES}) after startOfDay() AND project in (${PROJECT_KEYS})" \
  --data-urlencode "fields=summary,status,priority,updated" \
  --data-urlencode "maxResults=25" \
  "${BASE_URL}/rest/api/3/search"
```

Use `config.data_sources.jira.done_statuses` for the done filter.

### Step 4: Compile task data

**Completed today**: Tickets from step 3
**Active/in-progress**: Tickets from step 2 with status matching `in_progress_statuses`
**Blocked**: Tickets from step 2 that have a blocker flag or are in a "Blocked" status
**Total active**: All tickets from step 2

### Step 5: Group by project

Group tickets by their JIRA project key. Map project keys to friendly names using `config.project_mappings` if available.

## Output Fragment

Same structure as the obsidian adapter output:

```markdown
## Completed Tasks

### {Project Name}

- {TICKET-ID}: {Summary}

**Total**: {N} tasks completed today
```

Metrics provided:
- Tasks completed: N (tickets moved to done status today)
- Tasks in progress: N (active tickets)
- Tasks blocked: N

## Empty State

```markdown
## Completed Tasks

No JIRA tickets completed today. {N} tickets in progress.
```

## Error Handling

- Same as JIRA adapter: auth failures, rate limits, network errors
- If JIRA API is unavailable, the entire task adapter is skipped
