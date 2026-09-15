---
name: lanework-boards
description: "What a Lanework board is, how to read one, and how to cold-start a new one by hand. A board is a folder named `<Name>.lanework` holding plain directories and Markdown files that the Lanework macOS app renders live: the files ARE the board, there is no API and nothing to sync. Covers the shape of a board, the authority chain to read before any write, where boards live by convention, a one-pass shell recipe for reading a whole board, the three default lane sets (pipeline, design loop, datapoint), and the founding recipe for a brand new board. Use this skill whenever the user wants a new board, asks to create a board, found a board, start a board, 'set up a lanework board for X', 'a board for tracking X', or asks what a Lanework board is and how boards work. Not for sweeping or working an existing board and farming its cards out to subagents (that is the pitlane skill), and not for standing watch on a board and answering comments live (that is the pitwall skill)."
---

# Lanework boards

## What a board is

A Lanework board is a folder named `<Board Name>.lanework` holding plain directories and UTF-8 Markdown files, which the Lanework macOS app renders live as a kanban board.

> Plain folders and Markdown, rendered live by the Lanework app. You can (and should) manipulate the board by editing files directly — while the board is open, the app picks up every filesystem change automatically. There is nothing to sync and no API to call: the files are the board. (agent guide, opening paragraph)

Depth inside the board folder is the whole type system:

> Depth alone defines meaning: depth 1 = lane, depth 2 = card. There is no type field. (agent guide, *Layout*)

> Folder names are lowercase UUIDs and are the item's permanent identity. **Never rename a folder.** Titles live in frontmatter only. (agent guide, *Layout*)

Every item is a folder with an `index.md` inside it: YAML frontmatter between `---` lines, then a Markdown body. A board's `index.md` carries the board's title and settings, a lane's carries its title and `order`, a card's carries its title plus the body that is the card's content. Cards additionally hold `attachments/` and `comments/`.

Four names at board root belong to the app and not to you: `CLAUDE.md` and its byte-identical twin `AGENTS.md` (the agent guide), `.schema/` (the JSON Schema set plus its validator), `.log/` (the activity log, read-only for you), and `.trash/` (deleted cards and lanes). The app writes and refreshes all of them.

## The authority chain, read before any write

This skill does not restate the file format. Every board carries its own spec, it is versioned, and the app rewrites it on upgrades, so a copy here would rot. Before acting on any board, read, in order:

1. **`<board>.lanework/CLAUDE.md`** (or its twin `AGENTS.md`), the app-maintained agent guide. It is the complete and current authority on layout, frontmatter, stamping, creating and moving and trashing items, attachments, comments, mentions and git conduct. **Never edit it**, and never trust a remembered older version over what the file says today.
2. **The board's own `index.md` body**, where everything below the first `##` heading is the owner's instruction sheet for agents on that board, and everything above it is the board's description.
3. **Each lane's `index.md` body**, the per-lane entry criteria and policy, read before filing a card into that lane or moving one out of it.

Lower layers refine, never override. A board's `index.md` adds process on top of the guide, and this skill sits below both: where anything here seems to disagree with a board's own files, the board's files win.

A brand new board has no guide yet. That is the one moment this skill is the authority, and it lasts until the board's first open, when the app installs the guide and the schema set.

## Finding boards

Boards can live anywhere and be named anything. Two conventions are worth knowing because they are where boards usually are:

- **`<repo root>/Pitlane/<Name>.lanework`** for a project's own boards, inside the project's git repository, so the board's history travels with the code it tracks.
- **`~/Pitlane/<Name>.lanework`** for machine-level boards that belong to no single project.

Both are defaults, not rules. Ask the user where a board should go if the answer matters, and take a path they give you over either convention.

```bash
ls -d "<repo root>"/Pitlane/*.lanework   # a project's boards
ls -d ~/Pitlane/*.lanework               # machine-level boards
```

Do not scan the filesystem for boards. A project is identified by the work at hand or by the user naming it, and its `Pitlane/` folder is then the whole answer.

## Reading a board in one pass

Lanes run left to right by ascending `order`, cards top to bottom by ascending `order` within their lane, and an item with no `order` sorts after every item that has one. This prints a whole board in that reading order, with no dependencies:

```bash
board="<path>/<Name>.lanework"

lwf() { awk -v k="^$2:" '/^---[ \t]*$/ {n++; next} n==1 && $0 ~ k {sub(/^[^:]*:[ \t]*/, ""); print; exit}' "$1"; }

printf '%s  [%s]\n' "$(lwf "$board/index.md" title)" "$(lwf "$board/index.md" id)"

for lane in "$board"/*/; do
  [ -f "$lane/index.md" ] || continue
  o=$(lwf "$lane/index.md" order)
  printf '%s\t%s\t%s\n' "${o:-999999999}" "$(lwf "$lane/index.md" title)" "$lane"
done | sort -n | while IFS=$'\t' read -r o t lane; do
  printf '\n== %s (order %s)\n' "$t" "$o"
  for card in "$lane"*/; do
    [ -f "$card/index.md" ] || continue
    co=$(lwf "$card/index.md" order)
    printf '%s\t%s\t%s\n' "${co:-999999999}" "$(lwf "$card/index.md" title)" "$(basename "$card")"
  done | sort -n | while IFS=$'\t' read -r co ct cid; do
    printf '   %-8s %s  [%s]\n' "$co" "$ct" "${cid:0:8}"
  done
done
```

Notes on that recipe: the `*/` globs skip `.schema/`, `.log/` and `.trash/` for free because those names start with a dot, and quoting every path matters because a board's own folder name almost always contains a space. `lwf` prints the raw scalar, so a quoted title comes back with its quotes on; if a real YAML reading is needed, `yq` is a fine optional upgrade, but nothing here requires it.

Then read the bodies, which is where the meaning is: the board's `index.md` body, then the lane bodies, then the cards you care about. A card's comment thread is `comments/<uuid>/index.md`, sorted by `created.at` ascending.

## Cold-starting a new board

The whole recipe, with the literal file templates, is in `references/founding.md`. Read it before founding anything. The five-line version:

1. Make the folder `<Name>.lanework`, wherever the board belongs.
2. Write the board's own `index.md`: frontmatter with `schema: 1` and `kind: board`, body with the description above the first `##` and the owner's agent instruction sheet below it.
3. Make one lowercase-uuid folder per lane, each with an `index.md` carrying `kind: lane`, a `title`, an `order`, and a body stating that lane's entry criteria.
4. Write nothing else. On the first open the app heals in the rest: the guide pair `CLAUDE.md` and `AGENTS.md`, the current `.schema/` set, a seeded `.gitignore`, and the board `id` if you left it out. **Never copy `.schema/`, the guide files or the `.gitignore` from another board**, because a copied schema set brings that board's version marker with it.
5. Commit the board folder by its own explicit path, open it in the app, then commit the healed files as a second commit.

## Board kinds

Three lane sets cover most boards, and each comes with its own idea of what a card is: a **pipeline** (stages of commitment), a **design loop** (Brief through Chosen), and a **datapoint board** (one card per value, the body is the current value). Each set, with suggested `order` values and who moves a card, is in `references/board-kinds.md`. They are defaults and starting points, not rules: a board earns its own lane semantics whenever its work does not fit one of them.

## Writing conduct

The board's own guide has the full rules. These are the ones that hold on every board and cost the most when they are got wrong:

- **Stamp every write.** `created` and `modified` are mappings whose `by` is an identity map, and **a missing `by` claims the board's owner wrote the file**. Stamp `by: {name: <your name>, kind: agent, model: <your model>}` on everything you write, and move `at` and `by` together, always.
- **Write atomically, and stage the temp file outside the board.** The app reloads on every filesystem event and can catch a half-written file; write to a temp path outside the board folder, then `mv` it into place. A temp file left beside a card's `index.md` is not deleted, it is relocated into that card's `attachments/`.
- **Never rename a uuid folder.** The folder name is the item's permanent identity, and every link and reference to the item is that name.
- **Delete by moving into `<board>/.trash/`**, never `rm -r`. A container change stamps `modified`, and the trash sorts by `modified.at`.
- **Resolve a card's path immediately before every write to it.** A card can change lanes between your read and your write, and writing to the stale path silently creates a card-shaped ghost folder. If a write would have to create the card folder first, the path is wrong.
- **Icons: a glyph, and a color only with a reason.** An `icon` is a mapping, `{glyph: <SF Symbol name>}`; leave `color` off unless the tint says something the glyph cannot.
- **Git**: stage only your own paths, never `git add -A` or `git add .`, and keep board writes and code changes in separate commits.

Two other skills build on this one: **pitlane** for sweeping and working a board and farming its cards out to subagents, and **pitwall** for standing watch on a board and answering comments as they land. Both assume everything above.

## Versioning

Written against `lanework-agent-guide v67` and `lanework-schema v1`. Both markers are on line 1 of their own file, `CLAUDE.md` and `.schema/VERSION`, at the root of any board. If a board's guide reads a later version, the guide is right and this skill is stale.
