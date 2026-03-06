#!/bin/bash
# =========================================
# AI Stack Ready + Installer Script
# Fully automated, stops on critical errors
# Compatible with Ollama NSFW workflow
# =========================================

set -euo pipefail

ENV_PATH="/workspace/ollama_env"
PYTHON_BIN="$ENV_PATH/bin/python3"
PIP_BIN="$ENV_PATH/bin/pip"

echo "=== Activating virtual environment ==="
if [ -f "$ENV_PATH/bin/activate" ]; then
    source "$ENV_PATH/bin/activate"
else
    echo "[ERROR] Virtual environment not found at $ENV_PATH"
    exit 1
fi

echo "=== Uninstalling conflicting packages ==="
$PIP_BIN uninstall -y torch torchvision xformers spandrel torchsde comfy_kitchen || true

echo "=== Installing compatible versions ==="

# Torch + TorchVision
TORCH_VER="2.4.1+cu121"
TORCHVISION_VER="0.18.1+cu121"

$PIP_BIN install --no-cache-dir --index-url https://download.pytorch.org/whl/cu121 \
    torch==$TORCH_VER torchvision==$TORCHVISION_VER

# Other AI modules
$PIP_BIN install --no-cache-dir xformers==0.0.26 spandrel==0.4.2 comfy_kitchen==0.2.7 torchsde==0.2.6

# Ensure NumPy compatible
$PIP_BIN install --no-cache-dir "numpy>=1.26,<2.0"

echo "=== Verifying installations and CUDA ==="
$PYTHON_BIN - << 'EOF'
import sys
import importlib
from packaging import version

required = {
    "numpy": ("1.26", "2.0"),
    "torch": ("2.4", None),
    "torchvision": ("0.18", None),
    "xformers": ("0.0.26", None),
    "spandrel": ("0.4.2", None),
    "comfy_kitchen": ("0.2.7", None),
    "torchsde": ("0.2.6", None)
}

errors = False

for pkg, (min_ver, max_ver) in required.items():
    try:
        mod = importlib.import_module(pkg)
        ver = version.parse(mod.__version__)
        print(f"{pkg}: {ver}")
        if min_ver and ver < version.parse(min_ver):
            print(f"[ERROR] {pkg} version {ver} below minimum {min_ver}")
            errors = True
        if max_ver and ver >= version.parse(max_ver):
            print(f"[ERROR] {pkg} version {ver} exceeds maximum {max_ver}")
            errors = True
    except ImportError:
        print(f"[ERROR] {pkg} not installed")
        errors = True

# CUDA check
try:
    import torch
    if torch.cuda.is_available():
        print("CUDA detected:", torch.version.cuda)
        print("GPU count:", torch.cuda.device_count())
        print("Current device:", torch.cuda.current_device())
    else:
        print("CUDA NOT available, running on CPU")
except Exception as e:
    print("[ERROR] CUDA test failed:", e)
    errors = True

if errors:
    print("\n[FAILED] Stack is not ready. Fix the above issues before proceeding.")
    sys.exit(1)
else:
    print("\n[SUCCESS] Stack is ready for full workflow!")
EOF