#!/usr/bin/env python3
"""
Backend Server B - Mac 4
IP: 10.7.9.188
Port: 3002
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler

HOST = "0.0.0.0"
PORT = 3002
BACKEND_ID = "B"

class BackendBHandler(BaseHTTPRequestHandler):
    server_version = "BackendServer/1.0"

    def do_GET(self):
        if self.path in ["/", "/api/status"]:
            response_data = {
                "backend": BACKEND_ID,
                "status": "ok",
                "port": PORT,
                "message": "Hello from Backend B"
            }
            body = json.dumps(response_data, indent=2).encode("utf-8")
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("X-Backend", BACKEND_ID)
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.send_header("Content-Type", "application/json")
            self.send_header("X-Backend", BACKEND_ID)
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Not Found"}).encode("utf-8"))

def run():
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, BackendBHandler)
    print(f"[*] Backend B running on {HOST}:{PORT} (X-Backend: {BACKEND_ID})")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[!] Stopping Backend B...")
        httpd.server_close()

if __name__ == "__main__":
    run()
