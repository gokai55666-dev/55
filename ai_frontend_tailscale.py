#!/usr/bin/env python3
"""
ZTE AI Frontend (Tailscale-ready)
Auto-handles Ollama, free port selection, and desktop GUI.
"""

import os
import subprocess
import socket
import time
import sys
from pathlib import Path

try:
    import gradio as gr
except ModuleNotFoundError:
    print("[ERROR] Gradio not installed. Run: pip install gradio python-multipart")
    sys.exit(1)


# --- CONFIG ---
PORT_START = 7860
PORT_END = 7900
OLLSERVE_CMD = "ollama serve"
AI_FRONTEND_NAME = "ZTE AI Frontend"
DESKTOP_MODE = True  # change to False to run CLI only


# --- UTILITY FUNCTIONS ---

def get_free_port(start=PORT_START, end=PORT_END):
    """Find first free TCP port"""
    for port in range(start, end + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('0.0.0.0', port)) != 0:
                return port
    raise RuntimeError(f"No free port found in range {start}-{end}")


def tailscale_ip():
    """Get Tailscale IPv4"""
    try:
        ip = subprocess.check_output(["tailscale", "ip", "-4"]).decode().strip()
        return ip
    except Exception:
        return "127.0.0.1"


def ensure_ollama_running():
    """Start Ollama if not running"""
    # Check if process exists
    result = subprocess.run(["pgrep", "-f", "ollama"], capture_output=True)
    if result.stdout:
        print("[INFO] Ollama already running.")
        return
    print("[INFO] Starting Ollama...")
    subprocess.Popen(OLLSERVE_CMD.split())
    time.sleep(5)  # wait for Ollama to initialize


# --- FRONTEND LOGIC ---

def create_demo():
    """Create simple demo with text input"""
    with gr.Blocks() as demo:
        gr.Markdown(f"# {AI_FRONTEND_NAME}")
        input_text = gr.Textbox(label="Your Input", placeholder="Type here...")
        output_text = gr.Textbox(label="AI Output")
        btn = gr.Button("Send")

        def handle_input(txt):
            # Send input to Ollama API
            try:
                import requests
                resp = requests.post("http://127.0.0.1:11434/api/completions", json={
                    "model": "llama3.1:70b-instruct-q4_K_M",
                    "prompt": txt,
                    "max_tokens": 256
                })
                return resp.json().get("completion", "No response")
            except Exception as e:
                return f"[ERROR] {e}"

        btn.click(handle_input, inputs=input_text, outputs=output_text)

    return demo


def launch_gui():
    host_ip = tailscale_ip()
    port = get_free_port()
    print(f"[INFO] Launching frontend at http://{host_ip}:{port}")
    demo = create_demo()
    demo.launch(server_name=host_ip, server_port=port, share=False)


# --- MAIN ---
if __name__ == "__main__":
    ensure_ollama_running()
    if DESKTOP_MODE:
        launch_gui()
    else:
        print(f"{AI_FRONTEND_NAME} CLI ready. Type input below:")
        while True:
            try:
                prompt = input(">> ")
                demo_response = create_demo().process(prompt)
                print(demo_response)
            except KeyboardInterrupt:
                print("\n[INFO] Exiting...")
                break