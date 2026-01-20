#!/bin/bash
# Cleanup script for Stocky Docker deployment

set -e

echo "🧹 Cleaning up Stocky Docker resources..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Stop containers
echo -e "${YELLOW}Stopping containers...${NC}"
docker-compose down

# Remove volumes (optional)
read -p "Do you want to remove all volumes (database will be deleted)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing volumes...${NC}"
    docker-compose down -v
    echo -e "${GREEN}✓ Volumes removed${NC}"
fi

# Remove images (optional)
read -p "Do you want to remove Docker images? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing images...${NC}"
    docker rmi stocky_stocky-api:latest stocky_stocky-web:latest || true
    echo -e "${GREEN}✓ Images removed${NC}"
fi

# Prune unused resources
read -p "Do you want to prune unused Docker resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Pruning resources...${NC}"
    docker image prune -a --force
    docker system prune -a --force
    echo -e "${GREEN}✓ Resources pruned${NC}"
fi

echo -e "${GREEN}✅ Cleanup complete!${NC}"
