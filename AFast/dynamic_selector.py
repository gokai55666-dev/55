# ───────────────────────────────
# dynamic_selector.py
# ───────────────────────────────

import torch
from pathlib import Path
from open_clip import create_model_and_transforms, get_tokenizer

# Paths
LORAS_DIR = Path("/root/samantha_ultimate/models/diffusion/loras")
EMBEDDINGS_DIR = Path("/root/samantha_ultimate/data/embeddings")

# Initialize CLIP
model, _, preprocess = create_model_and_transforms('ViT-H-14', pretrained='laion2b_s32b_b79k')
tokenizer = get_tokenizer('ViT-H-14')
device = "cuda:0"  # temporarily for scoring
model = model.to(device)

def select_lora(prompt: str):
    """Select all NSFW LoRAs matching prompt"""
    prompt_lower = prompt.lower()
    candidates = [f for f in LORAS_DIR.glob("*.safetensors") if "nsfw" in f.name.lower()]
    # Optional: implement metadata scoring if you have LoRA metadata
    return candidates

def select_embedding(character_name: str):
    """Select best embedding by similarity with prompt"""
    character_lower = character_name.lower()
    best_score = -1
    best_embedding = None

    for emb_file in EMBEDDINGS_DIR.glob("*.pt"):
        if character_lower in emb_file.name.lower():
            embedding_vector = torch.load(emb_file, map_location=device)
            text_tokens = tokenizer(character_name)
            text_feat = model.encode_text(text_tokens.to(device))
            score = torch.cosine_similarity(text_feat, embedding_vector, dim=-1).item()
            if score > best_score:
                best_score = score
                best_embedding = emb_file

    return best_embedding