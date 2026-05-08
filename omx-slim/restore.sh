#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BACKUP_DIR="${1:-}"

usage() {
  cat <<'USAGE'
Usage: ./restore.sh [backup-dir]

If backup-dir is omitted, the script uses ~/.codex/backups/omx-slim-latest.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ -z "$BACKUP_DIR" ]]; then
  latest="$CODEX_HOME/backups/omx-slim-latest"
  if [[ ! -f "$latest" ]]; then
    echo "error: no backup dir provided and no latest marker found: $latest" >&2
    exit 1
  fi
  BACKUP_DIR="$(cat "$latest")"
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "error: backup dir does not exist: $BACKUP_DIR" >&2
  exit 1
fi

echo "Restoring OMX backup"
echo "Codex home: $CODEX_HOME"
echo "Backup dir: $BACKUP_DIR"

for item in AGENTS.md config.toml hooks.json .omx-config.json skills agents prompts; do
  if [[ -e "$BACKUP_DIR/$item" ]]; then
    rm -rf "$CODEX_HOME/$item"
    cp -a "$BACKUP_DIR/$item" "$CODEX_HOME/$item"
    echo "restored: $item"
  fi
done

echo "Restore complete. Restart Codex to reload restored instructions."
echo "You can also run 'omx doctor' to verify the restored full surface."
