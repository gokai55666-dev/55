#!/bin/bash
set -euo pipefail

INSTALL_DIR="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
OLLAMA_MODEL="samantha-uncensored"
LOG_FILE="$INSTALL_DIR/install_samantha_full.log"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Kill specific zombie processes
# -----------------------------
echo "[INFO] Cleaning up zombies..."
ZOMBIES=$(ps -eo stat,pid,cmd | awk '$1 ~ /Z/ {print $2}')
if [ -n "$ZOMBIES" ]; then
    echo "[INFO] Found zombies: $ZOMBIES"
    for pid in $ZOMBIES; do
        echo "[INFO] Killing zombie PID $pid"
        kill -9 "$pid" || true
    done
else
    echo "[INFO] No zombies found"
fi

# -----------------------------
# Clone or refresh Samantha repo
# -----------------------------
if [ ! -d "$MODEL_NAME" ]; then
    echo "[INFO] Cloning Samantha repository..."
    git clone https://huggingface.co/TheBloke/$MODEL_NAME
else
    echo "[INFO] Samantha directory exists, fetching latest..."
    cd "$MODEL_NAME"
    git fetch --all
    git reset --hard origin/main
    cd ..
fi

cd "$MODEL_NAME"

# -----------------------------
# Configure Git LFS for maximum speed
# -----------------------------
echo "[INFO] Configuring Git LFS for parallel downloads..."
git lfs install
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 7200

# -----------------------------
# Stratified fetch / resume
# -----------------------------
echo "[INFO] Starting stratified parallel fetch..."
# Retry loop for slower parts
retry_counter=0
max_retries=10

while [ $(ls *.gguf 2>/dev/null | wc -l) -lt 14 ] && [ $retry_counter -lt $max_retries ]; do
    git lfs fetch --all --include="*"
    git lfs checkout
    EXISTING=$(ls *.gguf 2>/dev/null | wc -l)
    echo "[INFO] Attempt $((retry_counter+1)) | GGUF parts downloaded: $EXISTING/14" >> "$LOG_FILE"
    retry_counter=$((retry_counter+1))
    sleep 5
done

# -----------------------------
# Cross-check all 14 parts exist
# -----------------------------
MISSING=$(comm -23 <(seq 1 14) <(ls *.gguf | sed 's/[^0-9]*//g' | sort -n))
if [ -n "$MISSING" ]; then
    echo "[WARN] Missing GGUF parts: $MISSING. Retrying..."
    git lfs fetch --all --include="*"
    git lfs checkout
fi

# -----------------------------
# Monitor progress in background
# -----------------------------
(
while true; do
    EXISTING_PARTS=$(ls *.gguf 2>/dev/null | wc -l)
    TOTAL_BYTES=$(du -cb *.gguf 2>/dev/null | tail -1 | awk '{print $1}')
    echo "$(date '+%H:%M:%S') | GGUF parts: $EXISTING_PARTS/14 | Total: $(numfmt --to=iec $TOTAL_BYTES)" >> "$LOG_FILE"
    sleep 10
done
) &
MONITOR_PID=$!

# Wait until all parts are present
while [ $(ls *.gguf 2>/dev/null | wc -l) -lt 14 ]; do
    sleep 5
done

kill $MONITOR_PID || true

# -----------------------------
# Build Ollama model automatically
# -----------------------------
cd "$INSTALL_DIR"
cat > "$INSTALL_DIR/Samantha-Modelfile" << EOF
FROM ./$MODEL_NAME.gguf
PARAMETER temperature 0.8
EOF

if ! ollama list | grep -q "$OLLAMA_MODEL"; then
    echo "[INFO] Creating Ollama Samantha model in background..."
    nohup ollama create $OLLAMA_MODEL -f "$INSTALL_DIR/Samantha-Modelfile" >> "$LOG_FILE" 2>&1 &
fi

echo "[INFO] Samantha download, cross-check, and Ollama setup complete!"
echo "[INFO] Check progress with: tail -f $LOG_FILE"