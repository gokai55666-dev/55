#!/bin/bash
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

BASE_DIR=/root/samantha_ultimate

echo -e "${GREEN}[INFO]${NC} Creating folder structure..."
mkdir -p $BASE_DIR/{envs,llms,diffusion,video,training,agent,embeddings,data/{datasets,embeddings},scripts,interfaces/modes,logs,models/{diffusion/loras,video,llm}}

# =============================================================================
# VIRTUAL ENVIRONMENTS
# =============================================================================
echo -e "${GREEN}[INFO]${NC} Creating Python virtual environments..."

python3 -m venv $BASE_DIR/envs/llm
python3 -m venv $BASE_DIR/envs/diffusion
python3 -m venv $BASE_DIR/envs/training
python3 -m venv $BASE_DIR/envs/agent
python3 -m venv $BASE_DIR/envs/embeddings

# =============================================================================
# DEPENDENCY INSTALLS
# =============================================================================
echo -e "${GREEN}[INFO]${NC} Installing dependencies..."

# LLM
source $BASE_DIR/envs/llm/bin/activate
pip install --upgrade pip
pip install torch transformers accelerate peft sentencepiece
deactivate

# Diffusion / Image
source $BASE_DIR/envs/diffusion/bin/activate
pip install --upgrade pip
pip install torch torchvision torchaudio diffusers[torch] safetensors
pip install xformers invisible-watermark
deactivate

# Training
source $BASE_DIR/envs/training/bin/activate
pip install --upgrade pip
pip install torch torchvision transformers diffusers accelerate safetensors
pip install datasets
deactivate

# Agent / Orchestration
source $BASE_DIR/envs/agent/bin/activate
pip install --upgrade pip
pip install streamlit requests numpy
deactivate

# Embeddings
source $BASE_DIR/envs/embeddings/bin/activate
pip install --upgrade pip
pip install clip-by-openai facenet-pytorch
deactivate

# =============================================================================
# DOWNLOAD MODELS, LoRAs & EMBEDDINGS
# =============================================================================
echo -e "${GREEN}[INFO]${NC} Downloading models..."

# Example: Diffusion
wget -c https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors -O $BASE_DIR/models/diffusion/sdxl_base.safetensors
wget -c https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors -O $BASE_DIR/models/diffusion/flux_dev.safetensors

# Video Models (Wan2.2)
wget -c https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors -O $BASE_DIR/models/video/wan2.2_t2v_high.safetensors
wget -c https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/wan2.2_i2v_high_noise_14B_fp16.safetensors -O $BASE_DIR/models/video/wan2.2_i2v_high.safetensors

# LLMs
mkdir -p $BASE_DIR/models/llm/llama3_70b
wget -c https://huggingface.co/meta-llama/Meta-Llama-3.1-70B-Instruct/resolve/main/model.safetensors -O $BASE_DIR/models/llm/llama3_70b/model.safetensors
mkdir -p $BASE_DIR/models/llm/qwen2.5_72b
wget -c https://huggingface.co/Qwen/Qwen2.5-72B-Instruct/resolve/main/model.safetensors -O $BASE_DIR/models/llm/qwen2.5_72b/model.safetensors

# LoRAs
wget -c <sigma_face_lora_url> -O $BASE_DIR/models/diffusion/loras/sigma_face.safetensors
wget -c <custom_nsfw_lora_url> -O $BASE_DIR/models/diffusion/loras/custom_nsfw.safetensors

# Face Embeddings
wget -c <face0_embedding_url> -O $BASE_DIR/data/embeddings/face0.pt

# =============================================================================
# COPY/PLACE INTERFACES
# =============================================================================
echo -e "${GREEN}[INFO]${NC} Moving interface scripts..."
cp /root/samantha_agi.py $BASE_DIR/interfaces/
cp /root/ai_frontend*.py $BASE_DIR/interfaces/
cp -r /root/modes/* $BASE_DIR/interfaces/modes/ || true

# =============================================================================
# SCRIPTS
# =============================================================================
echo -e "${GREEN}[INFO]${NC} Creating startup scripts..."

cat << 'EOF' > $BASE_DIR/scripts/start_all.sh
#!/bin/bash
source /root/samantha_ultimate/envs/llm/bin/activate && nohup python /root/samantha_ultimate/interfaces/samantha_agi.py &
source /root/samantha_ultimate/envs/diffusion/bin/activate && nohup python /root/samantha_ultimate/interfaces/modes/image_generation.py &
source /root/samantha_ultimate/envs/video/bin/activate && nohup python /root/samantha_ultimate/interfaces/modes/video_generation.py &
source /root/samantha_ultimate/envs/training/bin/activate && nohup python /root/samantha_ultimate/interfaces/modes/model_training.py &
EOF

chmod +x $BASE_DIR/scripts/start_all.sh

echo -e "${GREEN}[INFO]${NC} Samantha Ultimate AGI setup complete!"
echo -e "${GREEN}[INFO]${NC} Run with: bash $BASE_DIR/scripts/start_all.sh"