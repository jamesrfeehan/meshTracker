# Meshtastic-Garmin iOS Bridge

iOS app that bridges Meshtastic mesh network to Garmin watches via BLE.

## Overview

This app acts as a BLE bridge:
- **BLE Central** to Meshtastic device (receives position updates)
- **BLE Peripheral** to Garmin watch (broadcasts position data)

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  iOS Bridge App                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────┐    ┌───────────────────┐  │
│  │  Meshtastic        │    │  Garmin           │  │
│  │  BLE Central       │    │  BLE Peripheral   │  │
│  │                    │    │                   │  │
│  │  - Scan/Connect    │    │  - Advertise      │  │
│  │  - Subscribe to    │───▶│  - GATT Service   │  │
│  │    notifications   │    │  - Update chars   │  │
│  │  - Parse protobuf  │    │  - Notify watch   │  │
│  └────────────────────┘    └───────────────────┘  │
│           ▲                          │              │
│           │                          ▼              │
│  ┌────────┴──────────────────────────┴──────────┐ │
│  │         Position Tracker Service              │ │
│  │  - Store node positions                       │ │
│  │  - Calculate distances                        │ │
│  │  - Manage active nodes                        │ │
│  │  - Filter by distance/time                    │ │
│  └───────────────────────────────────────────────┘ │
│                                                      │
└─────────────────────────────────────────────────────┘
         ▲                                    ▼
    Meshtastic                           Garmin Watch
    Device(s)                            (Fenix 6, etc)
```

## Project Structure

```
MeshtasticGarminBridge/
├── MeshtasticGarminBridge/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── MeshtasticGarminBridgeApp.swift
│   ├── Models/
│   │   ├── MeshNode.swift              # Position, metadata
│   │   ├── NodeTracker.swift           # Track multiple nodes
│   │   └── GarminPacket.swift          # BLE packet format
│   ├── Services/
│   │   ├── MeshtasticService.swift     # BLE Central to Meshtastic
│   │   ├── GarminService.swift         # BLE Peripheral for Garmin
│   │   └── PositionCalculator.swift    # Distance/bearing math
│   ├── Views/
│   │   ├── ContentView.swift           # Main UI
│   │   ├── NodeListView.swift          # Show all tracked nodes
│   │   ├── MapView.swift               # Map overlay
│   │   └── SettingsView.swift          # Configuration
│   ├── Protobufs/
│   │   └── mesh.pb.swift               # Generated from Meshtastic
│   └── Resources/
│       ├── Info.plist
│       └── Assets.xcassets
├── MeshtasticGarminBridgeTests/
└── MeshtasticGarminBridge.xcodeproj
```

## Technical Specs

### BLE Service Design

**Custom GATT Service for Garmin:**

```swift
// UUIDs
let MG_SERVICE_UUID    = "D8F8A001-MESH-4000-8000-00805F9B34FB"
let MG_POSITION_CHAR   = "D8F8A002-MESH-4000-8000-00805F9B34FB"
let MG_NODELIST_CHAR   = "D8F8A003-MESH-4000-8000-00805F9B34FB"
let MG_CONFIG_CHAR     = "D8F8A004-MESH-4000-8000-00805F9B34FB"

// Position Packet Format (20 bytes)
struct GarminPositionPacket {
    uint32_t node_id;        // Node identifier (4 bytes)
    float    latitude;       // Degrees (4 bytes)
    float    longitude;      // Degrees (4 bytes)
    int16_t  altitude;       // Meters (2 bytes)
    uint32_t timestamp;      // Unix seconds (4 bytes)
    uint8_t  battery;        // Percent 0-100 (1 byte)
    int8_t   snr;            // Signal strength (1 byte)
} __attribute__((packed));  // Total: 20 bytes

// Node List Packet (for multiple nodes)
// Each entry: 12 bytes
struct GarminNodeEntry {
    uint32_t node_id;        // Node identifier
    float    distance;       // Meters from you
    int16_t  bearing;        // Degrees 0-359
    uint16_t last_seen;      // Seconds ago
} __attribute__((packed));
```

### Meshtastic Integration

**Subscribe to position updates:**

```swift
// Meshtastic uses standard BLE service
let MESHTASTIC_SERVICE_UUID = "6BA1B218-15A8-461F-9FA8-5DCAE273EAFD"
let MESHTASTIC_FROMRADIO    = "2C55E69E-4993-11ED-B878-0242AC120002"
let MESHTASTIC_TORADIO      = "F75C76D2-129E-4DAD-A1DD-7866124401E7"

// Protobuf format (already defined by Meshtastic)
// We just parse the position packets
```

## Key Features

### Multi-Node Tracking
- Track unlimited Meshtastic nodes
- Auto-filter by distance (e.g., only show <10km away)
- Auto-remove stale nodes (>30 min old)
- Prioritize closest nodes

### Smart Node Selection
- User can pin specific nodes (e.g., "Track my dog")
- Auto-select closest node
- Cycle through nodes on watch
- Group mode: Track all in group

### Background Operation
- Works when app is backgrounded
- BLE peripheral stays active
- Position updates continue
- Battery optimized

### Integration Features
- Export to GPX/KML
- History logging
- Share node coordinates
- Emergency "Help" button

## Development Roadmap

### Phase 1: Core Bridge (Week 1)
```
Day 1-2: Project setup
- Create Xcode project
- Add Meshtastic protobuf definitions
- Setup BLE permissions
- Basic UI scaffolding

Day 3-4: Meshtastic Connection
- BLE Central implementation
- Scan for Meshtastic devices
- Parse protobuf packets
- Extract position data

Day 5-7: Garmin Peripheral
- BLE Peripheral setup
- GATT service implementation
- Position packet formatting
- Test with LightBlue app
```

### Phase 2: Watch App (Week 2)
```
Day 1-2: Connect IQ Setup
- Install SDK
- Create data field project
- Basic BLE scanning

Day 3-4: Position Display
- Connect to iOS bridge
- Parse position packets
- Calculate distance/bearing
- Display on watch

Day 5-7: Testing & Polish
- Field testing
- UI refinement
- Error handling
```

### Phase 3: Advanced Features (Week 3)
```
- Multi-node support
- Node filtering
- Settings/configuration
- History/logging
- Map integration
```

### Phase 4: Production (Week 4)
```
- App Store submission
- Connect IQ Store submission
- Documentation
- Open source release
```

## What You Have Now ✅

The **iOS bridge starter code** is complete and ready to build:

**Core Services:**
- ✅ `MeshtasticService.swift` - BLE Central (connects to your Base Duos)
- ✅ `GarminService.swift` - BLE Peripheral (serves data to Garmin watches)
- ✅ `BridgeCoordinator.swift` - Smart coordinator (filters, selects, forwards)

**Models & UI:**
- ✅ `MeshNode.swift` - Position data with distance/bearing calculations
- ✅ `ContentView.swift` - Clean SwiftUI interface
- ✅ `Info.plist` - All BLE/Location permissions configured

**Documentation:**
- ✅ `GETTING_STARTED.md` - Step-by-step Xcode setup
- ✅ `TODO.md` - Prioritized work breakdown

**What's Missing:**
- ❌ Protobuf parsing (placeholder code only - needs Meshtastic protobuf integration)
- ❌ Garmin Connect IQ watch app (see `GARMIN_CONNECTIQ_APP_PLAN.md`)

**You can build and run this TODAY** - it will scan, connect, and advertise. Just needs protobuf to parse real position data.

---

## Getting Started

### Prerequisites

```bash
# Install Xcode
# Install Connect IQ SDK
brew install connectiq-sdk

# Install Protobuf compiler
brew install protobuf swift-protobuf

# Clone this repo
git clone https://github.com/yourusername/meshtastic-garmin-bridge
cd meshtastic-garmin-bridge
```

### Building

```bash
# Generate protobuf Swift files
cd protobufs
protoc --swift_out=../MeshtasticGarminBridge/Protobufs mesh.proto

# Open in Xcode
open MeshtasticGarminBridge.xcodeproj
```

### Running

1. Open Xcode project
2. Select your iPhone as target
3. Build and run (Cmd+R)
4. Grant Bluetooth permissions
5. Connect to your Meshtastic device
6. App starts advertising to Garmin watches

## Use Cases

### Backcountry Skiing
```
Scenario: Group of 4 skiers
- Each has Meshtastic device
- Leader has iPhone with bridge app + Garmin watch
- Watch shows distance/bearing to all 3 others
- Integrated with avalanche beacons
```

### Mountain Biking
```
Scenario: Trail riding group
- Everyone has Meshtastic on bike
- See who's ahead, who's behind
- Navigate to stragglers
- Meeting point coordination
```

### Hiking with Kids
```
Scenario: Family hike
- Kids have Meshtastic trackers
- Parents have Garmin watches
- Always know where kids are
- Perimeter alerts if too far
```

### Search & Rescue
```
Scenario: SAR operation
- Team members have Meshtastic
- Incident command has bridge + watch
- Track all team positions
- Coordinate rescue efforts
```

## Avalanche Beacon Integration (Future)

**Potential integration with transceivers:**

Most avalanche beacons use 457kHz analog signal, BUT:
- Newer beacons (RECCO, some Mammut) have digital capabilities
- Could create hybrid system:
  - Normal operation: Meshtastic tracking
  - Avalanche mode: Switch to beacon
  - Post-avalanche: Meshtastic shows last known position

**Protocol for avalanche scenario:**
```swift
// Special packet type
struct AvalancheAlert {
    uint32_t node_id;
    float    last_latitude;
    float    last_longitude;
    uint32_t alert_timestamp;
    uint8_t  alert_type;     // 0=SOS, 1=Avalanche, 2=Fall
}
```

## Technical Considerations

### BLE Reliability
- Reconnection logic
- Packet loss handling
- Multiple simultaneous connections
- Background mode optimization

### Battery Life
- Target: <5% additional drain/hour
- Optimize BLE advertising interval
- Smart notification batching
- Adjustable update frequencies

### Range & Coverage
- Meshtastic: 5-10km range
- Garmin BLE: ~10m range (watch must be near phone)
- Solution: Phone stays in pocket, watch on wrist
- Mesh network extends overall coverage

### Data Privacy
- Position data never leaves device
- No cloud uploads
- Encrypted BLE connection
- User controls what to share

## Open Source

This project will be **fully open source** (MIT License):
- Community contributions welcome
- No paywalls, no subscriptions
- Educational resource
- Benefit the entire Meshtastic ecosystem

## Contributing

We welcome contributions:
1. Fork the repository
2. Create feature branch
3. Make your changes
4. Submit pull request
5. Join Discord for discussion

## Community

- **Discord**: Meshtastic server, #garmin-integration channel
- **GitHub**: Issues, discussions, PRs
- **Forum**: Meshtastic community forum

## License

MIT License - see LICENSE file

## Credits

- Meshtastic project team
- Garmin Connect IQ team
- Contributors and testers

## Acknowledgments

This project bridges two amazing open-source/open-platform ecosystems:
- **Meshtastic**: Off-grid mesh communication
- **Garmin Connect IQ**: Wearable app platform

Together, they enable backcountry safety and coordination without cell service.

---

**Status**: Under active development
**First Release**: Targeting Q2 2026
**Maintainer**: [@yourusername]
