#!/bin/bash

# Flash Meshtastic firmware to ThinkNode M3
# This script automates the firmware flashing process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}ThinkNode M3 Firmware Flasher${NC}"
echo "=================================="
echo ""

# Check if meshtastic CLI is installed
if ! command -v meshtastic &> /dev/null; then
    echo -e "${YELLOW}Meshtastic CLI not found. Installing...${NC}"
    pip3 install --upgrade meshtastic
fi

# Check for firmware file
FIRMWARE_DIR="$HOME/Downloads"
FIRMWARE_FILE=$(find "$FIRMWARE_DIR" -name "firmware-thinknode_m3-*.uf2" -type f | sort -V | tail -n 1)

if [ -z "$FIRMWARE_FILE" ]; then
    echo -e "${YELLOW}No firmware file found in $FIRMWARE_DIR${NC}"
    echo "Please download firmware from: https://meshtastic.org/downloads"
    echo "Looking for: firmware-thinknode_m3-*.uf2"
    echo ""
    read -p "Enter full path to firmware file: " FIRMWARE_FILE

    if [ ! -f "$FIRMWARE_FILE" ]; then
        echo -e "${RED}File not found: $FIRMWARE_FILE${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Found firmware: $(basename "$FIRMWARE_FILE")${NC}"
echo ""

# Detect USB device
echo "Detecting ThinkNode M3..."
DEVICE=""

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    DEVICE=$(ls /dev/tty.usbmodem* 2>/dev/null | head -n 1 || echo "")
# Linux
else
    DEVICE=$(ls /dev/ttyACM* 2>/dev/null | head -n 1 || echo "")
fi

if [ -z "$DEVICE" ]; then
    echo -e "${YELLOW}ThinkNode M3 not detected via USB${NC}"
    echo ""
    echo "Please enter bootloader mode:"
    echo "1. Connect ThinkNode M3 to computer via USB"
    echo "2. Double-press the RESET button quickly"
    echo "3. Device should appear as 'THINKNODE' USB drive"
    echo ""
    read -p "Press Enter when ready..."

    # Check for UF2 bootloader mode (appears as USB drive)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Volumes/THINKNODE" ]; then
            echo -e "${GREEN}Bootloader mode detected!${NC}"
            echo "Copying firmware to device..."
            cp "$FIRMWARE_FILE" "/Volumes/THINKNODE/"
            echo -e "${GREEN}Firmware copied successfully!${NC}"
            echo "Device will reboot automatically in 5-10 seconds..."
            exit 0
        fi
    fi

    echo -e "${RED}Could not detect device${NC}"
    exit 1
fi

echo -e "${GREEN}Device found: $DEVICE${NC}"
echo ""

# Ask for confirmation
echo "Ready to flash firmware to ThinkNode M3"
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Flash firmware
echo ""
echo "Flashing firmware..."
echo -e "${YELLOW}This may take 30-60 seconds. Do not disconnect!${NC}"
echo ""

meshtastic --port "$DEVICE" --flash "$FIRMWARE_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Firmware flashed successfully!${NC}"
    echo ""
    echo "Device will reboot. Wait 10 seconds then run:"
    echo "  meshtastic --port $DEVICE --info"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Firmware flash failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Try entering bootloader mode (double-press RESET)"
    echo "2. Try different USB cable"
    echo "3. Check USB port permissions"
    exit 1
fi
