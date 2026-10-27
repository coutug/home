#!/usr/bin/env bash
# Delete current-project sessions whose last update is older than DAYS days.
# Usage: ./clean-oc.sh [DAYS] (default: 7). Deleting a session also deletes its children.
set -euo pipefail

days=${1:-7}
if (($# > 1)) || [[ ! "$days" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [positive-number-of-days]" >&2
  exit 2
fi

command -v opencode >/dev/null || {
  echo "Error: opencode is required." >&2
  exit 1
}
command -v jq >/dev/null || {
  echo "Error: jq is required." >&2
  exit 1
}

# `session list` returns top-level sessions for the current project.
sessions=$(opencode session list --format json --max-count 10000)
cutoff_ms=$((($(date +%s) - days * 86400) * 1000))

# `updated` is the last-activity timestamp in milliseconds.
selection=$(jq -r --argjson cutoff "$cutoff_ms" '
  .[] | select(.updated < $cutoff) | .id
' <<<"$sessions")
to_archive=()
if [[ -n "$selection" ]]; then
  mapfile -t to_archive <<<"$selection"
fi

if ((${#to_archive[@]} == 0)); then
  echo "No sessions to archive."
  exit 0
fi

printf 'Sessions not updated in the last %s days to delete: %d\n' "$days" "${#to_archive[@]}"
for id in "${to_archive[@]}"; do
  printf '%s\n' "$id"
done
read -r -p 'Type "y" to confirm: ' confirmation
[[ "$confirmation" == y ]] || {
  echo "Cancelled."
  exit 0
}

for id in "${to_archive[@]}"; do
  opencode session delete "$id"
done
