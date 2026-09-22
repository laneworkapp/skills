#!/bin/bash
# found-grill-board.sh: cold-start a grill-me board (references/board.md).
# usage: found-grill-board.sh "<path>/<Topic> Grill.lanework" ["Board Title"] \
#          [--model <model>] [--name <agent name>]
# Writes the board's index.md (schema 1, kind board, minted lowercase uuid
# id, the questionmark.bubble icon, the round label kind in config) and the
# five lanes (Brief, Facts, Asked, Settled, Parked) with the exact orders
# and bodies from board.md's "Lane bodies" table; Parked is collapsed. The
# board body is board.md's description and instruction sheet, with <topic>
# taken from the title minus a trailing " Grill". Writes nothing else — no
# CLAUDE.md, .schema, .gitignore; the app installs those on first open.
# Refuses if the board folder already exists and is non-empty.
set -euo pipefail

BOARD="${1:?usage: found-grill-board.sh <path>/<Topic> Grill.lanework [title] [--model m] [--name n]}"
shift

TITLE=""
if [ $# -gt 0 ] && [[ "$1" != --* ]]; then
  TITLE="$1"
  shift
fi

MODEL="${CLAUDE_MODEL:-unknown}"
NAME="claude"
while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="${2:?--model needs a value}"; shift 2 ;;
    --name)  NAME="${2:?--name needs a value}"; shift 2 ;;
    *) echo "found-grill-board.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -n "$TITLE" ] || TITLE=$(basename "$BOARD" .lanework)

TOPIC="$TITLE"
case "$TOPIC" in
  *" Grill") TOPIC="${TOPIC% Grill}" ;;
esac

if [ -d "$BOARD" ] && [ -n "$(ls -A "$BOARD" 2>/dev/null)" ]; then
  echo "found-grill-board.sh: refusing — $BOARD already exists and is not empty" >&2
  exit 1
fi

qtitle() {  # quote a scalar only when the guide says a bare one would break
  local s="$1"
  case "$s" in
    *": "*|"#"*|"["*|"{"*|"'"*|'"'*) printf '"%s"' "${s//\"/\\\"}" ;;
    *) printf '%s' "$s" ;;
  esac
}

NOW=$(date -u +%FT%TZ)
BY="{name: $NAME, kind: agent, model: $MODEL}"

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/grill-found.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$BOARD"
BOARD_ID=$(uuidgen | tr 'A-Z' 'a-z')

# ---- the board's own index.md ------------------------------------------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: board'
  printf 'title: %s\n' "$(qtitle "$TITLE")"
  printf 'id: %s\n' "$BOARD_ID"
  printf '%s\n' 'icon: {glyph: questionmark.bubble}'
  printf '%s\n' 'config: {show-card-body: 3, labels: [{type: round, text: Round}]}'
  printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
  printf '%s\n' '---'
  printf '# %s\n\n' "$TITLE"
  printf "A design interview on %s, one question per card. The agent asks in rounds; the owner rules; the ruling is written into the card in the owner's words. Brief holds the topic and the design tree, Facts what was looked up, and Settled is the record a later session resumes from.\n\n" "$TOPIC"
  cat <<'BODY'
## How this board works

- **The question card's body is the ask.** It is the one place the owner is asked anything on this board. Comments on a question card are records only and never mention the owner's handle; the `waiting` key is the bell.
- **Answer anywhere.** A comment on the card, or a reply in chat. The agent records a chat answer as a comment quoting it, then writes the ruling into the body under `## Ruling` and moves the card.
- **A ruling is the owner's words**, dated. "As recommended" is a ruling. A deferral or a refusal is a ruling too, and parks the card with the reason.
- **One question, one decision.** A round is every question whose prerequisites are settled. Questions number globally in the order asked; the round is the `Round` label.
- **Facts are cited.** A Facts card names its source and attaches the report; a question that leans on one links it under Depends on.
- **Nothing is built from this board.** When the frontier is empty and the owner confirms the understanding, work cards are filed on the project's pipeline board and link back here.
- **Git**: this board lives in the project repo. Stage only your own paths, plain commit messages, board writes separate from code changes.
BODY
} > "$STAGE/index.md"
mv "$STAGE/index.md" "$BOARD/index.md"

# ---- one folder and one index.md per lane -----------------------------------
while IFS='|' read -r ORDER LANE COLLAPSED LBODY; do
  [ -n "${ORDER:-}" ] || continue
  LANE_ID=$(uuidgen | tr 'A-Z' 'a-z')
  mkdir -p "$BOARD/$LANE_ID"
  {
    printf '%s\n' '---'
    printf '%s\n' 'schema: 1'
    printf '%s\n' 'kind: lane'
    printf 'title: %s\n' "$LANE"
    printf 'order: %s\n' "$ORDER"
    [ "$COLLAPSED" = "1" ] && printf '%s\n' 'collapsed: true'
    printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
    printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
    printf '%s\n' '---'
    printf '%s\n' "$LBODY"
  } > "$STAGE/lane.md"
  mv "$STAGE/lane.md" "$BOARD/$LANE_ID/index.md"
done <<'LANES'
1024|Brief|0|The two standing references. The Topic card states the scope and what a shared understanding must cover. The Design tree card is the outline of every decision, rewritten by the agent at the close of each round, and is the first thing a resuming session reads.
2048|Facts|0|One card per fact the agent established: from the code, the docs, the filesystem, a tool, or the web. The body is the fact and its source; the raw report is an attachment. A fact found wrong gets a dated correction comment, never an edit that hides the first reading.
3072|Asked|0|One card per open question, filed by the agent, waiting on the owner. The body is the question, the options and the recommendation. Answer by commenting on the card or by replying in chat. Only the agent moves a card out, and only once the ruling is written into the body.
4096|Settled|0|Answered questions. The body ends with a dated ruling in the owner's words. This lane is the design record: read it in order to see what was decided and why. A settled question is never edited; a change of mind is a new question in a later round that links this one.
5120|Parked|1|Questions the owner deferred or declined, with the reason as the ruling. Collapsed because it is read least; reopen one by asking it again as a new card that links this one.
LANES

printf 'founded %s\n' "$BOARD"
printf 'board id %s\n' "$BOARD_ID"
