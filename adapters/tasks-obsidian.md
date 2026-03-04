# Obsidian Task Notes Adapter

Reads task completions from Obsidian-style markdown files with YAML frontmatter.

## Prerequisites

- Obsidian vault (or any directory of markdown files with YAML frontmatter)
- Configured in `config.data_sources.tasks` with `provider: "obsidian"`

## Config Fields

```json
{
  "data_sources": {
    "tasks": {
      "enabled": true,
      "provider": "obsidian",
      "obsidian": {
        "tasks_path": "/path/to/vault/Tasks",
        "status_field": "status",
        "done_value": "done",
        "completed_date_field": "completedDate",
        "project_field": "project",
        "priority_field": "priority"
      }
    }
  }
}
```

All field names are configurable to support different frontmatter schemas. Defaults shown above.

## Collection Steps

### Step 1: Verify tasks directory exists

```bash
test -d "{tasks_path}" && echo "valid" || echo "missing"
```

If missing, log warning and skip.

### Step 2: Find task files

```bash
find "{tasks_path}" -name "*.md" -type f
```

### Step 3: Parse each file's frontmatter

For each `.md` file, read the YAML frontmatter (between `---` delimiters at the top of the file).

Extract these fields (using configured field names):
- `{status_field}` -- Task status
- `{completed_date_field}` -- Date the task was completed (YYYY-MM-DD)
- `{project_field}` -- Project/area name
- `{priority_field}` -- Priority level
- `title` -- Task title (from frontmatter or filename)
- `jira` -- JIRA ticket ID if linked (optional)

### Step 4: Filter to today's completions

A task counts as completed today if:
- `{status_field}` equals `{done_value}` (default: "done")
- AND `{completed_date_field}` equals today's date

Also track:
- **In-progress tasks**: `status` = "in-progress" (for metrics)
- **Blocked tasks**: `status` = "blocked" (for blockers section)
- **New tasks**: `dateCreated` = today (for "tasks created" count)

### Step 5: Group by project

Group completed tasks by their `{project_field}` value.

Apply `config.project_mappings` to convert folder/internal names to friendly display names.

### Step 6: Cross-reference with JIRA (if JIRA is enabled)

For completed tasks that have a `jira` field, note the ticket ID for the JIRA adapter to verify status.

## Output Fragment

### For the completed_tasks section:

```markdown
## Completed Tasks

### {Project Name}

- {Task title} ({JIRA-ID if linked})
- {Task title}

### {Another Project}

- {Task title}

**Total**: {N} tasks completed today
```

### For the metrics section:

Provide these counts:
- Tasks completed: N
- Tasks in progress: N
- Tasks blocked: N
- Tasks created today: N

### For the blockers section:

```markdown
## Active Blockers

- **{Task title}**: {blocker description from task body if available}
```

## Empty State

```markdown
## Completed Tasks

No tasks completed today.
```

## Error Handling

- **Tasks directory missing**: Log warning, skip adapter
- **File read error**: Skip that file, continue with others
- **Malformed frontmatter**: Skip that file, log warning
- **Missing fields**: Use defaults (no project = "Uncategorized", no priority = "normal")
