kmux() {
  if ! command -v kubie &> /dev/null || ! command -v tmux &> /dev/null || ! command -v tmuxp &> /dev/null || ! command -v k9s &> /dev/null; then
    echo "Erreur : il manque certain packages. Veuillez les installer d'abord."
    return 1
  fi

  # kubeconfigs directory
  KUBECONFIG_DIR="/home/gabriel/.kube/kubeconfig"
  if [ ! -d "$KUBECONFIG_DIR" ]; then
    echo "Erreur : Le répertoire '$KUBECONFIG_DIR' n'existe pas."
    exit 1
  fi

  kubeconfigs=$(find "$KUBECONFIG_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \))
  if [ -z "$kubeconfigs" ]; then
    echo "Aucun fichier kubeconfig trouvé dans le répertoire '$KUBECONFIG_DIR'."
    exit 1
  fi
  
  declare -a contexts
  echo "$kubeconfigs" | while read -r config; do
    context=$(kubectl config --kubeconfig="$config" get-contexts -o name | head -n1)

    if [ -n "$context" ]; then
        contexts+=("$context")
    else
        echo "Attention : Aucun contexte trouvé dans le fichier '$config'."
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

