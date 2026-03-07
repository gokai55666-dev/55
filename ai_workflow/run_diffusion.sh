#!/bin/bash
# run-diffusion - Absolute minimum  
ROOT="/root/samantha_ultimate"
source "$ROOT/scripts/lib/core.sh"
acquire_lock "diffusion"
export_gpu_env "diffusion"

CHECKPOINTS=($("$ROOT/scripts/samantha-assets" list checkpoint))
LORAS=($("$ROOT/scripts/samantha-assets" list lora))

[[ ${#CHECKPOINTS[@]} -eq 0 ]] && exit 1

source "$ROOT/envs/diffusion/bin/activate"

python "$ROOT/interfaces/modes/image_generation.py" \
    --model "${CHECKPOINTS[0]}" \
    --loras "${LORAS[@]}" \
    --port 8188 &

echo $! > "$ROOT/.locks/diffusion.pid"