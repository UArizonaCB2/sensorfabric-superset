"""Gunicorn configuration file for Superset production deployment."""
import multiprocessing
import os

# Server socket
bind = "0.0.0.0:8088"
backlog = 2048

# Worker processes
workers = int(os.getenv("GUNICORN_WORKERS", multiprocessing.cpu_count() * 2 + 1))
worker_class = "gthread"
threads = int(os.getenv("GUNICORN_THREADS", 4))
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = int(os.getenv("GUNICORN_TIMEOUT", 300))
graceful_timeout = 30
keepalive = 5

# Security
limit_request_line = 0
limit_request_fields = 100
limit_request_field_size = 0

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# Logging
accesslog = "-"  # Log to stdout
errorlog = "-"   # Log to stderr
loglevel = os.getenv("GUNICORN_LOG_LEVEL", "info")
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "superset"

# Server hooks
def pre_request(worker, req):
    """Log when a request is received."""
    worker.log.debug("%s %s" % (req.method, req.path))

def post_request(worker, req, environ, resp):
    """Log after request is processed."""
    pass

def worker_int(worker):
    """Handle worker interruption."""
    worker.log.info("Worker received INT or QUIT signal")

def worker_abort(worker):
    """Handle worker abort."""
    worker.log.info("Worker received SIGABRT signal")
