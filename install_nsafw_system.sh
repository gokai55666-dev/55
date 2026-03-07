#!/bin/bash
set -euo pipefail

# ================================
# FULL NSFW AI SYSTEM INSTALLER
# ================================
# Features:
# - Ollama + Dolphin-Mixtral uncensored
# - Stable Diffusion NSFW models + LoRAs
# - AI Frontend improved (text, image, video)
# - 4x RTX 4090 GPU ready
# - Automatic port & process handling
# ================================

echo "[INFO] Updating system and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl python3-pip git-lfs wget unzip ffmpeg
pip install --upgrade pip

echo "[INFO] Installing PyTorch + Diffusers + Transformers..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install diffusers transformers accelerate safetensors

echo "[INFO] Initializing git-lfs..."
git lfs install

# -------------------------------
# Ollama NSFW Dolphin-Mixtral
# -------------------------------
OllamaDir=~/Dolphin-Mixtral
if [ ! -d "$OllamaDir" ]; then
    echo "[INFO] Cloning Dolphin-Mixtral NSFW model..."
    git clone https://huggingface.co/TheBloke/Dolphin-Mixtral-70B-GGUF $OllamaDir
fi

echo "[INFO] Creating Ollama Modelfile..."
cat > ~/Dolphin-Modelfile << 'EOF'
FROM ./Dolphin-Mixtral-70B-GGUF/Dolphin-Mixtral-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

echo "[INFO] Creating Ollama model..."
ollama list | grep dolphin-uncensored >/dev/null 2>&1 || ollama create dolphin-uncensored -f ~/Dolphin-Modelfile

# -------------------------------
# Stable Diffusion NSFW models
# -------------------------------
SD_DIR=~/StableDiffusionModels
mkdir -p $SD_DIR
cd $SD_DIR

declare -a SD_MODELS=(
    "https://huggingface.co/SG161222/RealisticVisionV13_v13"
    "https://huggingface.co/Bohemian/NippleVision-NSFW"
    "https://huggingface.co/anonNSFW/NSFW-Realistic-V1"
    "https://huggingface.co/otherNSFW/NSFW-PornSD"
)

echo "[INFO] Downloading Stable Diffusion NSFW models..."
for repo in "${SD_MODELS[@]}"; do
    name=$(basename $repo)
    if [ ! -d "$name" ]; then
        git clone $repo
    fi
done

# -------------------------------
# LoRA / Textual Inversion NSFW
# -------------------------------
declare -a LORA_MODELS=(
    "https://huggingface.co/SG161222/NSFW-LoRA-1"
    "https://huggingface.co/SG161222/NSFW-LoRA-2"
    "https://huggingface.co/SG161222/NSFW-LoRA-3"
)

echo "[INFO] Downloading NSFW LoRAs..."
for repo in "${LORA_MODELS[@]}"; do
    name=$(basename $repo)
    if [ ! -d "$name" ]; then
        git clone $repo
    fi
done

# -------------------------------
# AI Frontend Improved
# -------------------------------
FRONTEND=~/ai_frontend_improved.py
if [ ! -f "$FRONTEND" ]; then
    echo "[INFO] Downloading improved AI frontend..."
    curl -fLo $FRONTEND https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
    chmod +x $FRONTEND
fi

# -------------------------------
# Start Ollama server safely
# -------------------------------
echo "[INFO] Killing any running Ollama..."
pkill -f ollama || true
sleep 2

echo "[INFO] Launching Ollama server..."
nohup ollama serve > ~/ollama.log 2>&1 &
sleep 10

# -------------------------------
# Launch AI Frontend
# -------------------------------
# Auto-find free port for Gradio frontend
PORT=7860
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
    PORT=$((PORT+1))
done

echo "[INFO] Launching AI Frontend on port $PORT..."
python3 $FRONTEND --desktop --host 0.0.0.0 --port $PORT