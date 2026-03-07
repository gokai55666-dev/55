# File: samantha_core.py
import torch

def weighted_lora_blend(loras):
    blend = {}
    total = len(loras)
    for idx, lora_file in enumerate(loras):
        blend[str(lora_file)] = round(1.0 - (idx / (total + 1)), 3)
    return blend

def blend_embeddings(embedding_files):
    blended_vector = None
    total = len(embedding_files)
    for idx, emb_file in enumerate(embedding_files):
        vec = torch.load(emb_file, map_location='cuda')
        weight = 1.0 - (idx / (total + 1))
        blended_vector = vec*weight if blended_vector is None else blended_vector + vec*weight
    return blended_vector / torch.norm(blended_vector)