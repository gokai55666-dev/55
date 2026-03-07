#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OLAMA V10.1 - SD API EDITION
Replaces ai_frontend.py by adding:
- Automatic1111 API integration (remote SD)
- Vast.ai/RunPod SD endpoint support
- Keeps your gallery structure
- Adds Ollama vision for analysis
"""

import os
import sys
import json
import base64
import io
import requests
import gradio as gr
from PIL import Image
from datetime import datetime
from typing import List, Dict, Optional, Tuple

# Configuration
SD_API_HOST = os.getenv("SD_API_HOST", "http://localhost:7860")  # A1111 or Vast
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

class SDClient:
    """Connects to Automatic1111 or Vast.ai SD instance."""
    
    def __init__(self, host: str = SD_API_HOST):
        self.host = host
        self.txt2img_url = f"{host}/sdapi/v1/txt2img"
        self.img2img_url = f"{host}/sdapi/v1/img2img"
    
    def is_running(self) -> bool:
        try:
            r = requests.get(f"{self.host}/sdapi/v1/sd-models", timeout=5)
            return r.status_code == 200
        except:
            return False
    
    def get_models(self) -> List[str]:
        try:
            r = requests.get(f"{self.host}/sdapi/v1/sd-models", timeout=5)
            return [m["title"] for m in r.json()]
        except:
            return ["sd-v1-5.ckpt [placeholder]"]
    
    def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        width: int = 512,
        height: int = 512,
        steps: int = 20,
        cfg_scale: float = 7.5,
        sampler: str = "DPM++ 2M Karras",
        model: str = None,
        nsfw: bool = False
    ) -> Optional[Image.Image]:
        """
        Generate image via SD API.
        Returns PIL Image or None on failure.
        """
        payload = {
            "prompt": prompt,
            "negative_prompt": negative_prompt + ("" if nsfw else ", nsfw, nude, naked"),
            "width": width,
            "height": height,
            "steps": steps,
            "cfg_scale": cfg_scale,
            "sampler_index": sampler,
            "enable_hr": False,
            "denoising_strength": 0.7,
        }
        
        # Model switching if provided
        if model:
            # Set model via options endpoint first
            requests.post(
                f"{self.host}/sdapi/v1/options",
                json={"sd_model_checkpoint": model},
                timeout=10
            )
        
        try:
            r = requests.post(self.txt2img_url, json=payload, timeout=300)
            r.raise_for_status()
            
            result = r.json()
            if "images" in result and result["images"]:
                # Decode base64
                img_data = base64.b64decode(result["images"][0])
                return Image.open(io.BytesIO(img_data))
            return None
            
        except Exception as e:
            print(f"SD generation failed: {e}")
            return None

class OllamaVisionClient:
    """Ollama for prompt enhancement and image analysis."""
    
    def __init__(self, host: str = OLLAMA_HOST):
        self.host = host
    
    def enhance_prompt(self, description: str, style: str = "photorealistic") -> str:
        """Use Ollama to create optimized SD prompt."""
        try:
            r = requests.post(
                f"{self.host}/api/generate",
                json={
                    "model": "llama2",
                    "prompt": f"Create a detailed Stable Diffusion prompt for: {description}. Style: {style}. Use comma-separated tags, quality keywords like 'masterpiece, best quality, highly detailed'.",
                    "stream": False
                },
                timeout=60
            )
            return r.json().get("response", description)
        except:
            return description
    
    def describe_image(self, image: Image.Image) -> str:
        """Analyze image with Ollama vision (if available)."""
        # Convert to base64
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_b64 = base64.b64encode(buffered.getvalue()).decode()
        
        try:
            r = requests.post(
                f"{self.host}/api/generate",
                json={
                    "model": "llava",
                    "prompt": "Describe this image in detail.",
                    "images": [img_b64],
                    "stream": False
                },
                timeout=60
            )
            return r.json().get("response", "Could not analyze")
        except:
            return "Vision model not available"

# Initialize
sd_client = SDClient()
ollama_client = OllamaVisionClient()

# Gallery storage
OUTPUT_DIR = os.path.join(os.environ.get("HOME", "/sdcard"), "olama_gallery")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_image(prompt, negative, steps, width, height, cfg, model, nsfw, enhance):
    """Main generation function combining Ollama + SD."""
    
    # Step 1: Enhance prompt with Ollama if requested
    if enhance:
        gr.Info("Enhancing prompt with Ollama...")
        prompt = ollama_client.enhance_prompt(prompt)
    
    # Step 2: Generate with SD
    gr.Info("Generating image via SD API...")
    image = sd_client.generate(
        prompt=prompt,
        negative_prompt=negative,
        width=width,
        height=height,
        steps=steps,
        cfg_scale=cfg,
        model=model if model != "Default" else None,
        nsfw=nsfw
    )
    
    if image is None:
        return None, "Generation failed. Check SD API connection."
    
    # Step 3: Save with metadata
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"gen_{timestamp}.png"
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    # Save image
    image.save(filepath)
    
    # Save metadata
    meta = {
        "prompt": prompt,
        "negative": negative,
        "steps": steps,
        "width": width,
        "height": height,
        "cfg": cfg,
        "model": model,
        "timestamp": timestamp,
        "filepath": filepath
    }
    with open(filepath.replace(".png", ".json"), "w") as f:
        json.dump(meta, f)
    
    # Step 4: Analyze with Ollama if available
    description = ""
    try:
        description = ollama_client.describe_image(image)
    except:
        pass
    
    return image, f"Saved: {filename}\nOllama: {description[:100]}..."

def load_gallery():
    """Load existing images from gallery."""
    images = []
    for f in sorted(os.listdir(OUTPUT_DIR)):
        if f.endswith(".png"):
            path = os.path.join(OUTPUT_DIR, f)
            meta_path = path.replace(".png", ".json")
            
            info = f
            if os.path.exists(meta_path):
                with open(meta_path) as mf:
                    meta = json.load(mf)
                    info = f"{f[:20]}... | {meta.get('prompt', '')[:30]}..."
            
            images.append((path, info))
    
    return images[:50]  # Limit to recent 50

# Gradio UI - Matches your frontend structure
with gr.Blocks(title="AI Frontend V10.1 - SD + Ollama") as demo:
    gr.Markdown("# AI Frontend V10.1")
    gr.Markdown(f"SD API: {'✓' if sd_client.is_running() else '✗'} | Ollama: {'✓' if ollama_client else '✗'}")
    
    with gr.Tab("Generate"):
        with gr.Row():
            with gr.Column():
                prompt = gr.Textbox(label="Prompt", lines=3)
                negative = gr.Textbox(label="Negative Prompt", value="blurry, low quality, distorted")
                
                with gr.Row():
                    steps = gr.Slider(10, 50, value=20, step=1, label="Steps")
                    cfg = gr.Slider(1, 15, value=7.5, step=0.5, label="CFG Scale")
                
                with gr.Row():
                    width = gr.Dropdown([512, 768, 1024], value=512, label="Width")
                    height = gr.Dropdown([512, 768, 1024], value=512, label="Height")
                
                model = gr.Dropdown(["Default"] + sd_client.get_models(), value="Default", label="Model")
                nsfw = gr.Checkbox(label="NSFW", value=False)
                enhance = gr.Checkbox(label="Enhance with Ollama", value=True)
                
                generate_btn = gr.Button("Generate", variant="primary")
            
            with gr.Column():
                output_image = gr.Image(label="Generated")
                output_info = gr.Textbox(label="Info", lines=3)
        
        generate_btn.click(
            generate_image,
            [prompt, negative, steps, width, height, cfg, model, nsfw, enhance],
            [output_image, output_info]
        )
    
    with gr.Tab("Gallery"):
        gallery = gr.Gallery(label="Previous Generations", columns=4, rows=4)
        refresh_btn = gr.Button("Refresh")
        
        def refresh():
            return load_gallery()
        
        refresh_btn.click(refresh, outputs=gallery)
        demo.load(refresh, outputs=gallery)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860, share=False)
