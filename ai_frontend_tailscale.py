#!/usr/bin/env python3
import subprocess
import socket
import time
import os
import sys

# ------------------------------
# CONFIG
# ------------------------------
OLLAMA_CMD = "/usr/local/bin/ollama"  # change if your Ollama binary is elsewhere
OLLAMA_PORT = 11434
GUI_HOST = "0.0.0.0"  # bind to all interfaces for Tailscale
GUI_PORT = 7860

# ------------------------------
# CHECK & START OLLAMA
# ------------------------------
def is_port_open(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect((host, port))
        s.close()
        return True
    except:
        return False

if not is_port_open("127.0.0.1", OLLAMA_PORT):
    print(f"[INFO] Ollama not running. Starting Ollama on port {OLLAMA_PORT}...")
    try:
        subprocess.Popen([OLLAMA_CMD, "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(5)  # give it a few seconds to start
    except FileNotFoundError:
        print(f"[ERROR] Cannot find Ollama at {OLLAMA_CMD}. Install it and try again.")
        sys.exit(1)
else:
    print("[INFO] Ollama already running.")

# ------------------------------
# CHECK DEPENDENCIES
# ------------------------------
try:
    import fastapi
    import uvicorn
    from fastapi import Form
except ImportError:
    print("[INFO] Installing missing Python dependencies...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "fastapi", "uvicorn", "python-multipart"])
    import fastapi
    import uvicorn
    from fastapi import Form

try:
    import gradio as gr
except ImportError:
    print("[INFO] Installing Gradio...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "gradio"])
    import gradio as gr

# ------------------------------
# FASTAPI + GRADIO FRONTEND
# ------------------------------
app = fastapi.FastAPI()

@app.post("/api/generate_text")
async def gen_text_endpoint(prompt: str = Form(...)):
    # call Ollama
    try:
        result = subprocess.run([OLLAMA_CMD, "query", "llama3.1:70b-instruct-q4_K_M", prompt],
                                capture_output=True, text=True)
        return {"output": result.stdout.strip()}
    except Exception as e:
        return {"error": str(e)}

# Placeholder for image/video endpoints
@app.post("/api/generate_image")
async def gen_image_endpoint(prompt: str = Form(...)):
    return {"output": "[Image generation placeholder]"}

@app.post("/api/generate_video")
async def gen_video_endpoint(prompt: str = Form(...)):
    return {"output": "[Video generation placeholder]"}

# ------------------------------
# LAUNCH DESKTOP GUI OVER TAILSCALE
# ------------------------------
def launch_gui():
    with gr.Blocks() as demo:
        gr.Markdown("## ZTE AI Frontend (Tailscale)")
        txt_input = gr.Textbox(label="Your Input")
        output = gr.Textbox(label="AI Output")
        btn = gr.Button("Send")

        def handle_input(prompt):
            import requests
            try:
                r = requests.post(f"http://127.0.0.1:{OLLAMA_PORT}/api/generate_text", data={"prompt": prompt})
                return r.json().get("output", "No output")
            except Exception as e:
                return f"Error: {str(e)}"

        btn.click(handle_input, txt_input, output)

    demo.launch(server_name=GUI_HOST, server_port=GUI_PORT)

if __name__ == "__main__":
    print(f"[INFO] Launching Desktop GUI at http://{GUI_HOST}:{GUI_PORT}")
    launch_gui()