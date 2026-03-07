#!/bin/bash
set -euo pipefail

# -----------------------------
# User variables
# -----------------------------
INSTALL_DIR="/root/ai_system"
SAMANTHA_INSTALLER_URL="https://raw.githubusercontent.com/gokai55666-dev/55/main/install_samantha_nsafw_fixed.sh"
FRONTEND_URL="https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py"

# -----------------------------
# Create main directory
# -----------------------------
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
# Download and run Samantha installer
# -----------------------------
echo "[INFO] Downloading Samantha NSFW installer..."
wget -O "$INSTALL_DIR/install_samantha_nsafw.sh" "$SAMANTHA_INSTALLER_URL"
chmod +x "$INSTALL_DIR/install_samantha_nsafw.sh"

echo "[INFO] Running Samantha NSFW installer..."
./install_samantha_nsafw.sh || echo "[WARN] Installer finished with errors, check the script"

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
echo "Run the frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"