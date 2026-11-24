#!/usr/bin/env python3
"""
Backend Server A - Mac 3
IP: 10.7.6.90
Port: 3001
Features: REST status endpoint, Cache-Control header, and ETag conditional validation
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler

HOST = "0.0.0.0"
PORT = 3001
BACKEND_ID = "A"
ETAG = '"backend-a-v1"'

class BackendAHandler(BaseHTTPRequestHandler):
    server_version = "BackendServer/1.0"

    def do_GET(self):
        if self.path in ["/", "/api/status"]:
            # Check conditional request (If-None-Match)
            client_etag = self.headers.get("If-None-Match")
            if client_etag == ETAG:
                self.send_response(304)
                self.send_header("ETag", ETAG)
                self.send_header("Cache-Control", "max-age=60")
                self.send_header("X-Backend", BACKEND_ID)
                self.end_headers()
                return

            response_data = {
                "backend": BACKEND_ID,
                "status": "ok",
                "port": PORT,
                "message": "Hello from Backend A"
            }
            body = json.dumps(response_data, indent=2).encode("utf-8")
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "max-age=60")
            self.send_header("ETag", ETAG)
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
    httpd = HTTPServer(server_address, BackendAHandler)
    print(f"[*] Backend A running on {HOST}:{PORT} (X-Backend: {BACKEND_ID}) with Cache-Control support")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[!] Stopping Backend A...")
        httpd.server_close()

if __name__ == "__main__":
    run()
