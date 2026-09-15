# Fixer Phase 2 — verification-outcome report

Sent to the lead after running the project's gate under the granted slot.

```
VERIFICATION: GREEN | RED

GATE: <the exact command run — as the board index.md / repo CLAUDE.md states it —
  and the gate's OWN success line with counts, e.g. "4580 passed, 0 failed,
  765 skipped". Population beside every zero; a status inferred from a path or
  an intent is not a status.>

BLAST RADIUS:
  <what actually changed, one-line rationale each, compared against the Phase-1
  EXPECTED BLAST RADIUS. Name any mismatch as a mismatch.>

PREDICTION vs OUTCOME:
  <the Phase-1 PRE-REGISTERED VERIFICATION against what was measured — which
  predicted failures/passes/counts held, and which did not.>

CROSS-POST:
  <2–4 lines for the lead to post on the related cards this branch touches, once
  it merges: what changed, the shape of the fix (which type/method/seam), and
  what a sibling fixer can REUSE or must BEWARE.>

PENDING: <anything not yet done, named as such — "opening X now" inside a green
  report reads to the lead as a completed step. "none" if none.>

SLOT RELEASED (worktree stays until merge — it is the lead's to remove)
```

**Report the population beside every delta.** "0 failures" alone cannot distinguish a correctly green run from a run that tested nothing.

If RED at any step, fix it in place and re-run from the failing step before reporting again — re-requesting the slot for anything heavy.
