#!/bin/bash
set -euo pipefail

# -----------------------------
# Variables
# -----------------------------
INSTALL_DIR="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MAX_RETRIES=5
SLEEP_BETWEEN=30  # seconds

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Clean old model files if needed
# -----------------------------
if [ -d "$MODEL_NAME" ]; then
    echo "[INFO] Removing existing Samantha folder to refresh download..."
    rm -rf "$MODEL_NAME"
fi

# -----------------------------
# Clone the repo
# -----------------------------
echo "[INFO] Cloning Samantha repository..."
git clone https://huggingface.co/TheBloke/$MODEL_NAME
cd "$MODEL_NAME"

# -----------------------------
# Configure Git LFS for parallel downloads
# -----------------------------
git lfs install
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# -----------------------------
# Persistent download function
# -----------------------------
download_lfs() {
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "[INFO] LFS download attempt $attempt/$MAX_RETRIES..."
        git lfs fetch --all --include="*"
        git lfs checkout

        MISSING=$(ls *.gguf 2>/dev/null | wc -l)
        if [ "$MISSING" -eq 14 ]; then
            echo "[INFO] All 14 parts downloaded successfully!"
            return 0
        else
            echo "[WARN] Only $MISSING parts downloaded. Retrying in $SLEEP_BETWEEN seconds..."
            sleep $SLEEP_BETWEEN
        fi
        attempt=$((attempt+1))
    done

    echo "[ERROR] Failed to download all 14 parts after $MAX_RETRIES attempts."
    return 1
}

# -----------------------------
# Run download in background with nohup
# -----------------------------
echo "[INFO] Starting persistent LFS download in background..."
nohup bash -c 'download_lfs' > "$INSTALL_DIR/lfs_download.log" 2>&1 &

echo "[INFO] LFS download running in background. Check log with:"
echo "tail -f $INSTALL_DIR/lfs_download.log"