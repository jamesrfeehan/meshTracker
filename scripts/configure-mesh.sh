#!/bin/bash

# Configure Meshtastic mesh network for dog tracking
# Sets up ThinkNode M3 as tracker and Base Duo as router

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Meshtastic Dog Tracker Configuration${NC}"
echo "======================================"
echo ""

# Check if meshtastic CLI is installed
if ! command -v meshtastic &> /dev/null; then
    echo -e "${RED}Error: Meshtastic CLI not installed${NC}"
    echo "Install with: pip3 install --upgrade meshtastic"
    exit 1
fi

# Function to detect device
detect_device() {
    local device=""

    # macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        device=$(ls /dev/tty.usbmodem* 2>/dev/null | head -n 1 || echo "")
    # Linux
    else
        device=$(ls /dev/ttyACM* 2>/dev/null | head -n 1 || echo "")
    fi

    echo "$device"
}

# Function to configure ThinkNode M3
configure_tracker() {
    local device="$1"

    echo -e "${BLUE}Configuring ThinkNode M3 as Tracker...${NC}"
    echo ""

    # Region selection
    echo "Select your region:"
    echo "1) US (United States)"
    echo "2) EU (Europe)"
    echo "3) ANZ (Australia/New Zealand)"
    echo "4) Other"
    read -p "Enter choice (1-4): " region_choice

    case $region_choice in
        1) REGION="US"; FREQ="US915" ;;
        2) REGION="EU_868"; FREQ="EU868" ;;
        3) REGION="ANZ"; FREQ="ANZ915" ;;
        4)
            read -p "Enter region code: " REGION
            read -p "Enter frequency: " FREQ
            ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac

    echo ""
    echo "Applying configuration..."

    # Basic settings
    meshtastic --port "$device" --set lora.region "$REGION"
    meshtastic --port "$device" --set lora.modem_preset LONG_FAST
    meshtastic --port "$device" --set device.role TRACKER

    # Node name
    meshtastic --port "$device" --set owner.long_name "Dog-Tracker"
    meshtastic --port "$device" --set owner.short_name "DOG"

    # GPS settings
    meshtastic --port "$device" --set position.gps_enabled true
    meshtastic --port "$device" --set position.gps_update_interval 60
    meshtastic --port "$device" --set position.position_broadcast_secs 60
    meshtastic --port "$device" --set position.position_broadcast_smart_enabled true
    meshtastic --port "$device" --set position.broadcast_smart_minimum_distance 25

    # Power settings
    meshtastic --port "$device" --set power.is_power_saving true
    meshtastic --port "$device" --set bluetooth.enabled false

    # LoRa settings
    meshtastic --port "$device" --set lora.tx_power 20
    meshtastic --port "$device" --set lora.hop_limit 3

    echo -e "${GREEN}✓ ThinkNode M3 configured${NC}"
    echo ""
}

# Function to configure Base Duo
configure_base() {
    local device="$1"

    echo -e "${BLUE}Configuring Base Duo as Router...${NC}"
    echo ""

    # Region selection
    echo "Select your region (MUST MATCH TRACKER):"
    echo "1) US (United States)"
    echo "2) EU (Europe)"
    echo "3) ANZ (Australia/New Zealand)"
    echo "4) Other"
    read -p "Enter choice (1-4): " region_choice

    case $region_choice in
        1) REGION="US"; FREQ="US915" ;;
        2) REGION="EU_868"; FREQ="EU868" ;;
        3) REGION="ANZ"; FREQ="ANZ915" ;;
        4)
            read -p "Enter region code: " REGION
            read -p "Enter frequency: " FREQ
            ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac

    echo ""
    echo "Applying configuration..."

    # Basic settings
    meshtastic --port "$device" --set lora.region "$REGION"
    meshtastic --port "$device" --set lora.modem_preset LONG_FAST
    meshtastic --port "$device" --set device.role ROUTER

    # Node name
    meshtastic --port "$device" --set owner.long_name "Home-Base"
    meshtastic --port "$device" --set owner.short_name "BASE"

    # Position settings
    meshtastic --port "$device" --set position.gps_enabled false
    meshtastic --port "$device" --set position.fixed_position true
    meshtastic --port "$device" --set position.position_broadcast_secs 3600

    # Get home coordinates
    echo ""
    echo "Enter home coordinates (from Google Maps):"
    read -p "Latitude (e.g., 37.7749): " lat
    read -p "Longitude (e.g., -122.4194): " lon

    meshtastic --port "$device" --set position.latitude "$lat"
    meshtastic --port "$device" --set position.longitude "$lon"

    # Power settings
    meshtastic --port "$device" --set power.is_power_saving false
    meshtastic --port "$device" --set bluetooth.enabled true

    # LoRa settings
    meshtastic --port "$device" --set lora.tx_power 20
    meshtastic --port "$device" --set lora.hop_limit 3

    echo -e "${GREEN}✓ Base Duo configured${NC}"
    echo ""
}

# Main menu
echo "Which device are you configuring?"
echo "1) ThinkNode M3 (Tracker)"
echo "2) Base Duo (Router)"
echo "3) Both (configure one at a time)"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            echo "Please connect ThinkNode M3 via USB"
            exit 1
        fi
        echo -e "Detected device: ${GREEN}$DEVICE${NC}"
        echo ""
        configure_tracker "$DEVICE"
        ;;
    2)
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            echo "Please connect Base Duo via USB"
            exit 1
        fi
        echo -e "Detected device: ${GREEN}$DEVICE${NC}"
        echo ""
        configure_base "$DEVICE"
        ;;
    3)
        echo ""
        echo "Step 1: Configure ThinkNode M3"
        echo "Connect ThinkNode M3 via USB and press Enter..."
        read
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            exit 1
        fi
        configure_tracker "$DEVICE"

        echo ""
        echo "Step 2: Configure Base Duo"
        echo "Disconnect ThinkNode M3, connect Base Duo, then press Enter..."
        read
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            exit 1
        fi
        configure_base "$DEVICE"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Power on both devices"
echo "2. Wait 1-2 minutes for mesh network to form"
echo "3. Connect mobile app to Base Duo"
echo "4. Verify tracker appears on map"
echo ""
echo "To verify configuration:"
echo "  meshtastic --port $DEVICE --info"
echo ""
