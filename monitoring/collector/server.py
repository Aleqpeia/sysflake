#!/usr/bin/env python3
"""
Status collector server for syscfg monitoring.
Receives status.json from machines and exposes Prometheus metrics.
"""

import json
import os
from pathlib import Path
from datetime import datetime, timezone
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import threading

DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)

# In-memory store for latest status from each host
status_store = {}
status_lock = threading.Lock()


class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        
        if path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
        
        elif path == "/metrics":
            # Prometheus metrics endpoint
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            
            metrics = self.generate_metrics()
            self.wfile.write(metrics.encode())
        
        elif path == "/status":
            # Return all status data as JSON
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            
            with status_lock:
                self.wfile.write(json.dumps(status_store, indent=2).encode())
        
        elif path.startswith("/status/"):
            # Return status for specific host
            hostname = path.split("/")[-1]
            
            with status_lock:
                if hostname in status_store:
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps(status_store[hostname], indent=2).encode())
                else:
                    self.send_response(404)
                    self.end_headers()
        
        else:
            # Dashboard
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(self.generate_dashboard().encode())
    
    def do_POST(self):
        path = urlparse(self.path).path
        
        if path == "/status":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            
            try:
                data = json.loads(body)
                hostname = data.get("hostname", "unknown")
                
                # Add receive timestamp
                data["received_at"] = datetime.now(timezone.utc).isoformat()
                
                # Store in memory
                with status_lock:
                    status_store[hostname] = data
                
                # Persist to disk
                status_file = DATA_DIR / f"{hostname}.json"
                with open(status_file, "w") as f:
                    json.dump(data, f, indent=2)
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "ok"}')
                
                print(f"Received status from {hostname}")
                
            except json.JSONDecodeError:
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()
    
    def generate_metrics(self) -> str:
        """Generate Prometheus metrics from status store."""
        lines = [
            "# HELP syscfg_host_up Whether the host has reported status recently",
            "# TYPE syscfg_host_up gauge",
        ]
        
        now = datetime.now(timezone.utc)
        
        with status_lock:
            for hostname, data in status_store.items():
                # Check if status is recent (within last hour)
                received = data.get("received_at", "")
                try:
                    received_dt = datetime.fromisoformat(received.replace("Z", "+00:00"))
                    age_seconds = (now - received_dt).total_seconds()
                    up = 1 if age_seconds < 3600 else 0
                except:
                    up = 0
                
                lines.append(f'syscfg_host_up{{hostname="{hostname}"}} {up}')
        
        lines.extend([
            "",
            "# HELP syscfg_gpg_keys_total Number of GPG keys",
            "# TYPE syscfg_gpg_keys_total gauge",
        ])
        
        with status_lock:
            for hostname, data in status_store.items():
                gpg = data.get("gpg_keys", {})
                shared = gpg.get("shared", 0)
                local = gpg.get("local", 0)
                lines.append(f'syscfg_gpg_keys_total{{hostname="{hostname}",scope="shared"}} {shared}')
                lines.append(f'syscfg_gpg_keys_total{{hostname="{hostname}",scope="local"}} {local}')
        
        lines.extend([
            "",
            "# HELP syscfg_ssh_keys_total Number of SSH keys",
            "# TYPE syscfg_ssh_keys_total gauge",
        ])
        
        with status_lock:
            for hostname, data in status_store.items():
                ssh = data.get("ssh_keys", {})
                shared = ssh.get("shared", 0)
                local = ssh.get("local", 0)
                lines.append(f'syscfg_ssh_keys_total{{hostname="{hostname}",scope="shared"}} {shared}')
                lines.append(f'syscfg_ssh_keys_total{{hostname="{hostname}",scope="local"}} {local}')
        
        lines.extend([
            "",
            "# HELP syscfg_devenv_projects_total Number of devenv projects",
            "# TYPE syscfg_devenv_projects_total gauge",
        ])
        
        with status_lock:
            for hostname, data in status_store.items():
                projects = data.get("devenv_projects", 0)
                lines.append(f'syscfg_devenv_projects_total{{hostname="{hostname}"}} {projects}')
        
        lines.extend([
            "",
            "# HELP syscfg_service_status Service status (1=ok, 0=error)",
            "# TYPE syscfg_service_status gauge",
        ])
        
        with status_lock:
            for hostname, data in status_store.items():
                services = data.get("services", {})
                for svc_name, svc_info in services.items():
                    status = svc_info.get("last_status", "unknown")
                    value = 1 if status in ["success", "clean"] else 0
                    lines.append(f'syscfg_service_status{{hostname="{hostname}",service="{svc_name}"}} {value}')
        
        return "\n".join(lines) + "\n"
    
    def generate_dashboard(self) -> str:
        """Generate simple HTML dashboard."""
        html = """<!DOCTYPE html>
<html>
<head>
    <title>Syscfg Status</title>
    <meta http-equiv="refresh" content="60">
    <style>
        body { font-family: -apple-system, sans-serif; margin: 2em; background: #1a1a2e; color: #eee; }
        h1 { color: #0f3460; }
        .host { background: #16213e; padding: 1em; margin: 1em 0; border-radius: 8px; }
        .host h2 { margin: 0 0 0.5em 0; color: #e94560; }
        .metric { display: inline-block; margin-right: 2em; }
        .metric .label { color: #888; font-size: 0.8em; }
        .metric .value { font-size: 1.5em; font-weight: bold; }
        .ok { color: #4ecca3; }
        .warn { color: #ffc107; }
        .error { color: #e94560; }
        .stale { opacity: 0.5; }
    </style>
</head>
<body>
    <h1>Syscfg Status Dashboard</h1>
"""
        
        with status_lock:
            if not status_store:
                html += "<p>No hosts reporting yet.</p>"
            else:
                for hostname, data in sorted(status_store.items()):
                    # Check freshness
                    received = data.get("received_at", "")
                    fresh = True
                    try:
                        received_dt = datetime.fromisoformat(received.replace("Z", "+00:00"))
                        age = (datetime.now(timezone.utc) - received_dt).total_seconds()
                        fresh = age < 3600
                    except:
                        fresh = False
                    
                    stale_class = "" if fresh else "stale"
                    
                    gpg = data.get("gpg_keys", {})
                    ssh = data.get("ssh_keys", {})
                    devenv = data.get("devenv_projects", 0)
                    services = data.get("services", {})
                    
                    html += f"""
    <div class="host {stale_class}">
        <h2>{hostname}</h2>
        <div class="metric">
            <div class="label">GPG Keys</div>
            <div class="value">{gpg.get('shared', 0)} / {gpg.get('local', 0)}</div>
        </div>
        <div class="metric">
            <div class="label">SSH Keys</div>
            <div class="value">{ssh.get('shared', 0)} / {ssh.get('local', 0)}</div>
        </div>
        <div class="metric">
            <div class="label">Devenvs</div>
            <div class="value">{devenv}</div>
        </div>
"""
                    
                    for svc_name, svc_info in services.items():
                        status = svc_info.get("last_status", "unknown")
                        status_class = "ok" if status in ["success", "clean"] else "error"
                        html += f"""
        <div class="metric">
            <div class="label">{svc_name}</div>
            <div class="value {status_class}">{status}</div>
        </div>
"""
                    
                    html += f"""
        <div class="metric">
            <div class="label">Last seen</div>
            <div class="value" style="font-size: 0.9em;">{received[:19] if received else 'never'}</div>
        </div>
    </div>
"""
        
        html += """
    <p><a href="/metrics">Prometheus metrics</a> | <a href="/status">JSON API</a></p>
</body>
</html>"""
        
        return html
    
    def log_message(self, format, *args):
        print(f"{datetime.now().isoformat()} - {args[0]}")


def load_persisted_status():
    """Load persisted status files on startup."""
    for status_file in DATA_DIR.glob("*.json"):
        try:
            with open(status_file) as f:
                data = json.load(f)
                hostname = data.get("hostname", status_file.stem)
                with status_lock:
                    status_store[hostname] = data
                print(f"Loaded persisted status for {hostname}")
        except Exception as e:
            print(f"Error loading {status_file}: {e}")


if __name__ == "__main__":
    load_persisted_status()
    
    port = int(os.environ.get("PORT", 8080))
    server = HTTPServer(("0.0.0.0", port), StatusHandler)
    print(f"Status collector listening on port {port}")
    print(f"  Dashboard: http://localhost:{port}/")
    print(f"  Metrics:   http://localhost:{port}/metrics")
    print(f"  API:       http://localhost:{port}/status")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()
