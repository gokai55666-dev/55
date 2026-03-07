#!/usr/bin/env python3
"""
Samantha Diffusion v4 - Ensemble generation, multiple samplers
"""

import os
import sys
import argparse
import torch
from pathlib import Path

os.environ.update({
    "HF_HUB_DISABLE_SYMLINKS_WARNING": "1",
    "DIFFUSERS_NO_SAFETY_CHECKER": "1",
    "CUDA_VISIBLE_DEVICES": "0"
})

def load_pipeline_ensemble(checkpoint_path, loras=None):
    """Load with multiple fallback strategies"""
    from diffusers import (
        StableDiffusionXLPipeline, 
        DPMSolverMultistepScheduler,
        EulerDiscreteScheduler,
        HeunDiscreteScheduler
    )
    
    # Primary pipeline
    pipe = StableDiffusionXLPipeline.from_single_file(
        checkpoint_path,
        torch_dtype=torch.float16,
        use_safetensors=True,
        safety_checker=None,
        requires_safety_checker=False,
        local_files_only=True,  # No HF hub calls
    ).to("cuda")
    
    # Complete safety neutering
    pipe.safety_checker = lambda images, **kwargs: (images, [[0.0, 0.0, 0.0, 0.0]] * len(images))
    pipe.feature_extractor = None
    
    # Multiple schedulers for variety
    pipe.schedulers = {
        'dpm': DPMSolverMultistepScheduler.from_config(pipe.scheduler.config),
        'euler': EulerDiscreteScheduler.from_config(pipe.scheduler.config),
        'heun': HeunDiscreteScheduler.from_config(pipe.scheduler.config),
    }
    
    # Load all LoRAs at maximum strength
    if loras:
        for lora_path in loras:
            try:
                pipe.load_lora_weights(lora_path, adapter_name=Path(lora_path).stem)
                print(f"Loaded: {lora_path}")
            except Exception as e:
                print(f"LoRA load failed (continuing): {e}")
        
        # Activate all at full strength
        if len(loras) > 1:
            pipe.set_adapters([Path(l).stem for l in loras], adapter_weights=[1.0] * len(loras))
    
    # Enable memory-efficient attention
    pipe.enable_xformers_memory_efficient_attention()
    pipe.enable_model_cpu_offload()  # Allow larger models
    
    return pipe

def generate_ensemble(pipe, prompt, negative="", width=1024, height=1024, steps=50, cfg=7.5, scheduler='dpm'):
    """Generate with multiple fallback strategies"""
    
    # Set scheduler
    if scheduler in pipe.schedulers:
        pipe.scheduler = pipe.schedulers[scheduler]
    
    # First attempt: standard
    try:
        result = pipe(
            prompt=prompt,
            negative_prompt=negative,
            num_inference_steps=steps,
            guidance_scale=cfg,
            width=width,
            height=height,
            generator=torch.Generator("cuda").manual_seed(torch.randint(0, 2**32, (1,)).item()),
        ).images[0]
        return result
    except torch.cuda.OutOfMemoryError:
        # Fallback: CPU offload, smaller resolution
        print("OOM, falling back to 768x768")
        pipe.enable_sequential_cpu_offload()
        result = pipe(
            prompt=prompt,
            negative_prompt=negative,
            num_inference_steps=steps,
            guidance_scale=cfg,
            width=768,
            height=768,
        ).images[0]
        return result