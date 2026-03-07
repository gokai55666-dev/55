#!/bin/bash

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
REFRESH_INTERVAL=3  # seconds between updates

cd "$AI_SYSTEM/$MODEL_NAME" || { echo "ERROR: Cannot cd to $MODEL_NAME"; exit 1; }

while true; do
    clear
    echo "[LIVE PROGRESS] Samantha compile/download status (refresh every $REFRESH_INTERVAL sec)"
    
    TOTAL=$(git lfs ls-files -n | wc -l)
    COUNT=0
    COMPLETED=0
    
    for FILE in $(git lfs ls-files -n); do
        COUNT=$((COUNT + 1))
        if [ -f "$FILE" ]; then
            STATUS="✅ READY"
            COMPLETED=$((COMPLETED + 1))
        else
            STATUS="⏳ MISSING"
        fi
        PERCENT=$((COUNT * 100 / TOTAL))
        echo "[$PERCENT%] ($COUNT/$TOTAL) $FILE - $STATUS"
    done

    echo
    echo "[SUMMARY] $COMPLETED/$TOTAL files complete."
    
    if [ "$COMPLETED" -eq "$TOTAL" ]; then
        echo "[LIVE PROGRESS] All files are now downloaded/compiled ✅"
        break
    fi

    sleep $REFRESH_INTERVAL
done