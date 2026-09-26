# Board sweeps: inventory → triage → farm

A sweep is a bounded, user-requested pass over one or more Pitlane boards
that ends in two things: a **triage report** to the user, and (when the
request includes working the board, not just reading it) work **farmed to
subagents** at the cheapest model tier that fits. A sweep is not a loop:
it runs once, reports, and stops. Standing cadences are the user's to set
up (via /loop or a schedule), never something a sweep grants itself.

## 1. Scope

"Sweep the boards" means the pipeline boards; "sweep Acme Pipeline" means
that one. When the user names no board, the candidates are, by default,
the current project's `Pitlane/*.lanework` plus `~/Pitlane` — never a
filesystem scan; a project not already in play enters the sweep by the
user naming it. Skip archive/schema boards unless asked.

A board says whether it is in scope for agent sweeps in **its own
`index.md` body, below the first `##` heading** — the owner's instruction
sheet, which the authority chain already opens. A sentence there narrows
or widens the default above; it is guidance, not a gate, so a board that
says nothing is swept or skipped by the rule above exactly as before.

## 2. Inventory

Per board, after reading the authority chain (board CLAUDE.md, board
index.md body, lane index.md bodies):

- **Ignore `.trash/` and the Done lane by default, plus any lane whose
  own `index.md` body says it is out of scope** — that body is where a
  telemetry or archive lane marks itself machine-written or excluded, and
  the board's own `index.md` body may name lanes too. Sweep them only
  when the owner explicitly asks — e.g. an archive sweep or a "what
  shipped last week?" question. Finished and deleted work is bulk that
  burns tokens and never yields a workload.
- List lanes in order with card counts.
- Read every card's frontmatter (title, labels, priority, due, modified)
  and skim bodies; read full threads only for cards that look actionable.
- A card's lane says who acts next — that is the primary classifier.

Classify each actionable card into one of these workloads (default lane
names; read the board):

| Workload | Where it shows up | Who acts |
|---|---|---|
| **Unanswered question** | any lane; a thread ending in a question — one mentioning the human's handle waits on them, one addressed to an agent waits on you | agent answers, or surface to user |
| **Approved, unstarted** | Approved lane | farm: build it |
| **Active, stalled** | Active lane, no thread movement | agent resumes or reports why it's stuck |
| **Shaping to advance** | Shaping lane, below the board's proposal bar | farm: shape into a proposal |
| **Awaiting human gate** | Ideas (triage) or Proposed (review) | report only — never move these |
| **Issue** | Issues lane | diagnose; fix if approved-level per board policy |
| **Hygiene** | Done/Rejected overdue for archive sweep, per board index.md | only on the owner's explicit request — never part of a default sweep |

## 3. The triage report

Always report before (or alongside) farming: per board, what's waiting on
the human (gates, mentions, questions with stated defaults), what you are
farming out and to what tier, and what you're deliberately leaving alone.
If the user asked only "anything on the boards?", the report IS the
deliverable — stop there.

## 4. Farming: model-tier routing

Execution leaves the main session; the main session keeps synthesis,
review of agent output, and every board write that represents a judgment
call. Route by the global model policy:

- **haiku** — mechanical: inventory of a big board, archive sweeps,
  formatting, running builds/tests and parsing output.
- **sonnet** — routine: shaping a well-understood card, building a
  tightly-specified Approved card, writing tests against a stated spec,
  doc updates.
- **opus** — complex implementation: tricky debugging, concurrency,
  migrations, anything where the Approved card's spec still leaves hard
  calls.
- **inherit (no override)** — only when the subagent itself must make
  architectural judgment calls.

Every farmed task's prompt must carry: the card's path, an instruction to
read the board's CLAUDE.md + index.md + the card's full thread before
acting, the identity to stamp (`by: {name: <role>, kind: agent, model:
<tier>}`), the requirement to journal plan → decisions → verification
evidence on the card's thread, and the comment rule from `writing.md`
spelled out, since a farmed agent without a role page never reads it:
records never mention the human; a question for the human is a separate
ask comment in the `examples/ask.md` shape, posted a second after the
record and linted with `scripts/lint-ask.sh <file> <board>` before the
`mv` (in a lead/fixer cycle it goes to the lead instead). A shaper is
the usual offender: it ends a long record with the question.

Multi-agent orchestration at Workflow-tool scale needs the user's explicit
opt-in; a requested sweep that farms a handful of Agent-tool subagents
does not. When a sweep uncovers enough parallel work that a workflow would
help, say so and ask rather than launching one.

## 5. The build cycle: lead / fixer / reviewer

For substantial coding cards (roughly: two or more independent Approved
cards to parallelize, or any card where review independence matters), use
a role split so no agent reviews its own work. Below that, work the card
directly with pitlane conduct and skip the ceremony. The **lead is the
main session**; the role pages are the complete job descriptions —
`lead.md`, `fixer.md`, `reviewer.md` — and the inter-agent reports use
the templates in `examples/`. The cycle:

```
lead creates + hands off a coding worktree
  -> fixer reads the card thread whole, posts its plan, codes (fix + one test)
  -> fixer sends the Phase-1 report (= slot request, with pre-registered verification)
  -> lead grants a slot
  -> fixer runs the project's gate, sends the Phase-2 report, releases the slot
  -> reviewer reviews the branch, posts the verdict on the card thread
  -> lead merges, re-verifies main, closes the card with evidence, cross-posts
  -> lead shuts down that reviewer AND fixer, removes the coding worktree
  -> next
```

The load-bearing ideas: **worktree isolation** (fixers never touch the
main checkout and never run `git worktree`); **slots** (heavy builds are
serialized by lead grant — the Phase-1 report is the request);
**phase reports** (the lead reads reports, not transcripts); **independent
review** (a separate reviewer, explicit verdict on the card thread before
merge); **the lead merges and closes** (evidence in the closing comment,
cross-posts to related cards, then teardown — nothing left running).

Project specifics — the gate command, what "green" means, blast-radius
rules, whether a remote/PR exists — come from the project's repo
CLAUDE.md and the board's index.md body, never from this file.

## 6. Closing a sweep

- **A finding that is not filed is lost.** Anything uncovered but not
  worked (a bug noticed in passing, a follow-up the fix implies) gets a
  card before the sweep ends — after a duplicate search on the mechanism,
  not the title phrasing (`traps.md`).
- Every card touched has its thread updated and its stamps correct.
- Board-repo commits made per the board's own git instructions (its
  index.md body says how that repo is committed), board writes separate
  from code commits.
- Final report to the user: what moved, what shipped, what waits on
  them, what it cost (agents spawned and tiers used).
