# The grill board

The shape of a `<Topic> Grill.lanework` board: its lanes, its three kinds of card, and the literal templates. The board's own guide (`CLAUDE.md`, app-maintained) is the authority on the file format; this page only fixes what this board kind means.

## Lanes

Five lanes, on the plain 1024 ladder. `Parked` is collapsed from the start.

| lane | order | entry | exit |
|---|---|---|---|
| Brief | 1024 | the Topic card and the Design tree card, written at framing | never; both are rewritten in place |
| Facts | 2048 | a fact found by the agent or a subagent, with evidence | never; a superseded fact gets a dated correction in its thread |
| Asked | 3072 | a question on the current frontier, filed by the agent | the owner answers, and the agent moves it |
| Settled | 4096 | an Asked card whose ruling is written into its body | never; a re-ruled question is a new card that links the old |
| Parked | 5120 | an Asked card the owner deferred or declined | the owner reopens it, as a new question in a later round |

Cards move only Asked → Settled or Asked → Parked, and only the agent moves them, after the ruling is in the body. The owner never has to touch a card to answer it: a comment in the thread, or a reply in chat, is the whole gesture.

## The board's `index.md`

The founding script writes this. The `config.labels` entry declares the `round` label kind so the app can offer it; every card's own label entry carries its full value anyway.

```markdown
---
schema: 1
kind: board
title: Tracker Grill
id: <lowercase uuid>
icon: {glyph: questionmark.bubble}
config: {show-card-body: 3, labels: [{type: round, text: Round}]}
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
# Tracker Grill

A design interview on <topic>, one question per card. The agent asks in rounds; the owner rules; the ruling is written into the card in the owner's words. Brief holds the topic and the design tree, Facts what was looked up, and Settled is the record a later session resumes from.

## How this board works

- **The body holds the question; the ask comment is where it is answered.** Every question card carries one ask in its thread, the handle on its first line, restating the question, its options and the recommendation. Reply to that comment. No other comment on the card mentions the handle.
- **Answer anywhere.** A comment on the card, or a reply in chat. The agent records a chat answer as a comment quoting it, then writes the ruling into the body under `## Ruling` and moves the card.
- **A ruling is the owner's words**, dated. "As recommended" is a ruling. A deferral or a refusal is a ruling too, and parks the card with the reason.
- **One question, one decision.** A round is every question whose prerequisites are settled. Questions number globally in the order asked; the round is the `Round` label.
- **Facts are cited.** A Facts card names its source and attaches the report; a question that leans on one links it under Depends on.
- **Nothing is built from this board.** When the frontier is empty and the owner confirms the understanding, work cards are filed on the project's pipeline board and link back here.
- **Git**: this board lives in the project repo. Stage only your own paths, plain commit messages, board writes separate from code changes.
```

## Lane bodies

```
Brief    | The two standing references. The Topic card states the scope and what a shared understanding must cover. The Design tree card is the outline of every decision, rewritten by the agent at the close of each round, and is the first thing a resuming session reads.
Facts    | One card per fact the agent established: from the code, the docs, the filesystem, a tool, or the web. The body is the fact and its source; the raw report is an attachment. A fact found wrong gets a dated correction comment, never an edit that hides the first reading.
Asked    | One card per open question, filed by the agent, waiting on the owner. The body is the question, the options and the recommendation. Answer by commenting on the card or by replying in chat. Only the agent moves a card out, and only once the ruling is written into the body.
Settled  | Answered questions. The body ends with a dated ruling in the owner's words. This lane is the design record: read it in order to see what was decided and why. A settled question is never edited; a change of mind is a new question in a later round that links this one.
Parked   | Questions the owner deferred or declined, with the reason as the ruling. Collapsed because it is read least; reopen one by asking it again as a new card that links this one.
```

## The Topic card

One per board, in Brief, written at framing and rewritten only when the owner changes the scope.

```markdown
---
schema: 1
kind: card
title: "Topic: <the thing being grilled>"
order: 1024
icon: {glyph: scope}
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
<One paragraph: what is being designed, and where the request came from.>

## A shared understanding covers

- <area one>
- <area two>

## Sources read

- <doc or file>, <what it settled before this session started>
```

## The Design tree card

One per board, in Brief, below the Topic card. Rewritten in place at the close of every round; the thread carries one comment per rewrite saying which round closed.

```markdown
---
schema: 1
kind: card
title: "Design tree"
order: 2048
icon: {glyph: point.3.connected.trianglepath.dotted}
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
Every decision in the design, as a tree. ✅ settled, with the ruling in one line and the card linked. ❓ on the frontier now, card linked. ◦ not yet askable, and what it waits on.

- ✅ Scope: two-way lifecycle sync is the MVP [Q3](lanework://<board>/<card>)
  - ❓ Lane to state mapping [Q11](lanework://<board>/<card>)
    - ◦ Auto-create lanes for unmapped states (waits on Q11)
  - ◦ Conflict policy (waits on Q11)
- ✅ Engine runs in the app [Q4](lanework://<board>/<card>)
  - ❓ Polling cadence [Q12](lanework://<board>/<card>)
```

## A question card

Filed into Asked by `scripts/file-question.sh`, or by hand to this template. The number is global and increments in the order asked; read the highest existing `Q<n>` across Asked, Settled and Parked before minting the next.

```markdown
---
schema: 1
kind: card
title: "Q7: Edition placement"
order: <bottom of Asked>
labels: [{text: "Round 2", kind: {type: round, text: Round}}]
waiting: {for: <owner handle from the guide>, since: <now>, comment: <ask comment uuid>}
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
Tracker sync was parked under a "Teams" tier that was never engaged, and the tier model itself was mooted on 2026-08-08. Is tracker sync now a feature of the one free app, the seed of a paid tier, or undecided?

## Options

- A: a feature of the one free Mac app
- B: the seed of Pro or Teams, gated when those return
- C: undecided; design edition-agnostic and record that the Teams placement is reopened

## Recommended

C. Placement changes packaging, not the model, but the reopening must be written into the editions doc so the corpus stays honest.

## Depends on

- [Q1](lanework://<board>/<card>): the July archive is inherited as defaults
- [Fact: editions pivot](lanework://<board>/<card>)
```

Its founding comment is a record: why the question is on the frontier now, in two or three lines, and never the owner's handle.

```markdown
---
schema: 1
kind: comment
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
**On the frontier because Q1 settled the archive's standing and the editions fact is in.** Nothing else hangs on this except the packaging section of the write-up.
```

Then the ask, one second later, the last comment on the card when it is filed. It is the pitlane ask shape (`pitlane/examples/ask.md`, linted with `pitlane/scripts/lint-ask.sh`): the handle on the first line, the question in one sentence, the options as one-liners, the recommendation, the default if unanswered, and `Context: body.` The card's `waiting.comment` names this comment's uuid.

```markdown
---
schema: 1
kind: comment
created:  {at: <now + 1s>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now + 1s>, by: {name: claude, kind: agent, model: <model>}}
---
@rzen Which edition does tracker sync belong to?

Options:
- A: the one free Mac app
- B: the seed of Pro or Teams, gated when those return
- C: undecided, design edition-agnostic and record the reopening in the editions doc

Recommended: C.
If no answer: C stands when the round closes.
Context: body.
```

## Recording a ruling

Whether the owner answered in chat or on the card, the body gains one section at the end, and the card moves. Never edit the question, the options or the recommendation; a reader must see what was asked.

```markdown
## Ruling

**2026-09-22** — C, as recommended. "Design it edition-agnostic; I'll note in the editions doc that Teams placement is reopened."
```

When the answer came in chat, it is first posted to the thread as a record, in reply to the ask, so the board holds the owner's words and not only the agent's reading of them:

```markdown
---
schema: 1
kind: comment
in-reply-to: <ask comment uuid>
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
**Owner answered in chat.** "C. Design it edition-agnostic and note in the editions doc that Teams placement is reopened."
```

A ruling that produced a glossary entry or an ADR says so on its own line under the ruling: `Glossary: **Tracker**, **Remote** in CONTEXT.md` or `ADR: docs/adr/0003-engine-in-app.md`.

A deferral parks the card with the same section: `**2026-09-22** — Parked. "Not until the sync service exists."`

## A Facts card

Filed into Facts when a subagent or a lookup returns. The body is the fact in the agent's words with its source; the raw report is an attachment, never pasted inline.

```markdown
---
schema: 1
kind: card
title: "Fact: Gitea issue state is binary"
order: <bottom of Facts>
icon: {glyph: doc.text.magnifyingglass}
created:  {at: <now>, by: {name: claude, kind: agent, model: <model>}}
modified: {at: <now>, by: {name: claude, kind: agent, model: <model>}}
---
Gitea issues carry `state: open | closed` and nothing else. Richer workflow lives in labels, or in Projects columns, whose REST API merged for 1.28.0 and is not in any stable release as of 1.27.3.

## Source

- https://gitea.com/swagger.v1.json, definitions.Issue, read 2026-09-22
- go-gitea/gitea PR #38691, merged 2026-08-08

## Bears on

- [Q11](lanework://<board>/<card>): lane to state mapping
```

Its founding comment names what asked for the fact and attaches the report under the comment's own `attachments/`.

## Ordering inside lanes

Asked and Settled read top to bottom in question order, which is filing order, so every new card goes to the bottom: `max existing order + 1024`, or `1024` in an empty lane. A card moving from Asked to Settled takes the bottom of Settled, so Settled reads as the sequence of rulings. Brief is fixed: Topic at 1024, Design tree at 2048.
