#!/bin/bash
#
# Fix OpenSensor Space user configuration
# This script fixes systemd services to use the correct username
# Run this if you see "Failed to determine user credentials" errors
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Get the actual username
CURRENT_USER="${SUDO_USER:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================="
echo " OpenSensor Space - User Fix Script"
echo "========================================="
echo

print_info "Current user detected: $CURRENT_USER"
print_info "Project root: $PROJECT_ROOT"
echo

# Check if services exist
if [ ! -f "/etc/systemd/system/opensensor-space.service" ]; then
    print_error "opensensor-space.service not found. Please run install-opensensor-space.sh first."
    exit 1
fi

# Stop services
print_info "Stopping services..."
sudo systemctl stop opensensor-space.service 2>/dev/null || true
sudo systemctl stop opensensor-sync.timer 2>/dev/null || true
sudo systemctl stop opensensor-sync.service 2>/dev/null || true
print_success "Services stopped"

# Fix data collection service
print_info "Fixing opensensor-space.service..."
sed -e "s|/home/pi/enviroplus-python|$PROJECT_ROOT|g" \
    -e "s|User=pi|User=$CURRENT_USER|g" \
    -e "s|Group=pi|Group=$CURRENT_USER|g" \
    "$SCRIPT_DIR/systemd/opensensor_space_systemd.service" | sudo tee /etc/systemd/system/opensensor-space.service > /dev/null
print_success "opensensor-space.service fixed"

# Fix sync service if it exists
if [ -f "$SCRIPT_DIR/systemd/sync_timer.service" ]; then
    print_info "Fixing opensensor-sync.service..."
    sed -e "s|/home/pi/enviroplus-python|$PROJECT_ROOT|g" \
        -e "s|User=pi|User=$CURRENT_USER|g" \
        -e "s|Group=pi|Group=$CURRENT_USER|g" \
        "$SCRIPT_DIR/systemd/sync_timer.service" | sudo tee /etc/systemd/system/opensensor-sync.service > /dev/null
    print_success "opensensor-sync.service fixed"
fi

# Reload systemd
print_info "Reloading systemd..."
sudo systemctl daemon-reload
print_success "Systemd reloaded"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"
print_success "Logs directory created"

# Restart services
print_info "Starting opensensor-space.service..."
sudo systemctl start opensensor-space.service
sleep 2

# Check status
if sudo systemctl is-active --quiet opensensor-space.service; then
    print_success "opensensor-space.service is running!"
else
    print_error "opensensor-space.service failed to start"
    echo
    print_info "Checking logs..."
    sudo journalctl -u opensensor-space.service -n 20 --no-pager
    exit 1
fi

# Start sync timer if it exists
if [ -f "/etc/systemd/system/opensensor-sync.timer" ]; then
    print_info "Starting opensensor-sync.timer..."
    sudo systemctl start opensensor-sync.timer

    if sudo systemctl is-active --quiet opensensor-sync.timer; then
        print_success "opensensor-sync.timer is running!"
    else
        print_warning "opensensor-sync.timer failed to start"
    fi
fi

echo
echo "========================================="
print_success "Fix completed successfully!"
echo "========================================="
echo

print_info "Service status:"
sudo systemctl status opensensor-space.service --no-pager -l | head -10
echo

print_info "Monitor logs with:"
echo "  tail -f $PROJECT_ROOT/logs/opensensor_space.log"
echo

print_info "Check data output:"
echo "  ls -lR $PROJECT_ROOT/output/"
