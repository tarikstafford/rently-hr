import os
import sys

# Debug logging
print(f"Environment variables: {dict(os.environ)}", file=sys.stderr)
print(f"PORT from env: {os.getenv('PORT')}", file=sys.stderr)

# Server socket
# Railway sets PORT=8080, but we need to use the TCP proxy port
port = os.getenv('RAILWAY_TCP_PROXY_PORT', os.getenv('PORT', '8000'))
print(f"Using port: {port}", file=sys.stderr)
bind = f"0.0.0.0:{port}"
backlog = 2048

# Worker processes
workers = 2
worker_class = 'sync'
worker_connections = 1000
timeout = 120
keepalive = 2

# Logging
accesslog = '-'
errorlog = '-'
loglevel = 'debug'

# Process naming
proc_name = 'horilla'

# SSL
forwarded_allow_ips = '*'
secure_scheme_headers = {
    'X-FORWARDED-PROTOCOL': 'ssl',
    'X-FORWARDED-PROTO': 'https',
    'X-FORWARDED-SSL': 'on'
}

# Proxy
proxy_protocol = True
proxy_allow_from = '*'

# Debug mode
capture_output = True
enable_stdio_inheritance = True 