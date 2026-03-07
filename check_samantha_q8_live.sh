#!/bin/bash
# ------------------------------------------------------
# Live monitor + parallel fetch for Samantha Q8_0 LFS
# ------------------------------------------------------

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_PATH="$AI_SYSTEM/$MODEL_NAME"

cd "$MODEL_PATH" || { echo "ERROR: Cannot cd to $MODEL_PATH"; exit 1; }

echo "[INFO] Checking LFS status for Q8_0 files..."

# List Q8_0 LFS files
FILES=$(git lfs ls-files -n | grep "Q8_0")

# Function to fetch a file if missing
fetch_file() {
    local FILE=$1
    if [ ! -f "$FILE" ] || [ ! -s "$FILE" ]; then
        echo "[FETCH] Starting $FILE..."
        git lfs fetch --include="$FILE" --max-retries=3
    fi
}

# Monitor loop
while :; do
    COUNT=0
    TOTAL=$(echo "$FILES" | wc -l)
    DONE=0

    for FILE in $FILES; do
        COUNT=$((COUNT+1))
        if [ -f "$FILE" ] && [ -s "$FILE" ]; then
            STATUS="✅ READY"
            DONE=$((DONE+1))
        else
            STATUS="⏳ MISSING"
        fi
        PERCENT=$((COUNT*100/TOTAL))
        echo "[$PERCENT%] ($COUNT/$TOTAL) $FILE - $STATUS"
    done

    if [ "$DONE" -eq "$TOTAL" ]; then
        echo "[INFO] All Q8_0 files downloaded ✅"
        break
    fi

    # Launch up to 2 parallel fetches for missing files
    MISSING_FILES=$(echo "$FILES" | while read f; do
        [ ! -f "$f" ] || [ ! -s "$f" ] && echo "$f"
    done)

    for FILE in $MISSING_FILES; do
        fetch_file "$FILE" &
        if [[ $(jobs -r -p | wc -l) -ge 2 ]]; then
            wait -n
        fi
    done

    sleep 5
    echo "--------------------------------------"
done