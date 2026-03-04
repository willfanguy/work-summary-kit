# Slack Adapter

Tracks your Slack message activity for the day via the Slack REST API.

## Prerequisites

- Slack user token (xoxp) with `search:read` and `users:read` scopes
- Environment variable set: value of `config.data_sources.slack.token_env` (default: `SLACK_TOKEN`)
- Configured in `config.data_sources.slack`

## Config Fields

```json
{
  "data_sources": {
    "slack": {
      "enabled": true,
      "token_env": "SLACK_TOKEN",
      "username": "jane.engineer",
      "channel_categories": {
        "project": ["eng-*", "proj-*"],
        "coordination": ["general", "engineering"],
        "support": ["ask-*", "help-*"]
      }
    }
  }
}
```

## Collection Steps

### Step 1: Verify token

```bash
test -n "${SLACK_TOKEN}" && echo "set" || echo "WARNING: SLACK_TOKEN not set"
```

Use the env var name from `config.data_sources.slack.token_env`. If not set, log warning and skip.

### Step 2: Search today's messages

```bash
curl -s -H "Authorization: Bearer ${SLACK_TOKEN}" \
  --get \
  --data-urlencode "query=from:${USERNAME} on:${TODAY}" \
  --data-urlencode "count=100" \
  "https://slack.com/api/search.messages"
```

Replace `${USERNAME}` with `config.data_sources.slack.username` and `${TODAY}` with today's date.

**Important**: Use the Slack REST API directly, not Glean or any other aggregator. Direct API gives complete results.

### Step 3: Parse results

From the API response, extract for each message:
- `channel.name` -- Channel name
- `channel.id` -- Channel ID
- `text` -- Message content
- `ts` -- Timestamp
- `username` -- Author (should be you for `from:` queries)

Count total messages and unique channels.

### Step 4: Resolve user names in conversations

For DMs or threads where other users are mentioned, resolve their identities:

```bash
curl -s -H "Authorization: Bearer ${SLACK_TOKEN}" \
  "https://slack.com/api/users.info?user=${USER_ID}"
```

Use `user.profile.display_name` or `user.profile.real_name` as the default name.

Then check `config.name_mappings`:
1. If their email is in `confirmed` -> use that name
2. If in `unverified` -> use email prefix
3. Otherwise -> use Slack profile name

**CRITICAL**: Only report users who actually appear in the API response. Never fabricate or guess participants.

### Step 5: Categorize by channel

Match channel names against `config.data_sources.slack.channel_categories`:

For each category (project, coordination, support):
- Check each channel name against the category's patterns
- Patterns support `*` as wildcard (e.g., `eng-*` matches `eng-backend`, `eng-frontend`)
- Unmatched channels go to "Other"

DMs go to a separate "Direct Messages" category.

### Step 6: Summarize activity

For each channel, create a brief summary:
- Topic of discussion (from message content)
- Key decisions made (look for affirmative language, agreements)
- Action items (look for "I'll", "TODO", "action item", task-like language)

Keep summaries brief -- one line per channel unless there's a significant decision or action item.

## Output Fragment

```markdown
## Slack Activity

**Overview**: {N} messages across {channel_count} channels

### Project Discussions ({N} messages)

- **#{channel}** ({N} messages): {Brief topic summary}

### Team Coordination ({N} messages)

- **#{channel}** ({N} messages): {Brief topic summary}
- **DM with {Name}** ({N} messages): {Brief topic summary}

### Key Decisions

- {Decision made, with channel reference}

### Action Items from Slack

- [ ] {Action item identified}
```

### Formatting rules

- Group by channel category, then by channel
- Summarize threads rather than listing individual messages
- Focus on outcomes (decisions, action items) over conversation details
- Keep brief -- one line per channel in most cases

## Empty State

```markdown
## Slack Activity

No Slack activity today.
```

## Error Handling

- **Token not set**: Log warning, skip adapter
- **Auth error (401)**: Log "Slack token expired or invalid", skip adapter
- **Rate limited (429)**: Wait 3 seconds, retry once. Note in footer if still limited.
- **API returns no results**: Show empty state (normal for low-activity days)
- **User resolution fails**: Use the user ID as fallback display name
