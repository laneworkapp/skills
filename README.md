# Lanework agent skills

A Lanework board is just a folder of plain directories and Markdown files that the Lanework macOS app renders live — there is no API and nothing to sync, so an agent works a board by reading and editing its files directly, exactly the same as its human owner does through the app.

## Skills

| skill | what it's for |
|---|---|
| `lanework-boards` | what a board is, reading one in one pass, and founding a new board by hand |
| `pitlane` | sweeping and working a board: triage, and farming work out to model-tiered subagents |
| `pitwall` | a standing watch on one board, responding to changes as they arrive |

## Install

Clone this repo, then symlink or copy each skill folder into `~/.claude/skills/<name>`, for example:

```bash
git clone https://github.com/laneworkapp/skills.git lanework-skills
ln -s "$(pwd)/lanework-skills/lanework-boards" ~/.claude/skills/lanework-boards
ln -s "$(pwd)/lanework-skills/pitlane" ~/.claude/skills/pitlane
ln -s "$(pwd)/lanework-skills/pitwall" ~/.claude/skills/pitwall
```

`SKILL.md` is the Agent Skills format Claude Code reads; other harnesses that read `SKILL.md` files work the same way.

## Defaults, not rules

The `Pitlane/` folder convention (`<repo root>/Pitlane/<Board>.lanework`, and `~/Pitlane/` for machine-level boards) and the pipeline lane set (Ideas → Shaping → Proposed → Approved → Active → Done, plus Issues) are the defaults these skills ship with, not requirements.

A board's actual folder layout, and each lane's own `index.md` body, always win over the defaults described here — the skills are written to defer to what a board's own files say.

## Versioning

This skill set was written against `lanework-agent-guide v67` and `lanework-schema v1`.

Wherever a skill here disagrees with the in-board guide (`<board>.lanework/CLAUDE.md`, app-maintained and rewritten by Lanework on upgrades), the guide wins.

## License

MIT — see `LICENSE`.
