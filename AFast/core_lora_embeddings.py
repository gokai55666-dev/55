from pathlib import Path
from core_setup import path_to_lora, path_to_model, FACE_EMBEDDINGS, run_command, gpu_for

# Folder containing LoRAs and embeddings
LORA_DIR = Path("/root/samantha_ultimate/models/diffusion/loras")
EMBEDDING_DIR = Path("/root/samantha_ultimate/data/embeddings")

# === NSFW LoRA Loader ===
def get_nsfw_loras():
    """Return all NSFW LoRA files available"""
    return [str(f) for f in LORA_DIR.glob("*.safetensors")]

# === Face Embedding Loader ===
def get_face_embeddings():
    """Return all available face embeddings"""
    return [str(EMBEDDING_DIR / f) for f in FACE_EMBEDDINGS if (EMBEDDING_DIR / f).exists()]

# === Dynamic pipeline runner ===
def run_pipeline(task: str, model_name: str, lora_names: list = None, embedding_names: list = None, extra_cmd=""):
    gpu_id = gpu_for(task)
    model_file = path_to_model(model_name, "diffusion" if task in ["diffusion", "video"] else "llm")
    
    # Resolve LoRAs
    loras = lora_names or get_nsfw_loras()
    lora_args = " ".join([f"--lora {LORA_DIR / l}" for l in loras])

    # Resolve Embeddings
    embeddings = embedding_names or get_face_embeddings()
    embedding_args = " ".join([f"--embedding {EMBEDDING_DIR / e}" for e in embeddings])

    # Build full command
    cmd = f"python run_pipeline.py --model {model_file} {lora_args} {embedding_args} {extra_cmd}"
    return run_command(cmd, env=task, gpu=gpu_id)