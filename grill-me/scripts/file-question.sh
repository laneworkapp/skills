#!/bin/bash
# file-question.sh: file a question card into a grill board's Asked lane.
# usage: file-question.sh <board>.lanework "<title without the Q-number>" \
#          --round <n> --body <file> [--depends <lanework-link>...] \
#          [--why <text>] [--model <model>] [--name <name>]
# Mints the next global Q number by scanning every card title matching
# `^"?Q([0-9]+):` across every lane (.trash excluded), files it at the
# bottom of Asked with a founding comment one second later, and sets
# `waiting` on the card pointing at the board's human handle (read from
# CLAUDE.md's "human answers to `@handle`" line, else `human`). All writes
# are staged outside the board and moved in as one folder.
set -euo pipefail

BOARD="${1:?usage: file-question.sh <board> <title> --round <n> --body <file> [...]}"
TITLE="${2:?usage: file-question.sh <board> <title> --round <n> --body <file> [...]}"
shift 2

ROUND=""; BODY_FILE=""; WHY="**On the frontier now.**"
MODEL="${CLAUDE_MODEL:-unknown}"; NAME="claude"
DEPENDS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --round)   ROUND="${2:?--round needs a value}"; shift 2 ;;
    --body)    BODY_FILE="${2:?--body needs a file}"; shift 2 ;;
    --depends) DEPENDS+=("${2:?--depends needs a link}"); shift 2 ;;
    --why)     WHY="${2:?--why needs text}"; shift 2 ;;
    --model)   MODEL="${2:?--model needs a value}"; shift 2 ;;
    --name)    NAME="${2:?--name needs a value}"; shift 2 ;;
    *) echo "file-question.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -n "$ROUND" ] || { echo "file-question.sh: --round is required" >&2; exit 1; }
[ -n "$BODY_FILE" ] && [ -r "$BODY_FILE" ] || { echo "file-question.sh: --body must name a readable file" >&2; exit 1; }
[ -d "$BOARD" ] || { echo "file-question.sh: no such board: $BOARD" >&2; exit 1; }
[ -f "$BOARD/index.md" ] || { echo "file-question.sh: $BOARD has no index.md" >&2; exit 1; }

# fm_value <file> <key>: first top-level "key: value" line in the frontmatter.
fm_value() {
  awk -v key="$2" '
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    fm {
      n = index($0, ":")
      if (n > 0) {
        k = substr($0, 1, n-1)
        if (k == key) { v = substr($0, n+1); sub(/^[ \t]+/, "", v); print v; exit }
      }
    }' "$1"
}
strip_quotes() { local s="$1"; s="${s%\"}"; s="${s#\"}"; printf '%s' "$s"; }
esc() { printf '%s' "${1//\"/\\\"}"; }

BOARD_ID=$(fm_value "$BOARD/index.md" id)

# ---- find the Asked lane by reading each lane's title: ----------------------
ASKED_LANE=""
for d in "$BOARD"/*/; do
  d="${d%/}"
  [ -f "$d/index.md" ] || continue
  [ "$(fm_value "$d/index.md" kind)" = "lane" ] || continue
  [ "$(strip_quotes "$(fm_value "$d/index.md" title)")" = "Asked" ] || continue
  ASKED_LANE="$d"
  break
done
[ -n "$ASKED_LANE" ] || { echo "file-question.sh: no Asked lane found on $BOARD" >&2; exit 1; }

# ---- mint the next global Q number, every lane, .trash excluded -------------
MAXQ=0
while IFS= read -r f; do
  t=$(strip_quotes "$(fm_value "$f" title)")
  case "$t" in
    Q[0-9]*:*)
      n="${t#Q}"; n="${n%%:*}"
      case "$n" in ''|*[!0-9]*) ;; *) [ "$n" -gt "$MAXQ" ] && MAXQ="$n" ;; esac
      ;;
  esac
done < <(find "$BOARD" -mindepth 1 -maxdepth 1 -type d -name '.*' -prune -o -mindepth 3 -maxdepth 3 -type f -name index.md -print)
NEXTQ=$((MAXQ + 1))

# ---- order = bottom of Asked --------------------------------------------------
MAXORDER=""
for d in "$ASKED_LANE"/*/; do
  d="${d%/}"
  [ -f "$d/index.md" ] || continue
  o=$(fm_value "$d/index.md" order)
  case "$o" in ''|*[!0-9.-]*) continue ;; esac
  if [ -z "$MAXORDER" ] || awk -v a="$o" -v b="$MAXORDER" 'BEGIN{exit !(a>b)}'; then
    MAXORDER="$o"
  fi
done
NEW_ORDER=1024
[ -z "$MAXORDER" ] || NEW_ORDER=$(awk -v m="$MAXORDER" 'BEGIN{print m+1024}')

# ---- the owner's handle, from CLAUDE.md, else "human" -----------------------
HANDLE="human"
if [ -r "$BOARD/CLAUDE.md" ]; then
  h=$(grep -o 'human answers to `@[^`]*`' "$BOARD/CLAUDE.md" | head -1 | sed 's/.*`@\([^`]*\)`/\1/')
  [ -n "$h" ] && HANDLE="$h"
fi

NOW=$(date -u +%FT%TZ)
NOW_PLUS1=$(date -u -v+1S +%FT%TZ)
BY="{name: $NAME, kind: agent, model: $MODEL}"
CARD_ID=$(uuidgen | tr 'A-Z' 'a-z')
COMMENT_ID=$(uuidgen | tr 'A-Z' 'a-z')

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/grill-ask.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$CARD_ID/comments/$COMMENT_ID"

# ---- the card -----------------------------------------------------------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: card'
  printf 'title: "Q%s: %s"\n' "$NEXTQ" "$(esc "$TITLE")"
  printf 'order: %s\n' "$NEW_ORDER"
  printf 'labels: [{text: "Round %s", kind: {type: round, text: Round}}]\n' "$ROUND"
  printf 'waiting: {for: %s, since: %s, comment: %s}\n' "$HANDLE" "$NOW" "$COMMENT_ID"
  printf 'created:  {at: %s, by: %s}\n' "$NOW" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW" "$BY"
  printf '%s\n' '---'
  cat "$BODY_FILE"
  if [ "${#DEPENDS[@]}" -gt 0 ]; then
    printf '\n## Depends on\n\n'
    for link in "${DEPENDS[@]}"; do
      printf -- '- %s\n' "$link"
    done
  fi
} > "$STAGE/$CARD_ID/index.md"

# ---- its founding comment ------------------------------------------------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: comment'
  printf 'created:  {at: %s, by: %s}\n' "$NOW_PLUS1" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW_PLUS1" "$BY"
  printf '%s\n' '---'
  printf '%s\n' "$WHY"
} > "$STAGE/$CARD_ID/comments/$COMMENT_ID/index.md"

mv "$STAGE/$CARD_ID" "$ASKED_LANE/$CARD_ID"

printf 'lanework://%s/%s\n' "$BOARD_ID" "$CARD_ID"
printf 'short id %s\n' "${CARD_ID:0:8}"
