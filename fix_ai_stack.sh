#!/bin/bash
# =========================================
# Full AI Stack Installer & Validator
# Compatible: Torch 2.3.1 + torchvision 0.18.1 + CUDA 12.1
# =========================================

ENV_PATH="/workspace/ollama_env"

echo "=== Activating virtual environment ==="
source "$ENV_PATH/bin/activate"

echo "=== Cleaning old/conflicting packages ==="
pip uninstall -y torch torchvision xformers spandrel torchsde comfy_kitchen

echo "=== Installing compatible packages ==="
# Torch + CUDA 12.1, TorchVision + matching version
pip install torch==2.3.1+cu121 torchvision==0.18.1+cu121 \
    xformers==0.0.24 spandrel==0.4.2 comfy_kitchen==0.2.7 \
    --index-url https://download.pytorch.org/whl/cu121

# Check if installation succeeded
if ! python3 -c "import torch" &> /dev/null; then
    echo "[ERROR] Torch failed to install. Aborting."
    exit 1
fi

echo "=== Verifying installed versions and CUDA ==="
python3 - <<'EOF'
import torch, torchvision, numpy

errors = False

print("NumPy:", numpy.__version__)
print("Torch:", getattr(torch, '__version__', 'NOT INSTALLED'))
print("TorchVision:", getattr(torchvision, '__version__', 'NOT INSTALLED'))

# Check CUDA
if torch.cuda.is_available():
    print("CUDA detected:", torch.version.cuda)
    print("GPU count:", torch.cuda.device_count())
    print("Current device:", torch.cuda.current_device())
else:
    print("CUDA NOT available, running on CPU")
    errors = True

if errors:
    print("\n[FAILED] Stack is not fully ready. Fix the above issues.")
    exit(1)
else:
    print("\n[SUCCESS] Stack is ready for full workflow!")
EOF