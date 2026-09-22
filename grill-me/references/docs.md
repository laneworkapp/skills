# The documents a grilling writes

The board holds the interview. Two documents outside it hold what the interview produced that the codebase should carry: a **glossary** and, rarely, a **decision record**. Both are written at the close of a round, from the rulings of that round, never batched to the end of the session.

## Glossary: `CONTEXT.md`

One file at the repo root (or, when a `CONTEXT-MAP.md` exists there, the `CONTEXT.md` of the context the topic belongs to). Create it lazily, the first time a term is pinned; add to it inline as later terms are pinned.

It is a glossary and nothing else: no implementation detail, no spec, no scratch notes. Definitions say what a thing **is**, in one or two sentences, and each term lists the words to avoid so that the whole codebase and every board uses one word per concept.

```markdown
# <Context name>

<One or two sentences: what this context is and why it exists.>

## Language

**Tracker**:
An external issue-tracking system a board can be bound to: Gitea, GitHub, GitLab, Jira.
_Avoid_: backend, integration, connector (the connector is the code that talks to a tracker)

**Remote**:
The tracker-side object a local object mirrors; an issue, for a card.
_Avoid_: counterpart, upstream, origin
```

Rules:

- **Be opinionated.** Pick the best word, list the rest under `_Avoid_`.
- **Only this project's terms.** A general programming concept does not belong, however much the project uses it.
- **Group under subheadings** only when clusters emerge on their own.
- **Challenge against it during the interview.** When the owner uses a term the glossary defines differently, or two words for one thing, the next round carries a question that names the conflict and proposes the canonical term.

A term pinned by a ruling is written the same round, and the Settled card names it: `Glossary: **Tracker**, **Remote** in CONTEXT.md`.

## Decision records: `docs/adr/`

An ADR is a paragraph, numbered `0001-slug.md`, `0002-slug.md`, … in `docs/adr/`, created lazily on the first one. Scan the folder for the highest number and increment.

```markdown
# <Short title of the decision>

<1 to 3 sentences: the context, what was decided, and why.>
```

Optional, only when it earns its place: a `status` frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`), a **Considered options** list when the rejected routes are worth remembering, a **Consequences** list when a downstream effect is not obvious.

Write one only when **all three** hold:

1. **Hard to reverse.** Changing it later costs something real.
2. **Surprising without context.** A future reader of the code would ask why.
3. **A real trade-off.** There were genuine alternatives and one was chosen for reasons.

Most rulings fail one of the three and get no ADR; the Settled card is their record. What qualifies: architectural shape, integration patterns between contexts, technology choices with lock-in, boundary and scope decisions (the explicit no-s as much as the yes-es), deliberate deviations from the obvious path, constraints invisible in the code, and rejected alternatives whose rejection is not obvious.

A ruling that produced an ADR links it from the Settled card: `ADR: docs/adr/0003-engine-in-app.md`. The ADR does not link back; it stands on its own.

## Where the project already keeps this

Some projects carry a design corpus of their own (a `DESIGN/` folder, a `SCHEMA.md`, a terminology section in a README). When they do, a ruling that changes what those documents say is also written there, in that project's own conventions, and the Settled card names the file. The glossary and the ADRs do not replace a project's corpus; they are the compact, machine-readable layer beside it.
