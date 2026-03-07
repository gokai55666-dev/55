import requests

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"

def generate_text(prompt, model="llama3"):

    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }

    r = requests.post(OLLAMA_URL, json=payload)

    if r.status_code == 200:
        return r.json()["response"]

    return f"Error: {r.text}"