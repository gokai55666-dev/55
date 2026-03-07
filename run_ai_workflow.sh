#!/bin/bash
set -euo pipefail

# ----------------------------------------
# 0. Quick sanity check
# ----------------------------------------
echo "[INFO] Checking GPUs and CUDA..."
nvidia-smi
python3 -c "import torch; print('Torch version:', torch.__version__, 'CUDA available:', torch.cuda.is_available(), 'GPUs:', torch.cuda.device_count())"

# ----------------------------------------
# 1. Install / Fix Python libraries
# ----------------------------------------
echo "[INFO] Installing stable AI libraries..."
pip install --upgrade pip
pip install --force-reinstall numpy==1.26.4
pip install torch==2.7.1+cu126 torchvision==0.15.2+cu126 torchaudio --index-url https://download.pytorch.org/whl/cu126
pip install xformers==0.0.31
pip install opencv-python==4.8.1.78 pillow streamlit requests

# Optional extras
pip install diffusers transformers accelerate safetensors

# ----------------------------------------
# 2. Download Unified AI Frontend (Samantha)
# ----------------------------------------
echo "[INFO] Downloading AI frontend..."
mkdir -p /root/ai_frontend
curl -fsSL -o /root/ai_frontend/unified_ai_frontend.py \
    https://raw.githubusercontent.com/gokai55666-dev/55/main/unified_ai_frontend.py

# ----------------------------------------
# 3. Download example models
# ----------------------------------------
echo "[INFO] Downloading example models for text, image, video..."
mkdir -p /root/ai_models
# Example: SD 1.5
curl -L -o /root/ai_models/stable_diffusion_1.5.safetensors \
    https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
# Example: LoRA
curl -L -o /root/ai_models/example_lora.safetensors \
    https://huggingface.co/someuser/example-lora/resolve/main/example_lora.safetensors

# ----------------------------------------
# 4. Set environment variables for multi-GPU
# ----------------------------------------
export CUDA_VISIBLE_DEVICES=0,1,2,3
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# ----------------------------------------
# 5. Launch Streamlit frontend
# ----------------------------------------
echo "[INFO] Starting AI frontend..."
streamlit run /root/ai_frontend/unified_ai_frontend.py \
    --server.address 0.0.0.0 --server.port 8501 \
    --server.headless true

# ----------------------------------------
# 6. Notes:
# - Samantha agent can select task type:
#   1. Text generation (LLM)
#   2. Image generation (Stable Diffusion)
#   3. Video generation (Frame-based pipeline)
#   4. LoRA / Fine-tuning
#   5. Visual profile creation + Character selection
# - Extra models can be added under /root/ai_models
# - Streamlit UI automatically lists models and lets Samantha choose
# ----------------------------------------