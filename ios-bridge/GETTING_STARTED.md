# Getting Started - iOS Bridge App

Quick guide to building and running the Meshtastic → Garmin bridge app.

## Prerequisites

- **Xcode 15+** (download from Mac App Store)
- **iOS 15+ device** (iPhone/iPad with Bluetooth)
- **Apple Developer account** (free tier is fine for testing)
- **Meshtastic device** (your Base Duo or ThinkNode)
- **Garmin watch** (optional for testing - you can use LightBlue app instead)

## Project Setup

### 1. Create Xcode Project

```bash
cd ~/projects/tracker/ios-bridge
```

**Option A: Command Line (requires Xcode command-line tools)**
```bash
# This would create the project programmatically
# But it's easier to just use Xcode GUI
```

**Option B: Xcode GUI (Recommended)**

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Fill in:
   - Product Name: `MeshtasticGarminBridge`
   - Team: Your Apple ID
   - Organization Identifier: `com.yourdomain`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
5. Save to: `~/projects/tracker/ios-bridge`

### 2. Add Files to Project

In Xcode, **drag and drop** these directories into the project navigator:

```
MeshtasticGarminBridge/
├── App/
│   └── MeshtasticGarminBridgeApp.swift
├── Models/
│   └── MeshNode.swift
├── Services/
│   ├── MeshtasticService.swift
│   ├── GarminService.swift
│   └── BridgeCoordinator.swift
├── Views/
│   └── ContentView.swift
└── Resources/
    └── Info.plist
```

**Important:** When dragging, select:
- ✅ "Copy items if needed"
- ✅ "Create groups"
- ✅ Add to target: MeshtasticGarminBridge

### 3. Configure Info.plist

**Option 1: Use the one we created**
- Replace the default Info.plist with `Resources/Info.plist`

**Option 2: Add manually in Xcode**
1. Select project → Target → Info tab
2. Add Custom iOS Target Properties:
   - `NSBluetoothAlwaysUsageDescription`: "Bridge needs Bluetooth"
   - `NSLocationWhenInUseUsageDescription`: "Calculate distances"
3. Add Background Modes capability:
   - bluetooth-central
   - bluetooth-peripheral
   - location

### 4. Add Required Frameworks

In Xcode:
1. Select project → Target → General
2. Scroll to "Frameworks, Libraries, and Embedded Content"
3. Click `+` and add:
   - **CoreBluetooth.framework**
   - **CoreLocation.framework**
   - **Combine.framework** (built-in)

## Building & Running

### 1. Connect Your iPhone

- Plug iPhone into Mac with USB cable
- Trust computer when prompted
- Unlock phone

### 2. Select Device

- In Xcode toolbar, click device dropdown
- Select your iPhone (not simulator - BLE doesn't work in simulator)

### 3. Configure Signing

1. Select project → Target → Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your Apple ID team
4. Xcode will provision your device

### 4. Build & Run

Press **Cmd + R** or click the Play button

First launch will:
1. Install app on your phone
2. Prompt for Bluetooth permission → **Allow**
3. Prompt for Location permission → **Allow While Using App**

## Testing Without Garmin Watch

You can test the BLE peripheral functionality using **LightBlue Explorer** app:

### 1. Install LightBlue

```bash
# iOS
# Download "LightBlue" from App Store (on a second device)

# Or use Mac version
brew install --cask lightblue
```

### 2. Test BLE Peripheral

1. Open your bridge app on iPhone
2. Tap **"Start Bridge"**
3. Open LightBlue on second device
4. Scan for devices
5. Look for **"Meshtastic Bridge"**
6. Connect to it
7. Should see service: `D8F8A001-MESH-4000-8000-00805F9B34FB`
8. Subscribe to characteristic: `D8F8A002-MESH-4000-8000-00805F9B34FB`

### 3. Test with Real Meshtastic Device

1. Make sure your Base Duo is powered on
2. In bridge app, tap **"Start Bridge"**
3. Should see your device appear (e.g., "DUO1", "DUO2")
4. Tap device to connect
5. Once connected, status should show "Ready"
6. When "paws" (or other nodes) send position updates, they'll appear in "Tracked Nodes"

## Project Structure

```
MeshtasticGarminBridge.xcodeproj
└── MeshtasticGarminBridge/
    ├── App/
    │   └── MeshtasticGarminBridgeApp.swift     # App entry point
    ├── Models/
    │   └── MeshNode.swift                      # Position data model
    ├── Services/
    │   ├── MeshtasticService.swift             # BLE Central (connects TO Meshtastic)
    │   ├── GarminService.swift                 # BLE Peripheral (serves data TO Garmin)
    │   └── BridgeCoordinator.swift             # Glue between the two
    ├── Views/
    │   └── ContentView.swift                   # Main UI
    └── Resources/
        ├── Info.plist                          # Permissions
        └── Assets.xcassets/                    # Icons, colors

```

## How It Works

### Data Flow

```
Meshtastic Device (paws, DUO1, DUO2)
           ↓ BLE Notifications
   MeshtasticService (BLE Central)
           ↓ Parse position packets
      BridgeCoordinator
           ↓ Filter & select nodes
     GarminService (BLE Peripheral)
           ↓ BLE Notifications
      Garmin Watch
```

### 1. MeshtasticService (BLE Central)

- Scans for Meshtastic devices
- Connects to your Base Duo
- Subscribes to FROM_RADIO characteristic
- Receives position updates from ALL nodes in mesh
- Parses protobuf packets (TODO: need protobuf integration)

### 2. BridgeCoordinator (Logic Layer)

- Receives node updates from MeshtasticService
- Filters stale nodes (>30 min old)
- Filters distant nodes (>10km away)
- Auto-selects closest node OR user-selected node
- Forwards selected node to GarminService

### 3. GarminService (BLE Peripheral)

- Advertises as "Meshtastic Bridge"
- Serves GATT service with custom UUIDs
- Updates position characteristic (20-byte binary format)
- Updates node list characteristic (12 bytes per node)
- Notifies subscribed Garmin watches

## Next Steps

### Immediate (What You Can Do Now)

1. **Build & run the app** - Test basic UI
2. **Connect to DUO1 or DUO2** - See Meshtastic connection
3. **Test BLE advertising** - Use LightBlue to verify Garmin service

### Short Term (Need Protobuf)

4. **Add Meshtastic protobuf definitions** - Parse real position packets
5. **Test with live mesh** - See "paws" position updates in real-time
6. **Add map view** - Visualize nodes on map

### Long Term (Complete Solution)

7. **Build Garmin Connect IQ app** - Display on watch
8. **Field testing** - Take to backcountry
9. **Battery optimization** - Tune update intervals
10. **Multi-node UI** - Better node selection/filtering

## Protobuf Integration

Currently, the app has **placeholder protobuf parsing**. To parse real Meshtastic packets:

### Option 1: Use Swift Protobuf (Recommended)

```bash
# Install Swift Protobuf compiler
brew install swift-protobuf

# Get Meshtastic protobuf definitions
git clone https://github.com/meshtastic/protobufs.git
cd protobufs

# Generate Swift code
protoc --swift_out=../ios-bridge/MeshtasticGarminBridge/Protobufs \
       *.proto

# Add generated files to Xcode project
```

### Option 2: Use Meshtastic Swift Library

Check if Meshtastic has a Swift library with protobuf already integrated:
- https://github.com/meshtastic/Meshtastic-Apple
- May be able to import directly via SPM

### Example Protobuf Usage

Once you have generated Swift protobufs:

```swift
// In MeshtasticService.swift
import MeshtasticProtobufs

private func parseFromRadioPacket(_ data: Data) {
    do {
        // Decode FromRadio wrapper
        let fromRadio = try FromRadio(serializedData: data)

        // Check if it's a mesh packet
        if fromRadio.hasPacket {
            let meshPacket = fromRadio.packet

            // Check if it's a position packet
            if meshPacket.decoded.portnum == .positionApp {
                let position = try Position(serializedData: meshPacket.decoded.payload)

                // Create MeshNode
                let node = MeshNode(
                    nodeId: meshPacket.from,
                    shortName: getShortName(for: meshPacket.from),
                    longName: getLongName(for: meshPacket.from),
                    latitude: Double(position.latitudeI) / 1e7,
                    longitude: Double(position.longitudeI) / 1e7,
                    altitude: Int16(position.altitude),
                    timestamp: Date(timeIntervalSince1970: TimeInterval(position.time)),
                    battery: getBatteryLevel(for: meshPacket.from),
                    snr: Int8(meshPacket.rxSnr)
                )

                // Forward to coordinator
                onNodeUpdate?(node)
            }
        }
    } catch {
        print("❌ Protobuf decode error: \(error)")
    }
}
```

## Troubleshooting

### App Won't Build

- **Error: "No such module CoreBluetooth"**
  - Add CoreBluetooth.framework to project

- **Error: "Cannot find 'MeshNode' in scope"**
  - Make sure all files are added to target
  - Check Build Phases → Compile Sources

### BLE Issues

- **No devices found when scanning**
  - Check Bluetooth is enabled on Mac/iPhone
  - Make sure Meshtastic device is powered on
  - Try restarting both devices

- **Connection fails immediately**
  - Meshtastic may be connected to iPad app
  - Disconnect from other apps first
  - Only one BLE central can connect at a time

- **Not advertising to Garmin**
  - Check Bluetooth permissions granted
  - Check Background Modes enabled
  - Use LightBlue to verify service is visible

### Simulator Limitations

- **BLE doesn't work in simulator**
  - Must use real iPhone/iPad device
  - CoreBluetooth APIs return errors in simulator

## Resources

- **Meshtastic Protobufs**: https://github.com/meshtastic/protobufs
- **Meshtastic BLE API**: https://meshtastic.org/docs/developers/device/ble-api
- **Apple BLE Docs**: https://developer.apple.com/documentation/corebluetooth
- **Connect IQ SDK**: https://developer.garmin.com/connect-iq/overview/

## What's Working Now

✅ Basic project structure
✅ BLE Central (Meshtastic connection)
✅ BLE Peripheral (Garmin advertising)
✅ Bridge coordinator logic
✅ Node tracking and filtering
✅ SwiftUI interface
✅ Location services integration

## What's Missing (TODO)

❌ Protobuf parsing (placeholder only)
❌ Real position packet decoding
❌ Node database request
❌ Error handling/retry logic
❌ Settings UI
❌ Map view
❌ Background mode testing
❌ Battery optimization
❌ Garmin Connect IQ app

## Your Unique Setup

Since you're a **senior software architect** with **Nordic BLE SDK experience**:

- You'll recognize the CBCentralManager/CBPeripheralManager patterns
- Architecture follows Nordic's client/server model
- Characteristics use notify pattern (like Nordic UART Service)
- Binary packet format similar to Nordic proprietary protocols
- State machine for connection management

The code is intentionally **well-commented** and **modular** so you can:
- Swap out protobuf parsing
- Customize packet formats
- Add your own filtering logic
- Integrate with existing systems

## Support

- **GitHub Issues**: (will add when open-sourced)
- **Meshtastic Discord**: #garmin-integration channel
- **Your existing mesh**: DUO1, DUO2, paws all working on Sub-GHz default channel

---

**Ready to build?** Open Xcode and let's get this running! 🚀
