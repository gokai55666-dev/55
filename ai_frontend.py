import streamlit as st

# Example AI function - replace with your model inference
def ai_response(user_input):
    return f"AI says: {user_input[::-1]}"  # just reverses text as placeholder

st.title("ZTE AI Frontend")
st.write("Type something for the AI to respond:")

user_input = st.text_input("Your Input")
if st.button("Run AI"):
    response = ai_response(user_input)
    st.write(response)