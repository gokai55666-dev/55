# ~/samantha_ultimate/samantha_ultimate_src/samantha_api.py
from fastapi import FastAPI
from pydantic import BaseModel
from samantha_core import SamanthaSupertool

app = FastAPI(title="Samantha Local API")

# Load your local models
samantha = SamanthaSupertool(
    llm_model="~/samantha_ultimate/config/models/WAN2.2",
    diffusion_model="~/samantha_ultimate/config/models/SDXL"
)

class Prompt(BaseModel):
    prompt: str

@app.post("/chat")
async def chat_endpoint(data: Prompt):
    try:
        response_text = samantha.chat(data.prompt)
        return {"response": response_text, "image": None}
    except Exception as e:
        return {"error": str(e)}