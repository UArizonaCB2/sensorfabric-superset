#!/bin/bash
set -e

# Configuration
REMOVE_VOLUMES=false
REMOVE_IMAGES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --images)
            REMOVE_IMAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Stop the Superset production stack"
            echo ""
            echo "Options:"
            echo "  -v, --volumes       Remove named volumes (WARNING: deletes data!)"
            echo "  --images            Remove images"
            echo "  --help              Show this help message"
            echo ""
            echo "Note: Use --volumes with caution as it will delete all data!"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
echo "Stopping Superset Production Stack"
echo "======================================"
echo ""

# Warn about volume removal
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "WARNING: You are about to remove volumes!"
    echo "This will delete all data including:"
    echo "  - Superset database"
    echo "  - Redis data"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
fi

# Stop services
echo "Stopping services..."
$COMPOSE_CMD down

# Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "Removing volumes..."
    $COMPOSE_CMD down -v
fi

# Remove images if requested
if [ "$REMOVE_IMAGES" = true ]; then
    echo "Removing images..."
    $COMPOSE_CMD down --rmi all
fi

echo ""
echo "======================================"
echo "Services stopped successfully!"
echo "======================================"
echo ""

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "All data has been removed."
    echo "To start fresh, run: ./up.sh --build"
else
    echo "Data has been preserved."
    echo "To start again, run: ./up.sh"
fi
