#!/bin/zsh
# Pitwall board watcher: fswatch-triggered snapshot diff.
#
# Usage: watch-board.sh <board-path> <state-file>
#
# fswatch is ONLY the trigger; the emitted paths come from a find-snapshot diff.
# Never filter fswatch's own event paths: the app posts a comment by renaming
# comments/.draft/ -> comments/<uuid>/ and moves cards between lanes the same
# way, so file-level FSEvents carry only the renamed DIRECTORY paths, never the
# unchanged index.md inside — a path filter on the raw events silently drops
# exactly the owner comments and card moves the watch exists for. The snapshot
# diff sees every path that appeared, vanished, or changed, whatever the app
# did on disk.
#
# -o collapses each event burst to one counter line (count discarded, it only
# fires the diff); -l 0.5 batches a burst so a lane move lands as one diff.
set -u
LC_ALL=C
BOARD=${1:?usage: watch-board.sh <board-path> <state-file>}
STATE=${2:?usage: watch-board.sh <board-path> <state-file>}

snap() { find "$BOARD" -name '*.md' -not -path '*/.trash/*' -not -path '*/comments/.draft/*' -exec stat -f '%m %z %N' {} + 2>/dev/null | sort; }

snap > "$STATE"
fswatch -r -o -l 0.5 "$BOARD" | while IFS= read -r _; do
  snap > "$STATE.new"
  changed=$(comm -3 "$STATE" "$STATE.new" | cut -d' ' -f3- | sort -u | sed "s|$BOARD/||")
  mv "$STATE.new" "$STATE"
  if [ -n "$changed" ]; then
    n=$(printf '%s\n' "$changed" | wc -l | tr -d ' ')
    if [ "$n" -gt 20 ]; then
      echo "BULK: $n board files changed"
    else
      printf '%s\n' "$changed" | sed 's/^/CHANGED /'
    fi
  fi
done
