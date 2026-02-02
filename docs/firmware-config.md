# Firmware Configuration Guide

This guide covers flashing Meshtastic firmware and configuring both devices for optimal dog tracking.

## Prerequisites

- ThinkNode M3 and Base Duo hardware assembled
- Computer with USB ports (Mac, Windows, or Linux)
- Meshtastic mobile app installed
- Internet connection for firmware downloads

## Firmware Flashing

### ThinkNode M3 Firmware

The ThinkNode M3 comes pre-flashed with Meshtastic firmware, but you should update to the latest version:

#### Using UF2 Bootloader (Recommended)

1. **Enter Bootloader Mode:**
   - Connect ThinkNode M3 to computer via USB
   - Double-press the reset button quickly
   - Device will appear as USB drive named "THINKNODE"

2. **Download Firmware:**
   - Visit: https://meshtastic.org/downloads
   - Download latest stable: `firmware-thinknode_m3-X.X.X.uf2`

3. **Flash Firmware:**
   - Drag and drop UF2 file onto THINKNODE drive
   - Device will automatically flash and reboot
   - Drive will disappear when complete (10-20 seconds)

4. **Verify:**
   - Device should power on and LED should blink
   - Connect via Meshtastic app to verify version

#### Using Web Flasher (Alternative)

1. Visit: https://flasher.meshtastic.org
2. Connect ThinkNode M3 via USB
3. Click "Connect" and select device
4. Choose "ThinkNode M3" from device list
5. Select latest firmware version
6. Click "Flash" and wait for completion

### Base Duo Firmware

The Base Duo also comes pre-flashed:

#### Using nRF Connect Programmer (Detailed Method)

1. **Install Tools:**
   ```bash
   # macOS
   brew install adafruit-nrfutil

   # Windows - download from Nordic Semi
   # https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-Desktop
   ```

2. **Download Firmware:**
   - Visit: https://meshtastic.org/downloads
   - Download: `firmware-base-duo-X.X.X.uf2` or `.hex`

3. **Flash via Bootloader:**
   - Connect Base Duo via USB-C
   - Double-tap reset button (or short RESET pin twice)
   - Device enters DFU mode
   - Drag and drop UF2 file

#### Using Meshtastic Python CLI

```bash
# Install Meshtastic CLI
pip install meshtastic

# Flash firmware
meshtastic --port /dev/ttyACM0 --flash firmware-base-duo-X.X.X.uf2
```

## Configuration

### Regional Settings

**IMPORTANT:** Set correct region for legal compliance.

#### For USA
```yaml
region: US
lora_frequency: US915
```

#### For Europe
```yaml
region: EU
lora_frequency: EU868
```

#### For other regions
Check: https://meshtastic.org/docs/settings/region

### ThinkNode M3 Configuration (Tracker)

#### Basic Settings

Connect via Meshtastic app (Bluetooth) and configure:

```yaml
# Device Role
device_role: TRACKER

# Node Name
node_name: "Dog-Tracker"

# Region (MUST MATCH BASE DUO)
region: US  # or EU, ANZ, etc.

# LoRa Settings
lora:
  frequency: US915  # or EU868
  transmit_power: 20  # dBm (max for good range)
  spread_factor: 10   # Balance of range vs. speed
  bandwidth: 125      # kHz
  coding_rate: 8      # 4/8 for reliability

# GPS Settings
gps:
  enabled: true
  update_interval: 60  # seconds (60s = 1 minute updates)
  wait_for_lock: true
  attempt_time: 120    # seconds to try getting GPS lock

# Position Settings
position:
  broadcast_interval: 60  # seconds (how often to send position)
  smart_position: true    # Only send if moved significantly
  minimum_distance: 25    # meters (minimum move to trigger update)
  broadcast_smart_minimum: 30  # seconds (minimum time between updates)

# Power Settings
power:
  power_saving: true
  wait_bluetooth_secs: 0  # Disable BT to save power (use Base Duo as gateway)
  mesh_sds_timeout_secs: 300  # Sleep timeout
  sds_secs: 300  # Deep sleep after 5 min idle
  ls_secs: 600   # Light sleep after 10 min
  min_wake_secs: 10

# Telemetry (for sensors)
telemetry:
  device_update_interval: 900  # 15 minutes (temp/humidity/battery)
  environment_update_interval: 900  # 15 minutes
  show_on_map: true
```

#### Optimized Settings for Battery Life

For 18-hour runtime with active tracking:

```yaml
position:
  broadcast_interval: 120  # 2 minutes instead of 1
  smart_position: true
  minimum_distance: 50     # Only update if moved 50m

power:
  power_saving: true
  wait_bluetooth_secs: 0   # BT off (save ~30% battery)

lora:
  transmit_power: 17  # Reduce if range adequate
```

#### Aggressive Tracking (Shorter Battery Life)

For maximum tracking frequency:

```yaml
position:
  broadcast_interval: 30  # 30 seconds
  smart_position: false   # Always send

gps:
  update_interval: 30

# Expect 6-8 hours battery life
```

### Base Duo Configuration (Router/Gateway)

#### Basic Settings

```yaml
# Device Role
device_role: ROUTER  # Or CLIENT if you want to also send messages

# Node Name
node_name: "Home-Base"

# Region (MUST MATCH THINKNODE M3)
region: US  # or EU

# LoRa Settings
lora:
  frequency: US915  # or EU868
  transmit_power: 20  # dBm
  spread_factor: 10
  bandwidth: 125
  coding_rate: 8
  hop_limit: 3  # Allow mesh routing

# Router Settings
router:
  enabled: true  # Acts as mesh router

# Power Settings (if battery powered)
power:
  power_saving: false  # Router should stay awake
  wait_bluetooth_secs: 300  # Allow BT connections

# Position Settings (Base doesn't move)
position:
  fixed_position: true
  latitude: 0.0  # Set your home coordinates
  longitude: 0.0
  altitude: 0
  broadcast_interval: 3600  # Only broadcast once per hour

# Store and Forward (optional - requires RAK19007+)
store_forward:
  enabled: false  # Enable if you have storage module

# MQTT (if you want cloud integration)
mqtt:
  enabled: false  # Set true for home assistant integration
  server: ""
  username: ""
  password: ""
```

#### Dual-Band Configuration

The Base Duo supports both Sub-GHz and 2.4GHz:

```yaml
# Primary: Sub-GHz (long range)
lora:
  frequency: US915  # Sub-GHz
  use_preset: LONG_FAST

# Secondary: 2.4GHz (optional, for nearby devices)
lora_secondary:
  enabled: true
  frequency: 2400  # 2.4GHz
  use_preset: SHORT_FAST
```

**Note:** ThinkNode M3 only supports Sub-GHz, so configure Base Duo's primary radio to match.

## Configuration via CLI

### Using Meshtastic CLI

Install:
```bash
pip install meshtastic
```

#### Configure ThinkNode M3:

```bash
# Connect to device
meshtastic --port /dev/ttyACM0

# Set device role
meshtastic --set device.role TRACKER

# Set region
meshtastic --set lora.region US

# Set position interval
meshtastic --set position.gps_update_interval 60
meshtastic --set position.position_broadcast_secs 60

# Enable smart position
meshtastic --set position.position_broadcast_smart_enabled true

# Set GPS
meshtastic --set position.gps_enabled true

# Disable Bluetooth to save power
meshtastic --set bluetooth.enabled false

# Set transmit power
meshtastic --set lora.tx_power 20
```

#### Configure Base Duo:

```bash
# Set device role
meshtastic --set device.role ROUTER

# Set region (MUST MATCH TRACKER)
meshtastic --set lora.region US

# Enable router
meshtastic --set device.is_router true

# Set fixed position
meshtastic --set position.fixed_position true
meshtastic --set position.latitude 37.7749
meshtastic --set position.longitude -122.4194

# Keep Bluetooth enabled for app connection
meshtastic --set bluetooth.enabled true
```

## Configuration via Mobile App

### Meshtastic App Setup

1. **Install App:**
   - iOS: App Store - "Meshtastic"
   - Android: Play Store - "Meshtastic"

2. **Connect to Base Duo:**
   - Open app
   - Tap "+" to add device
   - Select "Bluetooth"
   - Choose "Home-Base" from list
   - Wait for connection

3. **Configure Base Duo:**
   - Tap device name
   - Go to "Settings"
   - Navigate to "Radio Configuration"
   - Set:
     - Device Role: ROUTER
     - Region: US (or your region)
     - Frequency: US915
   - Navigate to "Position"
   - Enable "Fixed Position"
   - Set your home coordinates

4. **Configure ThinkNode M3:**
   - Temporarily enable Bluetooth on ThinkNode M3:
     ```bash
     meshtastic --set bluetooth.enabled true
     ```
   - Connect in app (same process)
   - Set:
     - Device Role: TRACKER
     - Region: US (MUST MATCH)
     - Position Broadcast: 60s
     - GPS Enabled: true
   - After config, disable BT to save power:
     ```bash
     meshtastic --set bluetooth.enabled false
     ```

## Testing Configuration

### Verify Settings

```bash
# Check ThinkNode M3 config
meshtastic --port /dev/ttyACM0 --info

# Check Base Duo config
meshtastic --port /dev/ttyACM1 --info
```

### Test GPS Lock

```bash
# Monitor GPS status on ThinkNode M3
meshtastic --port /dev/ttyACM0 --gps-watch
```

Should show:
- Satellites in view: 8+
- Fix type: 3D
- Accuracy: <5m

### Test Mesh Communication

1. Power on both devices
2. Open Meshtastic app connected to Base Duo
3. Go to "Map" view
4. Should see both devices
5. ThinkNode M3 should show GPS position
6. Base Duo shows fixed position

### Range Test

1. Walk with dog/ThinkNode M3
2. Monitor position updates in app
3. Check signal strength (SNR)
4. Note distance where connection drops

## Advanced Configuration

### Channel Settings

Both devices must use same channel:

```yaml
# Default channel
channel:
  name: "LongFast"
  psk: "AQ=="  # Default key
  uplink_enabled: true
  downlink_enabled: true
```

### Custom Channel (More Private)

```bash
# Generate random key
meshtastic --ch-set psk random --ch-index 0

# Or use custom key
meshtastic --ch-set psk base64:YOUR_KEY_HERE --ch-index 0

# Set on BOTH devices!
```

### Encryption

Default is AES-128. To use no encryption (not recommended):

```bash
meshtastic --ch-set psk none --ch-index 0
```

### MQTT Integration

For Home Assistant or cloud tracking:

```yaml
mqtt:
  enabled: true
  server: "your-mqtt-broker.com"
  port: 1883
  username: "user"
  password: "pass"
  encryption: false
  json_enabled: true
  map_reporting: true
```

## Troubleshooting

### Devices Not Connecting

1. Verify same region on both devices
2. Check same channel/PSK
3. Ensure antennas connected
4. Try increasing TX power
5. Check distance (start close, then test range)

### GPS Not Locking

1. Must be outdoors
2. Wait 3-5 minutes for cold start
3. Check `gps_enabled: true`
4. Verify GPS antenna connected (internal on M3)

### Battery Draining Fast

1. Reduce position_broadcast_interval
2. Enable smart_position
3. Disable Bluetooth
4. Reduce tx_power if range adequate
5. Increase minimum_distance threshold

### Position Not Updating

1. Check GPS lock status
2. Verify position_broadcast_secs not too high
3. Check smart_position settings
4. Ensure minimum_distance not too large
5. Verify LoRa connection to base

## Configuration Files

Pre-configured YAML files are available in the `config/` directory:
- `thinknode-m3-config.yaml` - ThinkNode M3 settings
- `base-duo-config.yaml` - Base Duo settings

Load via:
```bash
meshtastic --configure-from-file config/thinknode-m3-config.yaml
```

## Next Steps

1. [Mobile App Integration](mobile-app-setup.md)
2. Test in real-world conditions
3. Optimize settings for your area
4. Set up alerts and geofencing
