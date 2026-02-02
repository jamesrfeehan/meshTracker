# Quick Reference Card

Fast commands for common tasks. Keep this handy! 📋

---

## Mesh Network Commands

### Check Device Status
```bash
# DUO1
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --info

# DUO2
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14201 --info
```

### View All Nodes
```bash
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --nodes
```

### Send Test Message
```bash
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 \
  --sendtext "Test message"
```

### Monitor Traffic (Real-time)
```bash
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --debug
```

### Request Position Update
```bash
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 \
  --request-position !45a248b6  # DUO2's node ID
```

---

## Python Test Tools

### Run Full Test Suite
```bash
cd ~/projects/tracker/ios-bridge/Scripts
./test_mesh.py test
```

### Monitor Mesh (Live Dashboard)
```bash
./monitor_mesh.py DUO1
# Updates every 2 seconds, shows packet counts and positions
```

### Compare Positions
```bash
./compare_positions.py
# Shows DUO1 and DUO2 positions, calculates distance
```

### Quick Device Info
```bash
./test_mesh.py info DUO1
./test_mesh.py info DUO2
```

---

## iOS Bridge App

### Build and Run (Xcode)
```bash
# Open project
open ~/projects/tracker/ios-bridge/MeshtasticGarminBridge.xcodeproj

# In Xcode:
# 1. Select iPhone target
# 2. Press ⌘R to build and run
```

### View Logs (Console.app)
```
1. Open Console.app
2. Select your iPhone
3. Search for "MeshtasticGarminBridge"
4. Watch for:
   - "📍 Position update"
   - "✅ Connected"
   - "📦 Received packet"
```

### Quick Rebuild
```bash
# Clean build folder
xcodebuild -project ~/projects/tracker/ios-bridge/MeshtasticGarminBridge.xcodeproj \
  -scheme MeshtasticGarminBridge clean

# Build for device
xcodebuild -project ~/projects/tracker/ios-bridge/MeshtasticGarminBridge.xcodeproj \
  -scheme MeshtasticGarminBridge \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO
```

---

## Garmin Watch App

### Build (Monkey C)
```bash
cd ~/projects/tracker/garmin-watchapp

monkeyc \
  -o bin/Tracker.prg \
  -f monkey.jungle \
  -y ~/.Garmin/ConnectIQ/developer_key \
  -d instinct2x
```

### Run in Simulator
```bash
# Launch Connect IQ simulator
connectiq

# Load app
# File → Open → bin/Tracker.prg
```

---

## BLE Debugging

### Scan for Meshtastic Devices (macOS)
```bash
# Using system_profiler
system_profiler SPBluetoothDataType

# Check if DUO is visible
system_profiler SPBluetoothDataType | grep -i "duo"
```

### Check iOS Bridge Advertising
Use nRF Connect app on another iPhone/Android:
1. Open nRF Connect
2. Scan
3. Look for "Mesh Tracker"
4. Verify service: 0x181A
5. Check characteristics:
   - 0x2A67 (Position)
   - 0x2A68 (Status)

---

## Common Mesh Configuration

### Enable GPS
```bash
meshtastic --port /dev/cu.usbmodem14101 \
  --set position.gps_enabled true
```

### Set Position Broadcast Interval
```bash
# Every 5 minutes
meshtastic --port /dev/cu.usbmodem14101 \
  --set position.position_broadcast_secs 300

# Smart broadcasting (only when moved)
meshtastic --port /dev/cu.usbmodem14101 \
  --set position.position_broadcast_smart_enabled true
```

### Bluetooth Configuration
```bash
# Enable Bluetooth
meshtastic --port /dev/cu.usbmodem14101 \
  --set bluetooth.enabled true

# Set PIN (default: 123456)
meshtastic --port /dev/cu.usbmodem14101 \
  --set bluetooth.fixed_pin 123456
```

### Channel Info
```bash
# View current channels
meshtastic --port /dev/cu.usbmodem14101 --info | grep -A 5 "Channels:"

# Get channel URL (for sharing config)
meshtastic --port /dev/cu.usbmodem14101 --info | grep "URL:"
```

---

## Troubleshooting

### Can't Connect to Mesh Device
```bash
# List USB devices
ls /dev/cu.usbmodem*

# Check if port is in use
lsof | grep usbmodem

# Kill any blocking processes
# (Find PID from lsof, then:)
kill -9 <PID>
```

### BLE Won't Work
**Remember:** BLE and USB serial CANNOT work simultaneously!
- Disconnect USB-C cable from DUO
- OR stop any meshtastic CLI commands

### Position Data Not Updating
```bash
# Force an update
meshtastic --port /dev/cu.usbmodem14101 \
  --set position.position_broadcast_secs 10

# Wait 10 seconds, then check
meshtastic --port /dev/cu.usbmodem14101 --nodes
```

### Check Firmware Version
```bash
meshtastic --port /dev/cu.usbmodem14101 --info | grep firmware
# Should show: 2.7.18.fb3bf78 or newer
```

---

## File Locations

### iOS Bridge
- **Project:** `~/projects/tracker/ios-bridge/`
- **Protobufs:** `~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs/`
- **Scripts:** `~/projects/tracker/ios-bridge/Scripts/`

### Garmin Watch App
- **Project:** `~/projects/tracker/garmin-watchapp/`
- **Source:** `~/projects/tracker/garmin-watchapp/source/`
- **Binary:** `~/projects/tracker/garmin-watchapp/bin/Tracker.prg`

### Documentation
- **Status:** `~/projects/tracker/PROJECT_STATUS.md`
- **Deployment:** `~/projects/tracker/DEPLOYMENT_GUIDE.md`
- **This File:** `~/projects/tracker/QUICK_REFERENCE.md`

---

## Node IDs (Your Mesh)

Quick reference for node addressing:

| Node Name | Node ID | Hardware | Status |
|-----------|---------|----------|--------|
| DUO 1 | !b4458cbb | MUZI_BASE | ✅ Online |
| DUO2 | !45a248b6 | MUZI_BASE | ✅ Online |
| Paws | !e8588aea | THINKNODE_M3 | ⚠️ Offline |
| 77bc | !52bc77bc | RAK4631 | ✅ Online (3 hops) |
| Fuzzy Pumper | !69842820 | HELTEC_V4 | ✅ Online (5 hops) |
| circle 1 | !6c73c328 | TBEAM | ✅ Online |

---

## Performance Expectations

### Latency
- **Mesh packet propagation:** 1-5 seconds
- **BLE transfer:** 0.1-0.5 seconds
- **Total end-to-end:** 2-6 seconds

### Update Rates
- **Position broadcasts:** 300-3600 seconds (configurable)
- **Smart updates:** Only when moved >100m
- **BLE notifications:** Near real-time when data changes

### Signal Quality
- **Good SNR:** >5 dB (strong signal)
- **Acceptable:** -5 to 5 dB (usable)
- **Poor:** <-10 dB (unreliable)

### Battery Life
- **Mesh device:** 48-72 hours (5min updates)
- **iPhone:** 8-12 hours (continuous BLE)
- **Garmin:** 15-20 hours (GPS + BLE)

---

## Emergency Commands

### Factory Reset Mesh Device
```bash
# ⚠️ USE WITH CAUTION - Will erase all config!
meshtastic --port /dev/cu.usbmodem14101 --factory-reset
```

### Reboot Mesh Device
```bash
meshtastic --port /dev/cu.usbmodem14101 --reboot
```

### Export Configuration (Backup)
```bash
meshtastic --port /dev/cu.usbmodem14101 --export-config > duo1_config.yaml
```

### Restore Configuration
```bash
meshtastic --port /dev/cu.usbmodem14101 --configure duo1_config.yaml
```

---

## Quick Links

- **Meshtastic Docs:** https://meshtastic.org/docs/
- **Connect IQ Guide:** https://developer.garmin.com/connect-iq/programmers-guide/
- **SwiftProtobuf:** https://github.com/apple/swift-protobuf
- **CoreBluetooth:** https://developer.apple.com/documentation/corebluetooth

---

**Print this file and keep it nearby when testing!**

**Created:** 2026-02-02
**For:** Quick reference during development and testing
