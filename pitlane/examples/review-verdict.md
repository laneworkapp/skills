# Reviewer verdict

**Post this as a comment on the card thread** (stamped `by: {name: reviewer, kind: agent, model: <tier>}`), then send the same text to the lead. The thread is the durable copy — a verdict that lives only in an agent message is lost at teardown.

```
VERDICT: APPROVE | REQUEST-CHANGES

CARD:   <board-relative path + title>
BRANCH: <branch> at <head sha read off the branch, not off the hand-off>

FINDINGS: <count>
  <one line each: file:line @ <short sha> "<quoted line fragment>" — what is
  wrong, why, fix direction. "none" if clean.>

CHECKED:
  correctness vs done-when: <what was compared against the card's stated observation>
  project conduct:          <the repo CLAUDE.md bars checked, and any "assume Y" shapes found>
  both paths:               <second platform/code path handled, flagged, or why only one applies>
  test adequacy:            <would it have failed before the fix — VERIFIED or REASONED>
  blast radius:             <Phase-2 actual vs Phase-1 expected, and any unexplained churn>
  population:               <every reported delta arrived with its denominator, or it did not>

UNRESOLVED: <open questions for the lead or the card thread, or "none">
```

**REQUEST-CHANGES goes back to the same fixer**, by name, with the precise diagnosis. Do not start a fresh agent — the warm one is already in its worktree with the context.
