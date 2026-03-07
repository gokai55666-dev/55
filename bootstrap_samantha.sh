#!/bin/bash
set -euo pipefail

# -----------------------------
# User-configurable variables
# -----------------------------
INSTALL_DIR="/root/ai_system"
GITHUB_BASE="https://raw.githubusercontent.com/gokai55666-dev/55/main"
SAMANTHA_SCRIPT="install_samantha_github.sh"
SAMANTHA_MODEL_DIR="$INSTALL_DIR/Samantha-1.11-70B-GGUF"

# -----------------------------
# 1. Clean zombie Ollama processes
# -----------------------------
echo "[INFO] Checking for zombie processes..."
ZOMBIES=$(ps aux | awk '{ if($8=="Z") print $2 }')
if [ -n "$ZOMBIES" ]; then
    echo "[INFO] Killing zombies: $ZOMBIES"
    kill -9 $ZOMBIES || true
else
    echo "[INFO] No zombie processes found."
fi

# -----------------------------
# 2. Prepare installation directory
# -----------------------------
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# 3. Remove old Samantha files
# -----------------------------
if [ -d "$SAMANTHA_MODEL_DIR" ]; then
    echo "[INFO] Removing old Samantha model directory..."
    rm -rf "$SAMANTHA_MODEL_DIR"
fi

# -----------------------------
# 4. Install system dependencies
# -----------------------------
echo "[INFO] Installing system dependencies..."
apt update -qq
apt install -y git-lfs python3-pip wget curl unzip ffmpeg

python3 -m pip install --upgrade pip
pip install torch diffusers transformers accelerate safetensors fastapi uvicorn python-multipart gradio

# Initialize Git LFS
git lfs install

# -----------------------------
# 5. Download the fixed Samantha installer from GitHub
# -----------------------------
echo "[INFO] Downloading Samantha installer..."
curl -fLo "$SAMANTHA_SCRIPT" "$GITHUB_BASE/$SAMANTHA_SCRIPT"
chmod +x "$SAMANTHA_SCRIPT"

# -----------------------------
# 6. Run the Samantha installer
# -----------------------------
echo "[INFO] Running Samantha installer..."
./"$SAMANTHA_SCRIPT"

# -----------------------------
# 7. Download AI Frontend (Improved)
# -----------------------------
echo "[INFO] Downloading AI Frontend..."
wget -O "$INSTALL_DIR/ai_frontend_improved.py" "$GITHUB_BASE/ai_frontend_improved.py"
chmod +x "$INSTALL_DIR/ai_frontend_improved.py"

# -----------------------------
# 8. Finished
# -----------------------------
echo "[INFO] Samantha NSFW installation complete!"
echo "Run the frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"