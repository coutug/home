kmux() {
  if ! command -v kubie &> /dev/null || ! command -v tmux &> /dev/null || ! command -v tmuxp &> /dev/null || ! command -v k9s &> /dev/null || ! command -v fzf &> /dev/null; then
    echo "Erreur : il manque certain packages. Veuillez les installer d'abord."
    return 1
  fi

  # kubeconfigs directory
  KUBECONFIG_DIR="/home/gabriel/.kube/kubeconfig"
  if [ ! -d "$KUBECONFIG_DIR" ]; then
    echo "Erreur : Le répertoire '$KUBECONFIG_DIR' n'existe pas."
    exit 1
  fi

  declare -a kubeconfigs
  while IFS= read -r -d '' config; do
    kubeconfigs+=("$config")
  done < <(find -L "$KUBECONFIG_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)
  if [ ${#kubeconfigs[@]} -eq 0 ]; then
    echo "Aucun fichier kubeconfig trouvé dans le répertoire '$KUBECONFIG_DIR'."
    exit 1
  fi
  declare -a contexts
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
  if [ ${#contexts[@]} -eq 0 ]; then
    echo "Aucun contexte trouvé dans les fichiers kubeconfig du répertoire '$KUBECONFIG_DIR'."
    exit 1
  fi

  # Choosing context
  current_context=$(printf "%s\n" "${contexts[@]}" | fzf --prompt="Sélectionnez un contexte Kubernetes : ")

  echo "Contexte sélectionné : $current_context"
  export session_name="$current_context"

  tmuxp load kmux
}
