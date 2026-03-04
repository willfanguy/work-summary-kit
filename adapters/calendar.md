# Calendar Adapter

Fetches today's meetings from Google Calendar and calculates focus time.

## Prerequisites

- Google Workspace MCP server configured in Claude Code
- Tool available: `mcp__google-workspace__get_events`
- Configured in `config.data_sources.calendar`

## Config Fields

```json
{
  "data_sources": {
    "calendar": {
      "enabled": true,
      "provider": "google",
      "calendar_id": "primary",
      "working_hours": { "start": "09:00", "end": "18:00" },
      "meeting_categories": {
        "standup": ["standup", "stand-up", "daily", "scrum"],
        "planning": ["planning", "sprint", "refinement", "grooming", "retro"],
        "review": ["review", "demo", "showcase", "presentation"],
        "one_on_one": ["1:1", "1-on-1", "one-on-one", "check-in"],
        "social": ["lunch", "coffee", "social", "happy hour"]
      }
    }
  }
}
```

## Collection Steps

### Step 1: Fetch today's events

Use the Google Workspace MCP tool:

```
mcp__google-workspace__get_events:
  calendar_id: {config.data_sources.calendar.calendar_id}
  time_min: "{today}T00:00:00Z"
  time_max: "{tomorrow}T00:00:00Z"
  max_results: 50
  detailed: true
```

### Step 2: Filter events

Include:
- Events with response status: `accepted`, `tentative`, `needsAction`, `organizer`

Exclude:
- Events with response status: `declined`
- All-day events (unless they indicate OoO or similar)

### Step 3: Convert timezones

Convert all event times to the user's configured timezone (`config.user.timezone`).

The calendar API may return times in UTC or the event's timezone. Always convert before display.

```
For each event:
  start_time = convert(event.start, config.user.timezone)
  end_time = convert(event.end, config.user.timezone)
  duration = end_time - start_time
```

### Step 4: Categorize meetings

For each event, determine its category using `config.data_sources.calendar.meeting_categories`.

**Priority-based matching** (first match wins):

1. Convert event title to lowercase
2. Check categories in this order: standup, planning, review, one_on_one, social
3. For each category, check if any keyword from the config appears in the title
4. First match wins -- stop checking
5. If no match, category = "other"

**Category emoji**:
- standup: (no emoji, or use a running person symbol)
- planning: (clipboard)
- review: (eye)
- one_on_one: (people)
- social: (coffee)
- other: (calendar)

### Step 5: Calculate time allocation

Using `config.data_sources.calendar.working_hours`:

```
working_day_hours = end_hour - start_hour  (e.g., 18 - 9 = 9 hours)
total_meeting_hours = sum of all meeting durations
focus_hours = working_day_hours - total_meeting_hours
meeting_percentage = (total_meeting_hours / working_day_hours) * 100
focus_percentage = 100 - meeting_percentage
```

### Step 6: Assess focus quality

Identify contiguous free blocks between meetings:

- **Deep work block**: 2+ hours uninterrupted
- **Focus block**: 1-2 hours
- **Fragment**: < 1 hour

Assessment:
- **High**: 6+ focus hours, 1-2 meeting clusters
- **Moderate**: 4-6 focus hours, 3-4 meeting blocks
- **Low**: < 4 focus hours, or 5+ meetings, or heavily fragmented

## Output Fragment

```markdown
## Meetings & Time Allocation

**Meeting Breakdown** ({N} meetings, {total_hours}h total):

- {emoji} {start}-{end} ({duration}) {title} {(tentative) if tentative}
- {emoji} {start}-{end} ({duration}) {title}

**Time Analysis**:

- Meeting Time: {hours}h ({percentage}% of day)
- Focus Time: {hours}h ({percentage}% of day)
- Deep Work Blocks: {count} ({description})
- Focus Quality: {High/Moderate/Low}
```

Sort meetings chronologically.

## Empty State

```markdown
## Meetings & Time Allocation

No meetings today. Full focus day available ({working_hours}h).
```

## Error Handling

- **MCP tool not available**: Log "Google Calendar MCP not configured", skip adapter
- **Auth error**: Log "Calendar authentication failed -- reauthorize the Google Workspace MCP server", skip adapter
- **No events returned**: Show empty state (this is normal, not an error)
- **Timezone conversion fails**: Fall back to UTC display with a note
