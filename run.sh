#!/bin/bash
set -e

# Configuration
IMAGE_NAME="superset-base"
IMAGE_TAG="latest"
CONTAINER_NAME="superset"
VOLUME_NAME="superset_data"
PORT="8088"

# Parse command line arguments
DETACH=false
REMOVE=false
ENV_FILE=".env"

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--detach)
            DETACH=true
            shift
            ;;
        --rm)
            REMOVE=true
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --volume)
            VOLUME_NAME="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --detach        Run container in background"
            echo "  --rm                Remove container when it exits"
            echo "  --port PORT         Port to expose (default: 8088)"
            echo "  --name NAME         Container name (default: superset)"
            echo "  --image IMAGE       Image name (default: superset-base)"
            echo "  --tag TAG           Image tag (default: latest)"
            echo "  --volume VOL        Volume name (default: superset_data)"
            echo "  --env-file FILE     Environment file (default: .env)"
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

# Check if image exists
if ! docker image inspect ${IMAGE_NAME}:${IMAGE_TAG} &> /dev/null; then
    echo "Error: Image ${IMAGE_NAME}:${IMAGE_TAG} not found"
    echo "Please build the image first using ./build.sh"
    exit 1
fi

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Warning: Environment file $ENV_FILE not found"
    echo "Container will run without custom environment variables"
    ENV_FILE_ARG=""
else
    ENV_FILE_ARG="--env-file $ENV_FILE"
fi

# Check if container is already running
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} already exists"
    read -p "Do you want to remove it and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing container..."
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    else
        echo "Exiting without changes"
        exit 0
    fi
fi

# Create volume if it doesn't exist
if ! docker volume inspect ${VOLUME_NAME} &> /dev/null; then
    echo "Creating volume: ${VOLUME_NAME}"
    docker volume create ${VOLUME_NAME}
fi

# Build docker run command
RUN_CMD="docker run"

if [ "$DETACH" = true ]; then
    RUN_CMD+=" -d"
else
    RUN_CMD+=" -it"
fi

if [ "$REMOVE" = true ]; then
    RUN_CMD+=" --rm"
fi

RUN_CMD+=" --name ${CONTAINER_NAME}"
RUN_CMD+=" -p ${PORT}:8088"
RUN_CMD+=" -v ${VOLUME_NAME}:/app/superset_home"

if [ -n "$ENV_FILE_ARG" ]; then
    RUN_CMD+=" ${ENV_FILE_ARG}"
fi

# Add default admin credentials if not in env file
if [ -f "$ENV_FILE" ] && ! grep -q "ADMIN_USERNAME" "$ENV_FILE"; then
    RUN_CMD+=" -e ADMIN_USERNAME=admin"
    RUN_CMD+=" -e ADMIN_FIRSTNAME=Admin"
    RUN_CMD+=" -e ADMIN_LASTNAME=User"
    RUN_CMD+=" -e ADMIN_EMAIL=admin@superset.com"
    RUN_CMD+=" -e ADMIN_PASSWORD=admin"
    echo "Using default admin credentials (username: admin, password: admin)"
fi

RUN_CMD+=" ${IMAGE_NAME}:${IMAGE_TAG}"

# Execute run command
echo "Starting Superset container..."
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Container name: ${CONTAINER_NAME}"
echo "Port: ${PORT}"
echo "Volume: ${VOLUME_NAME}"
echo ""
eval ${RUN_CMD}

if [ "$DETACH" = true ]; then
    echo ""
    echo "Container started successfully!"
    echo "Access Superset at: http://localhost:${PORT}"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker logs -f ${CONTAINER_NAME}"
    echo "  Stop:         docker stop ${CONTAINER_NAME}"
    echo "  Start:        docker start ${CONTAINER_NAME}"
    echo "  Remove:       docker rm ${CONTAINER_NAME}"
else
    echo ""
    echo "Container stopped"
fi
