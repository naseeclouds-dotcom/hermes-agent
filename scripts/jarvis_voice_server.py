
import http.server
import socketserver
import subprocess
import json
import os
import sys
import asyncio
import threading

# Add current directory to path to import audio components
sys.path.append(os.path.dirname(__file__))
try:
    from luuzr_audio_core import record_until_silence
    from luuzr_speech_engine import engine as speech_engine
except ImportError:
    print("Speech engine not found. Please check installations.")

PORT = 8080
STATE_FILE = r"C:\Users\Naseeh-A\AppData\Local\hermes\scripts\luuzr_state.txt"

def set_state(state):
    with open(STATE_FILE, "w") as f:
        f.write(state)

def run_async(coro):
    """Helper to run async functions in a synchronous handler."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()

class JarvisHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data.decode('utf-8'))
        
        # If the request is for 'record', we trigger the high-quality recording
        if data.get("action") == "record":
            set_state("LISTENING")
            audio_data = record_until_silence()
            text = speech_engine.speech_to_text(audio_data)
            
            # Now process the text through Hermes
            set_state("PROCESSING")
            subprocess.run(["hermes", "chat", "-q", text, "--profile", "luuzr"], shell=True)
            
            # We can't easily return the audio in a POST response here, 
            # so we assume the Hermes agent will use a tool to speak back.
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "transcribed": text}).encode('utf-8'))
            return

        # Standard command handling
        command = data.get("command", "")
        set_state("PROCESSING")
        try:
            subprocess.run(["hermes", "chat", "-q", command, "--profile", "luuzr"], shell=True)
        except Exception as e:
            print(f"Error: {e}")
        
        set_state("IDLE")
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"status": "success"}).encode('utf-8'))

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

set_state("IDLE")
print(f"Luuzr High-Fidelity Server running on port {PORT}...")
with socketserver.TCPServer(("", PORT), JarvisHandler) as httpd:
    httpd.serve_forever()
