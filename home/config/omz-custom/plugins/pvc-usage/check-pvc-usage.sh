#!/usr/bin/env bash
set -euo pipefail

# Description: Show disk usage for Kubernetes PVs backed by node-local paths.
# Functioning: Lists PVs for a storage class, optionally filters by namespace, then checks usage over SSH.
# How to use: pvc-usage --sc <storageclass> [-n <namespace>] [--all]

show_all=false
storage_class=""
namespace=""

usage() {
  cat >&2 <<EOF
Usage: $0 --sc <storageclass> [-n <namespace>] [--all]

Flags:
  --all              Show usage for every matching PV. Without this, select one PV with fzf.
  --sc <name>        StorageClass name to use. Required.
  -n <namespace>     Filter PVs by claim namespace.
  -h, --help         Show this help.
EOF
}

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Error: $command_name is required in PATH." >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      show_all=true
      shift
      ;;
    --sc)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --sc requires a value." >&2
        usage
        exit 1
      fi
      storage_class=$2
      shift 2
      ;;
    -n)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: -n requires a namespace." >&2
        usage
        exit 1
      fi
      namespace=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'." >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$storage_class" ]]; then
  echo "Error: --sc is required." >&2
  usage
  exit 1
fi

require_command kubectl
require_command jq
require_command ssh

if [[ "$show_all" == false ]]; then
  require_command fzf
fi

list_pvs() {
  kubectl get pv -o json | jq -r --arg sc "$storage_class" --arg ns "$namespace" '
    .items[]
    | select(.spec.storageClassName == $sc)
    | select(($ns == "") or (.spec.claimRef.namespace == $ns))
    | . as $pv
    | [
        $pv.metadata.name,
        (($pv.spec.claimRef.namespace // "-") + "/" + ($pv.spec.claimRef.name // "-")),
        ([
          $pv.spec.nodeAffinity.required.nodeSelectorTerms[]?.matchExpressions[]?
          | select(.key == "kubernetes.io/hostname")
          | .values[0]
        ][0] // "-"),
        ($pv.spec.hostPath.path // $pv.spec.local.path // "-"),
        ($pv.spec.storageClassName // "-")
      ]
    | @tsv'
}

show_usage() {
  local pv=$1
  local claim=$2
  local node=$3
  local path=$4
  local pv_storage_class=$5
  local escaped_path

  echo "### claim=$claim pv=$pv node=$node path=$path storageclass=$pv_storage_class"

  if [[ "$node" == "-" ]]; then
    echo "Warning: skipping PV '$pv': node not found." >&2
    return 0
  fi

  if [[ "$path" == "-" ]]; then
    echo "Warning: skipping PV '$pv': local path not found." >&2
    return 0
  fi

  printf -v escaped_path '%q' "$path"

  if ! ssh "$node" "sudo du -shx $escaped_path 2>/dev/null; sudo df -h $escaped_path 2>/dev/null | tail -n +2"; then
    echo "Warning: failed to get usage for PV '$pv' on node '$node'." >&2
  fi
}

pv_list=$(list_pvs)

if [[ -z "$pv_list" ]]; then
  if [[ -n "$namespace" ]]; then
    echo "Error: no PV found for storageClass '$storage_class' in namespace '$namespace'." >&2
  else
    echo "Error: no PV found for storageClass '$storage_class'." >&2
  fi
  exit 1
fi

if [[ "$show_all" == true ]]; then
  while IFS=$'\t' read -r pv claim node path pv_storage_class; do
    show_usage "$pv" "$claim" "$node" "$path" "$pv_storage_class"
  done <<< "$pv_list"
else
  selected_pv=$(printf '%s\n' "$pv_list" | fzf --delimiter=$'\t' --with-nth=2,1,3,4,5 --header="CLAIM PV NODE PATH STORAGECLASS")

  if [[ -z "$selected_pv" ]]; then
    echo "No PV selected." >&2
    exit 1
  fi

  IFS=$'\t' read -r pv claim node path pv_storage_class <<< "$selected_pv"
  show_usage "$pv" "$claim" "$node" "$path" "$pv_storage_class"
fi
