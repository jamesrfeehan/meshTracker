# Garmin Connect IQ Watch App

Companion app for Garmin watches to display mesh tracker position data.

## Overview

This Garmin Connect IQ application:
1. Connects to the iOS bridge app via BLE
2. Reads position data of tracked mesh nodes
3. Displays distance, bearing, and position info
4. Shows on a compass-style interface

## Architecture

```
┌──────────────────────────────────────────┐
│         Garmin Watch (Instinct 2X)        │
├──────────────────────────────────────────┤
│  Connect IQ App (Monkey C)                │
│  - BLE Central                             │
│  - Reads position characteristic          │
│  - Calculates distance/bearing            │
│  - Renders compass UI                     │
└──────────────┬───────────────────────────┘
               │ BLE
┌──────────────▼───────────────────────────┐
│         iOS Bridge App (iPhone)          │
│  - BLE Peripheral                         │
│  - Advertises position service            │
│  - Characteristic: Position (Read/Notify)│
└──────────────┬───────────────────────────┘
               │ BLE Central
┌──────────────▼───────────────────────────┐
│      Meshtastic Device (Base Duo)        │
│  - Receives mesh position updates         │
│  - Forwards via BLE to iPhone             │
└──────────────────────────────────────────┘
```

## BLE Protocol

### Service UUID
```
0000181A-0000-1000-8000-00805f9b34fb (Custom Tracker Service)
```

### Characteristics

**Position Characteristic** (Read + Notify)
```
UUID: 00002A67-0000-1000-8000-00805f9b34fb

Format: 20 bytes binary
┌─────────┬────────┬─────────┬─────────┬──────────┬──────────┐
│ Lat (4) │ Lon(4) │ Alt (2) │ Time(4) │ NodeID(4)│ SNR (2)  │
└─────────┴────────┴─────────┴─────────┴──────────┴──────────┘
  Float     Float    Int16     UInt32    UInt32     Float

Latitude:  Degrees (float, -90 to 90)
Longitude: Degrees (float, -180 to 180)
Altitude:  Meters (int16)
Timestamp: Unix time (uint32)
NodeID:    Meshtastic node number (uint32)
SNR:       Signal-to-noise ratio (float)
```

**Status Characteristic** (Read)
```
UUID: 00002A68-0000-1000-8000-00805f9b34fb

Format: 8 bytes binary
┌──────────┬─────────────┬──────────┬──────────┐
│ Connected│ Nodes Seen  │ Updates  │ Battery  │
│  (1)     │    (1)      │  (4)     │  (2)     │
└──────────┴─────────────┴──────────┴──────────┘
  Bool       UInt8         UInt32     UInt16

Connected:   1 if mesh connected, 0 if not
NodesSeen:   Number of nodes in mesh
Updates:     Total position updates received
Battery:     iOS device battery (0-100)
```

## Connect IQ Development

### Prerequisites

1. **Install Garmin Connect IQ SDK**
   ```bash
   # Download from: https://developer.garmin.com/connect-iq/sdk/
   # Or install via VS Code extension
   ```

2. **Install VS Code Extension**
   - "Monkey C" extension by Garmin
   - Provides syntax highlighting, debugging, simulator

3. **Configure Target Device**
   - Device: Garmin Instinct 2X Solar
   - API Level: 4.0.0+
   - Minimum SDK: 4.0.0

### Project Structure

```
garmin-watchapp/
├── manifest.xml          # App metadata and permissions
├── resources/
│   ├── drawables/       # Icons and graphics
│   ├── layouts/         # UI layouts
│   ├── strings/         # Localized strings
│   └── settings/        # App settings
├── source/
│   ├── TrackerApp.mc    # Main application
│   ├── TrackerView.mc   # Display view
│   ├── BLEManager.mc    # BLE connection handling
│   └── PositionCalc.mc  # Distance/bearing calculations
└── README.md
```

### Building

```bash
# Using monkeyc compiler
monkeyc \
  -o bin/Tracker.prg \
  -m manifest.xml \
  -z resources/drawables/icon.png \
  -y ~/Library/Application\ Support/Garmin/ConnectIQ/developer_key

# Or use VS Code:
# Cmd+Shift+P → "Monkey C: Build for Device"
```

### Testing

```bash
# Launch simulator
connectiq

# Or use device:
# 1. Connect watch via USB
# 2. Cmd+Shift+P → "Monkey C: Run"
```

## App Features

### Main Screen - Compass View

```
╔══════════════════════════════════════╗
║             MESH TRACKER             ║
╠══════════════════════════════════════╣
║                                      ║
║         ↑                            ║
║         │  DUO2                      ║
║         │  243m                      ║
║         │  NW                        ║
║         │                            ║
║    ┌────┼────┐                       ║
║    │    ●    │  Compass              ║
║    └─────────┘                       ║
║                                      ║
║  SNR: 6.75 dB | Nodes: 8             ║
║  Updated: 2s ago                     ║
╚══════════════════════════════════════╝
```

### Data Fields Available

1. **Target Name** - Short name of tracked node
2. **Distance** - Meters to target
3. **Bearing** - Cardinal direction (N, NE, E, etc.)
4. **Bearing Degrees** - Exact heading (0-360°)
5. **Altitude Delta** - Height difference
6. **Signal Quality** - SNR in dB
7. **Last Update** - Time since last position
8. **Mesh Status** - Connected / # nodes

### Settings

- **Target Node** - Select which mesh node to track (default: nearest)
- **Units** - Metric / Imperial
- **Update Rate** - Position refresh interval
- **Auto-Select** - Automatically track nearest node

## Development Roadmap

### Phase 1: Core BLE ✅
- [x] BLE service definition
- [x] Characteristic format specification
- [ ] Connect IQ BLE profile implementation
- [ ] iOS bridge BLE peripheral

### Phase 2: Basic Display
- [ ] Compass UI layout
- [ ] Distance calculation
- [ ] Bearing calculation
- [ ] Data display

### Phase 3: Advanced Features
- [ ] Multi-node selection
- [ ] Waypoint marking
- [ ] Route tracking
- [ ] Battery optimization

### Phase 4: Polish
- [ ] Custom icons
- [ ] Settings page
- [ ] Error handling
- [ ] Field testing

## Connect IQ API Notes

### BLE Scanning (Central Role)
```monkey-c
using Toybox.BluetoothLowEnergy as Ble;

// Start scanning
var scanResult = Ble.scanResults();

// Profile definition
var profileDef = {
    Ble.SERVICE_UUID => SERVICE_UUID,
    Ble.CHARACTERISTIC_UUID => CHAR_UUID
};

// Register profile
Ble.registerProfile(profileDef);
```

### Reading Characteristics
```monkey-c
// Read position data
var positionChar = device.getCharacteristic(POSITION_UUID);
var data = positionChar.read();

// Parse binary data
var lat = bytesToFloat(data.slice(0, 4));
var lon = bytesToFloat(data.slice(4, 8));
```

### Distance/Bearing Calculations
```monkey-c
using Toybox.Position;
using Toybox.Math;

// Haversine distance
var distance = Position.haversine(
    myLat, myLon,
    targetLat, targetLon
);

// Bearing
var bearing = Position.bearing(
    myLat, myLon,
    targetLat, targetLon
);
```

## Deployment

### For Testing
1. Connect Garmin watch via USB
2. Enable Developer Mode on watch
3. Build and run from VS Code

### For Distribution (Future)
1. Create Garmin Developer account
2. Submit to Connect IQ Store
3. Review and approval process
4. Public release

## Resources

- [Connect IQ Programmer's Guide](https://developer.garmin.com/connect-iq/programmers-guide/)
- [Monkey C API Docs](https://developer.garmin.com/connect-iq/api-docs/)
- [BLE Profile Guide](https://developer.garmin.com/connect-iq/core-topics/bluetooth-low-energy/)
- [Instinct 2X Specs](https://developer.garmin.com/connect-iq/compatible-devices/)

## License

MIT License - See LICENSE file
