#!/bin/bash
# Live watchdog for Samantha Q8_0 LFS files
# Continuously monitors download/compile progress
# Logs to samantha_q8_watch.log

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_PATH="$AI_SYSTEM/$MODEL_NAME"
LOG_FILE="$MODEL_PATH/samantha_q8_watch.log"

cd "$MODEL_PATH" || { echo "ERROR: Cannot cd to $MODEL_PATH"; exit 2; }

echo "[WATCHDOG] Starting live Q8_0 monitor. Press Ctrl+C to stop." | tee -a "$LOG_FILE"

# Only track Q8_0 files
Q8_FILES=$(git lfs ls-files -n | grep "Q8_0")

while true; do
    clear
    COUNT=0
    MISSING=0
    TOTAL=$(echo "$Q8_FILES" | wc -l)

    for FILE in $Q8_FILES; do
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

    echo "[WATCHDOG] Check complete. Missing Q8_0 files: $MISSING" | tee -a "$LOG_FILE"

    # Stop if all files are ready
    if [ "$MISSING" -eq 0 ]; then
        echo "[WATCHDOG] All Q8_0 files ready. Exiting watchdog." | tee -a "$LOG_FILE"
        break
    fi

    sleep 5
done

exit 0