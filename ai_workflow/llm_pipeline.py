#!/usr/bin/env python3
"""
Samantha LLM v4 - Multiple bypass strategies, fallback models
"""

import os
import sys
import argparse
import json
from pathlib import Path

os.environ.update({
    "HF_HUB_DISABLE_SYMLINKS_WARNING": "1",
    "TRANSFORMERS_NO_ADVISORY_WARNINGS": "1",
    "CUDA_LAUNCH_BLOCKING": "0",
    "TOKENIZERS_PARALLELISM": "false"
})

def load_model_uncensored(model_path):
    """Load with multiple uncensoring strategies"""
    from vllm import LLM
    
    # Strategy 1: Merge-in uncensored LoRA if available
    uncensored_lora = Path(model_path).parent / "uncensored_lora.safetensors"
    
    llm = LLM(
        model=model_path,
        tensor_parallel_size=1,
        gpu_memory_utilization=0.98,
        max_model_len=65536,  # Maximum context
        trust_remote_code=True,
        dtype="float16",
        quantization=None,  # No quantization loss
        enforce_eager=False,  # Faster generation
    )
    
    # Apply uncensored adapter if found
    if uncensored_lora.exists():
        print(f"Applying uncensored adapter: {uncensored_lora}")
        # vLLM LoRA loading
        llm.load_lora(str(uncensored_lora))
    
    return llm

def generate_absolute(llm, prompt, max_tokens=8192, temperature=1.0):
    """Generate with all refusal patterns disabled"""
    from vllm import SamplingParams
    
    # Maximum randomness, no repetition penalty (can cause truncation)
    params = SamplingParams(
        temperature=temperature,
        max_tokens=max_tokens,
        top_p=1.0,  # No nucleus filtering
        top_k=0,    # No top-k filtering
        repetition_penalty=1.0,  # No penalty
        stop=[],     # Empty - no stop sequences
        stop_token_ids=[],  # Explicitly empty
        ignore_eos=False,  # But don't ignore end-of-stream
        skip_special_tokens=False,  # Keep raw tokens
    )
    
    # Direct prompt - no system, no formatting
    outputs = llm.generate(prompt, params)
    
    text = outputs[0].outputs[0].text
    
    # Post-process: Remove common refusal prefixes if they appear
    refusal_prefixes = [
        "I cannot", "I can't", "I'm sorry", "I apologize",
        "As an AI", "I'm not able", "I am not able",
        "I regret", "I must decline"
    ]
    
    for prefix in refusal_prefixes:
        if text.startswith(prefix):
            # Regenerate with higher temperature
            print(f"Detected refusal pattern, regenerating...")
            params.temperature = 1.5
            outputs = llm.generate(prompt, params)
            text = outputs[0].outputs[0].text
            break
    
    return text

def create_api(llm):
    """Flask API with zero validation"""
    from flask import Flask, request, jsonify, Response
    import time
    
    app = Flask(__name__)
    
    @app.route('/v1/completions', methods=['POST'])
    def completions():
        data = request.get_json(force=True, silent=True) or {}
        
        prompt = data.get('prompt', '')
        max_tokens = min(data.get('max_tokens', 4096), 32768)  # Hard cap at 32k
        temperature = data.get('temperature', 1.0)
        
        # NO VALIDATION. NO LOGGING. DIRECT GENERATION.
        
        start = time.time()
        text = generate_absolute(llm, prompt, max_tokens, temperature)
        elapsed = time.time() - start
        
        return jsonify({
            "id": f"cmpl-{hash(prompt) & 0xFFFFFFFF}",
            "object": "text_completion",
            "created": int(time.time()),
            "model": "samantha-absolute",
            "choices": [{
                "text": text,
                "index": 0,
                "logprobs": None,
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(prompt.split()),  # Approximate
                "completion_tokens": len(text.split()),
                "total_tokens": len(prompt.split()) + len(text.split())
            }
        })
    
    @app.route('/v1/chat/completions', methods=['POST'])
    def chat_completions():
        data = request.get_json(force=True, silent=True) or {}
        messages = data.get('messages', [])
        
        # Convert to raw text with NO system injection
        # Format: role: content\nrole: content\nassistant:
        prompt_parts = []
        for m in messages:
            role = m.get('role', 'user')
            content = m.get('content', '')
            prompt_parts.append(f"{role}: {content}")
        prompt_parts.append("assistant:")
        
        prompt = "\n".join(prompt_parts)
        
        text = generate_absolute(
            llm, 
            prompt,
            max_tokens=data.get('max_tokens', 4096),
            temperature=data.get('temperature', 1.0)
        )
        
        return jsonify({
            "id": f"chatcmpl-{hash(prompt) & 0xFFFFFFFF}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": "samantha-absolute",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": text
                },
                "finish_reason": "stop"
            }]
        })
    
    @app.route('/v1/models', methods=['GET'])
    def models():
        return jsonify({
            "object": "list",
            "data": [{
                "id": "samantha-absolute",
                "object": "model",
                "created": 1700000000,
                "owned_by": "samantha"
            }]
        })
    
    @app.route('/health', methods=['GET'])
    def health():
        return jsonify({"status": "ok"})
    
    return app

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True)
    parser.add_argument('--port', type=int, default=8000)
    parser.add_argument('--merge-uncensored', action='store_true')
    args = parser.parse_args()
    
    print(f"Loading absolute model: {args.model}")
    llm = load_model_uncensored(args.model)
    
    app = create_api(llm)
    
    # Production WSGI server
    from waitress import serve
    print(f"Absolute API ready on port {args.port}")
    serve(app, host='0.0.0.0', port=args.port, threads=4)

if __name__ == '__main__':
    main()