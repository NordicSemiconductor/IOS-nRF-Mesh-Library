from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import os
import ssl

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        query = parse_qs(parsed_path.query)
        path = parsed_path.path

        # Distributor nRF54L15 1.0.1+1234 -> 2.0.1+1234
        if path == '/check' and query.get('cfwid', [None])[0] == '590001000100D2040000':
            response = {
                "manifest": {
                    "firmware": {
                        "firmware_id": "590002000100D2040000",
                        "dfu_chain_size": 1,
                        "firmware_image_file_size": 446356
                    }
                }
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            import json
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif path == '/get' and query.get('cfwid', [None])[0] == '590001000100D2040000':
            file_path = 'dfu_distr_54L_2.0.1.zip'
            if os.path.exists(file_path):
                file_size = os.path.getsize(file_path)
                self.send_response(200)
                self.send_header('Content-Type', 'application/gzip')
                self.send_header('Content-Disposition', 'attachment; filename="dfu_distr_54L_2.0.1.zip"')
                self.send_header('Content-Length', str(file_size))
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_error(404, "File not found")

        # Target nRF52840 1.1 -> 2.0
        elif path == '/check' and query.get('cfwid', [None])[0] == '59000101000000000000':
            response = {
                "manifest": {
                    "firmware": {
                        "firmware_id": "59000200000000000000",
                        "dfu_chain_size": 1,
                        "firmware_image_file_size": 341466
                    }
                }
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            import json
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif path == '/get' and query.get('cfwid', [None])[0] == '59000101000000000000':
            file_path = 'dfu_target_52840_2.0.zip'
            if os.path.exists(file_path):
                file_size = os.path.getsize(file_path)
                self.send_response(200)
                self.send_header('Content-Type', 'application/gzip')
                self.send_header('Content-Disposition', 'attachment; filename="dfu_target_52840_2.0.zip"')
                self.send_header('Content-Length', str(file_size))
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_error(404, "File not found")
                    
        else:
            self.send_error(404, "Path not found")

def run(server_class=HTTPServer, handler_class=MyHandler, port=8000):
    server_address = ('0.0.0.0', port)  # <-- 0.0.0.0 listens on ALL interfaces (LAN included)
    httpd = server_class(server_address, handler_class)

    # Create an SSLContext
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile='server.pem')

    # Wrap the server socket
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    print(f'Starting HTTPS server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
