#!/bin/bash
# Startup script for Stocky Docker deployment

set -e

echo "🚀 Starting Stocky Application..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose found${NC}"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found, creating from .env.example${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env file with your configuration${NC}"
    else
        echo -e "${RED}❌ .env.example not found${NC}"
        exit 1
    fi
fi

# Determine environment
ENV=${1:-prod}

if [ "$ENV" == "dev" ]; then
    echo -e "${GREEN}📦 Starting in DEVELOPMENT mode with hot-reload${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
else
    echo -e "${GREEN}📦 Starting in PRODUCTION mode${NC}"
    docker-compose up -d
fi

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"

sleep 10

# Check PostgreSQL
echo -n "Checking PostgreSQL..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U stockyuser -d stockydb > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Check API
echo -n "Checking API..."
for i in {1..30}; do
    if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Check Web
echo -n "Checking Frontend..."
for i in {1..30}; do
    if curl -f http://localhost/ > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "${GREEN}✅ Stocky Application is now running!${NC}"
echo ""
echo -e "${GREEN}🌐 Access the application at:${NC}"

if [ "$ENV" == "dev" ]; then
    echo -e "  Frontend (dev):  ${YELLOW}http://localhost:4200${NC}"
else
    echo -e "  Frontend:        ${YELLOW}http://localhost${NC}"
fi

echo -e "  API:             ${YELLOW}http://localhost:8080${NC}"
echo -e "  PgAdmin:         ${YELLOW}http://localhost:5050${NC}"
echo -e "  Database:        ${YELLOW}localhost:5432${NC}"

echo ""
echo -e "${YELLOW}📋 Useful commands:${NC}"
echo "  View logs:       docker-compose logs -f"
echo "  Stop services:   docker-compose down"
echo "  Restart API:     docker-compose restart stocky-api"
echo "  DB shell:        docker-compose exec postgres psql -U stockyuser -d stockydb"

echo ""
echo -e "${GREEN}✨ Done!${NC}"
