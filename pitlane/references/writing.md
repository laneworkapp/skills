# Writing cards and comments

Board prose has two readers: the owner, who decides, and the next agent, who resumes cold. Both read a card-sized column, often on a phone. Every sentence is priced against that. The board's own CLAUDE.md (Use the thread) is the authority; this page is the procedure and the checks.

## Two kinds of comment, never mixed

| kind | carries | mentions the human | shape |
|---|---|---|---|
| **record** | context: reasoning, decisions, routes not taken, evidence, attachments | never | conclusion first, then labeled one-liners |
| **ask** | one request the human must act on | always, on the first line | `examples/ask.md` |

A record and an ask that belong together are two comments: the record first, the ask one second later (distinct `created.at`), so the ask is the last thing in the thread and the attention bell opens on it.

**The handle is a bell, not a cc.** It goes in an ask and nowhere else: not a founding comment, not a START, not a closing report, not a felt check tucked into a landing note. When the owner's action is needed after a landing, that is an ask of its own. Measured on one fleet over three days: 167 of 618 agent comments mentioned the owner, the typical one ran 250–700 words with the request last, and the bell stopped meaning anything.

## The ask

Fill `examples/ask.md`. The budget is hard:

- the handle on the first line, the ask in that same sentence: a question mark, or an imperative
- one ask per comment; two asks are two comments, each answered and settled on its own
- under 80 words
- sentences of one clause: no em-dashes, no semicolons
- no hashes, counts, log names, or file paths; those live in the record above, which the ask points at
- a card it names is a link (Card references below), never a bare id
- no hedging: "worth a try", "a note on whether", "it might be good to" all become the imperative
- the default and when it kicks in, or the word "blocked"
- a blank line after the options, and after every list: Markdown folds the next line into the last item (a live ask rendered `Why now:` as part of option C, 2026-09-14)

Run `scripts/lint-ask.sh <file> <board>` before the `mv` into place; it fails on each mechanical item above and is silent on a record.

## The record

- The first line is the conclusion, bold, one sentence.
- Then labeled one-liners, dropping any that are empty: **Decided**, **Rejected** (the route and why), **Accepted limitation**, **Evidence** (what ran, what it showed, the population beside every zero), **Attached** (raw logs, snapshots).
- Raw output goes in attachments, never inline. Name paths, never quote files.
- Cut on sight: restating the body or the thread; narrating tool use; self-narration about candor ("the record says so rather than hiding it", "nothing was widened to fit a number"); ceremonial tags ("as ruled", "is not owed", "that is a separate card"); a bold headline sentence that chains four clauses with dashes.
- A longer thought trace is its own "more context" comment, posted before the conclusion, never inside it.

## Card references

Every card that prose names carries its `lanework://` link, every time — in a comment, a card body, a commit message, a report to the owner. The form is the board guide's (Reading the board): `[<short id or title>](lanework://<board-id>/<card-id>)`, the board `id` from `<board>/index.md`, the card id from its folder name. A bare short id such as `572e3b41` is a search the reader has to run; the link is a click. Build it from the resolved card path:

```bash
bid=$(awk '/^id:/{print $2}' "$BOARD/index.md"); cid=$(basename "$CARD")
printf '[%s](lanework://%s/%s)\n' "${cid:0:8}" "$bid" "$cid"
```

`scripts/lint-ask.sh` flags a bare eight-hex id in an ask that has no matching link in the same body.

## Card bodies

The body is the spec, not a journal. The title is imperative, short enough to read in a lane at a glance, and **always double-quoted in the frontmatter** (a `: ` in a bare title is a YAML mapping and the app refuses the card); the sections are the ones the board's index.md asks for, one short paragraph or list each. A ruling edits the body in place (strike the open call through, add the dated bold ruling) and gets a record comment; a retraction does the same. Narrative about how the card got here belongs in the thread, not below a rule in the body.

## Before posting, both ways

Would a cold reader need anything not here? Would they skip anything that is? For an ask, one more: can the owner answer it in one line without opening anything else?
