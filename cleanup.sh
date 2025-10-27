#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="superset"
VOLUME_NAME="superset_data"

# Parse command line arguments
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --volume)
            VOLUME_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "This script stops and removes the Superset container and deletes the database volume."
            echo "Use this to wipe your Superset database and start fresh."
            echo ""
            echo "Options:"
            echo "  --name NAME         Container name (default: superset)"
            echo "  --volume VOL        Volume name (default: superset_data)"
            echo "  -f, --force         Skip confirmation prompt"
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

echo "======================================"
echo "Superset Database Cleanup"
echo "======================================"
echo ""
echo "This will:"
echo "  1. Stop container: ${CONTAINER_NAME}"
echo "  2. Remove container: ${CONTAINER_NAME}"
echo "  3. Delete volume: ${VOLUME_NAME}"
echo ""
echo "WARNING: All data in the Superset database will be lost!"
echo ""

# Ask for confirmation unless force flag is set
if [ "$FORCE" = false ]; then
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
fi

# Stop container if running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
else
    echo "Container ${CONTAINER_NAME} is not running"
fi

# Remove container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing container: ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
else
    echo "Container ${CONTAINER_NAME} does not exist"
fi

# Remove volume if exists
if docker volume inspect ${VOLUME_NAME} &> /dev/null; then
    echo "Removing volume: ${VOLUME_NAME}"
    docker volume rm ${VOLUME_NAME}
    echo "Volume ${VOLUME_NAME} removed successfully"
else
    echo "Volume ${VOLUME_NAME} does not exist"
fi

echo ""
echo "======================================"
echo "Cleanup completed successfully!"
echo "======================================"
echo ""
echo "To start fresh, run: ./run.sh -d"
