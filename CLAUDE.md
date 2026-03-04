# work-summary-kit

Reusable daily and weekly work summary system for Claude Code.

## Project Structure

- `skills/` -- Claude Code skills (the main entry points)
  - `daily-summary/SKILL.md` -- Generates daily work summaries
  - `weekly-summary/SKILL.md` -- Aggregates dailies into weekly summaries
  - `summary-init/SKILL.md` -- Interactive setup wizard
- `adapters/` -- Data source collection instructions (one file per source)
- `templates/` -- Output format specifications
- `config/` -- JSON Schema, example configs
- `scheduling/` -- Automation templates for launchd/cron

## How It Works

1. User runs `/summary-init` to generate `~/.config/work-summary/config.json`
2. User runs `/daily-summary` -- the skill reads config, loads relevant adapters, generates output
3. User runs `/weekly-summary` on Fridays -- aggregates the week's daily summaries

## Architecture

- **Skills** are the entry points. They orchestrate the workflow.
- **Adapters** are loaded conditionally based on which data sources are enabled in config. Each adapter is a self-contained markdown file with collection instructions.
- **Templates** define output format. The skill reads the template and uses it as a format specification.
- **Config** lives at `~/.config/work-summary/config.json` (never in this repo).

## Adding a New Adapter

1. Create `adapters/{source-name}.md` following the structure of existing adapters
2. Add the source to `config/config.schema.json`
3. Add conditional loading in `skills/daily-summary/SKILL.md`
4. Add a corresponding output section to templates
