#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s <hostname> <target-ip> <identity-file>\n' "${0##*/}" >&2
}

confirm() {
  local prompt="$1"
  local answer

  read -r -p "$prompt [y/N] " answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      printf 'Aborted.\n' >&2
      exit 1
      ;;
  esac
}

add_recipient() {
  local sops_config="$1"
  local recipient="$2"
  local host="$3"
  local tmpfile

  if grep -Fq "$recipient" "$sops_config"; then
    printf 'Recipient already present in %s\n' "$sops_config"
    return
  fi

  tmpfile="$(mktemp)"
  awk -v recipient="  - \"$recipient\" # $host" '
    BEGIN {
      in_age_keys = 0
      added = 0
    }
    /^age_keys:[[:space:]]*&age_keys/ {
      in_age_keys = 1
      print
      next
    }
    in_age_keys && /^$/ && !added {
      print recipient
      added = 1
      in_age_keys = 0
      print
      next
    }
    {
      print
    }
    END {
      if (in_age_keys && !added) {
        print recipient
      }
    }
  ' "$sops_config" >"$tmpfile"

  mv "$tmpfile" "$sops_config"
  chmod 0644 "$sops_config"
  printf 'Added recipient to %s\n' "$sops_config"
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

host="$1"
target_ip="$2"
identity_file="$3"

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

host_secret="$repo_root/secrets/hosts/$host/ssh_host_ed25519_key.yaml"
hardware_config="./hosts/$host/hardware-configuration.nix"
k0s_sops_config="$repo_root/secrets/k0s/.sops.yaml"
users_sops_config="$repo_root/secrets/users/.sops.yaml"
users_secret="$repo_root/secrets/users/mini.yaml"
extra_files=""

cleanup() {
  if [[ -n "$extra_files" && -d "$extra_files" ]]; then
    rm -rf "$extra_files"
  fi
}
trap cleanup EXIT

printf 'Bootstrap context:\n'
printf '  Host: %s\n' "$host"
printf '  Target: root@%s\n' "$target_ip"
printf '  Flake: .#%s\n' "$host"
printf '  Identity file: %s\n' "$identity_file"
printf '  Hardware config: %s\n' "$hardware_config"
printf '  Host key secret: %s\n\n' "$host_secret"

confirm 'Continue with host key generation and SOPS updates?'

printf '\n==> Generating encrypted SSH host key secret\n'
if [[ -e "$host_secret" ]]; then
  printf 'Host key secret already exists: %s\n' "$host_secret"
  confirm 'Reuse the existing encrypted host key secret?'
else
  "$repo_root/scripts/generate-host-key-secret" "$host"
fi

recipient="$(sops --decrypt --extract '["age_recipient"]' "$host_secret")"
printf '\nAge recipient for %s:\n%s\n\n' "$host" "$recipient"

confirm 'Add this recipient to k0s and users SOPS rules?'
add_recipient "$k0s_sops_config" "$recipient" "$host"
add_recipient "$users_sops_config" "$recipient" "$host"

confirm 'Run sops updatekeys for user and host k0s secrets?'
printf '\n==> Updating user password hash secret recipients\n'
sops updatekeys "$users_secret"

case "$host" in
  nixos-mini1 | nixos-mini3)
    k0s_token_secret="$repo_root/secrets/k0s/token-${host#nixos-}.yaml"
    if [[ -f "$k0s_token_secret" ]]; then
      printf '\n==> Updating k0s token secret recipients: %s\n' "$k0s_token_secret"
      sops updatekeys "$k0s_token_secret"
    else
      printf '\nSkipping missing k0s token secret: %s\n' "$k0s_token_secret"
    fi
    ;;
  nixos-mini2)
    printf '\nSkipping k0s token update for %s because it is the controller.\n' "$host"
    ;;
  *)
    printf '\nNo k0s token update rule for %s.\n' "$host"
    ;;
esac

confirm 'Prepare --extra-files directory from the encrypted host key secret?'
printf '\n==> Preparing nixos-anywhere extra files\n'
extra_files="$("$repo_root/scripts/prepare-host-key-extra-files" "$host")"
printf 'Prepared extra files directory: %s\n' "$extra_files"

printf '\nThe next step will run nixos-anywhere against root@%s.\n' "$target_ip"
confirm 'Continue with installation?'

read -rsp 'Root password: ' root_passwd
printf '\n'

printf '\n==> Running nixos-anywhere\n'
SSHPASS="$root_passwd" nix run github:nix-community/nixos-anywhere -- \
  --flake ".#$host" \
  --target-host "root@$target_ip" \
  -i "$identity_file" \
  --generate-hardware-config nixos-generate-config "$hardware_config" \
  --env-password \
  --extra-files "$extra_files"

unset root_passwd
printf '\nBootstrap completed for %s.\n' "$host"
