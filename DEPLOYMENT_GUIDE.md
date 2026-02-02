# Mesh Tracker - Complete Deployment Guide

**Last Updated:** 2026-02-02
**Status:** Ready for Testing

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Phase 1: Mesh Network Setup](#phase-1-mesh-network-setup)
4. [Phase 2: iOS Bridge App](#phase-2-ios-bridge-app)
5. [Phase 3: Garmin Watch App](#phase-3-garmin-watch-app)
6. [Testing Procedures](#testing-procedures)
7. [Troubleshooting](#troubleshooting)
8. [Performance Optimization](#performance-optimization)

---

## System Overview

### Complete Signal Flow

```
[Mesh Nodes] ──LoRa 2.4GHz──> [Base Duo] ──BLE──> [iPhone] ──BLE──> [Garmin Watch]
   (Paws)                       (DUO1/2)        (iOS Bridge)      (Instinct 2X)
```

### Component Status

| Component | Status | Location |
|-----------|--------|----------|
| Base DUO1 | ✅ Ready | USB-C connected to Mac |
| Base DUO2 | ✅ Ready | USB-C connected to Mac |
| Paws (ThinkNode) | ⚠️ Offline | Last heard 26hr ago |
| iOS Bridge App | ✅ Code Complete | `~/projects/tracker/ios-bridge/` |
| Garmin Watch App | ✅ Code Complete | `~/projects/tracker/garmin-watchapp/` |
| Python Test Tools | ✅ Ready | `~/projects/tracker/ios-bridge/Scripts/` |

---

## Hardware Requirements

### Essential

- **2x Muzi Base Duo** (DUO1, DUO2) - ✅ You have these
  - Firmware: 2.7.18.fb3bf78
  - LoRa 2.4GHz, LONG_FAST preset
  - Bluetooth: Enabled (PIN: 123456)

- **1x iPhone** (iOS 15+)
  - Bluetooth LE capable
  - Developer profile for testing

- **1x Garmin Instinct 2X Solar** - ✅ You have this
  - Connect IQ 4.0+
  - Developer mode enabled

### Optional

- **1x Muzi ThinkNode M3** (Paws) - Target to track
- **Additional mesh nodes** - More targets (77bc, Fuzzy Pumper, etc.)
- **Mac with Xcode** - For iOS development (Xcode downloading...)
- **USB-C cables** - For mesh device configuration

---

## Phase 1: Mesh Network Setup

### 1.1 Verify Mesh Network

```bash
# Check DUO1 connectivity
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --info

# Check DUO2 connectivity
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14201 --info

# Run automated test suite
cd ~/projects/tracker/ios-bridge/Scripts
./test_mesh.py test
```

**Expected Result:**
- DUO1 sees DUO2 (SNR: ~6.75 dB)
- DUO2 sees DUO1 (SNR: ~7.0 dB)
- DUO1 reports 8 nodes in mesh
- Position data available for DUO1

### 1.2 Configure GPS (if needed)

```bash
# Enable GPS on DUO1 (if not already enabled)
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 \
  --set position.gps_enabled true

# Enable position broadcasts
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 \
  --set position.position_broadcast_secs 300
```

### 1.3 Test Position Broadcasting

```bash
# Monitor DUO1 for 60 seconds
cd ~/projects/tracker/ios-bridge/Scripts
./monitor_mesh.py DUO1 2
```

**Expected Output:**
- POSITION packets incrementing
- Coordinates displayed
- SNR readings visible

---

## Phase 2: iOS Bridge App

### 2.1 Prerequisites

```bash
# Verify Xcode is installed
xcode-select -p
# Should show: /Applications/Xcode.app/Contents/Developer

# If not, set it:
sudo xcode-select -s /Applications/Xcode.app

# Verify protobufs generated
ls ~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs/meshtastic/
# Should show: mesh.pb.swift, telemetry.pb.swift, etc.
```

### 2.2 Open Xcode Project

```bash
open ~/projects/tracker/ios-bridge/MeshtasticGarminBridge.xcodeproj
```

### 2.3 Configure Signing

1. **Select Project** → MeshtasticGarminBridge target
2. **Signing & Capabilities**
   - Team: Select your Apple Developer account
   - Bundle Identifier: `com.yourteam.meshtasticgarminbridge`
   - Automatically manage signing: ✅

3. **Update Info.plist Permissions**
   - Bluetooth permission strings are already configured
   - Location permission strings are already configured

### 2.4 Build and Run

1. **Connect iPhone** via USB
2. **Select Device** - Choose your iPhone in toolbar
3. **Press ⌘R** to build and run

**First Launch:**
- iOS will prompt for Bluetooth permission → **Allow**
- iOS will prompt for Location permission → **Allow While Using**

### 2.5 Disconnect Mesh Device from Mac

**IMPORTANT:** BLE won't work if DUO is connected via USB to Mac!

```bash
# Check what's using the serial ports
lsof | grep usbmodem

# If meshtastic CLI is running, kill it
# Then physically disconnect USB-C cable from DUO1
```

### 2.6 Test BLE Connection

On iPhone app:
1. Tap **"Start Scanning"**
2. Should see device list appear (e.g., "DUO 1", "DUO2")
3. Tap **"DUO 1"** to connect
4. Wait for "Ready" status
5. Watch for position updates in log

**Expected Console Output:**
```
🔍 Scanning for Meshtastic devices...
📱 Found device: DUO 1
🔗 Connecting to DUO 1...
✅ Connected to DUO 1
✅ Subscribed to position updates
📦 Received packet: 42 bytes
📍 Position: DUO2 at (39.9704, -105.2574) alt: 1686m
👤 NodeInfo: DUO 1 (DUO1) - HW: MUZI_BASE
```

### 2.7 Verify BLE Peripheral Advertising

The iOS bridge should now be advertising as a BLE Peripheral for Garmin.

**Test with nRF Connect** (optional):
1. Install "nRF Connect" app on iPhone
2. Scan for devices
3. Should see "Mesh Tracker" advertising
4. Connect → See "Tracker Service" (0x181A)
5. Read Position Characteristic

---

## Phase 3: Garmin Watch App

### 3.1 Install Connect IQ SDK

```bash
# Download SDK from: https://developer.garmin.com/connect-iq/sdk/

# Or install via VS Code extension
# Extension: "Monkey C" by Garmin
```

### 3.2 Configure Project

```bash
cd ~/projects/tracker/garmin-watchapp

# Verify manifest.xml has correct device
grep "instinct2x" manifest.xml
```

### 3.3 Build Watch App

**Option A: VS Code**
1. Open `garmin-watchapp` folder in VS Code
2. Cmd+Shift+P → "Monkey C: Build for Device"
3. Select "Instinct 2X Solar"

**Option B: Command Line**
```bash
# Set path to SDK
export CIQ_SDK_PATH=~/ConnectIQ

# Build
monkeyc \
  -o bin/Tracker.prg \
  -f monkey.jungle \
  -y ~/.Garmin/ConnectIQ/developer_key \
  -d instinct2x
```

### 3.4 Deploy to Watch

**Via Garmin Express:**
1. Connect watch via USB
2. Copy `bin/Tracker.prg` to watch's APPS folder
3. Disconnect watch
4. Watch → Apps → Tracker

**Via Wi-Fi (if configured):**
1. Watch: Settings → Connectivity → Wi-Fi → Enable
2. VS Code: Cmd+Shift+P → "Monkey C: Run"
3. Select watch from network devices

### 3.5 First Run - Pairing

1. **Launch Tracker app on watch**
2. Should show: "Searching for iOS Bridge..."
3. **On iPhone**: iOS Bridge app should be running and connected to DUO
4. **Watch automatically scans** for BLE peripheral
5. **Pairing prompt** may appear on both devices → **Accept**
6. Watch displays: "Connected"

### 3.6 Verify Data Flow

**On Garmin Watch:**
```
╔══════════════════════════════════╗
║       MESH TRACKER              ║
╠══════════════════════════════════╣
║          ↗                       ║
║         DUO2                     ║
║         243m                     ║
║         NE                       ║
║                                  ║
║  SNR: 6.75 dB | Nodes: 8         ║
║  Updated: 2s ago                 ║
╚══════════════════════════════════╝
```

**Troubleshooting:**
- If "Searching..." persists → Check iPhone app is running
- If "No Data" → Check DUO has position updates
- If distance is 0 → Enable GPS on watch (Settings → Sensors → GPS)

---

## Testing Procedures

### Test 1: End-to-End Position Update

**Objective:** Verify position flows from mesh to watch

**Setup:**
- DUO1: Connected to iPhone via BLE (no USB)
- DUO2: Powered on, broadcasting position
- iPhone: Running iOS Bridge
- Watch: Running Tracker app

**Procedure:**
```bash
# 1. Force position update from DUO2
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14201 \
  --set position.position_broadcast_secs 10

# 2. Watch DUO1 receive update
# On iPhone app - should see log:
# "📍 Position: DUO2 at (...)"

# 3. Watch should update within 10 seconds
```

**Success Criteria:**
- ✅ Position appears on watch
- ✅ Distance calculation is accurate
- ✅ Bearing points correct direction
- ✅ Update latency < 15 seconds

### Test 2: Signal Quality

**Objective:** Verify SNR reporting

**Procedure:**
1. Note SNR on watch display
2. Compare with mesh CLI:
   ```bash
   ~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --nodes
   # Check "snr" field for DUO2
   ```

**Success Criteria:**
- ✅ SNR values match within ±2 dB

### Test 3: Range Test

**Objective:** Test tracking at various distances

**Procedure:**
1. Start with DUO2 nearby (~5m)
2. Move DUO2 incrementally further (10m, 50m, 100m, 500m)
3. Verify position updates at each distance
4. Note signal degradation

**Success Criteria:**
- ✅ Tracking works at all tested distances
- ✅ Distance calculation accuracy within ±10%
- ✅ SNR decreases with distance as expected

### Test 4: Multi-Node Selection

**Objective:** Switch between tracked nodes

**Procedure:**
1. On iOS Bridge: Implement node selection UI
2. Switch target from DUO2 to another node (e.g., "Paws")
3. Verify watch updates to new target

**Success Criteria:**
- ✅ Watch displays correct node name
- ✅ Position switches smoothly
- ✅ No connection drops

### Test 5: Battery Life

**Objective:** Measure power consumption

**Procedure:**
1. Fully charge watch
2. Run Tracker app for 8 hours
3. Monitor battery drain

**Expected:**
- Continuous GPS + BLE: ~15-20% per hour
- With power optimizations: ~8-10% per hour

---

## Troubleshooting

### iOS Bridge Issues

**Problem:** Can't see any Meshtastic devices in scan

**Solution:**
```bash
# 1. Verify Bluetooth is on
# 2. Disconnect DUO from USB (BLE won't work over USB!)
# 3. Power cycle DUO
# 4. Check Bluetooth permissions:
#    Settings → Privacy → Bluetooth → Allow for app
```

**Problem:** Connected but no packets received

**Solution:**
```bash
# Verify DUO is on correct channel
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --info
# Check "Channels:" section - should match iOS app expectations
```

**Problem:** Protobuf parsing errors

**Solution:**
```swift
// Check FROM_RADIO packet format
// Enable debug logging in MeshtasticService.swift:
print("Raw packet hex: \(data.hexEncodedString())")
```

### Garmin Watch Issues

**Problem:** "Searching for iOS Bridge..." never finds device

**Solution:**
1. Verify iOS bridge is advertising:
   - Use nRF Connect to scan from another phone
   - Should see "Mesh Tracker" service
2. Check Garmin BLE permissions:
   - Watch → Settings → System → About → Legal → Bluetooth
3. Restart watch Bluetooth:
   - Settings → Connectivity → Bluetooth → Off → On

**Problem:** Connected but "No Data"

**Solution:**
1. Check characteristic format matches:
   ```
   iOS: [lat(4), lon(4), alt(2), time(4), nodeID(4), snr(2)]
   Garmin: Same format expected
   ```
2. Verify byte order (Little Endian)
3. Add debug logging to BLEManager.mc

**Problem:** GPS not available on watch

**Solution:**
```
Watch → Settings → Sensors → GPS → On
Wait for GPS lock (may take 30-60s outdoors)
```

### Mesh Network Issues

**Problem:** Nodes not appearing

**Solution:**
```bash
# Check node database
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --nodes

# If empty, request node list
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --request-nodes

# Check channel configuration
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --info
# Ensure all devices on same channel
```

---

## Performance Optimization

### iOS Bridge

**Reduce BLE Power Consumption:**
```swift
// In GarminService.swift
// Reduce advertising frequency after first connection
peripheralManager.stopAdvertising()
// Re-advertise only when disconnected
```

**Optimize Position Updates:**
```swift
// In BridgeCoordinator.swift
// Only update characteristic when position changes > 10m
if distance(oldPosition, newPosition) > 10.0 {
    updateGarmin()
}
```

### Garmin Watch

**Battery Optimization:**
```monkey-c
// In TrackerView.mc
// Reduce GPS update rate when not moving
if (speed < 0.5) {  // m/s
    Position.enableLocationEvents(
        Position.LOCATION_ONE_SHOT,
        method(:onPosition)
    );
}
```

**Display Optimization:**
```monkey-c
// Update display only when data changes significantly
if (distanceDelta > 5 || bearingDelta > 5) {
    WatchUi.requestUpdate();
}
```

### Mesh Network

**Reduce Airtime:**
```bash
# Increase position broadcast interval (reduce mesh traffic)
meshtastic --set position.position_broadcast_secs 600  # 10 minutes

# Enable smart position broadcasting
meshtastic --set position.position_broadcast_smart_enabled true
```

---

## Next Steps

### Immediate (Ready to Test)
1. ✅ Wait for Xcode to finish downloading
2. ⏭️ Build iOS bridge app
3. ⏭️ Test BLE connection to DUO1
4. ⏭️ Verify position updates flow

### Short Term (This Week)
- Install Connect IQ SDK
- Build Garmin watch app
- Test end-to-end tracking
- Optimize battery life

### Medium Term (Next 2 Weeks)
- Add multi-node selection UI
- Implement waypoint marking
- Create route history
- Field testing in real scenarios

### Long Term (Future)
- Garmin Connect IQ Store submission
- Open source release
- Community contributions
- Advanced features (groups, geofencing, etc.)

---

## Support Resources

### Documentation
- **iOS Bridge:** `~/projects/tracker/ios-bridge/README.md`
- **Architecture:** `~/projects/tracker/ios-bridge/ARCHITECTURE.md`
- **Mesh Status:** `~/projects/tracker/ios-bridge/MESH_NETWORK_STATUS.md`
- **Garmin App:** `~/projects/tracker/garmin-watchapp/README.md`

### Test Tools
- **Mesh Tester:** `~/projects/tracker/ios-bridge/Scripts/test_mesh.py`
- **Mesh Monitor:** `~/projects/tracker/ios-bridge/Scripts/monitor_mesh.py`

### External Resources
- [Meshtastic Docs](https://meshtastic.org/docs/)
- [Connect IQ Programmer's Guide](https://developer.garmin.com/connect-iq/programmers-guide/)
- [CoreBluetooth Apple Docs](https://developer.apple.com/documentation/corebluetooth)

---

**End of Deployment Guide**

Your system is ready to build and test! All code is complete and waiting for Xcode to finish installing.
