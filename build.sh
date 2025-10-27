#!/bin/bash
set -e

# Configuration
IMAGE_NAME="superset-base"
IMAGE_TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

# Parse command line arguments
PUSH=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --push              Push image to registry after build"
            echo "  --tag TAG           Set image tag (default: latest)"
            echo "  --name NAME         Set image name (default: superset-base)"
            echo "  --platforms PLAT    Set platforms (default: linux/amd64,linux/arm64)"
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

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Platforms: ${PLATFORMS}"

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo "Error: docker buildx is not available"
    echo "Please install Docker with buildx support"
    exit 1
fi

# Create builder instance if it doesn't exist
BUILDER_NAME="superset-builder"
if ! docker buildx inspect ${BUILDER_NAME} &> /dev/null; then
    echo "Creating new buildx builder: ${BUILDER_NAME}"
    docker buildx create --name ${BUILDER_NAME} --use
else
    echo "Using existing buildx builder: ${BUILDER_NAME}"
    docker buildx use ${BUILDER_NAME}
fi

# Build command
BUILD_CMD="docker buildx build"
BUILD_CMD+=" --platform ${PLATFORMS}"
BUILD_CMD+=" -t ${IMAGE_NAME}:${IMAGE_TAG}"

if [ "$PUSH" = true ]; then
    BUILD_CMD+=" --push"
    echo "Image will be pushed to registry"
else
    BUILD_CMD+=" --load"
    echo "Image will be loaded locally (single platform only)"
    # When loading locally, only build for current platform
    CURRENT_ARCH=$(uname -m)
    if [ "$CURRENT_ARCH" = "x86_64" ]; then
        PLATFORMS="linux/amd64"
    elif [ "$CURRENT_ARCH" = "aarch64" ] || [ "$CURRENT_ARCH" = "arm64" ]; then
        PLATFORMS="linux/arm64"
    fi
    BUILD_CMD="docker buildx build --platform ${PLATFORMS} -t ${IMAGE_NAME}:${IMAGE_TAG} --load"
fi

BUILD_CMD+=" ."

# Execute build
echo "Executing: ${BUILD_CMD}"
eval ${BUILD_CMD}

echo "Build completed successfully!"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
