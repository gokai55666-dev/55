#!/bin/bash
set -euo pipefail

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_FILE="$AI_SYSTEM/Samantha-Modelfile"
LOG_FILE="$AI_SYSTEM/install_samantha_full.log"

mkdir -p "$AI_SYSTEM"
cd "$AI_SYSTEM"

echo "[INFO] Starting Samantha LFS download and Ollama build..." | tee -a "$LOG_FILE"

# -------------------- 1️⃣ Clone or update repo --------------------
if [ ! -d "$MODEL_NAME" ]; then
    echo "[INFO] Cloning Samantha repo..." | tee -a "$LOG_FILE"
    git clone https://huggingface.co/TheBloke/$MODEL_NAME
else
    echo "[INFO] Repo exists. Pulling latest changes..." | tee -a "$LOG_FILE"
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

# -------------------- 4️⃣ Fetch only missing LFS files --------------------
echo "[INFO] Checking for missing LFS files..." | tee -a "$LOG_FILE"

MISSING_FILES=()
for FILE in $(git lfs ls-files -n); do
    if [ ! -f "$FILE" ]; then
        echo "[MISSING] $FILE" | tee -a "$LOG_FILE"
        MISSING_FILES+=("$FILE")
    else
        echo "[OK] $FILE exists" | tee -a "$LOG_FILE"
    fi
done

# Fetch missing files only, with progress
if [ "${#MISSING_FILES[@]}" -eq 0 ]; then
    echo "[INFO] All files already exist. Skipping fetch." | tee -a "$LOG_FILE"
else
    echo "[INFO] Fetching ${#MISSING_FILES[@]} missing LFS files..." | tee -a "$LOG_FILE"
    for FILE in "${MISSING_FILES[@]}"; do
        echo "[FETCH] $FILE" | tee -a "$LOG_FILE"
        # Using curl-like progress for each file
        git lfs fetch --include="$FILE" --progress | while read -r line; do
            echo "$line" | tee -a "$LOG_FILE"
        done
        git lfs checkout "$FILE"
    done
fi

# -------------------- 5️⃣ Wait until all files exist --------------------
echo "[INFO] Verifying all files are present..." | tee -a "$LOG_FILE"
for FILE in $(git lfs ls-files -n); do
    until [ -f "$FILE" ]; do
        echo "[WAIT] $FILE not yet downloaded. Sleeping 15s..." | tee -a "$LOG_FILE"
        sleep 15
    done
    echo "[READY] $FILE exists" | tee -a "$LOG_FILE"
done

# -------------------- 6️⃣ Build Ollama NSFW model --------------------
if [ ! -f "$MODEL_FILE" ]; then
    echo "[INFO] Creating Ollama model file..." | tee -a "$LOG_FILE"
    cat > "$MODEL_FILE" << EOF
FROM ./$MODEL_NAME.gguf
PARAMETER temperature 0.8
EOF
fi

if ! ollama list | grep -q "samantha-uncensored"; then
    echo "[INFO] Building Ollama NSFW model..." | tee -a "$LOG_FILE"
    ollama create samantha-uncensored -f "$MODEL_FILE"
else
    echo "[INFO] Ollama NSFW model already exists. Skipping creation." | tee -a "$LOG_FILE"
fi

echo "[INFO] Samantha installation and Ollama build complete!" | tee -a "$LOG_FILE"