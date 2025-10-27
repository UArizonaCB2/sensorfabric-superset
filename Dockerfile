FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-pip \
    libsasl2-dev \
    libldap2-dev \
    default-libmysqlclient-dev \
    curl \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.11 python3.11-dev python3.11-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Install pip for Python 3.11
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Remove system-installed packages that conflict with requirements
RUN apt-get remove -y python3-blinker || true

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy Superset configuration
COPY superset_config.py .
COPY gunicorn_config.py .

# Set Superset config path
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# Set Flask app
ENV FLASK_APP=superset

# Set Superset home directory for database storage
ENV SUPERSET_HOME=/app/superset_home

# Copy entrypoint script
COPY entry.sh /app/entry.sh
RUN chmod +x /app/entry.sh

# Create volume for persistent database storage
VOLUME ["/app/superset_home"]

# Expose Superset port
EXPOSE 8088

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8088/health || exit 1

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=

# Set entrypoint
ENTRYPOINT ["/app/entry.sh"]
