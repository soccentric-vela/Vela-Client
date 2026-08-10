#!/bin/bash
set -e

# Vela-Client Development Run Script
# Creates necessary directories and runs the client with development config

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Vela-Client Development Run ===${NC}"

# Kill any existing vela-client processes
echo -e "${BLUE}Checking for existing vela-client processes...${NC}"
if pgrep -x "vela-client" > /dev/null; then
    echo -e "${YELLOW}Found running vela-client process(es). Terminating...${NC}"
    pkill -SIGTERM vela-client || true
    sleep 1
    
    # Force kill if still running
    if pgrep -x "vela-client" > /dev/null; then
        echo -e "${YELLOW}Process still running, force killing...${NC}"
        pkill -SIGKILL vela-client || true
        sleep 1
    fi
    echo -e "${GREEN}✓ All vela-client processes terminated${NC}"
else
    echo -e "${GREEN}✓ No existing processes found${NC}"
fi

# Clean up stale socket files and locks
echo -e "${BLUE}Cleaning up stale sockets and locks...${NC}"
rm -f /tmp/vela-diag.sock 2>/dev/null || true
rm -f ./data/spool/spool.db-shm 2>/dev/null || true
rm -f ./data/spool/spool.db-wal 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Create necessary directories
echo -e "${BLUE}Creating required directories...${NC}"
mkdir -p ./data/spool
mkdir -p ./data/logs
mkdir -p /tmp/vela 2>/dev/null || true
echo -e "${GREEN}✓ Directories ready${NC}"

# Check if binary exists
if [ ! -f "./build/bin/vela-client" ]; then
    echo -e "${RED}ERROR: Binary not found at ./build/bin/vela-client${NC}"
    echo "Please build the project first:"
    echo "  make build"
    echo "  OR: cd build && cmake --build . --parallel"
    exit 1
fi

# Check if dev config exists
if [ ! -f "./conf/client.conf.dev" ]; then
    echo -e "${RED}ERROR: Development config not found at ./conf/client.conf.dev${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Starting vela-client with debug logging...${NC}"
echo "Config: ./conf/client.conf.dev"
echo "Spool:  ./data/spool/spool.db"
echo "Press Ctrl+C to stop"
echo ""

# Set up trap to clean up on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Caught signal, cleaning up...${NC}"
    pkill -SIGTERM vela-client 2>/dev/null || true
    sleep 1
    rm -f /tmp/vela-diag.sock 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Run with debug logging
SPDLOG_LEVEL=debug ./build/bin/vela-client --config ./conf/client.conf.dev