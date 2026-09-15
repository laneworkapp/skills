# Ask — the one comment that mentions the human

Fill and post; nothing else goes in this comment. Under 80 words. Keep the blank line after the options: Markdown folds the line after a list item into that item, so without it `Why now:` renders as the tail of the last option. `@owner` below is a placeholder — the real handle is the board owner's, as stated in the board's CLAUDE.md under Mentions. Lint before the `mv`: `scripts/lint-ask.sh <file> <board>`.

```markdown
@<handle> <the ask in one sentence: a question, or an imperative>

Options, only when choosing:
- A: <one line>
- B: <one line>

Why now: <one line>
If no answer: <the default and when it applies, or "blocked">
Context: <the comment above | body ▸ <section>>. Nothing restated.
```

## Filled

```markdown
@owner Did you drag [572e3b41](lanework://0b1e2a3c-4d5e-4f60-8a7b-9c0d1e2f3a4b/572e3b41-5762-44dc-993c-66875f954f6b) and [7259cd45](lanework://0b1e2a3c-4d5e-4f60-8a7b-9c0d1e2f3a4b/7259cd45-d65e-467a-8825-74f680dac3fc) to Issues on purpose at 17:30Z and back at 17:31Z, or only once?

Why now: cards you dragged today re-move themselves on every reload.
If no answer: blocked. The diagnosis depends on it.
Context: the comment above.
```

## Not this

The same request as it was actually posted, as the tail of a 160-word record:

> @owner this is live in your running build: cards you dragged today are changing lanes on their own each time the board reloads. Worth a quit-and-relaunch to see whether it clears, and a note here of whether you dragged 572e3b41 / 7259cd45 to Issues on purpose at 17:30 (and back at 17:31) or only once.

Two asks in one sentence, both hedged, the handle mid-thread, the evidence restated, the cards named bare. It becomes three comments: the record, the ask above, and a second ask for the relaunch with `If no answer: I assume it did not clear`.
