#!/bin/bash
# file-question.sh: file a question card into a grill board's Asked lane.
# usage: file-question.sh <board>.lanework "<title without the Q-number>" \
#          --round <n> --body <file> [--ask <file>] [--depends <lanework-link>...] \
#          [--why <text>] [--model <model>] [--name <name>]
# Mints the next global Q number by scanning every card title matching
# `^"?Q([0-9]+):` across every lane (.trash excluded), files it at the
# bottom of Asked with two comments, one second apart: a founding record
# (--why, mentions nobody) and then the ask, which carries the owner's
# handle and is what the card's `waiting.comment` points at.
#
# --ask supplies the ask body verbatim. Without it, the ask is generated
# from --body: `@<handle> ` plus the paragraph above the first `## `
# heading (joined, whitespace collapsed) as the question; the `## Options`
# bullets verbatim, when that section exists; the first sentence of
# `## Recommended` (up to and including its first period) as the
# recommendation; and a matching "If no answer" default (the recommended
# option's leading letter when the sentence starts with one, else the
# generic form). The generated ask is linted with pitlane's lint-ask.sh
# before the mv; its output is printed as a warning and never aborts the
# file.
#
# The owner's handle (used for both `waiting.for` and the ask's mention)
# is read from CLAUDE.md's "human answers to `@handle`" line, else
# `human`. All writes are staged outside the board and moved in as one
# folder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LINT_SCRIPT="$SCRIPT_DIR/../../pitlane/scripts/lint-ask.sh"

BOARD="${1:?usage: file-question.sh <board> <title> --round <n> --body <file> [...]}"
TITLE="${2:?usage: file-question.sh <board> <title> --round <n> --body <file> [...]}"
shift 2

ROUND=""; BODY_FILE=""; ASK_FILE=""; WHY="**On the frontier now.**"
MODEL="${CLAUDE_MODEL:-unknown}"; NAME="claude"
DEPENDS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --round)   ROUND="${2:?--round needs a value}"; shift 2 ;;
    --body)    BODY_FILE="${2:?--body needs a file}"; shift 2 ;;
    --ask)     ASK_FILE="${2:?--ask needs a file}"; shift 2 ;;
    --depends) DEPENDS+=("${2:?--depends needs a link}"); shift 2 ;;
    --why)     WHY="${2:?--why needs text}"; shift 2 ;;
    --model)   MODEL="${2:?--model needs a value}"; shift 2 ;;
    --name)    NAME="${2:?--name needs a value}"; shift 2 ;;
    *) echo "file-question.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -n "$ROUND" ] || { echo "file-question.sh: --round is required" >&2; exit 1; }
[ -n "$BODY_FILE" ] && [ -r "$BODY_FILE" ] || { echo "file-question.sh: --body must name a readable file" >&2; exit 1; }
[ -z "$ASK_FILE" ] || [ -r "$ASK_FILE" ] || { echo "file-question.sh: --ask must name a readable file" >&2; exit 1; }
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

# preamble_of <file>: lines before the first "## " heading (a bare body has none).
preamble_of() {
  awk '/^## / { exit } { print }' "$1"
}

# section_of <file> <heading>: body lines of "## <heading>", up to the next "## " or EOF.
section_of() {
  awk -v h="## $2" '
    $0 == h { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$1"
}

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

# ---- build the ask body, unless one was supplied verbatim -------------------
if [ -z "$ASK_FILE" ]; then
  FIRST_PARA=$(preamble_of "$BODY_FILE" | awk 'NF' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//')
  OPTIONS_LINES=$(section_of "$BODY_FILE" Options | grep -E '^-[[:space:]]' || true)
  REC_JOINED=$(section_of "$BODY_FILE" Recommended | awk 'NF' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//')
  if [[ "$REC_JOINED" == *.* ]]; then
    REC_SENTENCE="${REC_JOINED%%.*}."
  else
    REC_SENTENCE="$REC_JOINED"
  fi
  if [[ "$REC_SENTENCE" =~ ^([A-Z])[.,] ]]; then
    IF_NO_ANSWER="If no answer: ${BASH_REMATCH[1]} stands when the round closes."
  else
    IF_NO_ANSWER="If no answer: the recommendation stands when the round closes."
  fi
  build_ask() {
    printf '@%s %s\n' "$HANDLE" "$FIRST_PARA"
    printf '\n'
    if [ -n "$OPTIONS_LINES" ]; then
      printf 'Options:\n'
      printf '%s\n' "$OPTIONS_LINES"
      printf '\n'
    fi
    printf 'Recommended: %s\n' "$REC_SENTENCE"
    printf '%s\n' "$IF_NO_ANSWER"
    printf 'Context: body.\n'
  }
fi

NOW=$(date -u +%FT%TZ)
NOW_PLUS1=$(date -u -v+1S +%FT%TZ)
NOW_PLUS2=$(date -u -v+2S +%FT%TZ)
BY="{name: $NAME, kind: agent, model: $MODEL}"
CARD_ID=$(uuidgen | tr 'A-Z' 'a-z')
FOUND_ID=$(uuidgen | tr 'A-Z' 'a-z')
ASK_ID=$(uuidgen | tr 'A-Z' 'a-z')

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/grill-ask.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$CARD_ID/comments/$FOUND_ID" "$STAGE/$CARD_ID/comments/$ASK_ID"

# ---- the card -----------------------------------------------------------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: card'
  printf 'title: "Q%s: %s"\n' "$NEXTQ" "$(esc "$TITLE")"
  printf 'order: %s\n' "$NEW_ORDER"
  printf 'labels: [{text: "Round %s", kind: {type: round, text: Round}}]\n' "$ROUND"
  printf 'waiting: {for: %s, since: %s, comment: %s}\n' "$HANDLE" "$NOW" "$ASK_ID"
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

# ---- its founding comment: a record, never mentions the handle ----------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: comment'
  printf 'created:  {at: %s, by: %s}\n' "$NOW_PLUS1" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW_PLUS1" "$BY"
  printf '%s\n' '---'
  printf '%s\n' "$WHY"
} > "$STAGE/$CARD_ID/comments/$FOUND_ID/index.md"

# ---- then the ask, one second later, the last comment when filed --------------
{
  printf '%s\n' '---'
  printf '%s\n' 'schema: 1'
  printf '%s\n' 'kind: comment'
  printf 'created:  {at: %s, by: %s}\n' "$NOW_PLUS2" "$BY"
  printf 'modified: {at: %s, by: %s}\n' "$NOW_PLUS2" "$BY"
  printf '%s\n' '---'
  if [ -n "$ASK_FILE" ]; then
    cat "$ASK_FILE"
  else
    build_ask
  fi
} > "$STAGE/$CARD_ID/comments/$ASK_ID/index.md"

# ---- lint the ask before it lands; warn, never abort ---------------------------
if [ -x "$LINT_SCRIPT" ]; then
  LINT_OUT=$("$LINT_SCRIPT" "$STAGE/$CARD_ID/comments/$ASK_ID/index.md" "$BOARD" 2>&1) || true
  if [ -n "$LINT_OUT" ]; then
    echo "file-question.sh: lint-ask warning:" >&2
    printf '%s\n' "$LINT_OUT" >&2
  fi
else
  echo "file-question.sh: warning: lint-ask.sh not found at $LINT_SCRIPT" >&2
fi

mv "$STAGE/$CARD_ID" "$ASKED_LANE/$CARD_ID"

printf 'lanework://%s/%s\n' "$BOARD_ID" "$CARD_ID"
printf 'short id %s\n' "${CARD_ID:0:8}"
printf 'ask comment %s\n' "$ASK_ID"
