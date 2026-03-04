# Linear Adapter

Uses Linear as your primary task/issue tracking system.

## Prerequisites

- Linear API token
- Environment variable set: value of `config.data_sources.tasks.linear.token_env` (default: `LINEAR_API_TOKEN`)
- Configured in `config.data_sources.tasks` with `provider: "linear"`

## Config Fields

```json
{
  "data_sources": {
    "tasks": {
      "enabled": true,
      "provider": "linear",
      "linear": {
        "token_env": "LINEAR_API_TOKEN",
        "team_key": "ENG"
      }
    }
  }
}
```

- `token_env` -- Name of the env var holding the Linear API token
- `team_key` -- Linear team key to filter issues

## Collection Steps

### Step 1: Verify token

```bash
test -n "${LINEAR_API_TOKEN}" && echo "set" || echo "WARNING: LINEAR_API_TOKEN not set"
```

If not set, log warning and skip.

### Step 2: Query completed issues

Linear uses a GraphQL API:

```bash
curl -s -X POST \
  -H "Authorization: ${LINEAR_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ issues(filter: { assignee: { isMe: { eq: true } }, completedAt: { gte: \"'"${TODAY}T00:00:00Z"'\" }, team: { key: { eq: \"'"${TEAM_KEY}"'\" } } }, first: 50) { nodes { identifier title state { name } priority completedAt project { name } } } }"
  }' \
  "https://api.linear.app/graphql"
```

### Step 3: Query active issues

```bash
curl -s -X POST \
  -H "Authorization: ${LINEAR_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ issues(filter: { assignee: { isMe: { eq: true } }, state: { type: { nin: [\"completed\", \"canceled\"] } }, team: { key: { eq: \"'"${TEAM_KEY}"'\" } } }, first: 50) { nodes { identifier title state { name } priority dueDate project { name } } } }"
  }' \
  "https://api.linear.app/graphql"
```

### Step 4: Parse results

For each issue, extract:
- `identifier` -- Issue ID (e.g., ENG-123)
- `title` -- Issue title
- `state.name` -- Current status
- `priority` -- Priority (0=none, 1=urgent, 2=high, 3=medium, 4=low)
- `completedAt` -- Completion timestamp
- `project.name` -- Project name (if assigned)

### Step 5: Group by project

Group issues by `project.name`. Apply `config.project_mappings` for friendly names.

## Output Fragment

```markdown
## Completed Tasks

### {Project Name}

- {ISSUE-ID}: {Title}

### {Another Project}

- {ISSUE-ID}: {Title}

**Total**: {N} issues completed today
```

Metrics:
- Issues completed: N
- Issues in progress: N
- Issues blocked: N (state contains "blocked")

## Empty State

```markdown
## Completed Tasks

No Linear issues completed today. {N} issues in progress.
```

## Error Handling

- **Token not set**: Log warning, skip adapter
- **Auth failure (401)**: Log "Linear API token invalid", skip adapter
- **GraphQL error**: Log the error message, skip adapter
- **Rate limited**: Wait 2 seconds, retry once
