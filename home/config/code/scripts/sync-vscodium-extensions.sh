# Syncs VSCodium extensions to match the desired list.
# Requires: $HOME, $desired_exts, $codium_bin set by caller.

mkdir -p "$HOME/.config/VSCodium/User"

current="$($codium_bin --list-extensions || true)"
current_sorted="$(printf '%s\n' "$current" | sed '/^$/d' | sort -u)"

printf '%s\n' "$desired_exts" | while IFS= read -r ext; do
  [ -n "$ext" ] || continue
  if ! printf '%s\n' "$current_sorted" | grep -Fxq "$ext"; then
    if ! $codium_bin --install-extension "$ext" --force; then
      echo "[syncVSCodiumExtensions] warn: failed to install $ext" >&2
    fi
  fi
done

if [ -n "$current_sorted" ]; then
  printf '%s\n' "$current_sorted" | while IFS= read -r ext; do
    [ -n "$ext" ] || continue
    if ! printf '%s\n' "$desired_exts" | grep -Fxq "$ext"; then
      if ! $codium_bin --uninstall-extension "$ext"; then
        echo "[syncVSCodiumExtensions] warn: failed to uninstall $ext" >&2
      fi
    fi
  done
fi
