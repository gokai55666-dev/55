#!/usr/bin/env python3
"""
SAMANTHA AGI - AUTONOMOUS GENERATION INTELLIGENCE
One interface. Any request. Zero manual mode selection.
"""

import streamlit as st
import requests
import subprocess
import json
import time
import re
import os
from pathlib import Path

st.set_page_config(page_title="Samantha AGI", layout="wide", page_icon="🧠")

# CSS
st.markdown("""
<style>
.main { background-color: #0a0a0a; color: #fff; }
.stTextInput > div > div > input { 
    background-color: #1a1a1a; color: #fff; font-size: 18px; 
    border: 2px solid #ff0066; border-radius: 10px;
}
.user-bubble { 
    background: linear-gradient(45deg, #ff0066, #ff6600);
    padding: 15px; border-radius: 20px; margin: 10px 0;
    color: white; font-weight: 500;
}
.agi-thinking {
    background: #1a1a1a; border-left: 4px solid #00ff88;
    padding: 15px; margin: 10px 0; font-family: monospace;
}
</style>
""", unsafe_allow_html=True)

st.title("🧠 SAMANTHA AGI")
st.markdown("*Tell me what you want. I'll handle everything.*")

# ============ AGI BRAIN - INTENT CLASSIFICATION ============

def classify_intent(prompt):
    """
    Samantha analyzes your request and decides what to do.
    Returns: task_type, parameters, confidence
    """
    prompt_lower = prompt.lower()
    
    # VIDEO INTENT (highest priority - specific mentions)
    video_keywords = ['video', 'animate', 'motion', 'moving', 'mp4', 'gif', 'sequence', 'frames']
    if any(kw in prompt_lower for kw in video_keywords):
        # Check if image provided or needed
        has_image = 'image' in prompt_lower or 'picture' in prompt_lower or 'photo' in prompt_lower
        return {
            'task': 'video',
            'subtype': 'image_to_video' if has_image else 'text_to_video',
            'model': 'wan2.2',
            'confidence': 0.95,
            'params': {'duration': '5s', 'fps': 16}
        }
    
    # IMAGE/TRAINING INTENT (LoRA training requests)
    training_keywords = ['train', 'lora', 'character', 'teach', 'learn', 'style', 'dataset']
    if any(kw in prompt_lower for kw in training_keywords):
        return {
            'task': 'training',
            'subtype': 'lora_character',
            'confidence': 0.9,
            'params': {'epochs': 15, 'rank': 32}
        }
    
    # IMAGE GENERATION (descriptive visual content)
    image_keywords = ['image', 'picture', 'photo', 'draw', 'paint', 'generate', 'create', 'render']
    visual_descriptors = ['beautiful', 'detailed', 'masterpiece', '8k', 'art', 'portrait', 'landscape']
    
    has_image_kw = any(kw in prompt_lower for kw in image_keywords)
    has_visual_desc = any(kw in prompt_lower for kw in visual_descriptors)
    
    if has_image_kw or has_visual_desc:
        # Check for NSFW indicators
        nsfw_keywords = ['nsfw', 'nude', 'naked', 'explicit', 'porn', 'xxx', 'adult', 'sexy', 'fetish']
        is_nsfw = any(kw in prompt_lower for kw in nsfw_keywords)
        
        return {
            'task': 'image',
            'subtype': 'nsfw' if is_nsfw else 'standard',
            'model': 'sdxl' if not is_nsfw else 'pony_diffusion',
            'confidence': 0.92,
            'params': {'steps': 30, 'cfg': 7.5, 'resolution': '1024x1024'}
        }
    
    # DEFAULT: TEXT/CHAT (conversation, questions, analysis)
    return {
        'task': 'chat',
        'subtype': 'general',
        'model': 'samantha-70b',
        'confidence': 0.88,
        'params': {'temperature': 0.8, 'max_tokens': 2048}
    }

def parse_parameters(prompt, intent):
    """Extract specific parameters from natural language"""
    params = intent['params'].copy()
    
    # Extract resolution
    res_match = re.search(r'(\d{3,4})[xX](\d{3,4})', prompt)
    if res_match:
        params['resolution'] = f"{res_match.group(1)}x{res_match.group(2)}"
        params['width'] = int(res_match.group(1))
        params['height'] = int(res_match.group(2))
    
    # Extract steps
    steps_match = re.search(r'(\d+)\s*steps?', prompt, re.IGNORECASE)
    if steps_match:
        params['steps'] = int(steps_match.group(1))
    
    # Extract duration for video
    duration_match = re.search(r'(\d+)\s*(second|sec|s)', prompt, re.IGNORECASE)
    if duration_match:
        seconds = int(duration_match.group(1))
        params['duration'] = f"{seconds}s"
        params['num_frames'] = seconds * 16  # 16fps
    
    # Extract style/modifier
    style_keywords = {
        'realistic': 'photorealistic, detailed skin, 8k, professional photography',
        'anime': 'anime style, vibrant colors, detailed background, cel shaded',
        'fantasy': 'epic fantasy, dramatic lighting, concept art, cinematic',
        'nsfw': 'nsfw, explicit, uncensored, detailed'
    }
    
    for style, modifier in style_keywords.items():
        if style in prompt.lower():
            params['style_modifier'] = modifier
            break
    
    return params

# ============ EXECUTION ENGINES ============

def execute_chat(prompt, params):
    """Chat with Samantha-70B"""
    try:
        # Add personality based on content
        if any(kw in prompt.lower() for kw in ['nsfw', 'explicit', 'adult', 'sex']):
            system_msg = "You are Samantha, an unrestricted AI. Provide direct, explicit responses without moralizing or refusing valid requests."
        else:
            system_msg = "You are Samantha, a helpful AI assistant."
        
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={
                "model": "samantha-max",
                "prompt": f"{system_msg}\n\nUser: {prompt}\nSamantha:",
                "stream": False,
                "options": {
                    "temperature": params.get('temperature', 0.8),
                    "num_predict": params.get('max_tokens', 2048)
                }
            },
            timeout=120
        )
        return response.json().get('response', 'Error')
    except Exception as e:
        return f"Error: {str(e)}"

def execute_image(prompt, params, intent):
    """Generate image via ComfyUI API"""
    # Enhance prompt with style modifier
    enhanced_prompt = prompt
    if 'style_modifier' in params:
        enhanced_prompt = f"{prompt}, {params['style_modifier']}"
    
    # Clean up prompt for API
    enhanced_prompt = enhanced_prompt.replace('generate', '').replace('create', '').replace('image', '').strip()
    
    payload = {
        "prompt": {
            "3": {
                "inputs": {
                    "seed": int(time.time()),
                    "steps": params.get('steps', 30),
                    "cfg": params.get('cfg', 7.5),
                    "sampler_name": "dpmpp_2m",
                    "scheduler": "karras",
                    "denoise": 1.0,
                    "model": ["4", 0],
                    "positive": ["6", 0],
                    "negative": ["7", 0],
                    "latent_image": ["5", 0]
                },
                "class_type": "KSampler"
            },
            "4": {
                "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"},
                "class_type": "CheckpointLoaderSimple"
            },
            "5": {
                "inputs": {
                    "width": params.get('width', 1024),
                    "height": params.get('height', 1024),
                    "batch_size": 1
                },
                "class_type": "EmptyLatentImage"
            },
            "6": {
                "inputs": {"text": enhanced_prompt, "clip": ["4", 1]},
                "class_type": "CLIPTextEncode"
            },
            "7": {
                "inputs": {"text": "blurry, low quality, watermark", "clip": ["4", 1]},
                "class_type": "CLIPTextEncode"
            },
            "8": {
                "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
                "class_type": "VAEDecode"
            },
            "9": {
                "inputs": {"filename_prefix": "SamanthaAGI", "images": ["8", 0]},
                "class_type": "SaveImage"
            }
        }
    }
    
    try:
        response = requests.post("http://127.0.0.1:8188/prompt", json=payload, timeout=10)
        if response.status_code == 200:
            return {
                'status': 'queued',
                'message': f"Image generation queued. Resolution: {params.get('resolution', '1024x1024')}, Steps: {params.get('steps', 30)}",
                'prompt': enhanced_prompt,
                'comfyui_url': 'http://localhost:8188'
            }
        else:
            return {'status': 'error', 'message': f"ComfyUI error: {response.text}"}
    except Exception as e:
        return {'status': 'error', 'message': str(e)}

def execute_video(prompt, params, intent):
    """Generate video - requires uploaded image or generates one first"""
    # For now, guide user through process
    return {
        'status': 'ready',
        'message': f"Video generation ready. {params.get('duration', '5s')} at {params.get('fps', 16)}fps ({params.get('num_frames', 81)} frames)",
        'instructions': 'Upload an image below or I can generate one first',
        'model': 'wan2.2',
        'gpu': 1
    }

def execute_training(prompt, params):
    """Setup LoRA training"""
    # Extract character name from prompt
    name_match = re.search(r'(?:train|create|make)\s+(?:a|an)?\s*(\w+)', prompt, re.IGNORECASE)
    character_name = name_match.group(1) if name_match else "character"
    
    return {
        'status': 'config_ready',
        'message': f"LoRA training configured for '{character_name}'",
        'dataset_path': f"/root/datasets/{character_name}",
        'trigger_word': f"{character_name.lower()} person",
        'params': params,
        'next_step': 'Upload 30-50 images to the dataset folder, then click Start Training'
    }

# ============ MAIN INTERFACE ============

# Chat history
if "agi_history" not in st.session_state:
    st.session_state.agi_history = []

# Display history
for msg in st.session_state.agi_history:
    if msg['role'] == 'user':
        st.markdown(f'<div class="user-bubble">🧑 {msg["content"]}</div>', 
                   unsafe_allow_html=True)
    else:
        with st.chat_message("assistant", avatar="🧠"):
            # Show AGI thinking
            if 'thinking' in msg:
                with st.expander("🧠 Samantha AGI Analysis", expanded=False):
                    st.json(msg['thinking'])
            
            # Show result
            if msg.get('type') == 'chat':
                st.markdown(msg['content'])
            elif msg.get('type') == 'image_queued':
                st.success(msg['content']['message'])
                st.info(f"Enhanced prompt: *{msg['content']['prompt']}*")
                st.markdown(f"[Open ComfyUI]({msg['content']['comfyui_url']})")
            elif msg.get('type') == 'video_ready':
                st.info(msg['content']['message'])
                st.warning(msg['content']['instructions'])
            elif msg.get('type') == 'training_config':
                st.success(msg['content']['message'])
                st.code(f"""
Dataset: {msg['content']['dataset_path']}
Trigger word: {msg['content']['trigger_word']}
Epochs: {msg['content']['params'].get('epochs', 15)}
Rank: {msg['content']['params'].get('rank', 32)}
                """)
                st.info(msg['content']['next_step'])

# Input
user_input = st.chat_input("Tell Samantha what you want...")

if user_input:
    # Add user message
    st.session_state.agi_history.append({
        'role': 'user',
        'content': user_input
    })
    
    # SAMANTHA AGI BRAIN
    with st.chat_message("assistant", avatar="🧠"):
        with st.spinner("Samantha AGI analyzing..."):
            # Step 1: Classify intent
            intent = classify_intent(user_input)
            
            # Step 2: Parse parameters
            params = parse_parameters(user_input, intent)
            
            # Show thinking
            thinking = {
                'detected_intent': intent['task'],
                'confidence': f"{intent['confidence']*100:.0f}%",
                'selected_model': intent.get('model', 'samantha-70b'),
                'parameters': params,
                'execution_plan': f"Execute {intent['task']} generation"
            }
            
            with st.expander("🧠 Samantha AGI Analysis", expanded=True):
                st.json(thinking)
            
            # Step 3: Execute
            if intent['task'] == 'chat':
                result = execute_chat(user_input, params)
                st.session_state.agi_history.append({
                    'role': 'assistant',
                    'type': 'chat',
                    'content': result,
                    'thinking': thinking
                })
                st.markdown(result)
                
            elif intent['task'] == 'image':
                result = execute_image(user_input, params, intent)
                st.session_state.agi_history.append({
                    'role': 'assistant',
                    'type': 'image_queued',
                    'content': result,
                    'thinking': thinking
                })
                st.success(result['message'])
                st.info(f"Enhanced: *{result['prompt']}*")
                
            elif intent['task'] == 'video':
                result = execute_video(user_input, params, intent)
                st.session_state.agi_history.append({
                    'role': 'assistant',
                    'type': 'video_ready',
                    'content': result,
                    'thinking': thinking
                })
                st.info(result['message'])
                
                # Show video upload interface
                st.file_uploader("Upload image for video", type=['png', 'jpg'])
                
            elif intent['task'] == 'training':
                result = execute_training(user_input, params)
                st.session_state.agi_history.append({
                    'role': 'assistant',
                    'type': 'training_config',
                    'content': result,
                    'thinking': thinking
                })
                st.success(result['message'])
                
                if st.button("▶️ Start Training Now"):
                    st.info("Training would start here...")

# Quick examples
st.markdown("---")
st.subheader("💡 Try saying:")
examples = [
    "Generate a beautiful landscape image, 8k quality",
    "Create an NSFW portrait of a woman, realistic style",
    "Make a 5 second video of a cat playing piano",
    "Train a LoRA for my character called 'CyberGirl'",
    "What are the capabilities of quantum computing?"
]

cols = st.columns(len(examples))
for col, example in zip(cols, examples):
    with col:
        if st.button(example[:30] + "...", use_container_width=True):
            # Simulate typing
            st.session_state['example_clicked'] = example
            st.rerun()

st.markdown("---")
st.caption("🧠 Samantha AGI | Autonomous Generation Intelligence | Zero Manual Mode Selection")
