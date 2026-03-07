#!/bin/bash
set -euo pipefail

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
LOG_FILE="$AI_SYSTEM/install_samantha_full.log"

mkdir -p "$AI_SYSTEM"
cd "$AI_SYSTEM"

echo "[INFO] Starting Samantha installation..." | tee -a "$LOG_FILE"

# -------------------- 1️⃣ Clone or update the repo --------------------
if [ ! -d "$MODEL_NAME" ]; then
    echo "[INFO] Cloning Samantha repo..." | tee -a "$LOG_FILE"
    git clone https://huggingface.co/TheBloke/"$MODEL_NAME"
else
    echo "[INFO] Samantha repo exists. Pulling latest changes..." | tee -a "$LOG_FILE"
    git -C "$MODEL_NAME" pull
fi

cd "$MODEL_NAME"

# -------------------- 2️⃣ Clean incomplete LFS objects --------------------
if [ -d ".git/lfs/incomplete" ]; then
    echo "[INFO] Removing incomplete LFS objects..." | tee -a "$LOG_FILE"
    rm -rf .git/lfs/incomplete/*
    git lfs prune | tee -a "$LOG_FILE"
fi

# -------------------- 3️⃣ Configure Git LFS for parallel downloads --------------------
echo "[INFO] Configuring Git LFS for parallel downloads..." | tee -a "$LOG_FILE"
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# -------------------- 4️⃣ Fetch missing LFS objects safely --------------------
echo "[INFO] Fetching missing LFS objects..." | tee -a "$LOG_FILE"
for FILE in $(git lfs ls-files -n); do
    if [ ! -f "$FILE" ]; then
        echo "[INFO] Fetching $FILE..." | tee -a "$LOG_FILE"
        git lfs pull --include="$FILE" --verbose | stdbuf -oL tr '\r' '\n'
    else
        echo "[INFO] $FILE already present, skipping." | tee -a "$LOG_FILE"
    fi
done

# -------------------- 5️⃣ Live progress display --------------------
echo "[INFO] Checking download status..." | tee -a "$LOG_FILE"
TOTAL=$(git lfs ls-files -n | wc -l)
COUNT=0
for FILE in $(git lfs ls-files -n); do
    COUNT=$((COUNT + 1))
    if [ -f "$FILE" ]; then STATUS="✅ READY"; else STATUS="⏳ MISSING"; fi
    PERCENT=$((COUNT * 100 / TOTAL))
    printf "[%3d%%] (%2d/%2d) %s - %s\n" "$PERCENT" "$COUNT" "$TOTAL" "$FILE" "$STATUS" | tee -a "$LOG_FILE"
done
echo "[INFO] Download check complete." | tee -a "$LOG_FILE"

# -------------------- 6️⃣ Build Ollama NSFW model --------------------
MODEL_FILE="$AI_SYSTEM/Samantha-Modelfile"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[INFO] Creating Ollama model file..." | tee -a "$LOG_FILE"
    cat > "$MODEL_FILE" << EOF
FROM ./$MODEL_NAME.gguf
PARAMETER temperature 0.8
EOF
fi

if ! ollama list | grep -q "samantha-uncensored"; then
    # Ensure all 14 files exist before creating Ollama model
    MISSING=$(git lfs ls-files -n | while read f; do [ ! -f "$f" ] && echo "$f"; done)
    if [ -z "$MISSING" ]; then
        echo "[INFO] Creating Ollama NSFW model..." | tee -a "$LOG_FILE"
        ollama create samantha-uncensored -f "$MODEL_FILE"
    else
        echo "[WARNING] Cannot create Ollama model, missing files:" | tee -a "$LOG_FILE"
        echo "$MISSING" | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "[INFO] Ollama NSFW model already exists. Skipping creation." | tee -a "$LOG_FILE"
fi

# -------------------- 7️⃣ Optional: Clean Python __pycache__ --------------------
echo "[INFO] Cleaning Python __pycache__..." | tee -a "$LOG_FILE"
find "$AI_SYSTEM" -type d -name "__pycache__" -exec rm -rf {} +
echo "[INFO] Cleanup complete." | tee -a "$LOG_FILE"

echo "[INFO] Samantha installation finished successfully!" | tee -a "$LOG_FILE"