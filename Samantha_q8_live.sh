#!/bin/bash
set -euo pipefail

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_PATH="$AI_SYSTEM/$MODEL_NAME"
LOG_FILE="$MODEL_PATH/samantha_q8_live.log"

# Ensure model folder exists
mkdir -p "$MODEL_PATH"
cd "$AI_SYSTEM" || { echo "ERROR: Cannot cd to $AI_SYSTEM"; exit 1; }

# Clone or update the repo
if [ ! -d "$MODEL_NAME" ]; then
    echo "[INFO] Cloning Samantha Q8 repo..." | tee -a "$LOG_FILE"
    git clone https://huggingface.co/TheBloke/$MODEL_NAME
else
    echo "[INFO] Pulling latest changes for Samantha Q8..." | tee -a "$LOG_FILE"
    git -C "$MODEL_NAME" pull
fi

cd "$MODEL_PATH" || { echo "ERROR: Cannot cd to $MODEL_PATH"; exit 1; }

# Configure Git LFS
git lfs install
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# Only include Q8_0 parts
Q8_FILES=$(git lfs ls-files -n | grep "Q8_0")

echo "[LIVE] Fetching only Q8_0 LFS files..." | tee -a "$LOG_FILE"

# Download missing Q8 files
for FILE in $Q8_FILES; do
    if [ ! -f "$FILE" ]; then
        echo "[INFO] Fetching $FILE..." | tee -a "$LOG_FILE"
        git lfs fetch --include="$FILE"
    else
        echo "[INFO] $FILE already exists, skipping..." | tee -a "$LOG_FILE"
    fi
done

# ----------------- Live monitor -----------------
echo "[LIVE] Monitoring Q8_0 download status..." | tee -a "$LOG_FILE"
while true; do
    clear
    COUNT=0
    TOTAL=$(echo "$Q8_FILES" | wc -l)
    MISSING=0

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

    echo "[LIVE] Check complete. Missing Q8_0 files: $MISSING"

    # Exit code 0 if all files ready
    if [ "$MISSING" -eq 0 ]; then
        break
    fi

    sleep 5
done

# ----------------- Build Ollama NSFW model -----------------
MODEL_FILE="$MODEL_PATH/Samantha-Q8-Modelfile"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[INFO] Creating Ollama model file for Q8..." | tee -a "$LOG_FILE"
    cat > "$MODEL_FILE" << EOF
FROM ./${Q8_FILES}
PARAMETER temperature 0.8
EOF
fi

if ! ollama list | grep -q "samantha-q8-uncensored"; then
    echo "[INFO] Creating Ollama NSFW Q8 model..." | tee -a "$LOG_FILE"
    ollama create samantha-q8-uncensored -f "$MODEL_FILE"
else
    echo "[INFO] Ollama NSFW Q8 model already exists. Skipping creation." | tee -a "$LOG_FILE"
fi

echo "[DONE] Samantha Q8 installation and Ollama build complete."