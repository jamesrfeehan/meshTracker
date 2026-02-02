# Quick Start Installation Guide

Follow these steps to get your dog tracker running in 30 minutes.

## What You Need

- [x] Elecrow ThinkNode M3
- [x] Muzi Works Base Duo
- [x] Computer (Mac/Windows/Linux)
- [x] USB cables (Micro USB for M3, USB-C for Base Duo)
- [x] Mobile phone with Bluetooth
- [x] Dog collar

## Step 1: Charge Devices (15 minutes)

### ThinkNode M3
1. Connect magnetic charging base to USB power
2. Place ThinkNode M3 on magnetic base (it will snap into place)
3. Red LED = charging, Green LED = fully charged
4. Charge for at least 30 minutes (full charge = 2-3 hours)

### Base Duo
1. Connect USB-C cable to Base Duo
2. Connect other end to USB power adapter or computer
3. Device should power on (LED indicator)
4. Leave connected for now (will run on USB power)

## Step 2: Install Meshtastic Software (5 minutes)

### On Your Computer

Open Terminal (Mac/Linux) or Command Prompt (Windows) and run:

```bash
# Install Python if not already installed
# Mac: brew install python3
# Windows: Download from python.org
# Linux: sudo apt install python3 python3-pip

# Install Meshtastic CLI
pip3 install --upgrade meshtastic
```

Verify installation:
```bash
meshtastic --version
```

### On Your Mobile Phone

1. Open App Store (iOS) or Play Store (Android)
2. Search for "Meshtastic"
3. Install the official Meshtastic app
4. Grant permissions when asked (Location, Bluetooth, Notifications)

## Step 3: Update Firmware (5 minutes - Optional but Recommended)

### Check Current Firmware

Both devices come pre-flashed, but it's good to update to latest:

1. **Connect ThinkNode M3 via USB**
   ```bash
   # Mac
   ls /dev/tty.usbmodem*

   # Linux
   ls /dev/ttyACM*

   # Windows
   # Check Device Manager for COM port
   ```

2. **Check version**
   ```bash
   meshtastic --port /dev/tty.usbmodem* --info
   # Replace /dev/tty.usbmodem* with your actual port
   ```

3. **Update if needed** (Optional)
   - Visit: https://meshtastic.org/downloads
   - Download latest firmware for your devices
   - Or use our script:
   ```bash
   cd ~/projects/tracker/scripts
   ./flash-thinknode.sh
   ```

## Step 4: Configure Devices (10 minutes)

### Easy Method: Use Our Configuration Script

```bash
cd ~/projects/tracker/scripts
./configure-mesh.sh
```

Follow the prompts:
1. Choose option 3 (configure both)
2. Connect ThinkNode M3 when prompted
3. Select your region (US, EU, etc.)
4. Disconnect M3, connect Base Duo when prompted
5. Select same region
6. Enter your home coordinates (get from Google Maps)

### Manual Method: Step by Step

#### Configure ThinkNode M3 (Tracker)

Connect via USB and run these commands (replace port as needed):

```bash
PORT=/dev/tty.usbmodem1234  # Replace with your port

# Set region (CRITICAL - choose yours!)
meshtastic --port $PORT --set lora.region US

# Set device role
meshtastic --port $PORT --set device.role TRACKER

# Set name
meshtastic --port $PORT --set owner.long_name "Dog-Tracker"

# Enable GPS
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 60
meshtastic --port $PORT --set position.position_broadcast_secs 60

# Enable smart position (battery saving)
meshtastic --port $PORT --set position.position_broadcast_smart_enabled true

# Disable Bluetooth (saves 30% battery)
meshtastic --port $PORT --set bluetooth.enabled false

# Set transmit power (max range)
meshtastic --port $PORT --set lora.tx_power 20

# Enable power saving
meshtastic --port $PORT --set power.is_power_saving true

# Verify configuration
meshtastic --port $PORT --info
```

#### Configure Base Duo (Router)

Disconnect M3, connect Base Duo, then run:

```bash
PORT=/dev/tty.usbmodem5678  # Replace with your port

# Set region (MUST MATCH M3!)
meshtastic --port $PORT --set lora.region US

# Set device role
meshtastic --port $PORT --set device.role ROUTER

# Set name
meshtastic --port $PORT --set owner.long_name "Home-Base"

# Disable GPS (not needed for base)
meshtastic --port $PORT --set position.gps_enabled false

# Set fixed position
meshtastic --port $PORT --set position.fixed_position true

# Set your home coordinates (REPLACE WITH YOURS!)
# Get from Google Maps: right-click -> "What's here?"
meshtastic --port $PORT --set position.latitude 37.7749
meshtastic --port $PORT --set position.longitude -122.4194

# Keep Bluetooth on (for app connection)
meshtastic --port $PORT --set bluetooth.enabled true

# Disable power saving (router stays awake)
meshtastic --port $PORT --set power.is_power_saving false

# Set transmit power
meshtastic --port $PORT --set lora.tx_power 20

# Verify configuration
meshtastic --port $PORT --info
```

## Step 5: Test GPS on ThinkNode M3 (3 minutes)

Before mounting on collar, test GPS:

1. **Take M3 outdoors** (clear sky view)
2. **Connect via USB** (or use battery)
3. **Monitor GPS status:**
   ```bash
   meshtastic --port /dev/tty.usbmodem* --gps-watch
   ```

4. **Wait for lock:**
   - Should see satellites appearing
   - Fix type should become "3D"
   - Typically 1-3 minutes for first lock

5. **Success looks like:**
   ```
   Satellites: 12
   Fix type: 3D
   Latitude: 37.774929
   Longitude: -122.419418
   Altitude: 52m
   ```

## Step 6: Setup Base Duo

1. **Attach antenna** to Base Duo (SMA connector)
   - CRITICAL: Never power on without antenna!
   - Screw on hand-tight
   - Position vertically

2. **Choose location:**
   - Near window for best range
   - Elevated (6+ feet high)
   - Away from metal objects
   - USB-C power connected

3. **Power on and verify LED is active**

## Step 7: Connect Mobile App

1. **Open Meshtastic app** on your phone

2. **Add Base Duo:**
   - Tap "+" button
   - Select "Bluetooth"
   - Choose "Home-Base" from list
   - Wait for connection (green indicator)

3. **Verify Base Duo location:**
   - Tap "Map" tab
   - Should see "Home-Base" at your location
   - If position is wrong, update in Settings

4. **Check mesh network:**
   - Tap "Nodes" tab
   - Should see "Home-Base" (green/online)
   - Should see "Dog-Tracker" (if powered on and in range)

## Step 8: Mount ThinkNode M3 on Collar

1. **Choose mounting method:**
   - Use included fixed base with magnetic mount
   - Or use protective pouch attached to collar
   - Position on top/side of neck (not underneath)

2. **Safety checks:**
   - Collar fits properly (two-finger rule)
   - Device secure but removable
   - Not too tight or loose
   - Dog comfortable

3. **Power on ThinkNode M3** (should auto-power when picked up)

## Step 9: Test the System

1. **Indoor test:**
   - With dog nearby, check app
   - Wait 2-3 minutes for GPS and mesh connection
   - "Dog-Tracker" should appear in Nodes list
   - Position may be inaccurate indoors (normal)

2. **Outdoor test:**
   - Go outside with dog
   - Wait 1-2 minutes for GPS lock
   - Check app - position should update
   - Walk around, verify position tracks

3. **Range test:**
   - Walk increasing distances from home
   - Monitor "Last Heard" time in app
   - Check signal strength (SNR)
   - Note where connection drops (your max range)

## Step 10: Optimize Settings

After initial testing, adjust if needed:

### For Better Battery Life:
```bash
# Increase update interval to 2 minutes
meshtastic --port /dev/tty.usbmodem* --set position.position_broadcast_secs 120

# Increase minimum distance
meshtastic --port /dev/tty.usbmodem* --set position.broadcast_smart_minimum_distance 50
```

### For More Frequent Updates:
```bash
# Update every 30 seconds
meshtastic --port /dev/tty.usbmodem* --set position.position_broadcast_secs 30
```

### For Longer Range (if signal weak):
```bash
# Use slower but more reliable preset
meshtastic --port /dev/tty.usbmodem* --set lora.modem_preset LONG_SLOW
```

## Troubleshooting Quick Fixes

### ThinkNode M3 not appearing in app
- Wait 3-5 minutes for mesh network to form
- Ensure both devices have same region (US vs EU)
- Take M3 outdoors for GPS lock
- Check M3 is powered on (press button, LED should light)

### No GPS lock
- Must be outdoors with clear sky view
- Wait 3-5 minutes (first lock takes longer)
- Move away from tall buildings

### Short range
- Elevate Base Duo antenna
- Ensure antennas are vertical
- Check antenna connections tight
- Urban areas have much shorter range (1-2km normal)

### Battery drains fast
- Enable smart position (done in config above)
- Disable Bluetooth on M3 (done in config above)
- Increase update interval to 120-180 seconds

## Daily Use

1. **Before walks:**
   - Check M3 battery level in app (>30%)
   - Verify M3 is secure on collar
   - Open app to monitor

2. **During walks:**
   - Check app occasionally
   - Position should update every 60 seconds
   - "Last Heard" should stay recent (<2 min)

3. **After walks:**
   - Check battery remaining
   - Charge if below 30%
   - Review track on map (optional)

## Charging Schedule

- **ThinkNode M3:** Charge every 1-2 days (18 hour runtime)
- **Base Duo:** Leave on USB power continuously (or use battery + solar)

## Need Help?

- See `docs/troubleshooting.md` for detailed solutions
- Hardware setup: `docs/hardware-setup.md`
- Configuration details: `docs/firmware-config.md`
- App features: `docs/mobile-app-setup.md`

## Quick Command Reference

```bash
# Check device info
meshtastic --port /dev/tty.usbmodem* --info

# Monitor GPS
meshtastic --port /dev/tty.usbmodem* --gps-watch

# Check battery
meshtastic --port /dev/tty.usbmodem* --info | grep -i batt

# Reboot device
meshtastic --port /dev/tty.usbmodem* --reboot

# Export configuration (backup)
meshtastic --port /dev/tty.usbmodem* --export-config > backup.yaml
```

## Success! 🎉

Your dog tracker is now operational! Test it in your area and adjust settings as needed. The system will:
- Track your dog's location every 60 seconds
- Show position on map in real-time
- Alert you to position updates
- Log movement history
- Monitor battery, temperature, and activity

Enjoy peace of mind knowing where your pup is!
