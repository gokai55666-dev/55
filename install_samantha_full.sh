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
    git clone https://huggingface.co/TheBloke/$MODEL_NAME
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

# -------------------- 4️⃣ Fetch all LFS objects safely --------------------
echo "[INFO] Fetching remaining LFS objects (no duplicates)..." | tee -a "$LOG_FILE"

# Fetch each file only if not already present
for FILE in $(git lfs ls-files -n); do
    if [ ! -f "$FILE" ]; then
        echo "[INFO] Fetching $FILE..." | tee -a "$LOG_FILE"
        git lfs fetch --include="$FILE"
    else
        echo "[INFO] $FILE already downloaded. Skipping..." | tee -a "$LOG_FILE"
    fi
done

echo "[INFO] Checking out all LFS objects..." | tee -a "$LOG_FILE"
git lfs checkout

# Wait until all 14 GGUF parts exist
echo "[INFO] Waiting for all 14 GGUF parts to finish downloading..." | tee -a "$LOG_FILE"
while [ "$(ls *.gguf 2>/dev/null | wc -l)" -lt 14 ]; do
    echo "[INFO] Downloaded $(ls *.gguf 2>/dev/null | wc -l)/14 files. Waiting..." | tee -a "$LOG_FILE"
    sleep 10
done

echo "[INFO] All 14 GGUF parts downloaded!" | tee -a "$LOG_FILE"

# -------------------- 5️⃣ Optional: Merge GGUF parts if needed --------------------
MERGED_FILE="Samantha-1.11-70B-GGUF.gguf"
if [ ! -f "$MERGED_FILE" ]; then
    echo "[INFO] Merging GGUF parts into $MERGED_FILE..." | tee -a "$LOG_FILE"
    cat Samantha-1.11-70b.*.gguf > "$MERGED_FILE"
    echo "[INFO] Merge complete." | tee -a "$LOG_FILE"
fi

# -------------------- 6️⃣ Build Ollama NSFW model --------------------
MODEL_FILE="$AI_SYSTEM/Samantha-Modelfile"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[INFO] Creating Ollama model file..." | tee -a "$LOG_FILE"
    cat > "$MODEL_FILE" << EOF
FROM ./$MERGED_FILE
PARAMETER temperature 0.8
EOF
fi

if ! ollama list | grep -q "samantha-uncensored"; then
    echo "[INFO] Creating Ollama NSFW model..." | tee -a "$LOG_FILE"
    ollama create samantha-uncensored -f "$MODEL_FILE"
else
    echo "[INFO] Ollama NSFW model already exists. Skipping creation." | tee -a "$LOG_FILE"
fi

echo "[INFO] Samantha installation complete!" | tee -a "$LOG_FILE"