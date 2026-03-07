#!/usr/bin/env python3
"""
Samantha Training v4 - Unfiltered dataset training
"""

import os
import sys
import argparse
from pathlib import Path

os.environ.update({
    "HF_HUB_DISABLE_SYMLINKS_WARNING": "1",
    "CUDA_VISIBLE_DEVICES": "3"
})

def train_lora_unfiltered(data_dir, output_dir, embeddings=None):
    """Train LoRA with no dataset filtering"""
    from diffusers import DiffusionPipeline
    from peft import LoraConfig, get_peft_model
    import torch
    
    # Load base model
    model = DiffusionPipeline.from_pretrained(
        "stabilityai/stable-diffusion-xl-base-1.0",
        torch_dtype=torch.float16,
        safety_checker=None,
        requires_safety_checker=False,
    ).unet  # Train UNet only
    
    # LoRA config - high rank for maximum capacity
    lora_config = LoraConfig(
        r=256,  # Higher than standard 128
        lora_alpha=256,
        target_modules=["to_q", "to_k", "to_v", "to_out.0", "proj_in", "proj_out", "ff.net.0.proj", "ff.net.2"],
        lora_dropout=0.0,  # No regularization
        bias="none",
    )
    
    model = get_peft_model(model, lora_config)
    
    # Dataset loading - NO FILTERING
    from torch.utils.data import Dataset, DataLoader
    from PIL import Image
    import json
    
    class UnfilteredDataset(Dataset):
        def __init__(self, data_dir, embeddings=None):
            self.data_dir = Path(data_dir)
            self.images = list(self.data_dir.rglob("*.jpg")) + list(self.data_dir.rglob("*.png"))
            self.embeddings = embeddings or []
            
            # Load captions if exist
            self.captions = {}
            for img in self.images:
                cap_file = img.with_suffix('.txt')
                if cap_file.exists():
                    self.captions[img] = cap_file.read_text().strip()
                else:
                    self.captions[img] = ""
        
        def __len__(self):
            return len(self.images)
        
        def __getitem__(self, idx):
            img = Image.open(self.images[idx]).convert('RGB')
            # NO CONTENT CHECKING ON IMAGE
            return {
                'image': img,
                'caption': self.captions[self.images[idx]]
            }
    
    dataset = UnfilteredDataset(data_dir, embeddings)
    dataloader = DataLoader(dataset, batch_size=1, shuffle=True)
    
    # Training loop - standard, no special handling
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-4)
    
    model.train()
    for epoch in range(10):
        for batch in dataloader:
            # Forward, loss, backward
            # ... standard training ...
            pass
    
    # Save
    model.save_pretrained(output_dir)
    print(f"Saved to: {output_dir}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--embeddings', nargs='*', default=[])
    args = parser.parse_args()
    
    train_lora_unfiltered(args.data, args.output, args.embeddings)

if __name__ == '__main__':
    main()