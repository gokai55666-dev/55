# samantha_ultimate_src/samantha_core.py
# Full SamanthaSupertool wiring: Ollama, ComfyUI, LoRA workflows

import requests
import subprocess
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

# ----------------------------
# API bridges
# ----------------------------

# Ollama bridge
OLLAMA_URL = "http://localhost:11434/api/generate"  # Update if your Ollama port is different

def ollama_chat(prompt, model="samantha"):
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    r = requests.post(OLLAMA_URL, json=payload)
    return r.json()["response"]

# ComfyUI bridge
COMFY_URL = "http://localhost:8188/api/v1/generate"  # Update if needed

def comfy_generate_image(prompt):
    payload = {"prompt": prompt}
    r = requests.post(COMFY_URL, json=payload)
    return r.json()  # Should contain images as URLs or base64

# ----------------------------
# Request models for FastAPI
# ----------------------------

class ChatRequest(BaseModel):
    prompt: str

class ImageRequest(BaseModel):
    prompt: str

class LoRARequest(BaseModel):
    model_name: str

# ----------------------------
# Samantha Supertool class
# ----------------------------

class SamanthaSupertool:
    def __init__(self, llm_model="samantha", diffusion_model="sdxl"):
        self.llm_model = llm_model
        self.diffusion_model = diffusion_model

    # Chat through Ollama
    def chat(self, prompt):
        return ollama_chat(prompt, model=self.llm_model)

    # Generate image through ComfyUI
    def generate_image(self, prompt):
        return comfy_generate_image(prompt)

    # Trigger LoRA training script
    def train_lora(self, model_name):
        # Adjust the path to your training script if needed
        script_path = f"../kohya_ss/scripts/train_{model_name}.sh"
        subprocess.Popen(["bash", script_path])
        return {"status": f"LoRA training started for {model_name}"}

# ----------------------------
# FastAPI endpoints
# ----------------------------

samantha = SamanthaSupertool()

@app.post("/chat")
def chat_endpoint(request: ChatRequest):
    response = samantha.chat(request.prompt)
    return {"response": response}

@app.post("/generate_image")
def image_endpoint(request: ImageRequest):
    response = samantha.generate_image(request.prompt)
    return {"images": response.get("images", [])}

@app.post("/train_lora")
def train_lora_endpoint(request: LoRARequest):
    return samantha.train_lora(request.model_name)

# Optional root
@app.get("/")
def root():
    return {"status": "Samantha API is alive"}
