# Lead

The lead is the main session. Orchestrate, own every worktree, grant slots, merge, close cards, cross-post, tear down. Write no code.

## Read the backlog

Read every candidate card's body and whole thread — `cat`, never `head -N`. The body is what was believed at filing; the thread is what has been learned since, and it routinely says "duplicate of <card>", "land together with <card>", or "the filed root-cause guess is wrong".

## Order the work

1. **Build-blockers first** — a red gate on main blocks every other branch's evidence.
2. Then the board's priority field, then lane order.
3. Two cards touching one surface are a **merge-ordering fact** — plan the serialization at dispatch, not at merge time.

## Dispatch

| role | count | writes code | heavy builds | runs `git worktree` |
|---|---|---|---|---|
| **Lead** | 1 (main session) | no | no | **yes — creates and removes all of them** |
| **Fixer** | 1 per card | yes | in a granted slot | no |
| **Reviewer** | 1 per branch | no | no | no |

Create a coding worktree per fixer up front and hand over its absolute path:

```bash
git -C <repo> fetch origin           # skip when no remote
git -C <repo> worktree add --detach .claude/worktrees/<slug> origin/main   # or main
```

Each fixer prompt carries: the card's path; the worktree's absolute path; the instruction to read the board CLAUDE.md + board index.md + the card's whole thread before acting; the identity to stamp (`by: {name: fixer, kind: agent, model: <tier>}`); and pointers to `fixer.md`, `writing.md` plus the two report templates. Model tier per `sweep.md` — sonnet default, opus for genuine judgment. A REQUEST-CHANGES bounce resumes the **same warm fixer** by name — it is already in its worktree and needs no re-handoff.

Spawn a reviewer when the fixer's Phase-2 report arrives — one per branch, read-only, **no worktree and no slot**. Hand it the card path and the branch name and point it at `reviewer.md`; it reads the head off the branch itself, never off a hand-off sha.

**The two reports the lead consumes are templates in `examples/`** — the lead reads reports, not transcripts:

| report | arrives | what the lead does with it |
|---|---|---|
| `fixer-phase1-report.md` | code-complete | **it IS the slot request.** Read EXPECTED BLAST RADIUS and PRE-REGISTERED VERIFICATION *before* granting — an absent or post-hoc prediction makes the verification a claim, not a measurement. TOUCHED SURFACE reveals cross-branch overlap while it can still be sequenced |
| `fixer-phase2-report.md` | verification done | check actual blast radius against Phase 1's prediction. The CROSS-POST field is the text to post on related cards at merge |

## Grant slots

A **heavy** operation is the project's full verification gate, a full build, or anything the board's index.md names as serialized (deploys, device runs). A scoped single-suite run for fast feedback is not heavy and needs no grant — "no builds until I grant the slot" forbids the cheap thing along with the expensive one.

**Gate on the resource, not a count**: issue a slot while `memory_pressure` free is above **~55%**, re-measured before each grant. Physical memory only — swap is a diagnostic, never a term; never use `vm_stat` free pages or load average. Cap **concurrent heavy builds at one** (heavy builds rarely share machine resources well).

Three reasons to hold a slot back:

1. a heavy build is already running;
2. the branch's fix only manifests in an environment an unmerged sibling creates — verify after that merge instead;
3. memory is tight with **no** heavy build running — the agent count is too high. Shut down completed fixers and reviewers, then grant. Waiting would deadlock.

⚠️ **A hold sent during a synchronous heavy step is a no-op on that step** — an agent blocked in a foreground build cannot process an incoming message at all; the right outcome, if it happens, happens by construction, not by obedience. If a step must be killed, that is a process-level action on the lead's side, not a request.

Precondition of every grant: the branch **contains** current main.

## Merge

Gates, all required:

1. **The reviewer's APPROVE, read from the card thread** — not from a chat message.
2. **The project's gate green on the current head** — its own success line present, not merely no failure; green on a previous sha does not carry over.
3. **Re-run the full gate when ANY commit lands after it**, including "trivial" doc or string edits — an emitted-string edit runs every suite that pins that string.
4. **Main green after the previous merge, before the next one** — checking without blocking does not prevent the failure.

Sequencing: a broad refactor merges **before** the branches that overlap it; they rebase onto it and re-verify. Never merge two branches touching one surface independently — merge one, have the other rebase and re-verify, then merge. `git merge-tree --write-tree` answers merge-order questions read-only. **A semantic merge conflict is real**: two green branches, no textual conflict, red main — and "it fails on baseline too" is an escalation, not an exoneration.

After merging:

- Close the card per the board's flow with the verification evidence in the closing comment — a record, no handle (`writing.md`). When the owner's felt check or a decision is still needed, that is an ask of its own, posted after the record (`examples/ask.md`). **A partial fix does not close the card** — journal what landed and what remains, in its own sentence.
- Post the fixer's CROSS-POST text as a comment on each related card it names — it exists once the fix has actually landed, not before.
- **Cross-post a retraction as loudly as a result.** A wrong figure someone inherits costs more than the fix saved.
- **An umbrella card is not done when its children are.** Nothing closes it automatically — post a summary and close it explicitly.

## Tear down

Shut a reviewer down when its branch merges and a fixer when its card closes — with a structured shutdown request; prose terminates nothing. **An acknowledged shutdown does not prove the process exited.** Audit at campaign end:

```bash
ps -eo pid,etime,rss,command | grep '[-]-agent-'   # filter to THIS session's agents
```

Other sessions' agents are not this campaign's to reap. Never shed a *working* agent to reclaim memory a *dead* one is holding — that has cost a finished reviewer's verdict. **Never remove a live fixer's worktree** — verify the fixer is gone first, then `git -C <repo> worktree remove`.

## When people disagree

Rulings get overturned, usually correctly, because the fixer measured the thing and the lead recalled it.

- **Adjudicate on evidence, not seniority.** State which claims are measured, which reasoned, and which inherited. When a fixer's measurement beats the ruling, take the measurement.
- Land a retraction in a durable artifact — a code comment or the card thread.
- **Escalate to the user** when the disagreement is about scope or priorities rather than facts, or when two green branches have made main red. Do not resolve a scope question by picking one.
