#!/bin/bash
set -euo pipefail

# ==============================================
# Samantha Full Installer (NSFW Ollama Model)
# Stratified LFS Download + Progress Bars
# ==============================================

AI_SYSTEM="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_FILE="$AI_SYSTEM/Samantha-Modelfile"
LOG_FILE="$AI_SYSTEM/install_samantha_full.log"

mkdir -p "$AI_SYSTEM"
cd "$AI_SYSTEM"

echo "[INFO] Starting Samantha installation..." | tee -a "$LOG_FILE"

# -------------------- 0️⃣ Clean zombie processes --------------------
ZOMBIES=$(ps -eo stat,pid,ppid,cmd | grep -w Z || true)
if [ -n "$ZOMBIES" ]; then
    echo "[INFO] Found zombie processes. Attempting cleanup..." | tee -a "$LOG_FILE"
    echo "$ZOMBIES" | awk '{print $2}' | xargs -r kill -HUP
else
    echo "[INFO] No zombie processes found." | tee -a "$LOG_FILE"
fi

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

# -------------------- 3️⃣ Configure Git LFS --------------------
echo "[INFO] Configuring Git LFS for parallel downloads..." | tee -a "$LOG_FILE"
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# -------------------- 4️⃣ Stratified LFS download with progress --------------------
echo "[INFO] Starting stratified LFS download..." | tee -a "$LOG_FILE"

# 1️⃣ List all files with size
FILES_AND_SIZES=$(git lfs ls-files -l | awk '{print $2 " " $1}' | sort -nrk2)

for LINE in $FILES_AND_SIZES; do
    FILE=$(echo $LINE | awk '{print $1}')
    # Skip if file already exists
    if [ -f "$FILE" ]; then
        echo "[INFO] $FILE already downloaded. Skipping..." | tee -a "$LOG_FILE"
        continue
    fi
    echo "[INFO] Downloading $FILE..." | tee -a "$LOG_FILE"

    # Show a pseudo progress with pv (needs pv installed)
    git lfs fetch --include="$FILE" 2>&1 | while read -r l; do
        if [[ "$l" =~ ([0-9]+)% ]]; then
            echo -ne "\rProgress: ${BASH_REMATCH[1]}% for $FILE"
        fi
    done
    echo ""  # newline after each file
done

echo "[INFO] Stratified LFS download complete." | tee -a "$LOG_FILE"

# Checkout all LFS objects
echo "[INFO] Checking out LFS objects..." | tee -a "$LOG_FILE"
git lfs checkout

# -------------------- 5️⃣ Wait for all 14 GGUF parts --------------------
echo "[INFO] Waiting for all 14 GGUF parts..." | tee -a "$LOG_FILE"
while [ "$(ls *.gguf 2>/dev/null | wc -l)" -lt 14 ]; do
    COUNT=$(ls *.gguf 2>/dev/null | wc -l)
    echo "[INFO] Downloaded $COUNT/14 files. Waiting..." | tee -a "$LOG_FILE"
    sleep 10
done
echo "[INFO] All 14 GGUF parts are present." | tee -a "$LOG_FILE"

# -------------------- 6️⃣ Build Ollama NSFW model --------------------
cd "$AI_SYSTEM"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[INFO] Creating Ollama model file..." | tee -a "$LOG_FILE"
    cat > "$MODEL_FILE" << EOF
FROM ./$MODEL_NAME.gguf
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