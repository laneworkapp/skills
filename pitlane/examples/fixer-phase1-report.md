# Fixer Phase 1 — code-complete report (= verification-slot request)

Send this structure to the lead, not free-form prose. It doubles as the slot request.

```
CARD:   <board-relative card path — lane/<uuid> — and title>
BRANCH: <branch name, worktree absolute path>
FILES:  <changed source files>
TEST:   <new/modified test suite + method>

LINKED CONTEXT:
  <what the card's thread and every linked card's thread say that bears on this
  fix: a duplicate, a one-fix-many sibling to bundle into this branch, a corrected
  root-cause guess, related work already landed or in flight. "none found" only
  after actually reading them.>

EXPECTED BLAST RADIUS:
  <which modules/behaviors should change and why — and what must come back
  byte-identical / behavior-identical. The identity half is load-bearing.>

PRE-REGISTERED VERIFICATION:
  <REQUIRED, written BEFORE the gate runs. The named test(s) that fail before the
  fix and pass after; the suites that must stay untouched; any count the change
  should move, with its expected value. The prediction is ALLOWED TO BE WRONG —
  report the mismatch; never bend the measurement or narrow the fix to match it.>

TOUCHED SURFACE:
  <which modules/suites/seams this branch touches — the lead's cross-branch
  overlap and merge-ordering signal.>

UNCERTAINTY:
  <anything genuinely unsure — an edge case the new test does not cover, a second
  path that may need the same fix, ambiguity in the card's done-when. An honest
  "I only fixed the macOS path" is exactly the signal the reviewer needs. Note
  that the new test is UNRUN at this point if it is.>

REQUESTING VERIFICATION SLOT
```

Why each field exists — and what a missing one costs — is in `references/fixer.md`.
