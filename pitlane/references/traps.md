# Command and write traps

Look up by the operation about to run. Each row is a command or write that returns a **plausible answer to a different question** — mostly a false zero or a silent success, the direction that reads as a pass. Board-format authority stays with the board's own CLAUDE.md; these are the failure modes it cannot warn about.

## Board writes

| about to… | what actually happens |
|---|---|
| Write a comment to a remembered card path | cards move lanes between read and write; a stale path plants a **ghost card**. Resolve fresh, in the same command as the write: `ls "$BOARD"/*/<card-uuid>/index.md` |
| use the Write tool on a board path | **the Write tool is a ghost machine**: it auto-creates parent directories, so a stale path silently mints a duplicate card instead of failing — and the app heals the collision under a *fresh* uuid, so the residue may not even carry the path you wrote. Prefer shell `mv`-into-place guarded by an existence check |
| write `title:` (or any string value) **unquoted** in frontmatter | a `: ` inside the value turns the line into a nested YAML mapping and **the app refuses the whole card** with "mapping values are not allowed in this context" (Lab board, 2026-09-12, a title reading `…are stale: ten module…`). The guide's own template shows the bare form. **Always double-quote every string value** — `title: "…"` — and it also covers `#`, a leading `*` `&` `!` `[` `{`, and bare `yes`/`no`/`null`. After writing, parse the frontmatter back: `awk '/^---$/{n++;next} n==1' "$f" | yq -e . >/dev/null` |
| `mkdir` a card directory to make a comment land | the path is wrong. Never `mkdir` card dirs |
| regex-patch a stamp line | nested braces corrupt (`}}}`) — rewrite the whole line explicitly, and `grep '}}}'` every touched file after stamp writes |
| post several comments in one burst | identical `created.at` seconds scramble thread order — give each comment a distinct second |
| `head -N` a board file | truncation has missed owner rulings. `cat` whole files, always |
| write a board file in place | the app reloads on every filesystem event and can read a half-written file. Build in a temp path, `mv` into place |
| `git add` a lane dir, a whole card dir, or `-A` | sweeps in other cards, and the owner's unposted `comments/.draft/`. Stage the specific `index.md` and `comments/<uuid>` paths you wrote |
| extract frontmatter with grep/sed | use `yq` over the frontmatter block: `awk '/^---$/{n++;next} n==1' "$f" \| yq -r '.created.by.kind // ""'` |
| `rm -r` anything on a board | delete = move to `<board>/.trash/`, never `rm` |
| file a card for a finding | **search the board first, on the mechanism, not your title phrasing** — a duplicate filed by someone else won't share your wording; grep Done too |

## Shell

| command | what it actually does |
|---|---|
| `grep -c` | exits **nonzero** when the count is 0, so it kills a `set -e` script and inverts an `if` |
| `cmd 2>/dev/null` on a sweep | discards the instrument's complaint about its own arguments — never suppress stderr on a sweep whose number gets quoted |
| a short lowercase pattern | matches **inside** longer words; the false positive can point the wrong way |
| `cmd \| head` / `cmd \| tail` | the pipeline's exit code is the **last** command's. Redirect to a log and echo `$?`, or set `pipefail` |
| `some-tool $VAR` under zsh | zsh does **not** word-split a variable expansion — the whole string arrives as one argument. Use an array |
| `log show` in this zsh | runs a **builtin** and returns nothing. Always `/usr/bin/log`, with whole-second `--start`/`--end` |
| filtering fswatch event paths | the app posts comments and moves cards by **renaming directories**, so raw FSEvents never carry the unchanged `index.md` inside — a path filter silently drops exactly the owner comments a watch exists for. Diff a find-snapshot instead (pitwall skill) |

## Git

| command | what it actually does |
|---|---|
| `git checkout -- <file>` | restores from the **index**, so on an uncommitted branch it deletes the fix. Revert an experiment with `cp` |
| `git diff main..HEAD` / `origin/main..HEAD` | diffs against a **moving** reference and reports the other side's commits as this branch's content. Diff from `git merge-base` or a pinned sha |
| `git blame` | answers "who last touched this line", **never** "did this line exist before" |
| `git grep -E` with `\b` `\s` `\d` | POSIX ERE has no shorthand classes — these match literals or nothing |
| `git -C <removed-worktree-dir>` | does **not** error — it walks up and answers about the **shared** repo. Confirm the worktree in `git worktree list` first |
| bare `git` with agents in play | answers from whatever cwd it inherited. Always pass `-C` |
| `grep -r` from a repo root containing worktrees | multiplies every count by the number of worktrees |
| `git merge-base --is-ancestor A B && echo ok` | prints nothing on failure, and silence reads as a pass. Give the negative branch a voice; treat exit >1 (unknown rev = 128) as fatal |
| `git merge-tree --write-tree` | answers merge-order questions **read-only** — use it instead of a trial merge |
