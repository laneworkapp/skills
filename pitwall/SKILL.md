---
name: pitwall
description: Pitwall — a live watch on one Lanework board: arm a persistent Monitor on the board's files, wake on every change, respond to the owner's new comments, and farm action-calling comments out to model-tiered subagents, until the user says stop. Use this skill whenever the user asks to watch a Lanework board, watch a board for changes, respond to board comments live, "sit on the board", "man the pitwall", or wants this session to react to comments as they arrive — even if they don't name the skill. Not for one-shot board sweeps or filing cards (that's the pitlane skill; pitwall is the standing watch).
---

# Pitwall: a standing watch on one Lanework board

The pitwall is the race-engineering post: this session stays up, watches one board's files for changes, and acts on what the owner writes — until told to stop. It builds on the `pitlane` skill, which governs *how* to read and write boards; pitwall only adds the watch loop and the response policy.

## Setup (once, when the watch starts)

1. **Load the `pitlane` skill** and follow its authority chain: read the board's `CLAUDE.md` (the app-maintained agent guide) and the board's own `index.md` body *now*, so later wake-ups act correctly without re-reading. Read every lane's `index.md` body at setup too, not only before moves — a lane says there whether it is out of scope for agents, and that body is the only place it says so.
2. **Resolve the board path** by the default convention in the pitlane skill (`<repo>/Pitlane/<Board>.lanework` or `~/Pitlane/…`), or the path the user names. Ask only if the user hasn't named a board and more than one exists.
3. **Arm a persistent Monitor** running the bundled watcher (needs homebrew `fswatch`; if absent, fall back to running the same snapshot-diff in a plain 2s `sleep` poll loop):

```bash
~/.claude/skills/pitwall/scripts/watch-board.sh '<absolute board path>' '<scratchpad>/board-snapshot.txt'
```

The design is deliberately hybrid, and the script's header comment is load-bearing history: **fswatch is only the trigger, the emitted paths come from a find-snapshot diff.** Never "improve" it by filtering fswatch's own event paths — the app posts a comment by renaming `comments/.draft/` → `comments/<uuid>/`, and moves cards between lanes the same way, so file-level FSEvents carry only the renamed *directory* paths, never the unchanged `index.md` inside; a path filter on the raw events silently drops exactly the owner comments and card moves the watch exists for (this happened — an owner comment arrived invisibly).

Pass `persistent: true` — the watch runs until TaskStop or session end. Tell the user the watch dies with the session and must be re-armed after a resume, and that "stop" tears it down (TaskStop). The Monitor survives `/clear`: after a clear, events keep arriving without the watch-session context, so re-read the board's authority chain before acting on one — or tear the watch down if the user has moved on.

## Handling an event

Each Monitor notification names one or more changed paths (or `BULK: N`). Events are background notifications, never user replies.

1. **Skip your own writes.** Every write you make re-fires the watcher once; recognize your recent paths and stamps and move on silently.
2. **Skip an excluded lane.** A change under a lane whose own `index.md` body says it is out of scope for agents is read for context and never answered — no reply, no move, no work farmed out of it.
3. **Read the changed file whole** — `cat`, never `head -N`; a truncated read has missed owner rulings before. For a comment, re-read the *entire thread and card body* before replying: answers land as later comments and context is cumulative.
4. **Classify who wrote it** by `created.by`, extracted with `yq` (mikefarah v4, homebrew) from the frontmatter:

```bash
fm() { awk '/^---$/{n++;next} n==1' "$1"; }   # frontmatter only
by=$(fm "$f" | yq -r '.created.by // ""')
kind=$(fm "$f" | yq -r '.created.by.kind // ""')
```

   - **Owner — respond**: `by` empty (the app's own writes are the owner's) **or** `kind` = `human`. The app stamps the human's identity on comments it posts, so don't rely on missing-`by` alone.
   - **Ignore**: `by` present and `kind` ≠ `human` — any agent (claude, a sweep session, shortcuts, a bare-name coercion). Read for context, never reply.
5. **`BULK` events** are usually lane moves or app rewrites (a moved card's whole subtree changes path). Diagnose with `git status --porcelain -- '<board>'` and `find` for the card's new lane. A bare move carries no comment: it's the owner acting at a gate. Surface it to the user in your next message; act only if the destination lane's semantics hand the work to agents *and* the user's standing instructions cover it — otherwise don't infer a work order from a drag.

## Responding to an owner comment

Only **new owner comments** get replies. Two shapes:

- **Ruling / discussion** (answers a question, picks an option, gives an opinion): handle in the main session. Fold the ruling into the card body the way the thread already does it — strike the open call through: `~~the question~~ — **ruled <date>: <ruling>**` — restamp the card's `modified` whole (`at` and `by` together), and post a short acknowledging reply — a three-line record per `pitlane/references/writing.md`: what was recorded, what state the card is now in, who acts next. No handle.
- **Action-calling** (asks for work to be performed): don't do the work in the watch session. Post a plan comment to the thread first (a record, so the journal records who's doing what), then farm it to subagents at the cheapest fitting tier — haiku for mechanical work, sonnet for well-specified implementation, opus for tricky debugging/concurrency, inherit only where the agent makes architectural calls; several in parallel when the ask splits. For a substantial coding card, run the pitlane build cycle instead of a bare subagent: the watch session is the lead — worktree, slot, phase reports, independent review — per `pitlane/references/lead.md`, `fixer.md`, `reviewer.md` and the report templates in `pitlane/examples/`. Review agent output in the main session against `pitlane/references/evidence.md` (a report whose numbers arrive without raw output alongside is a claim, not a measurement), journal the outcome and evidence in the thread, and keep synthesis and the user-facing reply here.
- **A question back to the owner is an ask of its own** — `pitlane/examples/ask.md`, under 80 words, handle on the first line, linted with `pitlane/scripts/lint-ask.sh <file> <board>` before the `mv` — posted after the record it depends on, never as its tail. The handle is a bell, not a cc: a watch that mentions the owner on every landing note and felt check trains them to stop reading the bell.

## Write hygiene (hard-won, all of it)

The full board-write and command trap tables live in `pitlane/references/traps.md`; the rules below are the ones a watch hits constantly.

- **Resolve the card's path fresh immediately before every write** — cards move lanes between your read and your write; a stale path plants a ghost card dir. Verify in the same command as the write (`ls "$BOARD"/*/<card-uuid>/index.md`), especially while the owner is live on the board. Never `mkdir` a card directory; if the comment write would need one, the path is wrong. **The Write tool is a ghost machine**: it auto-creates parent directories, so a Write to a stale card path silently mints a duplicate card instead of failing — and the app heals the collision by reminting the stray under a *fresh* uuid, so the residue may not even carry the path you wrote. Prefer shell `mv`-into-place writes guarded by the existence check.
- **Atomic writes**: build the file in a temp path **outside the board** (the session scratchpad, same volume), then `mv` it into place — the app reloads on every filesystem event, and a temp written inside a card dir is relocated into that card's `attachments/` within a second rather than deleted (2026-09-08).
- **Stamps**: sign everything `by: {name: claude, kind: agent, model: <model>, session: "board watch"}`; `at` and `by` travel together; after any stamp write, `grep '}}}'` the touched files — a triple brace is corruption.
- **Comment bursts** get distinct seconds in `created.at` — chronology is the thread order.
- **Git**: commit each handled comment's writes (card body + your reply) with a semantic message, and push. Stage the card's `index.md` and the specific `comments/<uuid>` folders you wrote — never a lane dir, never a whole card dir (the owner's unposted `comments/.draft/` rides in with it), never `-A`. Board writes and code changes are separate commits.
- **After posting replies, re-check the change stream** before going quiet: owner writes that land during your response window interleave with your own self-triggered events — sweep the notifications you skipped as "own writes" and make sure none of them were actually the owner's.

## Companion sessions

Other agent sessions (sweep sessions, /loop runners, other watches) work the same board concurrently. Their comments and moves arrive as events too:

- **A START comment is a claim.** When another session posts a plan/START on a card, that card is theirs — don't double-dispatch the work, even if an owner comment earlier called for it. Attribute before alleging: a surprising commit or move is usually a companion session's owner-ruled landing, not fabrication.
- **Relay, don't engage**, when owner input lands on a companion-owned card: forward the gist (card uuid, lane, one-line summary) to that session via SendMessage if it's reachable, or surface it to the user; reply on the thread only for what this watch owns.
- **Stamp your own `by.name`** consistently so threads read as a conversation between distinct hands; never impersonate another session's name.

## Report to the user

After each handled event, the turn's final message states what arrived, what you did (reply posted, ruling folded in, agents dispatched, commit hash), and anything sitting at a human gate. Skipped self-writes and no-op events need no message at all.
