#!/bin/bash
set -euo pipefail

INSTALL_DIR="/root/ai_system"
SAM_MODEL_DIR="$INSTALL_DIR/Samantha-1.11-70B-GGUF"

echo "[INFO] Starting Samantha bootstrap..."

# -----------------------------
# Kill zombie Ollama processes
# -----------------------------
if pgrep -x "ollama" > /dev/null; then
    echo "[INFO] Found running Ollama processes, terminating..."
    pkill -9 ollama || true
    sleep 2
fi

# -----------------------------
# Clean previous Samantha files
# -----------------------------
if [ -d "$SAM_MODEL_DIR" ]; then
    echo "[INFO] Removing existing Samantha folder..."
    rm -rf "$SAM_MODEL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Install system dependencies
# -----------------------------
echo "[INFO] Installing dependencies..."
apt update -qq
apt install -y git-lfs python3-pip wget curl unzip ffmpeg

python3 -m pip install --upgrade pip

# -----------------------------
# Install Python packages
# -----------------------------
echo "[INFO] Installing Python packages..."
pip install torch diffusers transformers accelerate safetensors fastapi uvicorn python-multipart gradio

# -----------------------------
# Initialize Git LFS
# -----------------------------
git lfs install

# -----------------------------
# Clone Samantha model from GitHub (no token)
# -----------------------------
echo "[INFO] Cloning Samantha model..."
if [ -d "$SAM_MODEL_DIR" ]; then
    rm -rf "$SAM_MODEL_DIR"
fi
git clone https://huggingface.co/TheBloke/Samantha-1.11-70B-GGUF "$SAM_MODEL_DIR"

# -----------------------------
# Create Ollama model
# -----------------------------
echo "[INFO] Creating Ollama Samantha model..."
if ! ollama list | grep -q "samantha-uncensored"; then
    cat > "$INSTALL_DIR/Samantha-Modelfile" << EOF
FROM ./Samantha-1.11-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF
    ollama create samantha-uncensored -f "$INSTALL_DIR/Samantha-Modelfile"
fi

# -----------------------------
# Launch Ollama server
# -----------------------------
echo "[INFO] Starting Ollama server..."
nohup ollama serve > "$INSTALL_DIR/ollama.log" 2>&1 &
sleep 5

echo "[INFO] Samantha bootstrap complete!"
echo "Run the frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"