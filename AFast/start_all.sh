#!/bin/bash
set -euo pipefail

# Root path
BASE="/root/samantha_ultimate"

echo "[INFO] Launching Samantha Ultimate AGI..."

# Start LLM
echo "[LLM] Starting chatbot..."
CUDA_VISIBLE_DEVICES=0 bash -c "source $BASE/envs/llm/bin/activate && python $BASE/interfaces/modes/text_generation.py &"

# Start Diffusion / Image
echo "[DIFFUSION] Starting image generation..."
CUDA_VISIBLE_DEVICES=1 bash -c "source $BASE/envs/diffusion/bin/activate && python $BASE/interfaces/modes/image_generation.py &"

# Start Video Generation
echo "[VIDEO] Starting video generation..."
CUDA_VISIBLE_DEVICES=2 bash -c "source $BASE/envs/video/bin/activate && python $BASE/interfaces/modes/video_generation.py &"

# Start Model Training
echo "[TRAINING] Starting LoRA / DreamBooth training..."
CUDA_VISIBLE_DEVICES=3 bash -c "source $BASE/envs/training/bin/activate && python $BASE/interfaces/modes/model_training.py &"

# Start Embeddings Service
echo "[EMBEDDINGS] Face embeddings pipeline..."
CUDA_VISIBLE_DEVICES=1 bash -c "source $BASE/envs/embeddings/bin/activate && python $BASE/interfaces/modes/embeddings.py &"

echo "[INFO] All services started. Check logs for details."