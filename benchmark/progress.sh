#!/usr/bin/env bash
# usage: progress.sh [-w|--watch] [method_dir] [dataset_dir]
#   default : print the progress once and exit
#   -w      : refresh every 30s; exit by itself once no benchmark/run.py worker is left
# Works with `bash progress.sh`, `./progress.sh`, and `source progress.sh`.
# The body runs in a subshell, so sourcing never changes your directory or closes your shell.
_artisan_progress() (
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1   # resolve paths from the project root
  watch=0
  if [[ $1 == -w || $1 == --watch ]]; then watch=1; shift; fi
  d=${1:-outputs/ArtVIP/Artisan_GPT-6.1-Sol}
  data=${2:-benchmark/data/ArtVIP}
  # A case is a sub-folder (ArtVIP, LightWheel, ABO-Mass) or a .txt prompt file (Stability).
  T=$(find "$data" -mindepth 1 -maxdepth 1 ! -name '.*' \( -type d -o -name '*.txt' \) 2>/dev/null | wc -l); W=40
  # A missing method_dir just means nothing has started yet (shows 0); a bad dataset_dir is an error.
  (( T > 0 )) || { echo "Bad dataset_dir: $data" >&2; exit 1; }
  while :; do
    D=0; R=0; F=0
    for j in "$d"/*/.run.json; do
      [[ -f $j ]] || continue
      c=$(dirname "$j")
      if [[ -f $c/native/object.urdf && -f $c/native/object.articulated.glb ]]; then ((D++))
      elif grep -q '"running"' "$j"; then ((R++))
      elif grep -q '"last_exit_code": [1-9]' "$j" && grep -q Traceback "$c/.run.log" 2>/dev/null; then ((F++)); fi
    done
    workers=$(pgrep -u "$(id -u)" -fc '^[^ ]*python[^ ]* benchmark/run.py')   # python workers only, not wrapper shells
    n=$((D*W/T))
    printf '\r[%s%s] %d/%d (%d%%) | running %d | failed %d | workers %d | %s ' \
      "$(printf '%*s' $n '' | tr ' ' '#')" "$(printf '%*s' $((W-n)) '' | tr ' ' '-')" \
      $D $T $((D*100/T)) $R $F $workers "$(date +%H:%M:%S)"
    if (( !watch )); then echo; exit 0; fi
    if (( workers == 0 )); then echo; echo "No worker left; stopping."; exit 0; fi
    sleep 30
  done
)
_artisan_progress "$@"
