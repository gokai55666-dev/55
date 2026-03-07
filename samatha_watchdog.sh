#!/bin/bash

MODEL_DIR="/root/ai_system/Samantha-1.11-70B-GGUF"
LOG_FILE="/root/ai_system/install_samantha_full.log"

echo "[WATCHDOG] Samantha cleanup monitor started"

while true; do

echo "-----------------------------"
echo "[WATCHDOG] $(date)"

# Kill zombie processes
ZOMBIES=$(ps aux | awk '$8=="Z" {print $2}')
if [ ! -z "$ZOMBIES" ]; then
  echo "[CLEAN] Killing zombie processes"
  echo "$ZOMBIES" | xargs -r kill -9
fi

# Kill duplicate git-lfs downloads
DUPES=$(ps aux | grep "git-lfs" | grep -v grep | wc -l)
if [ "$DUPES" -gt 6 ]; then
  echo "[CLEAN] Too many git-lfs processes ($DUPES). Reducing."
  ps aux | grep git-lfs | grep -v grep | awk '{print $2}' | tail -n +7 | xargs -r kill -9
fi

# Remove incomplete downloads
if [ -d "$MODEL_DIR/.git/lfs/incomplete" ]; then
  SIZE=$(du -sh "$MODEL_DIR/.git/lfs/incomplete" 2>/dev/null | awk '{print $1}')
  if [ "$SIZE" != "0" ]; then
    echo "[CLEAN] Removing incomplete LFS downloads ($SIZE)"
    rm -rf "$MODEL_DIR/.git/lfs/incomplete/"*
  fi
fi

# Prune unused LFS objects
cd "$MODEL_DIR" 2>/dev/null
git lfs prune --verify-remote >/dev/null 2>&1

# Detect repeating errors
if [ -f "$LOG_FILE" ]; then
  ERRORS=$(tail -50 "$LOG_FILE" | grep -i "error" | wc -l)
  if [ "$ERRORS" -gt 10 ]; then
    echo "[WATCHDOG] Repeating errors detected in install log"
  fi
fi

# Disk usage report
df -h / | tail -1

sleep 120

done