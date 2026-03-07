#!/bin/bash
set -euo pipefail

# -----------------------------
# User-configurable variables
# -----------------------------
"
INSTALL_DIR="/root/ai_system"
SAMANTHA_REPO="https://huggingface.co/TheBloke/Samantha-1.11-70B-GGUF"

# Create main directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Install system dependencies
# -----------------------------
echo "[INFO] Installing system dependencies..."
apt update -qq
apt install -y git-lfs python3-pip wget curl unzip ffmpeg

# Upgrade pip
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
# Download Samantha model via token
# -----------------------------
MODEL_DIR="$INSTALL_DIR/Samantha-1.11-70B-GGUF"
if [ -d "$MODEL_DIR" ]; then
    echo "[INFO] Removing existing folder $MODEL_DIR"
    rm -rf "$MODEL_DIR"
fi

echo "[INFO] Cloning Samantha NSFW model..."
git clone "https://${HUGGINGFACE_TOKEN}@huggingface.co/TheBloke/Samantha-1.11-70B-GGUF" "$MODEL_DIR"

# -----------------------------
# Create Ollama Modelfile
# -----------------------------
cat > "$INSTALL_DIR/Samantha-Modelfile" << EOF
FROM ./Samantha-1.11-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

# -----------------------------
# Create Ollama model
# -----------------------------
if ! ollama list | grep -q "samantha-uncensored"; then
    echo "[INFO] Creating Ollama model samantha-uncensored..."
    ollama create samantha-uncensored -f "$INSTALL_DIR/Samantha-Modelfile"
fi

# -----------------------------
# Launch Ollama server if not running
# -----------------------------
if ! pgrep -x "ollama" > /dev/null; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve > "$INSTALL_DIR/ollama_samantha.log" 2>&1 &
    sleep 5
fi

echo "[INFO] Samantha NSFW installation complete!"
echo "Run with Ollama CLI or integrate with your AI frontend."