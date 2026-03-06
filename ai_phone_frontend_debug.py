# file: ai_phone_frontend_debug.py

import gradio as gr
from ollama import Ollama

# Connect to Olama
olama = Ollama(model="your-chat-model")  # replace with your actual Olama chat model

def generate_image(prompt):
    # Placeholder AI workflow
    return f"Image generated for prompt: {prompt}"

def workflow(prompt):
    ai_output = generate_image(prompt)

    # Debug Olama response
    olama_response = olama.chat(f"User generated: {prompt}. Give suggestions or feedback.")

    # Handle different return types
    if hasattr(olama_response, "text"):
        response_text = olama_response.text
    elif isinstance(olama_response, list) and len(olama_response) > 0:
        response_text = olama_response[0].get("message", str(olama_response[0]))
    else:
        response_text = str(olama_response)

    return ai_output, response_text

# Gradio interface
demo = gr.Interface(
    fn=workflow,
    inputs=gr.Textbox(lines=2, placeholder="Enter your prompt..."),
    outputs=[
        gr.Textbox(label="AI Output"),
        gr.Textbox(label="Olama Response")
    ],
    title="AI Workflow + Olama",
    description="Type your prompt, see AI generate + Olama respond in real time."
)

demo.launch(server_name="0.0.0.0", server_port=7860, debug=True)