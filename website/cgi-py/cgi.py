
#!/usr/bin/env python3

import os
import sys
import json
import html
from datetime import datetime
from urllib.parse import parse_qs

method = os.environ.get("REQUEST_METHOD", "UNKNOWN")
uri = os.environ.get("REQUEST_URI", os.environ.get("SCRIPT_NAME", "/"))
path = os.environ.get("PATH_INFO", "")
query_string = os.environ.get("QUERY_STRING", "")
protocol = os.environ.get("SERVER_PROTOCOL", "UNKNOWN")
server_name = os.environ.get("SERVER_NAME", "UNKNOWN")
server_port = os.environ.get("SERVER_PORT", "UNKNOWN")
remote_addr = os.environ.get("REMOTE_ADDR", "UNKNOWN")
remote_host = os.environ.get("REMOTE_HOST", "UNKNOWN")
user_agent = os.environ.get("HTTP_USER_AGENT", "UNKNOWN")
content_type = os.environ.get("CONTENT_TYPE", "None")
content_length = os.environ.get("CONTENT_LENGTH", "0")

# Request body
body = ""
if method in ("POST", "PUT", "PATCH"):
    try:
        length = min(int(content_length or 0), 1024 * 1024)
        body = sys.stdin.read(length)
    except (ValueError, OSError):
        body = ""

query = parse_qs(query_string, keep_blank_values=True)

# CGI environment headers
headers = {
    key: value
    for key, value in os.environ.items()
    if key.startswith("HTTP_")
}

def pretty(value):
    return html.escape(json.dumps(value, indent=2, ensure_ascii=False))

def safe(value):
    return html.escape(str(value))

print("Content-Type: text/html; charset=utf-8")
print()

print(f"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Python CGI Inspector</title>
<style>
* {{ box-sizing: border-box; }}
body {{
    margin: 0;
    padding: 35px;
    background: #0b1020;
    color: #e2e8f0;
    font-family: Arial, sans-serif;
}}
main {{ max-width: 1050px; margin: auto; }}
h1 {{ margin-bottom: 8px; }}
.subtitle {{ color: #94a3b8; margin-bottom: 25px; }}
.badge {{
    display: inline-block;
    padding: 8px 13px;
    border-radius: 7px;
    background: #064e3b;
    color: #4ade80;
    font-size: 13px;
    font-weight: bold;
}}
.card {{
    background: #151e30;
    border: 1px solid #29364c;
    padding: 22px;
    border-radius: 12px;
    margin-bottom: 17px;
}}
.label {{
    font-size: 11px;
    color: #94a3b8;
    text-transform: uppercase;
    margin-bottom: 10px;
}}
.method {{
    font-size: 25px;
    font-weight: bold;
    color: #4ade80;
}}
.url {{ font-size: 17px; overflow-wrap: anywhere; }}
.grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 17px;
}}
pre {{
    margin: 0;
    padding: 15px;
    border-radius: 8px;
    background: #090e19;
    color: #a5f3fc;
    overflow: auto;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    font-size: 13px;
    line-height: 1.6;
}}
.footer {{
    color: #64748b;
    text-align: center;
    margin-top: 25px;
    font-size: 12px;
}}
@media(max-width:650px) {{
    body {{ padding: 15px; }}
    .grid {{ grid-template-columns: 1fr; }}
}}
</style>
</head>
<body>
<main>

<h1>🐍 Python CGI Inspector</h1>
<div class="subtitle">HTTP Request Information Dashboard</div>

<div class="card">
    <span class="badge">● RUNNING VIA CGI-BIN</span>
    <p class="label" style="margin-top:22px">Request Method</p>
    <div class="method">{safe(method)}</div>
    <p class="label" style="margin-top:22px">Request URI</p>
    <div class="url">{safe(uri)}</div>
</div>

<div class="grid">
    <div class="card">
        <div class="label">Server Information</div>
        <pre>{pretty({
            "Server": server_name,
            "Port": server_port,
            "Protocol": protocol,
            "Script": os.environ.get("SCRIPT_FILENAME", "Unknown"),
            "CGI": "Python CGI"
        })}</pre>
    </div>

    <div class="card">
        <div class="label">Client Information</div>
        <pre>{pretty({
            "IP Address": remote_addr,
            "Remote Host": remote_host,
            "User Agent": user_agent,
            "Time": datetime.now().astimezone().isoformat()
        })}</pre>
    </div>
</div>

<div class="card">
    <div class="label">Query Parameters</div>
    <pre>{pretty(query)}</pre>
</div>

<div class="card">
    <div class="label">Request Headers</div>
    <pre>{pretty(headers)}</pre>
</div>

<div class="card">
    <div class="label">Request Body</div>
    <pre>{safe(body) if body else "No request body received."}</pre>
</div>

<div class="card">
    <div class="label">CGI Environment</div>
    <pre>{pretty({
        "REQUEST_METHOD": method,
        "REQUEST_URI": uri,
        "SCRIPT_NAME": os.environ.get("SCRIPT_NAME"),
        "PATH_INFO": path,
        "QUERY_STRING": query_string,
        "CONTENT_TYPE": content_type,
        "CONTENT_LENGTH": content_length,
        "GATEWAY_INTERFACE": os.environ.get("GATEWAY_INTERFACE")
    })}</pre>
</div>

<div class="footer">
    Python {safe(sys.version.split()[0])} · CGI-BIN Execution · Request Inspector
</div>

</main>
</body>
</html>""")
