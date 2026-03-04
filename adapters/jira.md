# JIRA Adapter

Fetches ticket status and activity from JIRA Cloud via REST API.

## Prerequisites

- JIRA Cloud instance accessible via API
- Environment variables set:
  - `JIRA_USERNAME` (or custom name from `config.data_sources.jira.username_env`)
  - `JIRA_API_TOKEN` (or custom name from `config.data_sources.jira.token_env`)
- Configured in `config.data_sources.jira`

## Config Fields

```json
{
  "data_sources": {
    "jira": {
      "enabled": true,
      "base_url": "https://company.atlassian.net",
      "project_keys": ["ENG", "PLAT"],
      "username_env": "JIRA_USERNAME",
      "token_env": "JIRA_API_TOKEN",
      "done_statuses": ["Done", "Closed", "Resolved"],
      "in_progress_statuses": ["In Progress", "In Development", "In Review"],
      "handed_off_statuses": ["QA", "Ready for Staging"]
    }
  }
}
```

## Collection Steps

### Step 1: Verify credentials

```bash
test -n "${!JIRA_USERNAME_ENV}" && echo "username set" || echo "WARNING: username not set"
test -n "${!JIRA_TOKEN_ENV}" && echo "token set" || echo "WARNING: token not set"
```

Replace `JIRA_USERNAME_ENV` and `JIRA_TOKEN_ENV` with the actual env var names from config.

If credentials are missing, log a warning and skip JIRA collection. Do NOT fail the entire summary.

### Step 2: Collect ticket IDs to query

Gather ticket IDs from multiple sources:

1. **From git adapter** (if git is also enabled): Use ticket IDs detected in commit messages and branch names
2. **From task adapter** (if tasks are enabled): Use JIRA IDs from task notes
3. **From config**: Use `project_keys` to search for recently updated tickets

### Step 3: Query each ticket

For each unique ticket ID found:

```bash
curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${BASE_URL}/rest/api/3/issue/${TICKET_ID}?fields=summary,status,priority,updated,duedate,customfield_10020"
```

Extract:
- `fields.summary` -- Ticket title
- `fields.status.name` -- Current status
- `fields.priority.name` -- Priority level
- `fields.updated` -- Last update timestamp
- `fields.duedate` -- Due date (if set)
- `fields.customfield_10020` -- Sprint data (may be array, null, or string)

### Step 4: Classify ticket status

Using `config.data_sources.jira.*_statuses` lists:

- Match `fields.status.name` against `done_statuses` -> Done
- Match against `in_progress_statuses` -> In Progress
- Match against `handed_off_statuses` -> Handed Off
- No match -> use the status name as-is

### Step 5: Handle sprint field

Sprint data (`customfield_10020`) is notoriously inconsistent:

1. If it's an array, use the first element
2. If null/empty, fall back to `duedate`
3. If it's a string containing dates, extract them
4. If parsing fails, note "Sprint data unavailable" and continue

### Step 6: Search for recently updated tickets (optional)

If fewer than 3 tickets were found from commits/tasks, search for your recently updated tickets:

```bash
curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${BASE_URL}/rest/api/3/search?jql=assignee=currentUser()+AND+updated>=-1d+AND+project+in+(${PROJECT_KEYS})&fields=summary,status,priority,updated"
```

Replace `${PROJECT_KEYS}` with comma-separated project keys from config.

## Output Fragment

```markdown
## JIRA Ticket Updates

### {TICKET-ID} - {Summary}

- **Status**: {status_name} {status_change_indicator}
- **Priority**: {priority}
- **Activity**: {linked commits, recent updates}
- **Sprint/Deadline**: {sprint or due date info}

### {TICKET-ID} - {Summary}

- **Status**: {status_name}
- **Priority**: {priority}
```

Status change indicators:
- Arrow up if status progressed toward done
- Warning if approaching deadline
- No indicator if unchanged

## Empty State

```markdown
## JIRA Ticket Updates

No JIRA activity detected today.
```

## Error Handling

- **Auth failure (401)**: Log "JIRA authentication failed -- check credentials", skip adapter
- **Ticket not found (404)**: Note "{TICKET-ID}: not found or no access", continue with others
- **Rate limited (429)**: Wait 2 seconds, retry once. If still limited, note the error and continue.
- **Network error**: Log the error, note "JIRA API unavailable" in footer
- **NEVER fall back to local status**: If the API fails, report "Status unknown (API unavailable)", never use cached/local status
