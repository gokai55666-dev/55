#!/bin/bash
set -euo pipefail

LOGFILE="/root/ai_system/install_samantha_full.log"
mkdir -p /root/ai_system
cd /root/ai_system

echo "[INFO] Starting full Samantha installer..." | tee -a "$LOGFILE"

# -----------------------------
# Kill specific zombie processes
# -----------------------------
echo "[INFO] Checking for zombie processes..." | tee -a "$LOGFILE"
ZOMBIES=$(ps -e -o stat,pid | awk '$1=="Z" {print $2}')
if [ -n "$ZOMBIES" ]; then
    echo "[INFO] Killing zombies: $ZOMBIES" | tee -a "$LOGFILE"
    kill -9 $ZOMBIES || true
else
    echo "[INFO] No zombies found" | tee -a "$LOGFILE"
fi

# -----------------------------
# Install system dependencies
# -----------------------------
echo "[INFO] Installing system dependencies..." | tee -a "$LOGFILE"
apt update -qq
apt install -y git git-lfs python3-pip wget curl unzip ffmpeg || true
python3 -m pip install --upgrade pip

git lfs install
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# -----------------------------
# Download Samantha repo via GitHub
# -----------------------------
MODEL_NAME="Samantha-1.11-70B-GGUF"
if [ ! -d "$MODEL_NAME" ]; then
    echo "[INFO] Cloning Samantha repo..." | tee -a "$LOGFILE"
    git clone https://huggingface.co/TheBloke/$MODEL_NAME || true
fi

cd "$MODEL_NAME"

echo "[INFO] Fetching all LFS objects in parallel..." | tee -a "$LOGFILE"
git lfs fetch --all --include="*"
git lfs checkout

cd ..

# -----------------------------
# Build Ollama Modelfile
# -----------------------------
MODFILE="Samantha-Modelfile"
echo "[INFO] Creating Ollama Modelfile..." | tee -a "$LOGFILE"
cat > "$MODFILE" << EOF
FROM ./Samantha-1.11-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

# -----------------------------
# Create Ollama model if missing
# -----------------------------
if ! ollama list | grep -q "samantha-uncensored"; then
    echo "[INFO] Creating Ollama model in background..." | tee -a "$LOGFILE"
    nohup ollama create samantha-uncensored -f "$MODFILE" >> "$LOGFILE" 2>&1 &
else
    echo "[INFO] Ollama model already exists" | tee -a "$LOGFILE"
fi

echo "[INFO] Samantha installation started. Monitor with:" | tee -a "$LOGFILE"
echo "tail -f $LOGFILE"