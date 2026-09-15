---
name: pitlane
description: "Pitlane / Lanework board operations — reading and writing cards and comments on Lanework kanban boards (plain folders + Markdown rendered live by the Lanework app; the files ARE the board, no API); by default, a project keeps a `Pitlane/` folder at its repo root holding `<Project> Pipeline.lanework`, and `~/Pitlane` holds machine-level boards; and agentic board sweeps: sweeping a pipeline board for workloads, triaging them, and farming the work out to model-tiered subagents with a lead/fixer/reviewer split. Use this skill whenever the user mentions Lanework, Pitlane, a pipeline board (e.g. 'Acme Pipeline', 'Lab Pipeline'), sweeping or working a board, filing/moving a card, posting a board comment, triaging Ideas, answering board questions, or working the Approved lane — 'sweep the pipeline board', 'check the lab board', 'file a card on the lab board', 'any open questions on the boards?', 'work the approved cards'. Not for generic kanban/project-management advice unrelated to Lanework boards."
---

# Pitlane / Lanework boards

A Lanework board is a folder named `<Board Name>.lanework`: plain directories
and Markdown files that the Lanework macOS app renders live. There is no API
and nothing to sync — you manipulate a board by editing its files, and the
app picks up every filesystem change while the board is open. Boards are
where the user and their agents coordinate work: cards are specs, comment
threads are journals, and on pipeline boards **a card's lane says who acts
next**.

## The authority chain — read before any write

This skill deliberately does **not** restate the board file format. Every
board carries its own spec, and it is versioned and app-maintained, so a
copy here would rot. Before acting on any board, read, in order:

1. **`<board>.lanework/CLAUDE.md`** — the app-maintained agent guide
   (byte-identical twin `AGENTS.md`). It is the complete, current authority
   on layout, frontmatter schema, stamping (`created`/`modified` with the
   `by` map), creating/moving/trashing items, attachments, comments,
   mentions, and git conduct. The app rewrites it on upgrades — **never
   edit it**, and never trust a remembered older version over what the
   file says today.
2. **The board's own `index.md` body** — everything below its first `##`
   heading is the owner's instruction sheet for agents on that board
   (repo facts, what "green"/verified means there, blast-radius rules,
   card-quality bars). Above the first `##` is the board description.
3. **Each lane's `index.md` body** — per-lane entry criteria and policy,
   read before filing into or moving a card out of that lane.

Lower layers refine, never override: a board's index.md can add process on
top of the app guide, and this skill sits below both — where anything here
seems to disagree with a board's own files, the board's files win.

## Finding boards: the default convention

- **`~/Pitlane/`** — machine-level boards, for the user's own environment
  rather than any one project.
- **`<project repo root>/Pitlane/`** — a project's Lanework boards, inside
  the project's own git repo. A work pipeline board is typically named
  `<Project> Pipeline.lanework`; a project may keep additional boards
  beside it (schema boards, archives).

These two locations are defaults, not rules: a board is any folder named
`<Name>.lanework`, and the user can name one anywhere. A project's own
CLAUDE.md, or a board's own `index.md` body, can declare a different
location — that instruction wins.

```bash
ls -d "<project root>"/Pitlane/*.lanework   # a project's boards, by default
ls -d ~/Pitlane/*.lanework                  # machine-level boards, by default
```

A board's own `index.md` body states how its repo is committed, and that
instruction wins. Don't scan beyond the defaults unless the user asks: a
project is identified by the work at hand or by the user naming it, and
its `Pitlane/` folder is then the place to look.

## Working conduct (stable invariants)

The board's CLAUDE.md has the full rules; these are the ones that hold
everywhere and are most costly to get wrong:

- **Stamp every write.** `created`/`modified` are mappings with a `by` map;
  a missing `by` claims the board's **owner** wrote it. In the main
  session stamp `by: {name: claude, kind: agent, model: <your model>}`;
  a role-named orchestration agent stamps its role name (`lead`, `fixer`,
  `reviewer`) so threads read as a conversation. `at` and `by` travel
  together, always.
- **The body is the spec; the thread is the journal.** File cards with a
  founding comment (the why, not a restatement); post your plan when you
  start, decisions as you make them; close with verification evidence.
  **A comment is a record or an ask, never both**: context and evidence
  go in a record, which never mentions the human; one request for the
  human goes in an ask — their handle on the first line, under 80 words,
  the shape in `examples/ask.md`, checked by `scripts/lint-ask.sh`. The
  handle is a bell, not a cc. The whole rule is `references/writing.md`.
  Re-read the whole thread before resuming any card.
- **Resolve a card's path immediately before every comment write** — cards
  move lanes; a stale path silently creates a ghost card folder. Never
  `mkdir` a card directory to make a comment land.
- **Delete = move to `<board>/.trash/`**, never `rm -r`; never rename UUID
  folders; atomic writes (temp file + rename) because the app reloads on
  every filesystem event — and **the temp file goes outside the board**
  (the session scratchpad, same volume, then `mv` into place). A temp
  written beside a card's `index.md` is a stray to the app: within a
  second it is relocated into that card's `attachments/`, not deleted,
  and warns as a legacy attachment (2026-09-08). After any aborted
  write, check `attachments/` for a loose file before committing.
- **Icons: a glyph, and color only with a reason.** An `icon` on a card
  you file or shape carries a `glyph`; leave `color` off unless the tint
  says something the glyph cannot. A lane of multi-colored icons reads
  loud (measured on one board after an owner ruling); the schema still
  allows the key, so this is conduct, not format.
- **Git**: boards usually live inside a git repo; the board's index.md
  body says how that repo is committed. Commit your board writes yourself
  with semantic messages, stage only your own paths, and follow the
  board index.md's repo instructions. Board writes and code changes are
  separate commits.

## Pipeline boards: the default lane set

This is the default lane set shipped with the pipeline pattern — a
board's actual lanes, and each lane's own `index.md` body, always win.
Where a board follows the default, lanes are **stages of commitment**:

```
Ideas → Shaping → Proposed → Approved → Active → Done
```

with `Issues` as the side entrance for things broken in the running system
(some boards add `Rejected` or archive boards, rename lanes, or drop ones
they don't need; read the board).

What agents do on a default-shaped board: **shape** cards in Shaping into
implementable proposals (the board index.md usually defines the quality
bar — files touched, verification command, done-when as an observation,
blast radius), **build** from Approved through Active to Done with
evidence in the closing comment, **answer** questions and mentions on any
card, and **report** what sits at a human gate — surfacing it, never
pushing through it.

## Deeper playbooks — start here

| task | read |
|---|---|
| sweeping/triaging a board, farming work to subagents | `references/sweep.md` |
| orchestrating a multi-card build campaign (lead) | `references/lead.md` |
| fixing one card in a worktree (fixer) | `references/fixer.md` |
| reviewing a card's branch (reviewer) | `references/reviewer.md` |
| trusting a number, a count, a zero, or a green | `references/evidence.md` |
| writing a card body, a record comment, or an ask to the human | `references/writing.md` |
| a command or board write about to do something subtle | `references/traps.md` |

The three inter-agent reports (Phase-1, Phase-2, verdict) and the ask to
the human are templates in `examples/` — fill and send the structure, not
free-form prose.

These are **procedures, not proof obligations**: run the steps, investigate
when a check surprises, and before adding a check name the wrong answer it
would catch — if none exists, skip it.

Maintaining this skill: entries **replace**, they don't append — prefer
extending an existing entry, then generalizing several into one, then
adding. Project facts (gate commands, what "green" means, blast-radius
rules) never move into these files; they stay in the board's index.md and
the repo's CLAUDE.md, which the authority chain already reads.
