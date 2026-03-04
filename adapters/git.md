# Git Adapter

Collects commit activity from configured git repositories.

## Prerequisites

- Git installed and accessible via command line
- Configured repos in `config.data_sources.git.repos` with valid paths

## Config Fields

```json
{
  "data_sources": {
    "git": {
      "enabled": true,
      "repos": [
        { "name": "my-service", "path": "/path/to/repo", "default_branch": "main" }
      ],
      "author_email": "you@company.com"
    }
  }
}
```

- `repos` -- Array of repositories to scan. Each needs at minimum a `path`.
- `author_email` -- Filters commits to only yours. Falls back to `config.user.email`.
- `repos[].name` -- Display name. Falls back to directory name if omitted.
- `repos[].default_branch` -- Defaults to `main`.

## Collection Steps

### Step 1: Determine author email

```
AUTHOR_EMAIL = config.data_sources.git.author_email OR config.user.email
```

### Step 2: Get today's date in user timezone

```bash
TZ={config.user.timezone} date "+%Y-%m-%d"
```

### Step 3: For each repo in config.data_sources.git.repos

Check the repo exists:
```bash
test -d "{repo.path}/.git" && echo "valid" || echo "missing"
```

If missing, log a warning and skip this repo.

Collect all commits from today, across all branches, by the configured author:
```bash
cd {repo.path} && git log --all \
  --since="{today} 00:00:00" \
  --author="{AUTHOR_EMAIL}" \
  --format="%h|%s|%an|%ai" \
  --stat
```

Fields: short hash | subject | author name | date

### Step 4: Parse commit data

For each commit, extract:
- **hash**: Short commit hash (first field)
- **message**: Commit subject line (second field)
- **date**: Commit timestamp (fourth field, convert to user timezone)
- **files_changed**: Number of files changed (from --stat)
- **insertions**: Lines added (from --stat summary)
- **deletions**: Lines removed (from --stat summary)

### Step 5: Detect JIRA ticket IDs (if JIRA is enabled)

Scan commit messages and branch names for ticket patterns:

```
Pattern: [A-Z]+-\d+
```

Apply to:
1. Commit message (e.g., "ENG-375: Fix validation bug")
2. Branch name: `git branch --contains {hash} | head -1`

Normalize: uppercase, add hyphen if missing (e.g., "eng 375" -> "ENG-375"), deduplicate.

Store detected ticket IDs for the JIRA adapter to query later.

### Step 6: Group commits by feature/ticket

Group related commits together:
1. Commits with the same JIRA ticket ID -> group by ticket
2. Commits on the same branch -> group by branch/feature
3. Remaining commits -> group by repo

For each group, calculate:
- Total commits in group
- Net line changes (+added / -removed)
- Files touched

### Step 7: Read state for incremental tracking

Read `lastProcessedCommit` from state file for each repo.
After collection, update state with the latest commit hash.

Note: Even though we track the last processed commit, daily summaries always collect ALL of today's commits (full-day mode). The state is used by the weekly summary to avoid reprocessing.

## Output Fragment

```markdown
## Code Activity

### {Repo Name}

#### {Feature/Ticket Group Title} ({N} commits, +{added}/-{removed})

- [{hash}] {commit message}
- [{hash}] {commit message}

**Impact**: {Brief one-line summary of what this group accomplished}

#### {Another Group} ({N} commits, +{added}/-{removed})

- [{hash}] {commit message}

---

**Daily Code Totals**: {total_commits} commits across {repo_count} repos (+{total_added}/-{total_removed} lines, {total_files} files)
```

### Formatting rules

- Group related commits under a descriptive heading
- Show commit hash in brackets + short message
- One impact statement per group (not per commit)
- Total line changes at the bottom
- If only one repo, skip the repo-level heading

## Empty State

If no commits found today:

```markdown
## Code Activity

No commits today.
```

## Error Handling

- **Repo path doesn't exist**: Log warning, skip repo, continue with others
- **Not a git repo**: Log warning, skip
- **No commits matching author**: Show empty state for that repo
- **Git command fails**: Log the error, skip that repo, continue
