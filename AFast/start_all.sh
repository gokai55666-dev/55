#!/bin/bash
set -euo pipefail

echo "[INFO] Activating virtual environments and launching modules..."

# GPU mapping
export GPU0=0
export GPU1=1
export GPU2=2
export GPU3=3

# Launch LLM (GPU0)
echo "[INFO] Starting LLM module on GPU0..."
source /root/samantha_ultimate/envs/llm/bin/activate
CUDA_VISIBLE_DEVICES=$GPU0 python /root/samantha_ultimate/interfaces/modes/text_generation.py &
LLM_PID=$!

# Launch Diffusion / Image generation (GPU1)
echo "[INFO] Starting Diffusion module on GPU1..."
source /root/samantha_ultimate/envs/diffusion/bin/activate
CUDA_VISIBLE_DEVICES=$GPU1 python /root/samantha_ultimate/interfaces/modes/image_generation.py &
DIFF_PID=$!

# Launch Video generation (GPU2)
echo "[INFO] Starting Video module on GPU2..."
source /root/samantha_ultimate/envs/diffusion/bin/activate
CUDA_VISIBLE_DEVICES=$GPU2 python /root/samantha_ultimate/interfaces/modes/video_generation.py &
VIDEO_PID=$!

# Launch Training module (GPU3)
echo "[INFO] Starting Training module on GPU3..."
source /root/samantha_ultimate/envs/training/bin/activate
CUDA_VISIBLE_DEVICES=$GPU3 python /root/samantha_ultimate/interfaces/modes/model_training.py &
TRAIN_PID=$!

# Launch Agent orchestration (CPU + optional GPU)
echo "[INFO] Launching Agent Controller..."
source /root/samantha_ultimate/envs/agent/bin/activate
python /root/samantha_ultimate/interfaces/modes/agent_controller.py &
AGENT_PID=$!

echo "[INFO] All modules started successfully!"
echo "LLM PID: $LLM_PID | Diffusion PID: $DIFF_PID | Video PID: $VIDEO_PID | Training PID: $TRAIN_PID | Agent PID: $AGENT_PID"