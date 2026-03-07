#!/bin/bash
set -euo pipefail

BASE="/root/samantha_ultimate"

echo "[INFO] Creating folder structure..."
mkdir -p $BASE/{envs/llm,envs/diffusion,envs/training,envs/agent,envs/embeddings}
mkdir -p $BASE/{models/diffusion/loras,models/video,models/llm}
mkdir -p $BASE/{data/datasets,data/embeddings}
mkdir -p $BASE/{scripts,interfaces/modes,logs}

echo "[INFO] Moving LLM files..."
mv /root/Samantha-1.11-70B-GGUF $BASE/models/llm/ || true
mv /root/unified_ai_frontend.py $BASE/interfaces/ || true
mv /root/ai_frontend*.py $BASE/interfaces/ || true
mv /root/samantha_agi.py $BASE/interfaces/ || true
mv /root/samantha_working.py $BASE/interfaces/ || true

echo "[INFO] Moving video/image models..."
mv /root/ComfyUI/* $BASE/models/diffusion/ || true
mv /root/wan2.2_t2v*.safetensors $BASE/models/video/ || true

echo "[INFO] Moving LoRAs & embeddings..."
mv /root/sigma_face_lora.safetensors $BASE/models/diffusion/loras/ || true
mv /root/custom_nsfw_lora.safetensors $BASE/models/diffusion/loras/ || true
mv /root/clip_embeddings/* $BASE/data/embeddings/ || true

echo "[INFO] Moving scripts..."
mv /root/start_all.sh $BASE/scripts/ || true
mv /root/install_models.sh $BASE/scripts/ || true
mv /root/update_system.sh $BASE/scripts/ || true

echo "[INFO] Moving modular interface scripts..."
mv /root/modes/*.py $BASE/interfaces/modes/ || true

echo "[SUCCESS] File organization completed!"