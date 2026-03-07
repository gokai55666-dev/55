#!/bin/bash
set -euo pipefail

# -----------------------------
# VARIABLES
# -----------------------------
INSTALL_DIR="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
OLLAMA_MODEL="samantha-uncensored"
MAX_RETRIES=10
SLEEP_BETWEEN=30  # seconds between retries
LOG_FILE="$INSTALL_DIR/install_samantha_full.log"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Function: Kill zombie processes
# -----------------------------
fix_zombies() {
    ZOMBIES=$(ps -eo stat,pid,ppid,cmd | awk '$1 ~ /Z/ {print $2}')
    if [ -n "$ZOMBIES" ]; then
        echo "[INFO] Found zombie processes: $ZOMBIES"
        for PID in $ZOMBIES; do
            PPID=$(ps -p $PID -o ppid= | tr -d ' ')
            echo "[INFO] Killing parent of zombie PID $PID (PPID $PPID)"
            kill -9 $PPID 2>/dev/null || true
        done
        echo "[INFO] Zombies fixed."
    else
        echo "[INFO] No zombie processes found."
    fi
}

# -----------------------------
# Function: Persistent LFS download
# -----------------------------
download_lfs() {
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "[INFO] LFS download attempt $attempt/$MAX_RETRIES..."
        git lfs fetch --all --include="*"
        git lfs checkout

        PARTS=$(ls *.gguf 2>/dev/null | wc -l)
        echo "[INFO] GGUF parts present: $PARTS/14"
        if [ "$PARTS" -eq 14 ]; then
            echo "[INFO] All 14 GGUF parts downloaded!"
            return 0
        fi

        echo "[WARN] Incomplete download. Retrying in $SLEEP_BETWEEN seconds..."
        sleep $SLEEP_BETWEEN
        attempt=$((attempt+1))
    done

    echo "[ERROR] Failed to download all parts after $MAX_RETRIES attempts."
    return 1
}

# -----------------------------
# MAIN INSTALLER
# -----------------------------
echo "[INFO] Running full Samantha installer..." | tee -a "$LOG_FILE"

# Step 1: Kill zombies
fix_zombies | tee -a "$LOG_FILE"

# Step 2: Remove old model if exists
if [ -d "$MODEL_NAME" ]; then
    echo "[INFO] Removing old model folder..." | tee -a "$LOG_FILE"
    rm -rf "$MODEL_NAME"
fi

# Step 3: Clone model repo
echo "[INFO] Cloning Samantha repository..." | tee -a "$LOG_FILE"
git clone https://huggingface.co/TheBloke/$MODEL_NAME
cd "$MODEL_NAME"

# Step 4: Configure Git LFS for parallel downloads
git lfs install
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

# Step 5: Persistent LFS download in background
echo "[INFO] Starting LFS download in background..." | tee -a "$LOG_FILE"
nohup bash -c 'download_lfs' > "$LOG_FILE" 2>&1 &

# Step 6: Wait until all GGUF files exist, then create Ollama model
(
    while [ "$(ls *.gguf 2>/dev/null | wc -l)" -lt 14 ]; do
        echo "[INFO] Waiting for all 14 GGUF parts..."
        sleep 15
    done

    echo "[INFO] All GGUF files detected. Building Ollama model..." | tee -a "$LOG_FILE"

    cd "$INSTALL_DIR"
    cat > Samantha-Modelfile << EOF
FROM ./$MODEL_NAME/*.gguf
PARAMETER temperature 0.8
EOF

    if ! ollama list | grep -q "$OLLAMA_MODEL"; then
        echo "[INFO] Creating Ollama model: $OLLAMA_MODEL" | tee -a "$LOG_FILE"
        ollama create "$OLLAMA_MODEL" -f Samantha-Modelfile
    else
        echo "[INFO] Ollama model $OLLAMA_MODEL already exists." | tee -a "$LOG_FILE"
    fi
) &

echo "[INFO] Installer running in background. Monitor progress with:"
echo "tail -f $LOG_FILE"