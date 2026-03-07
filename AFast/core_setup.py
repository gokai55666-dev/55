# /root/samantha_ultimate/interfaces/core_setup.py
"""
Core Setup Module for Samantha Ultimate AGI
- Centralizes all paths, environment info, GPU mapping, model locations, LoRAs, embeddings
- Handles dependency versions for each pipeline
- Provides utility functions for environment activation, GPU allocation, and model access
"""

import os
import subprocess
from pathlib import Path

# -----------------------------
# 1️⃣ ROOT & ENVIRONMENT PATHS
# -----------------------------
ROOT = Path("/root/samantha_ultimate")
ENVS = {
    "llm": ROOT / "envs" / "llm",
    "diffusion": ROOT / "envs" / "diffusion",
    "training": ROOT / "envs" / "training",
    "agent": ROOT / "envs" / "agent",
    "embeddings": ROOT / "envs" / "embeddings",
}

MODELS = {
    "diffusion": ROOT / "models" / "diffusion",
    "video": ROOT / "models" / "video",
    "llm": ROOT / "models" / "llm",
    "loras": ROOT / "models" / "diffusion" / "loras",
}

DATA = {
    "datasets": ROOT / "data" / "datasets",
    "embeddings": ROOT / "data" / "embeddings",
}

SCRIPTS = ROOT / "scripts"
LOGS = ROOT / "logs"
INTERFACES = ROOT / "interfaces"

# -----------------------------
# 2️⃣ GPU MAPPING
# -----------------------------
GPU_MAP = {
    "llm": 0,
    "diffusion": 1,
    "video": 2,
    "training": 3,
}

# -----------------------------
# 3️⃣ DEPENDENCY VERSIONS
# -----------------------------
DEPS = {
    "llm": {
        "torch": "2.3.1",
        "transformers": "4.34.0",
        "sentencepiece": "0.1.99",
        "accelerate": "0.23.0",
    },
    "diffusion": {
        "torch": "2.3.1",
        "torchvision": "0.15.2",
        "diffusers": "0.23.1",
        "accelerate": "0.23.0",
        "safetensors": "0.3.1",
        "xformers": "0.0.21",
    },
    "training": {
        "torch": "2.3.1",
        "torchvision": "0.15.2",
        "diffusers": "0.23.1",
        "transformers": "4.34.0",
        "safetensors": "0.3.1",
    },
    "agent": {
        "requests": "2.31.0",
        "streamlit": "1.29.0",
        "flask": "2.3.5",
        "asyncio": "3.4.3",
        "websockets": "11.0.3",
    },
    "embeddings": {
        "torch": "2.3.1",
        "clip-by-openai": "1.1",
    }
}

# -----------------------------
# 4️⃣ MODELS, LoRAs & EMBEDDINGS
# -----------------------------
NSFW_LORAS = [
    "sigma_face.safetensors",
    "custom_nsfw_lora.safetensors",
]

FACE_EMBEDDINGS = [
    "face0.pt",
    "clip_nsfw.pt",
]

WAN2_MODELS = [
    "wan2.2_t2v_high.safetensors",
    "wan2.2_i2v_high.safetensors",
]

DIFF_MODELS = [
    "sdxl_base.safetensors",
    "flux_dev.safetensors",
]

LLM_MODELS = [
    "llama3_70b",
    "qwen2.5_72b",
]

# -----------------------------
# 5️⃣ UTILITIES
# -----------------------------
def activate_env(env_name):
    """Activate a virtual environment"""
    path = ENVS.get(env_name)
    if path:
        return f"source {path}/bin/activate"
    else:
        raise ValueError(f"Environment {env_name} does not exist!")

def gpu_for(task):
    """Get GPU ID for a task"""
    return GPU_MAP.get(task, None)

def run_command(command, env=None, gpu=None):
    """
    Run a shell command optionally in a specific virtual environment
    and with CUDA_VISIBLE_DEVICES set
    """
    env_prefix = ""
    if env:
        env_prefix = f"source {ENVS[env]}/bin/activate && "
    if gpu is not None:
        env_prefix = f"CUDA_VISIBLE_DEVICES={gpu} {env_prefix}"
    result = subprocess.run(env_prefix + command, shell=True, capture_output=True, text=True)
    return result

def path_to_model(model_name, category):
    """Get full path to a model"""
    if category in MODELS:
        return MODELS[category] / model_name
    else:
        raise ValueError(f"Unknown model category {category}")

def path_to_lora(lora_name):
    return MODELS["loras"] / lora_name

def path_to_embedding(embedding_name):
    return DATA["embeddings"] / embedding_name

# -----------------------------
# 6️⃣ DEBUG CHECKS
# -----------------------------
def check_structure():
    """Ensure all major directories exist"""
    for d in [*ENVS.values(), *MODELS.values(), *DATA.values(), SCRIPTS, LOGS, INTERFACES]:
        if not d.exists():
            print(f"[WARNING] Missing directory: {d}")
        else:
            print(f"[OK] {d}")

def list_all_models():
    """Print all models, LoRAs, embeddings"""
    print("Diffusion Models:", list(DIFF_MODELS))
    print("Video Models:", list(WAN2_MODELS))
    print("LLMs:", list(LLM_MODELS))
    print("NSFW LoRAs:", NSFW_LORAS)
    print("Face Embeddings:", FACE_EMBEDDINGS)