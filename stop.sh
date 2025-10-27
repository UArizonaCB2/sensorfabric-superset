#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="superset"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "This script safely stops the Superset container."
            echo ""
            echo "Options:"
            echo "  --name NAME         Container name (default: superset)"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
    echo "Container stopped successfully!"
elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} is already stopped"
else
    echo "Container ${CONTAINER_NAME} does not exist"
    exit 1
fi
