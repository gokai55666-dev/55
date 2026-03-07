#!/bin/bash
set -euo pipefail
echo "[INFO] Starting full Samantha Ultimate AGI setup..."

ROOT="/root/samantha_ultimate"

# -----------------------------
# 1️⃣ Create folder structure
# -----------------------------
echo "[INFO] Creating folder structure..."
mkdir -p $ROOT/{envs,llm,diffusion,training,agent,embeddings,models/{diffusion/video/llm},data/{datasets/embeddings},scripts,interfaces/modes,logs}

# -----------------------------
# 2️⃣ Create virtual environments
# -----------------------------
echo "[INFO] Creating virtual environments..."

python3 -m venv $ROOT/envs/llm
python3 -m venv $ROOT/envs/diffusion
python3 -m venv $ROOT/envs/training
python3 -m venv $ROOT/envs/agent
python3 -m venv $ROOT/envs/embeddings

# Upgrade pip inside each venv
for v in llm diffusion training agent embeddings; do
    source $ROOT/envs/$v/bin/activate
    pip install --upgrade pip setuptools wheel
    deactivate
done

# -----------------------------
# 3️⃣ Download models
# -----------------------------
echo "[INFO] Downloading all models..."
MODEL_DIR="$ROOT/models"
mkdir -p $MODEL_DIR/diffusion/loras $MODEL_DIR/video $MODEL_DIR/llm

# Example downloads (can be expanded)
declare -A MODELS
MODELS=(
["sdxl_base.safetensors"]="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
["flux_dev.safetensors"]="https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors"
["wan2.2_t2v_high.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
["wan2.2_i2v_high.safetensors"]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/wan2.2_i2v_high_noise_14B_fp16.safetensors"
)

for f in "${!MODELS[@]}"; do
    url=${MODELS[$f]}
    echo "[INFO] Downloading $f..."
    wget -c "$url" -O "$MODEL_DIR/${f}"
done

# -----------------------------
# 4️⃣ Download NSFW LoRAs & embeddings
# -----------------------------
echo "[INFO] Downloading NSFW LoRAs & embeddings..."
LORA_DIR="$MODEL_DIR/diffusion/loras"
EMB_DIR="$ROOT/data/embeddings"
mkdir -p $LORA_DIR $EMB_DIR

# Replace these with fully free, uncensored sources
declare -A LORAS
LORAS=(
["sigma_face.safetensors"]="https://huggingface.co/Wan-AI/Sigma-Face-LoRA/resolve/main/sigma_face.safetensors"
["custom_nsfw_lora.safetensors"]="https://huggingface.co/Wan-AI/Custom-NSFW-LORA/resolve/main/custom_nsfw_lora.safetensors"
)

for f in "${!LORAS[@]}"; do
    wget -c "${LORAS[$f]}" -O "$LORA_DIR/$f"
done

# Example embeddings
declare -A EMBS
EMBS=(
["face0.pt"]="https://huggingface.co/Wan-AI/Face0-Embeddings/resolve/main/face0.pt"
["clip_nsfw.pt"]="https://huggingface.co/Wan-AI/CLIP-NSFW/resolve/main/clip_nsfw.pt"
)

for f in "${!EMBS[@]}"; do
    wget -c "${EMBS[$f]}" -O "$EMB_DIR/$f"
done

# -----------------------------
# 5️⃣ Set up interfaces & scripts
# -----------------------------
echo "[INFO] Setting up scripts..."
cat > $ROOT/scripts/start_all.sh <<'EOF'
#!/bin/bash
/root/samantha_ultimate/start_all_template.sh
EOF

chmod +x $ROOT/scripts/start_all.sh

# -----------------------------
# 6️⃣ Install dependencies per environment
# -----------------------------
echo "[INFO] Installing Python dependencies..."
# LLM environment
source $ROOT/envs/llm/bin/activate
pip install torch transformers sentencepiece accelerate --upgrade
deactivate

# Diffusion / video
source $ROOT/envs/diffusion/bin/activate
pip install torch torchvision diffusers==0.23.1 accelerate==0.23.0 safetensors --upgrade
pip install xformers --upgrade
deactivate

# Training (LoRA / DreamBooth)
source $ROOT/envs/training/bin/activate
pip install torch torchvision safetensors diffusers==0.23.1 transformers --upgrade
deactivate

# Agent environment
source $ROOT/envs/agent/bin/activate
pip install requests streamlit flask asyncio websockets
deactivate

# Embeddings environment
source $ROOT/envs/embeddings/bin/activate
pip install torch clip-by-openai --upgrade
deactivate

# -----------------------------
# 7️⃣ GPU mapping reminder
# -----------------------------
echo "[INFO] Assign GPUs per module:"
echo "GPU0 → LLM"
echo "GPU1 → Diffusion / Image"
echo "GPU2 → Video (Wan2.2 T2V/I2V)"
echo "GPU3 → Training / LoRA / embeddings"

echo "[SUCCESS] Samantha Ultimate AGI setup complete!"