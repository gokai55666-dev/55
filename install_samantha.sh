#!/bin/bash
set -euo pipefail

# Directory where Samantha will be installed
INSTALL_DIR="/root/ai_system"
SAMANTHA_DIR="$INSTALL_DIR/Samantha-1.11-70B-GGUF"

echo "[INFO] Creating installation directory..."
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
# Initialize Git LFS
# -----------------------------
git lfs install

# -----------------------------
# Download Samantha model
# -----------------------------
if [ ! -d "$SAMANTHA_DIR" ]; then
    echo "[INFO] Cloning Samantha NSFW model..."
    git clone https://huggingface.co/TheBloke/Samantha-1.11-70B-GGUF "$SAMANTHA_DIR"
else
    echo "[INFO] Samantha model already exists, skipping download."
fi

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
    echo "[INFO] Creating Ollama Samantha NSFW model..."
    ollama create samantha-uncensored -f "$INSTALL_DIR/Samantha-Modelfile"
else
    echo "[INFO] Ollama Samantha model already exists, skipping creation."
fi

# -----------------------------
# Done
# -----------------------------
echo "[INFO] Samantha NSFW installer finished successfully!"
echo "You can now start your Ollama server with: nohup ollama serve &"