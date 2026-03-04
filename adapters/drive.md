# Google Drive Adapter

Tracks files you modified today in Google Drive. Reports metadata only.

## Prerequisites

- Google Workspace MCP server configured in Claude Code
- Tool available: `mcp__google-workspace__search_drive_files`
- Configured in `config.data_sources.drive`

## Config Fields

```json
{
  "data_sources": {
    "drive": {
      "enabled": true,
      "provider": "google"
    }
  }
}
```

No additional configuration needed beyond enabling.

## Collection Steps

### Step 1: Search for today's modified files

Use the Google Workspace MCP tool:

```
mcp__google-workspace__search_drive_files:
  query: "modifiedTime > '{today}T00:00:00' and 'me' in owners"
  page_size: 25
  corpora: "user"
  include_items_from_all_drives: false
```

Replace `{today}` with today's date in YYYY-MM-DD format.

**Filtering strategy**:
- `'me' in owners` -- Only files you own (excludes shared docs edited by others)
- `corpora: 'user'` -- Your personal drive only
- `include_items_from_all_drives: false` -- Excludes shared drives

### Step 2: Extract metadata

For each file returned, extract only:
- **File name**
- **File type** (Google Doc, Sheet, Slides, PDF, etc.)
- **Modified timestamp** (convert to user timezone)
- **File link/URL**

### Step 3: Convert timestamps

Convert the `modifiedTime` to the user's configured timezone before display.

## Output Fragment

```markdown
## Google Drive Activity

**Files Modified Today** ({N} files):

- **[{filename}]({link})** ({file_type})
  - Modified: {timestamp in user timezone}

- **[{filename}]({link})** ({file_type})
  - Modified: {timestamp in user timezone}
```

## CRITICAL: No Hallucination Rule

This section reports ONLY factual metadata. You must NEVER:

- Describe what was changed in a file
- Infer why a file was modified
- Connect file changes to tasks or meetings
- Write narrative activity summaries
- Fabricate details about file content

You MAY note a possible connection ONLY if the filename contains an obvious reference (e.g., a JIRA ticket ID in the filename), and you must caveat it:
- "May relate to ENG-123 (filename match)"
- "Note: File modification does not confirm task completion"

## Empty State

```markdown
## Google Drive Activity

No files modified today.
```

## Error Handling

- **MCP tool not available**: Log "Google Drive MCP not configured", skip adapter
- **Auth error**: Log "Drive authentication failed", skip adapter
- **No results**: Show empty state (normal)
