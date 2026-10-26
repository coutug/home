kmux() {
  if ! command -v kubie &> /dev/null || ! command -v tmux &> /dev/null || ! command -v tmuxp &> /dev/null || ! command -v k9s &> /dev/null || ! command -v fzf &> /dev/null; then
    echo "kmux: missing required commands (kubie, tmux, tmuxp, k9s, fzf)." >&2
    return 1
  fi

  # kubeconfigs directory
  local KUBECONFIG_DIR="$HOME/.kube/kubeconfig"
  local config context_line context current_context
  if [ ! -d "$KUBECONFIG_DIR" ]; then
    echo "kmux: kubeconfig directory '$KUBECONFIG_DIR' does not exist." >&2
    return 1
  fi

  local -a kubeconfigs=()
  while IFS= read -r -d '' config; do
    kubeconfigs+=("$config")
  done < <(find -L "$KUBECONFIG_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)
  if [ "${#kubeconfigs[@]}" -eq 0 ]; then
    echo "kmux: no kubeconfig files found in '$KUBECONFIG_DIR'." >&2
    return 1
  fi
  local -a contexts=()
  for config in "${kubeconfigs[@]}"; do
    context_line=$(grep -m1 '^[[:space:]]*current-context:' "$config" 2>/dev/null || true)

    if [ -n "$context_line" ]; then
      context=${context_line#*:}
      context=${context#"${context%%[![:space:]]*}"}
      context=${context%"${context##*[![:space:]]}"}
      if [ -n "$context" ]; then
        contexts+=("$context")
      fi
    fi
  done
  if [ "${#contexts[@]}" -eq 0 ]; then
    echo "kmux: no contexts found in '$KUBECONFIG_DIR'." >&2
    return 1
  fi

  # Choosing context
  if ! current_context=$(printf "%s\n" "${contexts[@]}" | fzf --prompt="Select a Kubernetes context: "); then
    return 1
  fi
  if [ -z "$current_context" ]; then
    return 1
  fi

  echo "Selected context: $current_context"
  local -x session_name="$current_context"

  tmuxp load kmux
}
