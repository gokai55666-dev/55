#!/bin/bash

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"

cd "$AI_SYSTEM/$MODEL_NAME" || { echo "ERROR: Cannot cd to $MODEL_NAME"; exit 1; }

echo "[PROGRESS] Checking Samantha compile/download status..."

TOTAL=$(git lfs ls-files -n | wc -l)
COUNT=0

for FILE in $(git lfs ls-files -n); do
    COUNT=$((COUNT + 1))
    if [ -f "$FILE" ]; then
        STATUS="✅ READY"
    else
        STATUS="⏳ MISSING"
    fi
    PERCENT=$((COUNT * 100 / TOTAL))
    echo "[$PERCENT%] ($COUNT/$TOTAL) $FILE - $STATUS"
done

echo "[PROGRESS] Check complete."