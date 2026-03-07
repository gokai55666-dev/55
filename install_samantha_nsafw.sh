#!/bin/bash
set -euo pipefail

# -----------------------------
# User-configurable variables
# -----------------------------
"
INSTALL_DIR="/root/ai_system"
SANTANA_MODEL="Samantha-1.11-70B-GGUF"
FRONTEND_REPO="https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py"

# -----------------------------
# Create main directory
# -----------------------------
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# Install system dependencies
# -----------------------------
echo "[INFO] Installing dependencies..."
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
# Function to download a HuggingFace model via token
# -----------------------------
download_model() {
    REPO_URL="$1"
    DEST="$2"

    if [ -d "$DEST" ]; then
        echo "[INFO] Removing existing folder $DEST"
        rm -rf "$DEST"
    fi

    echo "[INFO] Cloning $REPO_URL into $DEST..."
    git clone "https://${HUGGINGFACE_TOKEN}@${REPO_URL#https://}" "$DEST"
}

# -----------------------------
# Download Samantha-1.11 NSFW LLM
# -----------------------------
download_model "https://huggingface.co/TheBloke/Samantha-1.11-70B-GGUF" "$INSTALL_DIR/$SANTANA_MODEL"

# -----------------------------
# Create Ollama Modelfile
# -----------------------------
cat > "$INSTALL_DIR/Samantha-Modelfile" << 'EOF'
FROM ./Samantha-1.11-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

# -----------------------------
# Create Ollama model
# -----------------------------
if ! ollama list | grep -q "samantha-uncensored"; then
    ollama create samantha-uncensored -f "$INSTALL_DIR/Samantha-Modelfile"
fi

# -----------------------------
# Launch Ollama server if not running
# -----------------------------
if ! pgrep -x "ollama" > /dev/null; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve > "$INSTALL_DIR/ollama.log" 2>&1 &
    sleep 5
fi

# -----------------------------
# Download Stable Diffusion NSFW model
# -----------------------------
echo "[INFO] Setting up Stable Diffusion NSFW pipeline..."
SD_DIR="$INSTALL_DIR/stable_diffusion"
mkdir -p "$SD_DIR"
python3 - << PYTHON
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained("runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16)
pipe = pipe.to("cuda")
pipe.save_pretrained("$SD_DIR")
PYTHON

# -----------------------------
# Download AI Frontend (Improved)
# -----------------------------
echo "[INFO] Downloading AI Frontend..."
wget -O "$INSTALL_DIR/ai_frontend_improved.py" "$FRONTEND_REPO"
chmod +x "$INSTALL_DIR/ai_frontend_improved.py"

# -----------------------------
# Done
# -----------------------------
echo "[INFO] Installation complete!"
echo "Run the Improved AI Frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"