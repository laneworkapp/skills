# Founding a board by hand

Cold-starting a new Lanework board: the two file templates, a runnable recipe, what not to write, how to check it before the app ever sees it, and how the first two commits go.

## When a new board is warranted at all

Most work that feels like it needs a board does not. A program card on an existing board, with its own comment thread and a handful of child cards beside it, carries a multi-week effort perfectly well and keeps it in the same reading order as everything else. Splitting work across boards costs a reader every time they have to remember which board something is on.

A new board earns itself when it has at least one of three things of its own. **Its own lane semantics**: the work moves through stages the existing board's lanes do not describe, so cards on it would sit in lanes that mean the wrong thing. **Its own instruction sheet**: the conduct for this work is different enough that the owner would be writing a second set of rules into one board's body. **Its own audience**: a different set of people or agents read it, and mixing it into an existing board buries what each of them came for.

When none of those is true, file a card instead. When you are unsure, ask the owner in one sentence before founding anything.

## The board's `index.md`

The one file that must exist, and the only place `schema: 1` is required.

> Frontmatter must parse as YAML. The board's own `index.md` must carry `schema: 1`; everywhere else `schema` and `order` are optional and a missing one is read, never refused. (agent guide, *Hard rules*)

```markdown
---
schema: 1
kind: board
title: Acme Pipeline
id: 67a7285d-c960-4008-b5b9-9ee0e7cd6fe0
icon: {glyph: arrowshape.forward.fill}
config: {show-card-body: 3}
created:  {at: 2026-09-15T15:51:55Z, by: {name: claude, kind: agent, model: opus-5}}
modified: {at: 2026-09-15T15:51:55Z, by: {name: claude, kind: agent, model: opus-5}}
---
# Acme Pipeline

<the description: one or two paragraphs saying what this board is for and what a card on it is>

## How this board works

<the owner's instruction sheet for agents, one line per rule>
```

Key by key:

- `schema: 1` and `kind: board` are both written at creation. `kind` is redundant with position everywhere except `.trash/`, which is flat, so write it anyway.
- `title` is the display name. Absent, it falls back to the folder name without the extension, so writing it is optional but always worth it. **Quote any title containing a colon**, and keep every scalar on one line.
- `id` is a lowercase uuid, the board's identity and the host of every `lanework://` link into it. It is the one key here the app will mint for you: "a lowercase UUID that is the board's identity, written by the app the first time it opens a board without one" (agent guide, *Frontmatter*). Writing one by hand is optional and recommended, because a board that already has its id is linkable from the moment it exists and its founding commit is complete. **Never change it once it is there.**
- `icon` is the mapping `{glyph, color}`. A glyph alone is the normal case; add `color` only when the tint says something the glyph cannot.
- `config` is the board's settings mapping, and every subkey is optional. `show-card-body: 3` previews the first three lines of each card's opening paragraph on the card face, which is worth having on a board whose cards carry prose. `show-statusbar: true` adds the breadcrumb along the window's bottom edge. Leave the mapping out entirely if you want every default.
- `created` and `modified` are mappings, never bare timestamps: `{at: <ISO-8601 with zone>, by: {name, kind, model}}`. Get the timestamp from `date -u +%FT%TZ`. A missing `by` is a claim that the board's owner wrote the file, so an agent always writes one, with `kind: agent`. Any extra subkey under `by` is preserved verbatim, so a session name or a tool name can ride along there.

### The body: description, then the instruction sheet

The body's split is load-bearing, and it is the first thing any agent reads on the board:

> **Read this board's `index.md` body before doing anything else**: everything below its first `##` heading is the owner's instruction sheet for agents on this board; above it is the board's description. A body with no `##` heading at all is entirely description. (agent guide, opening)

Above the first `##`: what the board is for, what one card on it represents, and where the work comes from. Below it: the rules an agent needs before it touches a card. A worked example, the shape to aim for:

```markdown
# Acme Pipeline

Where work on Acme goes from a raw idea to something built, one card per piece of work. Lanes are stages of commitment, so a card's lane says who acts next.

## How this board works

- **Flow**: Ideas to Shaping to Proposed to Approved to Active to Done, with Issues as the side entrance for things broken in the running system.
- **Two human gates**: triage out of Ideas, and review out of Proposed. Agents surface what sits at a gate and never move a card through one.
- **A card is ready to build** when its body names the files it touches, the command that verifies it, and a done-when a reader could check without asking.
- **Verified means** `<the project's own test command>` run on the current head, with its output quoted in the closing comment.
- **The body is the spec, the thread is the journal.** Edit the body when scope or done-when change, put everything else in comments.
- **Git**: this board lives in the Acme repo. Commit your own board writes with a plain message, stage only your own paths, and keep board writes and code changes in separate commits.
```

What belongs there is whatever an agent would otherwise get wrong: the gates and who holds them, the quality bar for a card, what counts as verified, the blast radius nobody may exceed, and the repo conduct. What does not belong there is anything the app's own guide already states, because the guide is read first and is newer than anything written here.

Per-board process lives in this body and nowhere else:

> Per-board process — lane cadence, commit conventions, anything specific to this board — belongs in the board's `index.md` body, under a `##` heading, not here — and not in a file of its own at board root. (agent guide, *Use the thread*)

## A lane's `index.md`

One folder per lane, named a fresh lowercase uuid, each holding exactly this file. Nothing else is needed to found a lane.

```markdown
---
schema: 1
kind: lane
title: Shaping
order: 2048
created:  {at: 2026-09-15T15:51:55Z, by: {name: claude, kind: agent, model: opus-5}}
modified: {at: 2026-09-15T15:51:55Z, by: {name: claude, kind: agent, model: opus-5}}
---
The agent work lane. A raw idea is developed here into a proposal with scope, constraints, risks and a recommendation in the body.

A card here is actively being worked. When the proposal is ready for human eyes it moves to Proposed, never straight to Approved.
```

- `order` ranks lanes left to right, ascending, and a lane without one goes last.
- The body is the lane's entry criteria and policy: what puts a card in this lane, what takes it out, and who is allowed to do either. Agents read it before filing into the lane or moving a card out of it, so write it as instructions rather than as a label.
- A lane may also carry `icon`, `background`, `width` (an integer multiplier of the standard lane width), `collapsed: true` to fold it to a slim strip, `group` to section its cards, and `filter` to narrow which of them show. All are optional and none is needed to found a board. To expand a collapsed lane later, remove the key rather than writing `collapsed: false`.

### How `order` works, and the spacing to use

> **`order` is what places the card, and computing it means reading the lane**: bottom of the lane = max existing card `order` + 1024; top = min − 1024; between two cards = their midpoint. (Empty lane: any number, conventionally 1024.) (agent guide, *Creating a card*)

Lanes rank the same way among themselves. So a fresh lane set is numbered `1024, 2048, 3072, …`, one step of 1024 per lane, which is exactly what the boards in the wild carry. The gap is the point: inserting a lane between the second and the third later means writing `2560`, their midpoint, and touching no other file. Slotting a side entrance in beside Ideas means `1536`. Ties break by folder name, and an item with no `order` sorts after every item that has one.

## The recipe

Founding a board is one script. It mints the uuids, writes each file to a temp path outside the board and moves it in, and writes nothing the app is going to write for itself.

```bash
#!/bin/bash
# found-board.sh: cold-start a Lanework board by hand.
# usage: found-board.sh "<path>/<Name>.lanework" ["Board Title"]
set -euo pipefail

BOARD="${1:?usage: found-board.sh <path to Name.lanework> [title]}"
TITLE="${2:-$(basename "$BOARD" .lanework)}"

NOW=$(date -u +%FT%TZ)
BY='{name: claude, kind: agent, model: opus-5}'

# Every write is staged OUTSIDE the board and moved in: the app reloads on
# every filesystem event, and a temp file left inside a board is swept.
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/lanework-found.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$BOARD"
BOARD_ID=$(uuidgen | tr 'A-Z' 'a-z')

# ---- the board's own index.md ------------------------------------------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: board'
  printf 'title: %s\n' "$TITLE"
  printf 'id: %s\n' "$BOARD_ID"
  printf '%s\n' 'icon: {glyph: arrowshape.forward.fill}'
  printf '%s\n' 'config: {show-card-body: 3}'
  printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
  printf '%s\n' '---'
  printf '# %s\n\n' "$TITLE"
  cat <<'BODY'
Where work on Acme goes from a raw idea to something built, one card per piece of work. Lanes are stages of commitment, so a card's lane says who acts next.

## How this board works

- **Flow**: Ideas to Shaping to Proposed to Approved to Active to Done, with Issues as the side entrance for things broken in the running system.
- **Two human gates**: triage out of Ideas, and review out of Proposed. Agents surface what sits at a gate and never move a card through one.
- **A card is ready to build** when its body names the files it touches, the command that verifies it, and a done-when a reader could check without asking.
- **The body is the spec, the thread is the journal.** Edit the body when scope or done-when change, put everything else in comments.
- **Git**: this board lives in the Acme repo. Commit your own board writes with a plain message, stage only your own paths, and keep board writes and code changes in separate commits.
BODY
} > "$STAGE/index.md"
mv "$STAGE/index.md" "$BOARD/index.md"

# ---- one folder and one index.md per lane -----------------------------------
while IFS='|' read -r ORDER LANE BODY; do
  [ -n "${ORDER:-}" ] || continue
  LANE_ID=$(uuidgen | tr 'A-Z' 'a-z')
  mkdir -p "$BOARD/$LANE_ID"
  {
    printf '%s\n' '---'
    printf '%s\n' 'schema: 1'
    printf '%s\n' 'kind: lane'
    printf 'title: %s\n' "$LANE"
    printf 'order: %s\n' "$ORDER"
    printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
    printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
    printf '%s\n' '---'
    printf '%s\n' "$BODY"
  } > "$STAGE/lane.md"
  mv "$STAGE/lane.md" "$BOARD/$LANE_ID/index.md"
done <<'LANES'
1024|Ideas|The inbox and the triage queue. Zero bar to entry, a one-line card is fine. Triage moves each card on to Shaping, or out.
1536|Issues|The side entrance for something broken in the running system. An issue skips triage and is shaped or fixed on its own merit.
2048|Shaping|The agent work lane. A raw idea is developed here into a proposal with scope, constraints, risks and a recommendation in the body.
3072|Proposed|The human review gate. The proposal is finished and waiting on the owner. Agents never move a card out of this lane.
4096|Approved|The ready-to-build queue, ranked in build order, top is next. The spec is frozen, so a scope change bounces the card back to Shaping.
5120|Active|The build lane. One session holds a card at a time, claiming it with a comment naming the session and the branch.
6144|Done|Shipped work. A card arrives when its done-when is met, with a closing comment carrying the evidence.
LANES

printf 'founded %s\n' "$BOARD"
printf 'board id %s\n' "$BOARD_ID"
```

Three details in there are deliberate and worth keeping when you adapt it.

The stamps go in as `printf` **arguments**, never inside a single-quoted format string, where a `${VAR}` never expands and ships literally into the file. The two bodies come from quoted heredocs, `<<'BODY'` and `<<'LANES'`, so backticks and `$` inside the prose reach the file as text instead of running as commands. And every file is written to `$STAGE` and moved in, because a board is watched: the app reloads on every filesystem event and can catch a half-written file, and a stray temp file left inside a card folder is relocated into that card's `attachments/` rather than deleted.

Swap the lane table for whichever set fits, and see `board-kinds.md` for the other two.

## What not to write

The app heals a board root on every open and reload. It writes and refreshes the guide pair, installs the current schema set, seeds a `.gitignore`, and mints a missing board `id`. So the hand-written minimum is exactly the board's `index.md` plus one `index.md` per lane, and everything below is the app's:

- **`CLAUDE.md` and `AGENTS.md`.** "created and kept up to date by the Lanework app. This guide is written at two names, CLAUDE.md and AGENTS.md, kept byte-identical. Don't edit either file: both are overwritten on upgrades" (agent guide, line 1).
- **`.schema/`.** "**The folder is the app's**: the set is rewritten whenever its marker is older than the app's, the script alone whenever its own is, never edited by you" (agent guide, *Frontmatter*).
- **`.gitignore`.** "The seeded `.gitignore` is the app's — line 1 is `# lanework-gitignore vN`, and the app rewrites the file to its current seed at every open, marked or not" (agent guide, *Git*). A board is never a repository root, so your own exclusions go in a `.gitignore` above the board folder.
- **`.log/` and `.trash/`.** Both are app-managed. The log is read-only for you, it is off unless a `config.logging` turns it on, and the seeded `.gitignore` excludes it. The trash is created when something is first deleted.
- **`id`**, if you would rather the app minted it. Leaving it out is legal and the board works; you simply cannot write a `lanework://` link to it until after the first open.

**Never copy any of those from another board.** A copied `.schema/` carries the other board's version marker, which then disagrees with what the file actually holds, and a copied guide is one version behind the moment the app upgrades. Copying the folder of an existing board to start a new one has the same problem plus a duplicated `id`. Write the two file kinds, let the app do the rest.

## Validate before the first open

The schema set ships with its own validator, and it reads the set that sits beside the script. A new board has no `.schema/` of its own yet, so point another board's copy at it:

```bash
python3 "<some other board>.lanework/.schema/bin/lanework-validate.py" "<new board>.lanework"
```

A `.lanework` directory argument walks the whole board: every lane, card, comment and attachment. A file argument validates that one document against the schema its position picks. Add `--schema <dir>` to read a set from somewhere other than the folder the script lives in.

A clean board walk prints a population summary and exits 0:

```
schema      <some other board>.lanework/.schema (lenient)
boards      1
documents   8  —  board 1, lane 7, card 0, comment 0, attachment 0, config 0
skipped     strays 0, index-less identity folders 0, symlinks 0, retired flat attachments 0
warnings    0
deprecated  0
failures    0 over 0 of 8 documents
```

Read the last three lines, not just the exit code. A `FAIL` line names the rule and exits 1. A `DEPRECATED` line names a retired spelling your file matched and still exits 0, so a run can pass while telling you to write something else: the check to make before committing a hand-written file is **exit 0 with no `DEPRECATED` line**. Exit 2 is a usage error or a population of zero documents, which is never a pass.

If no other board is on the machine, there is no schema set to validate against yet. Check the frontmatter parses as YAML by hand, then let the app's first open report what it finds.

## The founding commit

Boards belong in git when they live inside a repository, and Lanework never commits anything itself. Stage the board by its own explicit path, never with `-A` or `.`, which would sweep up whatever else the working tree happens to be holding:

```bash
git add "Pitlane/Acme Pipeline.lanework"
git status --short -- "Pitlane/Acme Pipeline.lanework"     # read it before committing
git commit -m "Found the Acme Pipeline board"
```

A plain message. If the repository is shared with other sessions, commit only your own paths (`git commit --only -- <paths>`), never amend, and never stash.

## Open it, then commit what the app healed in

Open the new board once so the app can complete it: double-click the `.lanework` folder in Finder, or File then Open in the Lanework app. The window comes up with the lanes in `order` and no cards.

That open writes the guide pair, the `.schema/` set, the `.gitignore` seed, and the board `id` if you left it out. All of them belong in git on a board that lives in a repository, so check the tree again and take a second commit:

```bash
git status --short -- "Pitlane/Acme Pipeline.lanework"
git add "Pitlane/Acme Pipeline.lanework"
git commit -m "Acme Pipeline: app-installed guide, schema and gitignore"
```

The `.log/` folder, if the board turns logging on later, is excluded by the seeded `.gitignore` and is never committed.

The board is now founded. File its first cards the ordinary way, one uuid folder and one `index.md` per card, each with a founding comment saying why the card exists; see the pitlane skill for working a board from here.
