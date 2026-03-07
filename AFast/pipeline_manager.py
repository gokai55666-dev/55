import subprocess, os, random
from pathlib import Path

BASE_DIR = Path("/root/samantha_ultimate")

# Load available LoRAs and embeddings
LORAS = list((BASE_DIR/"models/diffusion/loras").glob("*.safetensors"))
EMBEDDINGS = list((BASE_DIR/"data/embeddings").glob("*.pt"))

GPU_ASSIGN = {
    "llm": 0,
    "diffusion": 1,
    "video": 2,
    "training": 3
}

ENV_PATHS = {
    "llm": BASE_DIR/"envs/llm/bin/activate",
    "diffusion": BASE_DIR/"envs/diffusion/bin/activate",
    "video": BASE_DIR/"envs/video/bin/activate",
    "training": BASE_DIR/"envs/training/bin/activate",
}

def execute(cmd, env=None, gpu=None):
    full_cmd = ""
    if env:
        full_cmd += f"source {env} && "
    if gpu is not None:
        full_cmd += f"CUDA_VISIBLE_DEVICES={gpu} "
    full_cmd += cmd
    return subprocess.Popen(full_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable="/bin/bash")

def select_optimal_lora_embedding(prompt, lo_ra_list=LORAS, embeddings_list=EMBEDDINGS):
    """
    Placeholder scoring function:
    You can expand this with:
    - Character identity matching
    - Prompt similarity
    - LoRA NSFW rating
    Returns best LoRA + embedding pair
    """
    # For now: random selection
    lora = random.choice(lo_ra_list)
    emb = random.choice(embeddings_list)
    return lora, emb

def launch_diffusion(prompt, gpu=1):
    lora, emb = select_optimal_lora_embedding(prompt)
    cmd = f"python /root/samantha_ultimate/interfaces/modes/image_generation.py --prompt \"{prompt}\" --lora {lora} --embedding {emb}"
    return execute(cmd, ENV_PATHS["diffusion"], gpu)

def launch_video(prompt, gpu=2):
    lora, emb = select_optimal_lora_embedding(prompt)
    cmd = f"python /root/samantha_ultimate/interfaces/modes/video_generation.py --prompt \"{prompt}\" --lora {lora} --embedding {emb}"
    return execute(cmd, ENV_PATHS["video"], gpu)

def train_character(character_name, data_path, gpu=3):
    """
    Fine-tune LoRA for a specific character
    """
    cmd = f"python /root/samantha_ultimate/interfaces/modes/model_training.py --character {character_name} --data {data_path}"
    return execute(cmd, ENV_PATHS["training"], gpu)