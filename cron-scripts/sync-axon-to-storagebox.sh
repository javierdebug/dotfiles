#!/usr/bin/env bash
set -euo pipefail

SOURCE="$HOME/Documents/JV/Code/WonderCraft/Projects/Axon/green-field/axon-marketing-wondercraft-green-field"
DEST="storageWebdav:/personal/Code/WonderCraft/Projects/Axon/green-field/axon-marketing-wondercraft-green-field"

LOG="$HOME/.logs/backup-axon-storagebox.log"
LOCK="$HOME/.cache/backup-axon-storagebox.lock"
EXCLUDES="$HOME/cron-scripts/rclone-excludes-folders.txt"
TOPIC="jv"

mkdir -p "$HOME/.logs" "$(dirname "$LOCK")"

notify_ok()   { curl -fsS -d "✅ Axon backup OK → storageWebdav ($(date -Is))" "https://ntfy.sh/$TOPIC" >/dev/null; }
notify_fail() { curl -fsS -d "❌ Axon backup FAILED → storageWebdav ($(date -Is)) — see log" "https://ntfy.sh/$TOPIC" >/dev/null || true; }
notify_skip() { curl -fsS -d "⏭️ Axon backup skipped (already running) ($(date -Is))" "https://ntfy.sh/$TOPIC" >/dev/null || true; }

# sanity checks
if [ ! -d "$SOURCE" ]; then
  echo "ERROR: SOURCE does not exist: $SOURCE" >> "$LOG"
  notify_fail
  exit 2
fi

if [ ! -f "$EXCLUDES" ]; then
  echo "ERROR: EXCLUDES file missing: $EXCLUDES" >> "$LOG"
  notify_fail
  exit 3
fi

{
  echo "===== $(date -Is) backup start ====="
  echo "SOURCE=$SOURCE"
  echo "DEST=$DEST"
  echo "EXCLUDES=$EXCLUDES"

  # Try to acquire the lock and run rclone. If lock is busy, treat as "skipped".
  if ! flock -n "$LOCK" rclone sync \
    "$SOURCE" \
    "$DEST" \
    --exclude-from "$EXCLUDES" \
    --delete-during \
    --transfers 8 \
    --checkers 16 \
    --timeout 30s \
    --retries 5 \
    --retries-sleep 10s \
    --log-level INFO
  then
    # flock returns non-zero if lock can't be acquired OR if rclone fails.
    # Distinguish them by checking whether the lock is held by someone else.
    if flock -n "$LOCK" true 2>/dev/null; then
      echo "===== $(date -Is) backup failed ====="
      notify_fail
      exit 1
    else
      echo "===== $(date -Is) backup skipped (lock busy) ====="
      notify_skip
      exit 0
    fi
  fi

  echo "===== $(date -Is) backup end (ok) ====="
} >> "$LOG" 2>&1

notify_ok

