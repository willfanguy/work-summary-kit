# Google Tasks Adapter

Uses Google Tasks as your primary task/todo system.

## Prerequisites

- Google Workspace MCP server configured in Claude Code
- Tool available: `mcp__google-workspace__list_tasks`
- Configured in `config.data_sources.tasks` with `provider: "google-tasks"`

## Config Fields

```json
{
  "data_sources": {
    "tasks": {
      "enabled": true,
      "provider": "google-tasks",
      "google_tasks": {
        "list_id": "@default"
      }
    }
  }
}
```

- `list_id` -- Google Tasks list ID. Use `@default` for the primary list. Get list IDs via `mcp__google-workspace__list_task_lists`.

## Collection Steps

### Step 1: Get task list ID

Use `config.data_sources.tasks.google_tasks.list_id`. If set to `@default`, use the primary task list.

If the user hasn't specified a list, first list available task lists:

```
mcp__google-workspace__list_task_lists
```

And use the first/primary list.

### Step 2: Fetch completed tasks

```
mcp__google-workspace__list_tasks:
  task_list_id: "{list_id}"
  show_completed: true
  show_hidden: true
  completed_min: "{today}T00:00:00Z"
  completed_max: "{tomorrow}T00:00:00Z"
  max_results: 50
```

This returns tasks completed today.

### Step 3: Fetch active tasks

```
mcp__google-workspace__list_tasks:
  task_list_id: "{list_id}"
  show_completed: false
  max_results: 50
```

This returns open/active tasks for metrics.

### Step 4: Parse task data

For each task, extract:
- `title` -- Task name
- `status` -- "needsAction" or "completed"
- `completed` -- Completion timestamp (for completed tasks)
- `due` -- Due date (if set)
- `notes` -- Task description/notes

### Step 5: Count metrics

- Tasks completed today: count of tasks from step 2
- Tasks active: count of tasks from step 3 with status "needsAction"
- Tasks overdue: active tasks where `due` < today

## Output Fragment

```markdown
## Completed Tasks

- {Task title}
- {Task title}

**Total**: {N} tasks completed today
```

Google Tasks doesn't have a project concept, so tasks are listed flat (no project grouping) unless the user has organized by task list.

## Empty State

```markdown
## Completed Tasks

No tasks completed today. {N} tasks active.
```

## Error Handling

- **MCP tool not available**: Log "Google Tasks MCP not configured", skip adapter
- **Auth error**: Log "Google Tasks authentication failed", skip adapter
- **Empty list**: Show empty state
