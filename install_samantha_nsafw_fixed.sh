#!/bin/bash
set -euo pipefail

# -----------------------------
# User variables
# -----------------------------
"
INSTALL_DIR="/root/ai_system"
FRONTEND_URL="https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py"
MODEL_NAME="Samantha-1.11-70B-GGUF"
MODEL_DIR="$INSTALL_DIR/$MODEL_NAME"

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
# Download Samantha model
# -----------------------------
if [ -d "$MODEL_DIR" ]; then
    echo "[INFO] Removing existing $MODEL_DIR"
    rm -rf "$MODEL_DIR"
fi

echo "[INFO] Downloading $MODEL_NAME..."
git clone "https://${HUGGINGFACE_TOKEN}@huggingface.co/TheBloke/$MODEL_NAME" "$MODEL_DIR"

# -----------------------------
# Create Ollama Modelfile
# -----------------------------
cat > "$INSTALL_DIR/Samantha-Modelfile" << EOF
FROM ./$MODEL_NAME.gguf
PARAMETER temperature 0.8
EOF

# -----------------------------
# Create Ollama model if not exists
# -----------------------------
if ! ollama list | grep -q "samantha-uncensored"; then
    ollama create samantha-uncensored -f "$INSTALL_DIR/Samantha-Modelfile"
fi

# -----------------------------
# Launch Ollama if not running
# -----------------------------
if ! pgrep -x "ollama" > /dev/null; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve > "$INSTALL_DIR/ollama.log" 2>&1 &
    sleep 5
fi

# -----------------------------
# Download improved AI frontend
# -----------------------------
echo "[INFO] Downloading Improved AI Frontend..."
wget -O "$INSTALL_DIR/ai_frontend_improved.py" "$FRONTEND_URL"
chmod +x "$INSTALL_DIR/ai_frontend_improved.py"

# -----------------------------
# Done
# -----------------------------
echo "[INFO] Installation complete!"
echo "Run frontend: cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"