#!/bin/bash
AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
LOG_FILE="$AI_SYSTEM/check_samantha_live.log"

cd "$AI_SYSTEM/$MODEL_NAME" || { echo "ERROR: Cannot cd to $MODEL_NAME"; exit 2; }

echo "[LIVE] Starting live Samantha LFS monitor. Press Ctrl+C to stop."
echo "[LIVE] Logging to $LOG_FILE"

while true; do
    clear
    echo "[LIVE] Checking Samantha compile/download status..."
    
    TOTAL=$(git lfs ls-files -n | wc -l)
    COUNT=0
    MISSING=0

    for FILE in $(git lfs ls-files -n); do
        COUNT=$((COUNT + 1))
        if [ -f "$FILE" ]; then
            STATUS="✅ READY"
        else
            STATUS="⏳ MISSING"
            MISSING=$((MISSING + 1))
        fi
        PERCENT=$((COUNT * 100 / TOTAL))
        LINE="[$PERCENT%] ($COUNT/$TOTAL) $FILE - $STATUS"
        echo "$LINE"
        echo "$LINE" >> "$LOG_FILE"
    done

    echo "[LIVE] Check complete. Missing files: $MISSING"
    
    # Exit with non-zero if any missing
    if [ "$MISSING" -gt 0 ]; then
        EXIT_CODE=1
    else
        EXIT_CODE=0
    fi

    sleep 5
done

exit $EXIT_CODE