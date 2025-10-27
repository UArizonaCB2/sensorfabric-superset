#!/bin/bash
set -e

# Initialize the database
superset db upgrade

# Create admin user if it doesn't exist
superset fab create-admin \
    --username "${ADMIN_USERNAME}" \
    --firstname "${ADMIN_FIRSTNAME}" \
    --lastname "${ADMIN_LASTNAME}" \
    --email "${ADMIN_EMAIL}" \
    --password "${ADMIN_PASSWORD}" || true

# Initialize Superset
superset init

# Start Superset with Gunicorn
gunicorn \
    --config /app/gunicorn_config.py \
    --bind 0.0.0.0:8088 \
    "superset.app:create_app()"
