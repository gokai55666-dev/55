#!/usr/bin/env python3
# ai_frontend_tailscale.py
# Full Ollama + SDXL + AnimateDiff frontend for CLI + Tailscale GUI

import os, sys, asyncio, subprocess
from fastapi import FastAPI, Form
from fastapi.responses import JSONResponse, FileResponse
import uvicorn
from pathlib import Path
import json
import threading

# -------------------------------
# CONFIG
# -------------------------------
TAILSCALE_IP = os.getenv("TAILSCALE_IP", "100.100.100.100")  # Replace with your Tailscale IP
PORT = 7860
OUTPUT_DIR = Path("outputs")
OUTPUT_DIR.mkdir(exist_ok=True)

# -------------------------------
# FASTAPI SERVER
# -------------------------------
app = FastAPI(title="AI Frontend (Tailscale Secure)")

@app.get("/")
def index():
    return {"status": "AI frontend running", "outputs": str(OUTPUT_DIR)}

# -------------------------------
# OLAMA / LLAMA TEXT
# -------------------------------
async def generate_text(prompt: str):
    # Using Ollama local API
    import httpx
    url = f"http://127.0.0.1:11434/api/generate"
    payload = {"model": "llama3.1:70b-instruct-q4_K_M", "prompt": prompt, "max_tokens": 500}
    async with httpx.AsyncClient() as client:
        r = await client.post(url, json=payload, timeout=180)
        data = r.json()
        return data.get("completion", "")

@app.post("/gen_text")
async def gen_text_endpoint(prompt: str = Form(...)):
    text = await generate_text(prompt)
    return JSONResponse({"result": text})

# -------------------------------
# IMAGE GENERATION (SDXL stub)
# -------------------------------
def generate_image(prompt: str, filename: str = None):
    if not filename:
        filename = OUTPUT_DIR / f"{hash(prompt)}.png"
    else:
        filename = OUTPUT_DIR / filename
    # Stub call to SDXL / Stable Diffusion CLI
    cmd = f"python scripts/txt2img.py --prompt '{prompt}' --outdir {OUTPUT_DIR}"
    subprocess.run(cmd, shell=True)
    return filename

@app.post("/gen_image")
def gen_image_endpoint(prompt: str = Form(...)):
    file_path = generate_image(prompt)
    return FileResponse(file_path)

# -------------------------------
# VIDEO GENERATION (AnimateDiff stub)
# -------------------------------
def generate_video(prompt: str, filename: str = None):
    if not filename:
        filename = OUTPUT_DIR / f"{hash(prompt)}.mp4"
    else:
        filename = OUTPUT_DIR / filename
    # Stub call to AnimateDiff / Deforum
    cmd = f"python generate_video.py --prompt '{prompt}' --out {filename}"
    subprocess.run(cmd, shell=True)
    return filename

@app.post("/gen_video")
def gen_video_endpoint(prompt: str = Form(...)):
    file_path = generate_video(prompt)
    return FileResponse(file_path)

# -------------------------------
# CLI INTERFACE
# -------------------------------
def cli_loop():
    print("AI Frontend CLI (type 'help' for commands)")
    while True:
        cmd = input(">> ").strip()
        if cmd.startswith("text "):
            prompt = cmd[5:]
            result = asyncio.run(generate_text(prompt))
            print(f"\n{result}\n")
        elif cmd.startswith("img "):
            prompt = cmd[4:]
            file = generate_image(prompt)
            print(f"Image saved: {file}")
        elif cmd.startswith("video "):
            prompt = cmd[6:]
            file = generate_video(prompt)
            print(f"Video saved: {file}")
        elif cmd == "help":
            print("Commands:\n text <prompt>\n img <prompt>\n video <prompt>\n exit")
        elif cmd == "exit":
            sys.exit(0)
        else:
            print("Unknown command, type 'help'")

# -------------------------------
# RUN SERVER + CLI
# -------------------------------
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--cli", action="store_true", help="Run CLI mode")
    parser.add_argument("--desktop", action="store_true", help="Run Tailscale desktop mode")
    args = parser.parse_args()

    if args.cli:
        cli_loop()
    elif args.desktop:
        # Run server in thread
        threading.Thread(target=lambda: uvicorn.run(app, host=TAILSCALE_IP, port=PORT, log_level="info")).start()
        print(f"Desktop GUI running at http://{TAILSCALE_IP}:{PORT}")
        cli_loop()  # optional CLI alongside
    else:
        print("Use --cli or --desktop")