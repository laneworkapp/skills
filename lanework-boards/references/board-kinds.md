# Three default lane sets

Three shapes cover most boards. Each one is a **default**, a starting point to copy and then change, not a rule the format enforces: the app knows nothing about lane names, and a board's meaning comes entirely from its lane titles and the bodies underneath them. Take the set that matches the work, rename what does not fit, and delete the lanes you will not use.

The `order` values below are the plain 1024 ladder. Use the gaps: a lane inserted later takes the midpoint of its neighbours and touches no other file.

## Pipeline

Work moving from a raw idea to something built. **Lanes are stages of commitment**, so a card's lane says who acts next.

| lane | order | what it holds |
|---|---|---|
| Ideas | 1024 | the inbox and the triage queue, zero bar to entry |
| Issues | 1536 | the side entrance for something broken in the running system |
| Shaping | 2048 | the agent work lane, where an idea becomes a proposal |
| Proposed | 3072 | the human review gate |
| Approved | 4096 | the ready-to-build queue, ranked, top is next |
| Active | 5120 | the build lane, one session holding one card |
| Done | 6144 | shipped work, with the evidence in the closing comment |

**A card is one piece of work**: a feature, a fix, a chore. Its body is the spec and grows as the card moves right, from a one-line capture in Ideas to a self-contained brief in Approved that an agent can pick up cold. Its comment thread is the journal: the reasoning that founded it, the plan when work starts, decisions as they are made, and the verification evidence at the end.

**Who moves it**: agents do the shaping, the building, the answering and the reporting, and move cards between the lanes on either side of their own work. Humans hold two gates and agents never move a card through one: **triage** out of Ideas (worth doing now, or out) and **review** out of Proposed (approve, bounce back to Shaping with notes, or reject). An agent that finds a card sitting at a gate surfaces it and stops there.

Common additions: a `Rejected` lane as a terminal side exit, collapsed, holding one line per card saying why; a `Deferred` lane, collapsed, for good ideas that are not now; a `Tasks` lane for chores that never need shaping. A busy `Done` lane usually carries `filter: [{by: modified, op: newer, value: 2d}]` so it shows recent landings only, and `group: {by: modified, direction: descending}` to bucket them by day.

## Design loop

One surface, one question, or one artefact worked up through drawn alternatives until a human picks a direction. The loop is the point: cards go back and forth between the middle lanes rather than moving steadily right.

| lane | order | what it holds |
|---|---|---|
| Brief | 1024 | the standing reference: inventory, constraints, evidence, the open calls |
| Alternatives | 2048 | one candidate direction per card, a paragraph and its reasoning |
| Mockups | 3072 | drawn: renders attached to the card, light and dark, every variant it lists |
| Sittings | 4096 | the owner has walked it, rulings recorded, and a card can loop back to Mockups |
| Chosen | 5120 | the direction that won, leaving as build cards elsewhere |
| Dead ends | 6144 | collapsed, one line each saying why it died |

**A card is one thing being designed**: a screen, a menu, a gesture, a piece of naming. Its body is the current proposal and gets rewritten as the design moves. Its attachments are the renders, and its thread is the argument, including every route rejected and the sentence that rejected it. A card in Mockups that shows no picture is not in Mockups.

**Who moves it**: agents inventory, draw, compare and argue, and they move cards from Brief through Alternatives into Mockups on their own. **The owner rules.** No direction is chosen by an agent, a Sitting happens only with the human present, and a ruling is recorded on the card in the owner's own words, one sentence. A card leaves Chosen as a card on a pipeline board, linked both ways.

Set `Dead ends` to `collapsed: true` from the start. It fills up, and it is the lane people read least and regret losing most.

## Datapoint board

One card per value that exists whether or not anyone is working on it: a listing field, a setting, a published number, a policy. Cards live here permanently and move between lanes as the value's state changes, rather than being born and retired.

| lane | order | what it holds |
|---|---|---|
| Brief | 1024 | the map: what the record is, where the values are pushed, what the limits are |
| Ideas | 2048 | what is not a card yet |
| Drafting | 3072 | the body is ahead of the file, the value is still being written |
| Filed | 4096 | the body matches the file in the repository, and the live system does not have it yet |
| Pushed | 5120 | the live system holds exactly what the body says, verified by reading it back |

**A card is one datapoint**, and the split inside its body is the whole convention: **everything above the first `##` heading is the current value, verbatim**, exactly as the live system will show it, and everything below it is the card's facts, the limit, the file it is written to, the surface it renders on, when the live system was last read. Its thread is the value's evolution: the idea, the discussion, the version that won. An idea about a datapoint is a comment on its card, never a new card, and the card drops back to Drafting the moment its body changes.

**Who moves it**: agents draft values, file them in the same commit that writes the file, and read the live system back. **Pushing is the owner's**, and a card earns Pushed only after a read-back that agrees with the body. A value that breaks a house rule is bounced to Drafting with a comment.

Optional beside those five, for the release steps around the values rather than the values themselves: `Checklist` 6144, `Active` 7168, `Done` 8192. A task card moves through those once and is done, unlike a datapoint card, which never leaves. Mark the difference with a label kind so the two read apart on the board.

Lanes on this kind of board are worth grouping: `group: {by: component, direction: descending}` on Filed and Pushed sections the values by whatever scope they belong to.
