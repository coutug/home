typeset -g PVC_USAGE_PLUGIN_DIR="${${(%):-%N}:A:h}"

pvc-usage() {
  local script="$PVC_USAGE_PLUGIN_DIR/check-pvc-usage.sh"

  if [[ ! -x "$script" ]]; then
    print -u2 "Error: $script is not executable."
    return 1
  fi

  "$script" "$@"
}
