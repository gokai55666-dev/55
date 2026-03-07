#!/usr/bin/env python3
import os, subprocess, sys, time
from pathlib import Path

# ---------------------------
# Check & start Ollama
# ---------------------------
def start_ollama():
    try:
        subprocess.run(["ollama", "ping"], check=True, stdout=subprocess.DEVNULL)
    except Exception:
        print("[INFO] Ollama not running, starting...")
        subprocess.Popen(["ollama", "serve"])
        time.sleep(5)

# ---------------------------
# Simple CLI for text/image/video
# ---------------------------
def main():
    start_ollama()
    print("AI Frontend Improved CLI")
    print("Commands: text, image, video, exit")
    while True:
        cmd = input(">> ").strip().lower()
        if cmd == "exit":
            break
        elif cmd == "text":
            prompt = input("Prompt: ")
            subprocess.run(["ollama", "run", "llama3.1:70b-instruct-q4_K_M", prompt])
        elif cmd == "image":
            prompt = input("Image prompt: ")
            subprocess.run(["python3", "-m", "imgen", prompt])
        elif cmd == "video":
            prompt = input("Video prompt: ")
            subprocess.run(["python3", "-m", "im2vid", prompt])
        else:
            print("Unknown command")

if __name__ == "__main__":
    main()