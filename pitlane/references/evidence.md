# Evidence rules

Distilled measurement discipline for agents reporting numbers, counts, and green/red statuses on boards. Read once; apply the ones that bind.

**Nearly every measurement trap fails toward a false zero or a false green** — the direction that reads as a pass. That single fact motivates most of what follows.

**E0 comes first: before adding a check, name the wrong answer it would catch.** If none exists, skip it — ceremony that could not have changed the verdict is cost, not rigour. These are procedures, not proof obligations.

| | rule |
|---|---|
| **E1** | **Report the population beside every delta and every zero.** "0 failures" means nothing without "over N tests in M suites"; a correct count over a slightly-wrong population is the dominant failure mode. Put the denominator in the sentence. |
| **E2** | Ask whether the check would pass if the claim were **false**. Confirmatory is not discriminating — an untouched suite still passing separates no hypotheses. |
| **E3** | Pair a load-bearing zero with a **positive control in the same run**, differing in the dimension being measured. A control returning the measurement's own number is not a control. |
| **E4** | **Report only a status read out of the work's own output.** A status inferred from a path, a flag, or an intent is not a status. Require the gate's own success line, not the absence of a failure line. |
| **E5** | Re-derive any figure received from anyone, including the lead. A finding that arrives as *diagnosis + prescribed edit* leaves only the edit to evaluate, and the diagnosis is never re-derived. |
| **E6** | Suspect the instrument before the artifact whenever a result looks clean. |
| **E7** | Two agreeing signals that share an input are **one** signal. To corroborate, vary a parameter the answer must not depend on — never take a second reading the same way. |
| **E8** | Pre-register the **observable**, not the reporting channel. "The gate will be red" is not an observation; "test X fails with message Y" is. |
| **E9** | Verify a claim at the **sha it was made about** — checking HEAD refutes a different claim. Never cite a line number below the insertion point being written; name the site instead. |
| **E10** | **Read the hits, don't count them.** When a count surprises, print the distribution before believing it — an empty distribution indicts the pattern, not the corpus. |
| **E11** | Land a retraction in a **durable** artifact — a code comment or the card thread, never only an agent message. A deliberate absence needs a comment at the site where someone would add it back, or the next person "restores" it. |
| **E12** | Check the fix for the defect class it just fixed — the bug's shape recurs inside its own fix reliably enough to be a standing check. |
| **E13** | Label every claim **measured**, **reasoned**, or **inherited** — in reports, reviews, and card comments. Adjudicate disagreements on that labeling, not on seniority. |

## Fleet-specific, measured — do not re-derive

- **A blocked subagent can fabricate a deliverable.** Measured 2026-08-29: a Bash-denied subagent returned an invented data table rather than reporting the block. Any number that must be right is produced in the main session or cross-checked against one independently-derived value; a subagent report that contains no raw command output alongside its numbers is a claim, not a measurement.
- **Attribute before alleging fabrication.** Measured 2026-08-31: a "fabricated commit" was a concurrent session's owner-ruled landing. A surprising commit or card move has an author — read commit trailers, board stamps (`by` maps carry session identity), and companion-session claims before treating it as invented.
