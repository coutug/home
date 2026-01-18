# Backs up existing VS Code / VSCodium user config files before linking.
# Requires: $HOME, $backup_ext set by caller.

for rel in \
  ".config/Code/User/settings.json" \
  ".config/Code/User/keybindings.json" \
  ".config/VSCodium/User/settings.json" \
  ".config/VSCodium/User/keybindings.json"
do
  target="$HOME/$rel"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$(dirname "$target")"
    mv "$target" "$target$backup_ext"
  elif [ -L "$target" ] && [ ! -e "$target" ]; then
    rm -f "$target"
  fi
done
