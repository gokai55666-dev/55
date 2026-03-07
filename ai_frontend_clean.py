#!/usr/bin/env python3
import subprocess
import sys

# ------------------------
# CONFIGURATION
# ------------------------
OLLAMA_PORT = 11434  # default Ollama API port

# ------------------------
# UTILITY FUNCTIONS
# ------------------------
def is_ollama_running():
    """Check if Ollama is running on localhost"""
    try:
        import requests
        r = requests.get(f"http://127.0.0.1:{OLLAMA_PORT}/api/tags", timeout=2)
        return r.status_code == 200
    except:
        return False

def call_ollama_model(prompt, model="llama3.1:70b-instruct-q4_K_M"):
    """Send prompt to Ollama and get response"""
    import requests
    try:
        r = requests.post(
            f"http://127.0.0.1:{OLLAMA_PORT}/api/completions",
            json={"model": model, "prompt": prompt, "max_tokens": 500},
            timeout=30
        )
        return r.json()["completion"]
    except Exception as e:
        return f"[Error communicating with Ollama]: {e}"

# ------------------------
# FRONTEND LOOP
# ------------------------
def main():
    print("AI Frontend Clean CLI")
    print("Commands: text, image, video, exit\n")

    if not is_ollama_running():
        print("Warning: Ollama is not running. Start it manually with `ollama serve`.\n")

    while True:
        cmd = input(">> ").strip().lower()
        if cmd == "exit":
            break
        elif cmd in ("text", "image", "video"):
            prompt = input(f"Enter {cmd} prompt: ")
            output = call_ollama_model(prompt)
            print(f"AI Output:\n{output}\n")
        else:
            print("Unknown command. Valid commands: text, image, video, exit")

if __name__ == "__main__":
    main()