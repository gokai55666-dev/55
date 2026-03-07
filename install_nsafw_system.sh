#!/bin/bash
set -e

# -------------------------------
# FULL NSFW AI SYSTEM INSTALLER
# -------------------------------
# Works on Ubuntu 22.04+ with 4x RTX 4090
# Installs: Ollama + Dolphin-Mixtral + SD NSFW models + LoRAs + AI frontend
# -------------------------------

echo "[INFO] Installing system dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl python3-pip git-lfs wget unzip ffmpeg
pip install --upgrade pip

echo "[INFO] Installing PyTorch and Diffusers..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install diffusers transformers accelerate safetensors

echo "[INFO] Initializing git-lfs..."
git lfs install

# -------------------------------
# NSFW Ollama Models
# -------------------------------
echo "[INFO] Downloading Dolphin-Mixtral uncensored..."
git clone https://huggingface.co/TheBloke/Dolphin-Mixtral-70B-GGUF ~/Dolphin-Mixtral-70B-GGUF

echo "[INFO] Creating Ollama Modelfile..."
cat > ~/Dolphin-Modelfile << 'EOF'
FROM ./Dolphin-Mixtral-70B-GGUF/Dolphin-Mixtral-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

echo "[INFO] Creating Ollama model..."
ollama create dolphin-uncensored -f ~/Dolphin-Modelfile

# -------------------------------
# Stable Diffusion NSFW Models
# -------------------------------
SD_DIR=~/StableDiffusionModels
mkdir -p $SD_DIR
cd $SD_DIR

echo "[INFO] Downloading main NSFW SD models..."
git lfs install

git clone https://huggingface.co/SG161222/RealisticVisionV13_v13
git clone https://huggingface.co/Bohemian/NippleVision-NSFW
git clone https://huggingface.co/anonNSFW/NSFW-Realistic-V1
git clone https://huggingface.co/otherNSFW/NSFW-PornSD

# -------------------------------
# LoRA / Textual Inversion models
# -------------------------------
echo "[INFO] Downloading NSFW LoRAs..."
git clone https://huggingface.co/SG161222/NSFW-LoRA-1
git clone https://huggingface.co/SG161222/NSFW-LoRA-2
git clone https://huggingface.co/SG161222/NSFW-LoRA-3

# -------------------------------
# AI Frontend Setup
# -------------------------------
echo "[INFO] Downloading improved AI frontend..."
curl -fLo ~/ai_frontend_improved.py https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
chmod +x ~/ai_frontend_improved.py

# -------------------------------
# Start Ollama server
# -------------------------------
echo "[INFO] Killing any running Ollama..."
pkill -f ollama || true
sleep 2

echo "[INFO] Starting Ollama server..."
nohup ollama serve > ~/ollama.log 2>&1 &
sleep 10

# -------------------------------
# Launch AI Frontend
# -------------------------------
echo "[INFO] Launching AI Frontend..."
python3 ~/ai_frontend_improved.py --desktop --host 0.0.0.0