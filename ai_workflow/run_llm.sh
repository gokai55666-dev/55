#!/bin/bash
# run-llm - Absolute minimum
ROOT="/root/samantha_ultimate"
source "$ROOT/scripts/lib/core.sh"
acquire_lock "llm"
export_gpu_env "llm"

MODELS=($("$ROOT/scripts/samantha-assets" list llm))
[[ ${#MODELS[@]} -eq 0 ]] && exit 1

source "$ROOT/envs/llm/bin/activate"

python "$ROOT/interfaces/modes/text_generation.py" \
    --model "${MODELS[0]}" \
    --port 8000 &

echo $! > "$ROOT/.locks/llm.pid"