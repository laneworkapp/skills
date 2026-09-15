#!/bin/bash
# Lint an ask comment before it lands.   Usage: lint-ask.sh <file> [<board dir>]
#   <file>   a comment index.md (frontmatter + body) or a bare body file
#   <board>  the .lanework folder; its CLAUDE.md names the human's handle. Without it, the
#            first @token in the body is taken as the handle.
# A body that mentions nobody is a record and passes untouched. A body that mentions the
# human is an ask and must fit the budget in references/writing.md: handle on the first
# line, under 80 words, one question, one clause per sentence (no em-dash, no semicolon),
# no hedging, a blank line after any list (the next line folds into the last item otherwise), every card it names linked (`lanework://<board-id>/<card-id>` somewhere in the
# body for each bare eight-hex id). One line per violation on stdout and exit 1; silent exit 0
# when clean.
set -u
f=${1:?usage: lint-ask.sh <file> [<board dir>]}; board=${2:-}
[ -r "$f" ] || { echo "no such file: $f"; exit 2; }
body=$(awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm' "$f")
handle=""
if [ -n "$board" ] && [ -r "$board/CLAUDE.md" ]; then
  handle=$(grep -o 'human answers to `@[^`]*`' "$board/CLAUDE.md" | head -1 | sed 's/.*`@\([^`]*\)`/\1/')
fi
[ -n "$handle" ] || handle=$(printf '%s\n' "$body" | grep -o -E '(^|[^[:alnum:]_])@[[:alnum:]_-]+' | head -1 | sed 's/.*@//')
[ -n "$handle" ] || exit 0                                   # no mention anywhere: a record
mention="(^|[^[:alnum:]_])@$handle([^[:alnum:]_-]|$)"
printf '%s\n' "$body" | grep -q -i -E "$mention" || exit 0   # mentions someone else: not the human's ask
v=0; say() { echo "$1"; v=1; }
first=$(printf '%s\n' "$body" | grep -v '^[[:space:]]*$' | head -1)
printf '%s\n' "$first" | grep -q -i -E "$mention" || say "handle @$handle is not on the first line"
words=$(printf '%s\n' "$body" | wc -w | tr -d ' ')
[ "$words" -le 80 ] || say "$words words; an ask stays under 80"
q=$(printf '%s\n' "$body" | grep -o '?' | wc -l | tr -d ' ')
[ "$q" -le 1 ] || say "$q question marks; two asks are two comments"
printf '%s\n' "$body" | grep -q -E '—|;' && say "a dash- or semicolon-chained sentence; one clause per sentence"
printf '%s\n' "$body" | grep -q -i -E 'worth (a|an|the|trying|checking|seeing)|might be (good|worth|nice)|a note (here )?on whether|if you get a chance|perhaps|maybe|would be (good|nice|great) to' && say "a hedged ask; say what you need"
printf '%s\n' "$body" | awk 'prev && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*- / && $0 !~ /^[[:space:]]/ {hit=1} {prev = ($0 ~ /^[[:space:]]*- /)} END {exit !hit}' && say "a list runs straight into the next line; leave a blank line after the list"
for id in $(printf '%s\n' "$body" | grep -o -E '(^|[^0-9a-f-])[0-9a-f]{8}([^0-9a-f-]|$)' | grep -o -E '[0-9a-f]{8}' | grep '[a-f]' | sort -u); do
  printf '%s\n' "$body" | grep -q -E "lanework://[0-9a-f-]{36}/$id" || say "card $id named without a lanework:// link"
done
exit $v
