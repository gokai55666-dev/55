#!/bin/bash
# Final Build: Fully Automated RunPod A40 Setup
# ComfyUI + AnimateDiff Evolved + SDXL NSFW + Local Goonsai NSFW LLM (via Ollama)
# Optimized for performance and reliability

set -e
set -o pipefail

echo "=== Step 1: Verify GPU & CUDA ==="
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "Warning: NVIDIA GPU not detected. Please ensure you are using a GPU-enabled instance (e.g., A40)."
fi

echo "=== Step 2: Install system dependencies ==="
# Note: On RunPod, you might already be root or need sudo.
# Using 'sudo' but handling cases where it might not be present.
SUDO_CMD=""
if command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
fi

$SUDO_CMD apt update
$SUDO_CMD apt install -y git wget unzip python3-pip curl

echo "=== Step 3: Install Ollama for Goonsai NSFW LLM ==="
# Instead of raw Docker which might have permission issues on some pods, 
# we use Ollama which is easier to run and manages the models well.
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Start Ollama in the background
ollama serve > ollama.log 2>&1 &
sleep 5

echo "=== Step 4: Pull Goonsai NSFW LLM Model ==="
# Using the 3B model for a good balance of speed and quality
ollama pull goonsai/qwen2.5-3B-goonsai-nsfw-100k:latest

echo "=== Step 5: Clone ComfyUI ==="
WORKSPACE_DIR="/workspace"
if [ ! -d "$WORKSPACE_DIR" ]; then
    WORKSPACE_DIR=$HOME
fi

COMFY_DIR="$WORKSPACE_DIR/ComfyUI"
if [ ! -d "$COMFY_DIR" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
fi
cd "$COMFY_DIR"

echo "=== Step 6: Install Python dependencies ==="
python3 -m pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt

echo "=== Step 7: Install custom nodes ==="
# TaraLLM (Correct Repo)
if [ ! -d "custom_nodes/TaraLLM" ]; then
    git clone https://github.com/ronniebasak/ComfyUI-Tara-LLM-Integration.git custom_nodes/TaraLLM
fi
# AnimateDiff Evolved (Correct Repo)
if [ ! -d "custom_nodes/AnimateDiff" ]; then
    git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git custom_nodes/AnimateDiff
fi

# Install node-specific requirements
if [ -f "custom_nodes/AnimateDiff/requirements.txt" ]; then
    pip install -r custom_nodes/AnimateDiff/requirements.txt
fi

echo "=== Step 8: Prepare folders & models ==="
mkdir -p models/checkpoints models/motion_modules models/vae
mkdir -p custom_nodes/AnimateDiff/models
mkdir -p outputs/images outputs/videos workflows

# SDXL NSFW model (using a reliable mirror/direct link if possible, here using standard SDXL as base)
SDXL_URL="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
if [ ! -f "models/checkpoints/sd_xl_base_1.0_nsfw.safetensors" ]; then
    echo "Downloading SDXL model..."
    wget -O models/checkpoints/sd_xl_base_1.0_nsfw.safetensors "$SDXL_URL"
fi

# AnimateDiff motion module
ANIMATEDIFF_URL="https://huggingface.co/guoyww/AnimateDiff/resolve/main/mm_sd_v15_v2.ckpt"
if [ ! -f "models/motion_modules/mm_sd_v15_v2.ckpt" ]; then
    echo "Downloading AnimateDiff motion model..."
    wget -O models/motion_modules/mm_sd_v15_v2.ckpt "$ANIMATEDIFF_URL"
fi

# Symlink motion module into AnimateDiff node folder
ln -sf "$(pwd)/models/motion_modules/mm_sd_v15_v2.ckpt" "$(pwd)/custom_nodes/AnimateDiff/models/mm_sd_v15_v2.ckpt"

echo "=== Step 9: Validate Goonsai/Ollama endpoint ==="
if curl -s http://localhost:11434/api/tags | grep -q "goonsai"; then
    echo "Goonsai NSFW LLM is ready via Ollama."
else
    echo "Warning: Goonsai model not found in Ollama. Checking status..."
    ollama list
fi

echo "=== Step 10: Launch ComfyUI ==="
# Using --listen 0.0.0.0 to allow external access via RunPod proxy
# Added --highvram for A40 performance
python3 main.py --listen 0.0.0.0 --port 8188 --highvram &

echo "=== Setup Complete ==="
echo "ComfyUI: http://localhost:8188"
echo "LLM API (Ollama): http://localhost:11434"
echo "Goonsai Model: goonsai/qwen2.5-3B-goonsai-nsfw-100k"
echo "Outputs: $COMFY_DIR/outputs/"


