# ~/ai_frontend/samantha_frontend.py
import streamlit as st
import requests

st.title("Samantha Local Frontend")

BACKEND_URL = "http://localhost:8080/chat"

prompt = st.text_input("Type a prompt:", value="Hello Samantha")

if st.button("Send"):
    try:
        resp = requests.post(BACKEND_URL, json={"prompt": prompt})
        data = resp.json()
        st.markdown(f"**Samantha says:** {data.get('response', 'No response')}")
    except Exception as e:
        st.error(f"Failed to contact backend: {e}")