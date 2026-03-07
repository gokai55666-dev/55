# ───────────────────────────────
# samantha_controller.py
# ───────────────────────────────

import os
import subprocess
import time
from pathlib import Path

# Base paths
BASE_DIR = Path("/root/samantha_ultimate")
ENVS = {
    "llm": BASE_DIR / "envs/llm",
    "diffusion": BASE_DIR / "envs/diffusion",
    "video": BASE_DIR / "envs/video",
    "training": BASE_DIR / "envs/training",
    "agent": BASE_DIR / "envs/agent",
    "embeddings": BASE_DIR / "envs/embeddings",
}

SCRIPTS = {
    "text": BASE_DIR / "interfaces/modes/text_generation.py",
    "image": BASE_DIR / "interfaces/modes/image_generation.py",
    "video": BASE_DIR / "interfaces/modes/video_generation.py",
    "training": BASE_DIR / "interfaces/modes/model_training.py",
}

LOG_DIR = BASE_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)

# GPU assignment
GPUS = {
    "text": "0",
    "image": "1",
    "video": "2",
    "training": "3",
}

# LoRA + NSFW embeddings
LORAS_DIR = BASE_DIR / "models/diffusion/loras"
EMBEDDINGS_DIR = BASE_DIR / "data/embeddings"

def launch_module(name, env_path, script_path, gpu):
    """Launch a module in its venv with assigned GPU"""
    log_file = LOG_DIR / f"{name}.log"
    cmd = f"""
    source {env_path}/bin/activate && \
    CUDA_VISIBLE_DEVICES={gpu} python {script_path} >> {log_file} 2>&1
    """
    print(f"[INFO] Launching {name} on GPU{gpu}, logging to {log_file}")
    return subprocess.Popen(cmd, shell=True, executable="/bin/bash")

def find_loras(prompt: str):
    """Auto-select LoRAs tagged NSFW / matching prompt"""
    selected = []
    for lora_file in LORAS_DIR.glob("*.safetensors"):
        # Example: select all NSFW LoRAs
        if "nsfw" in lora_file.name.lower():
            selected.append(lora_file)
    return selected

def find_embeddings(character_name: str):
    """Auto-select face embeddings matching character"""
    selected = []
    for emb_file in EMBEDDINGS_DIR.glob("*.pt"):
        if character_name.lower() in emb_file.name.lower():
            selected.append(emb_file)
    return selected

def main():
    print("[INFO] Starting Samantha Ultimate AGI...")

    # Example: preselect embeddings for testing
    character = "samantha"
    embeddings = find_embeddings(character)
    loras = find_loras(character)

    print(f"[INFO] Selected embeddings: {embeddings}")
    print(f"[INFO] Selected LoRAs: {loras}")

    # Launch all modules
    processes = []
    for name, script in SCRIPTS.items():
        env_path = ENVS[name if name in ENVS else "llm"]
        gpu = GPUS.get(name, "0")
        p = launch_module(name, env_path, script, gpu)
        processes.append(p)

    # Monitor processes
    try:
        while True:
            for p in processes:
                if p.poll() is not None:
                    print(f"[WARN] Process {p.pid} exited unexpectedly!")
            time.sleep(10)
    except KeyboardInterrupt:
        print("[INFO] Shutting down all modules...")
        for p in processes:
            p.terminate()
        print("[INFO] Samantha AGI terminated.")

if __name__ == "__main__":
    main()