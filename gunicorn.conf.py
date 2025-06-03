import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Log environment variables
logger.info("Environment variables:")
for key, value in os.environ.items():
    logger.info(f"{key}: {value}")

# Get port from environment
port = os.getenv('PORT', '8000')
logger.info(f"Using port: {port}")

# Gunicorn config
bind = f"0.0.0.0:{port}"
workers = 4
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"

# SSL and proxy settings
forwarded_allow_ips = "*"
proxy_protocol = True
proxy_allow_from = "*"

# Capture output for better logging
capture_output = True
enable_stdio_inheritance = True

# Worker settings
max_requests = 1000
max_requests_jitter = 50
worker_tmp_dir = "/dev/shm"

# Preload app
preload_app = True

def on_starting(server):
    logger.info("Starting Gunicorn server...")
    logger.info(f"Binding to: {bind}")
    logger.info(f"Number of workers: {workers}")
    logger.info(f"Worker class: {worker_class}")
    logger.info(f"Worker connections: {worker_connections}")
    logger.info(f"Timeout: {timeout}")
    logger.info(f"Keepalive: {keepalive}")
    logger.info(f"Forwarded allow ips: {forwarded_allow_ips}")
    logger.info(f"Proxy protocol: {proxy_protocol}")
    logger.info(f"Proxy allow from: {proxy_allow_from}")
    logger.info(f"Capture output: {capture_output}")
    logger.info(f"Enable stdio inheritance: {enable_stdio_inheritance}")
    logger.info(f"Max requests: {max_requests}")
    logger.info(f"Max requests jitter: {max_requests_jitter}")
    logger.info(f"Worker tmp dir: {worker_tmp_dir}")
    logger.info(f"Preload app: {preload_app}")

def on_exit(server):
    logger.info("Shutting down Gunicorn server...") 