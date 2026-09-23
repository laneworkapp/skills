#!/bin/bash
# settle-question.sh: record a ruling on a grill board question card and move it.
# usage: settle-question.sh <board>.lanework <card-uuid> --ruling <file> \
#          [--to settled|parked] [--reply <comment-uuid>] [--record <file>] \
#          [--model <model>] [--name <name>] [--session <text>]
# Appends `## Ruling` (the --ruling file's text, which should open with the
# bold date) to the card body, drops `waiting`, restamps `modified`, posts the
# --record file as a comment (in reply to --reply when given), and moves the
# card to the bottom of Settled (default) or Parked. Every write is staged
# outside the board; the card's path is resolved immediately before the write.
set -euo pipefail

BOARD="${1:?usage: settle-question.sh <board> <card-uuid> --ruling <file> [...]}"
CID="${2:?usage: settle-question.sh <board> <card-uuid> --ruling <file> [...]}"
shift 2
TO="settled"; REPLY=""; RULING=""; RECORD=""
MODEL="${CLAUDE_MODEL:-unknown}"; NAME="claude"; SESSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --to)      TO="${2:?}"; shift 2 ;;
    --reply)   REPLY="${2:?}"; shift 2 ;;
    --ruling)  RULING="${2:?}"; shift 2 ;;
    --record)  RECORD="${2:?}"; shift 2 ;;
    --model)   MODEL="${2:?}"; shift 2 ;;
    --name)    NAME="${2:?}"; shift 2 ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -r "${RULING:-}" ] || { echo "--ruling must name a readable file" >&2; exit 2; }
case "$TO" in settled) LANE_TITLE="Settled" ;; parked) LANE_TITLE="Parked" ;; *) echo "--to is settled or parked" >&2; exit 2 ;; esac

fm_val() { awk -v k="^$2:" '/^---[ \t]*$/ {n++; next} n==1 && $0 ~ k {sub(/^[^:]*:[ \t]*/, ""); print; exit}' "$1"; }
lane_by_title() { local l; for l in "$BOARD"/*/; do [ -f "$l/index.md" ] || continue; [ "$(fm_val "$l/index.md" title)" = "$1" ] && { printf '%s' "${l%/}"; return; }; done; return 1; }
DEST=$(lane_by_title "$LANE_TITLE") || { echo "no lane titled $LANE_TITLE" >&2; exit 1; }

if [ -n "$SESSION" ]; then BY="{name: $NAME, kind: agent, model: $MODEL, session: \"$SESSION\"}"; else BY="{name: $NAME, kind: agent, model: $MODEL}"; fi
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/grill-settle.XXXXXX"); trap 'rm -rf "$STAGE"' EXIT

# ---- the card: resolve now, rewrite body, restamp ----------------------------
CARD=$(ls -d "$BOARD"/*/"$CID" 2>/dev/null | head -1)
[ -n "$CARD" ] && [ -f "$CARD/index.md" ] || { echo "no card $CID on the board" >&2; exit 1; }
NOW=$(date -u +%FT%TZ)
MAXO=$( { for f in "$DEST"/*/index.md; do [ -f "$f" ] && fm_val "$f" order; done; true; } 2>/dev/null | { grep -E '^-?[0-9]+$' || true; } | sort -n | tail -1)
ORDER=$(( ${MAXO:-0} + 1024 ))
awk -v o="order: $ORDER" -v m="modified: {at: $NOW, by: $BY}" '
  /^---[ \t]*$/ {n++}
  n==1 && /^waiting:/ {next}
  n==1 && /^order:/ {print o; next}
  n==1 && /^modified:/ {print m; next}
  {print}' "$CARD/index.md" > "$STAGE/index.md"
{ printf '\n## Ruling\n\n'; cat "$RULING"; } >> "$STAGE/index.md"
grep -q '}}}' "$STAGE/index.md" && { echo "triple brace after restamp; aborting" >&2; exit 1; }

# ---- the record comment ------------------------------------------------------
COID=""
if [ -n "$RECORD" ]; then
  [ -r "$RECORD" ] || { echo "--record must name a readable file" >&2; exit 2; }
  COID=$(uuidgen | tr 'A-Z' 'a-z'); mkdir -p "$STAGE/comment"
  {
    printf '%s\n' '---' 'schema: 1' 'kind: comment'
    [ -n "$REPLY" ] && printf 'in-reply-to: %s\n' "$REPLY"
    printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
    printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
    printf '%s\n' '---'
    cat "$RECORD"
  } > "$STAGE/comment/index.md"
fi

# ---- land: re-resolve, write, move -------------------------------------------
CARD=$(ls -d "$BOARD"/*/"$CID" 2>/dev/null | head -1)
[ -n "$CARD" ] && [ -f "$CARD/index.md" ] || { echo "card $CID moved during settle; nothing written" >&2; exit 1; }
mv "$STAGE/index.md" "$CARD/index.md"
if [ -n "$COID" ]; then mkdir -p "$CARD/comments"; mv "$STAGE/comment" "$CARD/comments/$COID"; fi
if [ "$CARD" != "$DEST/$CID" ]; then mv "$CARD" "$DEST/$CID"; fi
BID=$(fm_val "$BOARD/index.md" id)
printf 'settled %s -> %s (order %s)\n' "${CID:0:8}" "$LANE_TITLE" "$ORDER"
[ -n "$COID" ] && printf 'record comment %s\n' "$COID"
printf 'lanework://%s/%s\n' "$BID" "$CID"
