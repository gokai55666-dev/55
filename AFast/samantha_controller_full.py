# ───────────────────────────────
# samantha_controller_full.py
# ───────────────────────────────

import os
import subprocess
import time
from pathlib import Path
import torch
from open_clip import create_model_and_transforms, get_tokenizer

# ───────────────────────────────
# BASE PATHS
# ───────────────────────────────
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

LORAS_DIR = BASE_DIR / "models/diffusion/loras"
EMBEDDINGS_DIR = BASE_DIR / "data/embeddings"

# ───────────────────────────────
# GPU ASSIGNMENTS
# ───────────────────────────────
GPUS = {
    "text": "0",
    "image": "1",
    "video": "2",
    "training": "3",
    "embeddings": "1",
}

# ───────────────────────────────
# CLIP MODEL FOR EMBEDDINGS
# ───────────────────────────────
device = f"cuda:{GPUS['embeddings']}"
clip_model, _, preprocess = create_model_and_transforms('ViT-H-14', pretrained='laion2b_s32b_b79k')
clip_tokenizer = get_tokenizer('ViT-H-14')
clip_model = clip_model.to(device)

# ───────────────────────────────
# HELPER FUNCTIONS
# ───────────────────────────────
def launch_module(name, env_path, script_path, gpu):
    """Launch a module in its venv with assigned GPU and log"""
    log_file = LOG_DIR / f"{name}.log"
    cmd = f"""
    source {env_path}/bin/activate && \
    CUDA_VISIBLE_DEVICES={gpu} python {script_path} >> {log_file} 2>&1
    """
    print(f"[INFO] Launching {name} on GPU{gpu}, logging to {log_file}")
    return subprocess.Popen(cmd, shell=True, executable="/bin/bash")

def select_lora(prompt: str):
    """Select all NSFW LoRAs matching prompt"""
    return [f for f in LORAS_DIR.glob("*.safetensors") if "nsfw" in f.name.lower()]

def select_embedding(character_name: str):
    """Select the best embedding by cosine similarity"""
    best_score = -1
    best_embedding = None
    character_lower = character_name.lower()
    for emb_file in EMBEDDINGS_DIR.glob("*.pt"):
        if character_lower in emb_file.name.lower():
            emb_vector = torch.load(emb_file, map_location=device)
            text_tokens = clip_tokenizer(character_name)
            text_feat = clip_model.encode_text(text_tokens.to(device))
            score = torch.cosine_similarity(text_feat, emb_vector, dim=-1).item()
            if score > best_score:
                best_score = score
                best_embedding = emb_file
    return best_embedding

# ───────────────────────────────
# MAIN CONTROLLER
# ───────────────────────────────
def main():
    print("[INFO] Starting Samantha Ultimate AGI Full System...")

    # Example preselection
    character = "Samantha"
    embeddings = select_embedding(character)
    loras = select_lora(character)

    print(f"[INFO] Selected embedding: {embeddings}")
    print(f"[INFO] Selected NSFW LoRAs: {loras}")

    # Launch all modules on their assigned GPUs
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