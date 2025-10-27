#!/bin/bash
set -e

# Configuration
ENV_FILE=".env"
BUILD=false
DETACH=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD=true
            shift
            ;;
        --no-detach)
            DETACH=false
            shift
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Start the Superset production stack with Docker Compose"
            echo ""
            echo "Options:"
            echo "  --build             Build images before starting"
            echo "  --no-detach         Run in foreground (default: background)"
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

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found"
    echo ""
    echo "Please create a .env file from .env.example:"
    echo "  cp .env.example .env"
    echo ""
    echo "Then edit .env and set your values, especially:"
    echo "  - SECRET_KEY (generate with: openssl rand -base64 42)"
    echo "  - ADMIN_USERNAME, ADMIN_PASSWORD, etc."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: docker-compose not found"
    echo "Please install Docker Compose"
    exit 1
fi

# Use 'docker compose' or 'docker-compose' based on availability
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "======================================"
echo "Starting Superset Production Stack"
echo "======================================"
echo ""
echo "Services:"
echo "  - Redis (caching & async tasks)"
echo "  - Superset (application)"
echo "  - Nginx (reverse proxy)"
echo ""

# Build command
CMD="$COMPOSE_CMD"

if [ "$BUILD" = true ]; then
    echo "Building images..."
    $CMD build
    echo ""
fi

# Start services
echo "Starting services..."
if [ "$DETACH" = true ]; then
    $CMD up -d
else
    $CMD up
fi

if [ "$DETACH" = true ]; then
    echo ""
    echo "======================================"
    echo "Services started successfully!"
    echo "======================================"
    echo ""
    echo "Access Superset at: http://localhost:${NGINX_PORT:-80}"
    echo ""
    echo "Useful commands:"
    echo "  View logs:        $COMPOSE_CMD logs -f"
    echo "  View status:      $COMPOSE_CMD ps"
    echo "  Stop services:    ./down.sh"
    echo "  Restart:          $COMPOSE_CMD restart"
    echo ""
    echo "Service-specific logs:"
    echo "  Superset:         $COMPOSE_CMD logs -f superset"
    echo "  Redis:            $COMPOSE_CMD logs -f redis"
    echo "  Nginx:            $COMPOSE_CMD logs -f nginx"
fi
