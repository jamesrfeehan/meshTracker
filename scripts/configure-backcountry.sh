#!/bin/bash

# Configure Meshtastic devices for backcountry skiing
# Optimized for mountain terrain, cold weather, and safety

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Backcountry Skiing Tracker Configuration${NC}"
echo "=========================================="
echo ""
echo "This will configure your devices for backcountry use:"
echo "  • 30-second position updates"
echo "  • LONG_SLOW preset (better terrain penetration)"
echo "  • Maximum transmit power"
echo "  • No power saving (6-10 hour battery life)"
echo "  • Higher hop limit for mesh routing"
echo ""

# Check for meshtastic CLI
if ! command -v meshtastic &> /dev/null; then
    echo -e "${RED}Error: Meshtastic CLI not installed${NC}"
    echo "Install with: pip3 install --upgrade meshtastic"
    exit 1
fi

# Function to detect device
detect_device() {
    local device=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        device=$(ls /dev/tty.usbmodem* 2>/dev/null | head -n 1 || echo "")
    else
        device=$(ls /dev/ttyACM* 2>/dev/null | head -n 1 || echo "")
    fi
    echo "$device"
}

# Function to configure ThinkNode M3 for backcountry
configure_backcountry_tracker() {
    local device="$1"

    echo -e "${BLUE}Configuring ThinkNode M3 for Backcountry Use${NC}"
    echo ""

    # Region selection
    echo "Select your region:"
    echo "1) US (United States)"
    echo "2) EU (Europe)"
    echo "3) ANZ (Australia/New Zealand)"
    read -p "Enter choice (1-3): " region_choice

    case $region_choice in
        1) REGION="US" ;;
        2) REGION="EU_868" ;;
        3) REGION="ANZ" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac

    echo ""
    echo -e "${YELLOW}Applying backcountry configuration...${NC}"
    echo ""

    # Device role
    echo "Setting device role to TRACKER..."
    meshtastic --port "$device" --set device.role TRACKER

    # Node name
    echo "Setting node name..."
    meshtastic --port "$device" --set owner.long_name "Dog-Backcountry"
    meshtastic --port "$device" --set owner.short_name "DOG"

    # Regional settings
    echo "Setting region to $REGION..."
    meshtastic --port "$device" --set lora.region "$REGION"

    # LoRa settings - Optimized for mountains
    echo "Configuring LoRa for mountain terrain..."
    meshtastic --port "$device" --set lora.modem_preset LONG_SLOW
    meshtastic --port "$device" --set lora.tx_power 22  # Max power
    meshtastic --port "$device" --set lora.hop_limit 5

    # GPS settings - Frequent updates for safety
    echo "Configuring GPS for real-time tracking..."
    meshtastic --port "$device" --set position.gps_enabled true
    meshtastic --port "$device" --set position.gps_update_interval 30
    meshtastic --port "$device" --set position.position_broadcast_secs 30
    meshtastic --port "$device" --set position.position_broadcast_smart_enabled false
    meshtastic --port "$device" --set position.gps_attempt_time 180

    # Position flags - Include altitude, heading, speed
    meshtastic --port "$device" --set position.position_flags 7

    # Power settings - No power saving for safety
    echo "Disabling power saving (prioritize safety over battery)..."
    meshtastic --port "$device" --set power.is_power_saving false
    meshtastic --port "$device" --set power.mesh_sds_timeout_secs 0
    meshtastic --port "$device" --set power.sds_secs 0
    meshtastic --port "$device" --set power.ls_secs 0

    # Bluetooth off to save battery
    echo "Disabling Bluetooth (saves battery)..."
    meshtastic --port "$device" --set bluetooth.enabled false

    # Telemetry - Monitor temperature and battery
    echo "Enabling environmental monitoring..."
    meshtastic --port "$device" --set telemetry.device_update_interval 300
    meshtastic --port "$device" --set telemetry.environment_update_interval 300

    # Detection sensor for motion/avalanche
    echo "Enabling motion detection..."
    meshtastic --port "$device" --set detection_sensor.enabled true

    echo ""
    echo -e "${GREEN}✓ Backcountry configuration complete!${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
    echo "  • Battery life: 6-10 hours (vs 18 hours in standard mode)"
    echo "  • Updates every 30 seconds (vs 60 seconds standard)"
    echo "  • Always broadcasts position (no smart mode)"
    echo "  • Optimized for terrain penetration (LONG_SLOW)"
    echo "  • Maximum transmit power for range"
    echo ""
}

# Function to configure handheld device
configure_handheld() {
    local device="$1"

    echo -e "${BLUE}Configuring Handheld Device${NC}"
    echo ""

    # Region selection
    echo "Select your region (MUST MATCH TRACKER):"
    echo "1) US (United States)"
    echo "2) EU (Europe)"
    echo "3) ANZ (Australia/New Zealand)"
    read -p "Enter choice (1-3): " region_choice

    case $region_choice in
        1) REGION="US" ;;
        2) REGION="EU_868" ;;
        3) REGION="ANZ" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac

    echo ""
    echo -e "${YELLOW}Applying handheld configuration...${NC}"
    echo ""

    # Device role - CLIENT since you're also moving
    echo "Setting device role to CLIENT..."
    meshtastic --port "$device" --set device.role CLIENT

    # Node name
    echo "Setting node name..."
    meshtastic --port "$device" --set owner.long_name "Skier-Handheld"
    meshtastic --port "$device" --set owner.short_name "SKIER"

    # Regional settings - must match tracker
    echo "Setting region to $REGION..."
    meshtastic --port "$device" --set lora.region "$REGION"

    # LoRa settings - match tracker
    echo "Configuring LoRa..."
    meshtastic --port "$device" --set lora.modem_preset LONG_SLOW
    meshtastic --port "$device" --set lora.tx_power 22
    meshtastic --port "$device" --set lora.hop_limit 5

    # GPS settings - track yourself too
    echo "Configuring GPS..."
    meshtastic --port "$device" --set position.gps_enabled true
    meshtastic --port "$device" --set position.gps_update_interval 60
    meshtastic --port "$device" --set position.position_broadcast_secs 60
    meshtastic --port "$device" --set position.position_broadcast_smart_enabled false
    meshtastic --port "$device" --set position.position_flags 7

    # Power settings
    echo "Configuring power settings..."
    meshtastic --port "$device" --set power.is_power_saving false

    # Keep Bluetooth on for phone connection
    echo "Enabling Bluetooth for phone connection..."
    meshtastic --port "$device" --set bluetooth.enabled true

    echo ""
    echo -e "${GREEN}✓ Handheld configuration complete!${NC}"
    echo ""
}

# Function to configure trailhead base
configure_trailhead_base() {
    local device="$1"

    echo -e "${BLUE}Configuring Trailhead Base Station${NC}"
    echo ""

    # Region selection
    echo "Select your region (MUST MATCH OTHER DEVICES):"
    echo "1) US (United States)"
    echo "2) EU (Europe)"
    echo "3) ANZ (Australia/New Zealand)"
    read -p "Enter choice (1-3): " region_choice

    case $region_choice in
        1) REGION="US" ;;
        2) REGION="EU_868" ;;
        3) REGION="ANZ" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac

    echo ""
    echo -e "${YELLOW}Applying base station configuration...${NC}"
    echo ""

    # Device role - ROUTER for relay
    echo "Setting device role to ROUTER..."
    meshtastic --port "$device" --set device.role ROUTER

    # Node name
    echo "Setting node name..."
    meshtastic --port "$device" --set owner.long_name "Trailhead-Base"
    meshtastic --port "$device" --set owner.short_name "BASE"

    # Regional settings
    echo "Setting region to $REGION..."
    meshtastic --port "$device" --set lora.region "$REGION"

    # LoRa settings - match other devices
    echo "Configuring LoRa..."
    meshtastic --port "$device" --set lora.modem_preset LONG_SLOW
    meshtastic --port "$device" --set lora.tx_power 22
    meshtastic --port "$device" --set lora.hop_limit 5

    # Position settings - fixed at trailhead
    echo "Configuring as fixed position..."
    meshtastic --port "$device" --set position.gps_enabled false
    meshtastic --port "$device" --set position.fixed_position true

    echo ""
    echo "Enter trailhead coordinates (from Google Maps):"
    read -p "Latitude (e.g., 39.5501): " lat
    read -p "Longitude (e.g., -106.0661): " lon
    read -p "Altitude in meters (e.g., 2800): " alt

    meshtastic --port "$device" --set position.latitude "$lat"
    meshtastic --port "$device" --set position.longitude "$lon"
    meshtastic --port "$device" --set position.altitude "$alt"

    # Power settings - no sleep for router
    echo "Configuring power settings..."
    meshtastic --port "$device" --set power.is_power_saving false

    # Bluetooth on for initial setup
    meshtastic --port "$device" --set bluetooth.enabled true

    echo ""
    echo -e "${GREEN}✓ Trailhead base station configured!${NC}"
    echo ""
    echo "This device will:"
    echo "  • Act as mesh relay/router"
    echo "  • Log all positions to 8MB flash"
    echo "  • Extend your range"
    echo ""
}

# Main menu
echo "What would you like to configure?"
echo ""
echo "1) ThinkNode M3 (Dog Tracker) - Backcountry Mode"
echo "2) Handheld Device (Your device while skiing)"
echo "3) Trailhead Base Station (Leave at car)"
echo "4) Complete Setup (All three devices)"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected. Connect ThinkNode M3 via USB.${NC}"
            exit 1
        fi
        echo -e "Device found: ${GREEN}$DEVICE${NC}"
        echo ""
        configure_backcountry_tracker "$DEVICE"
        ;;
    2)
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected. Connect handheld device via USB.${NC}"
            exit 1
        fi
        echo -e "Device found: ${GREEN}$DEVICE${NC}"
        echo ""
        configure_handheld "$DEVICE"
        ;;
    3)
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected. Connect base station via USB.${NC}"
            exit 1
        fi
        echo -e "Device found: ${GREEN}$DEVICE${NC}"
        echo ""
        configure_trailhead_base "$DEVICE"
        ;;
    4)
        echo ""
        echo "Complete Setup - Configure all devices"
        echo ""

        # Step 1: Tracker
        echo -e "${GREEN}Step 1/3: Configure ThinkNode M3 (Dog Tracker)${NC}"
        echo "Connect ThinkNode M3 via USB and press Enter..."
        read
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            exit 1
        fi
        configure_backcountry_tracker "$DEVICE"

        # Step 2: Handheld
        echo ""
        echo -e "${GREEN}Step 2/3: Configure Handheld Device${NC}"
        echo "Disconnect M3, connect handheld device, then press Enter..."
        read
        DEVICE=$(detect_device)
        if [ -z "$DEVICE" ]; then
            echo -e "${RED}No device detected${NC}"
            exit 1
        fi
        configure_handheld "$DEVICE"

        # Step 3: Base (optional)
        echo ""
        echo -e "${GREEN}Step 3/3: Configure Trailhead Base (Optional)${NC}"
        read -p "Do you have a third device for trailhead base? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Disconnect handheld, connect base station, then press Enter..."
            read
            DEVICE=$(detect_device)
            if [ -z "$DEVICE" ]; then
                echo -e "${RED}No device detected${NC}"
                exit 1
            fi
            configure_trailhead_base "$DEVICE"
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Configuration Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Test GPS lock outdoors (3-5 minutes)"
echo "   meshtastic --port /dev/tty.usbmodem* --gps-watch"
echo ""
echo "2. Verify all devices on mesh network"
echo "   Check Meshtastic app - all devices should appear"
echo ""
echo "3. Test range at your skiing location"
echo "   Start close, gradually increase distance"
echo ""
echo "4. Mount tracker securely on dog collar"
echo "   Use insulated pouch in extreme cold"
echo ""
echo "5. Read the backcountry guide:"
echo "   docs/backcountry-guide.md"
echo ""
echo -e "${YELLOW}Important Reminders:${NC}"
echo "  • Battery life: 6-10 hours in backcountry mode"
echo "  • Charge fully before each trip"
echo "  • Keep devices warm in extreme cold"
echo "  • Always carry avalanche safety equipment"
echo "  • Tracker is supplementary to visual/voice control"
echo ""
echo "Safe travels! 🎿🐕"
echo ""
