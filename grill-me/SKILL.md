---
name: grill-me
description: "Grill me — a relentless design interview run on a Lanework board. Interrogates the user in rounds until a plan or design is a shared understanding, mapping every decision as a design tree, and accumulates the questions, the owner's rulings, the facts dug up along the way and the resulting glossary and decision records on a grill board (a `<Topic> Grill.lanework` folder the skill founds when none exists). Every question is a card, every ruling is written into that card in the owner's words, and the board is the record a later session resumes from. Use this skill whenever the user says 'grill me', 'grill me on X', 'interview me about', 'interrogate me', 'sharpen this plan', 'let's think through X properly', 'design session for X', or wants a plan or feature examined question by question before anything is built. Not for founding general boards (lanework-boards), sweeping a pipeline board (pitlane), or standing watch on one (pitwall)."
---

# Grill me

A grilling is an interview: the agent asks, the owner decides, and the session ends when nothing is left silently assumed. This skill runs that interview on a Lanework board so the questions, the answers and the facts survive the chat that produced them. The board is the design record; the chat is the conversation.

Two things carry over from the plain interview and are not optional: the **design tree**, where every decision branches into the decisions that hang off it, and the **frontier**, the set of decisions whose prerequisites are settled and which can be asked now without guessing at an answer not yet heard. A round is the whole frontier, asked at once. What the board adds is that each question is a card, each ruling is a sentence in the owner's words on that card, and the tree itself is a card that is rewritten as it grows.

## The authority chain

This skill builds on **lanework-boards**, and everything there holds here: read the board's app-maintained guide (`<board>.lanework/CLAUDE.md`) before any write, then the board's own `index.md` body, then each lane's body. The guide is the authority on frontmatter, stamping, comments, `waiting`, `in-reply-to`, labels and mentions; nothing below restates it. Where anything here disagrees with a board's own files, the board's files win.

## The board

A grill board has five lanes and three kinds of card. The full shape, with the literal file templates, is in `references/board.md`; the lane set in one table:

| lane | order | what it holds |
|---|---|---|
| Brief | 1024 | the Topic card and the Design tree card, the two standing references |
| Facts | 2048 | one card per fact found in the environment or the world, with its evidence attached |
| Asked | 3072 | one card per open question, waiting on the owner |
| Settled | 4096 | answered questions, the ruling written into the body in the owner's words |
| Parked | 5120, collapsed | questions the owner deferred or declined, with the reason |

**Finding or founding it.** A grill board is named `<Topic> Grill.lanework` and lives where the project's boards live, `<repo root>/Pitlane/` by default, or `~/Pitlane/` when there is no project. Before founding, look for one: the user may name a board, and a topic that was grilled before has its board already. Found a new one only when none fits, with `scripts/found-grill-board.sh`, and then open it once in the app so the guide and schema are installed before the first question is filed. A board that already exists for the topic is resumed, never duplicated.

**A grilling can also run on an existing board's card** when the owner says so, one question card per comment thread being too heavy for a small clarification. That is the plain interview with the board as a notebook; the shape below is for a design worth its own record.

## Running the interview

### 1. Frame

Read what exists before asking anything: the codebase, the design docs, any earlier card or note the owner wrote on the topic, and the board itself if it already exists. Facts are the agent's job, never the owner's. Anything a round needs from the environment is dispatched to a subagent and lands as a **Facts card** when it returns; the questions that depend on it wait for it, and the rest of the frontier is asked now.

Write the **Topic card** (the scope in one paragraph, and what a shared understanding of it would have to cover) and the first **Design tree card** (every decision you can already see, as an outline with nothing settled yet). Both go in Brief.

### 2. Ask a round

Compute the frontier. For every question in it, file one card into Asked with `scripts/file-question.sh`, or by hand to the same template: the question in the body above the first `##`, the options under `## Options`, your recommendation under `## Recommended`, and the settled cards it hangs off under `## Depends on`, each a `lanework://` link. Questions number globally and in order asked, `Q1`, `Q2`, … across every round, so the chat and the board agree; the round is a label. Each card arrives with a founding comment saying why it is on the frontier now, and a `waiting` key pointing at that comment, so the lane header counts what the owner owes.

Then post the same round in chat, because the owner may be at the terminal, in the interview format with each question's title linking its card:

```
❓ **Q7** - **Edition placement** [7c0e12a4](lanework://<board-id>/<card-id>): <question, options>

➡️ <your recommended answer>
```

A question whose answer depends on another question still open in the round belongs to a later round. Every question gets a recommended answer; a recommendation is what the owner accepts with one word.

### 3. Take the answers

Answers arrive two ways and are recorded the same way:

- **In chat.** Post a record comment on the card quoting the owner's answer verbatim, in reply to the founding comment, then write the ruling into the body.
- **On the card.** The owner comments in the app; the app clears `waiting`. Re-read the whole thread, then write the ruling into the body.

The ruling goes in the body under `## Ruling`, dated, in the owner's words, one or two sentences. The recommendation stays above it; a reader should see what was proposed and what was decided. Then move the card to the bottom of Settled. An answer that defers or declines the question moves the card to Parked with the reason as its ruling.

**Challenge as you go.** An answer that conflicts with a settled card, with the glossary, or with what the code does is not recorded and moved on from; it is put back to the owner in the next round as a new question that names the conflict. "You settled Q3 as X; this answer implies Y. Which holds?"

### 4. Close the round

When every Asked card of the round is Settled or Parked, rewrite the Design tree card: settled decisions with their card links and one-line rulings, open ones with their card links, the ones not yet askable as plain outline lines. Recompute the frontier and go to step 2.

Rulings also feed two documents outside the board, and this is the moment to write them: the **glossary** (`CONTEXT.md` at the repo root) for every term the round pinned, and an **ADR** (`docs/adr/NNNN-slug.md`) for the rare ruling that is hard to reverse, surprising without context, and the result of a real trade-off. `references/docs.md` has the formats and the bar. A Settled card whose ruling produced an ADR links it under its ruling.

### 5. Finish

The session is done when the frontier is empty. Post a closing record on the Topic card: the count of settled and parked questions, the documents written, and the one-paragraph shape of what was agreed. Then ask the owner, in one ask, whether this is a shared understanding. **Do not build anything, and do not turn the board into work cards, until the owner says so.**

## Resuming

A grilling that stopped mid-way resumes from the board, not from memory. Read the board in one pass (the lanework-boards recipe), then the Design tree card, then every Asked card's thread: a card whose thread holds an owner comment newer than its `waiting.since` has an answer not yet recorded, and that is the first thing to do. Then continue from step 4.

If the owner wants to answer on the board while the session waits, the **pitwall** skill's watch is the right tool: arm it on the grill board and every owner comment on an Asked card is an event to record and move.

## Writing conduct

The pitlane skill's `references/writing.md` governs every comment here. The specific rules of a grill board:

- **The question card's body is the ask.** It is the one place the owner is asked something, and it is not a comment; so no comment on a question card mentions the owner's handle. The `waiting` key is the bell.
- **A ruling is the owner's words.** Not a paraphrase, not the recommendation restated as if accepted. When the owner said "yes", the ruling is the recommendation, marked as accepted as recommended.
- **One question per card, one decision per question.** A question with two decisions in it is two cards.
- **Facts are cited, never asserted.** A Facts card names its source, attaches the report, and a question that leans on it links it.
- **Stamp every write** with your own identity, write atomically from a temp path outside the board, never rename a uuid folder, delete by moving to `.trash/`, and resolve a card's path immediately before every write to it. The guide has the rest.

## Versioning

Written against `lanework-agent-guide v70` and `lanework-schema v1`. Both markers are on line 1 of their own file, `CLAUDE.md` and `.schema/VERSION`, at the root of any board. If a board's guide reads a later version, the guide is right and this skill is stale.
