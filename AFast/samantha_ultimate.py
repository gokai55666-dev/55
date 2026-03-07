import os
import subprocess
from pathlib import Path

# Base paths
BASE_PATH = Path("/root/samantha_ultimate")
MODELS_PATH = BASE_PATH / "models"
SCRIPTS_PATH = BASE_PATH / "scripts"

# GPU allocation
GPU_MAP = {
    "llm": 0,
    "diffusion": 1,
    "video": 2,
    "training": 3,
    "embeddings": 1
}

# Virtual environments
VENV_MAP = {
    "llm": BASE_PATH / "envs/llm/bin/activate",
    "diffusion": BASE_PATH / "envs/diffusion/bin/activate",
    "video": BASE_PATH / "envs/video/bin/activate",
    "training": BASE_PATH / "envs/training/bin/activate",
    "agent": BASE_PATH / "envs/agent/bin/activate",
    "embeddings": BASE_PATH / "envs/embeddings/bin/activate"
}

# NSFW LoRAs / Enhancers
NSFW_LORAS = [
    "sigma_face.safetensors",
    "custom_nsfw_lora.safetensors"
]

# Face embeddings
FACE_EMBEDDINGS = [
    "face0_embedding.pt",
    "clip_face_embedding.pt"
]

# Core utilities
def activate_env(env_name: str):
    """Return source command for venv"""
    venv_path = VENV_MAP[env_name]
    if not venv_path.exists():
        raise FileNotFoundError(f"Venv {env_name} not found at {venv_path}")
    return f"source {venv_path}"

def gpu_for(task: str):
    """Return GPU ID for task"""
    return GPU_MAP.get(task, 0)

def path_to_model(model_name: str, model_type: str):
    """Return full path to a model"""
    model_dir = MODELS_PATH / model_type
    model_path = model_dir / model_name
    if not model_path.exists():
        raise FileNotFoundError(f"Model {model_name} not found in {model_dir}")
    return str(model_path)

def path_to_lora(lora_name: str):
    """Return full path to LoRA"""
    lora_dir = MODELS_PATH / "diffusion" / "loras"
    lora_path = lora_dir / lora_name
    if not lora_path.exists():
        raise FileNotFoundError(f"LoRA {lora_name} not found in {lora_dir}")
    return str(lora_path)

def run_command(command: str, env: str = None, gpu: int = None, timeout: int = 600):
    """Run a shell command in a specific venv and GPU"""
    if env:
        command = f"{activate_env(env)} && {command}"
    if gpu is not None:
        command = f"CUDA_VISIBLE_DEVICES={gpu} {command}"
    return subprocess.run(command, shell=True, capture_output=True, text=True, executable='/bin/bash')