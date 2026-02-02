# Protobuf Integration Guide

Complete guide to adding Meshtastic protobuf support to the iOS bridge.

## Quick Start (15 minutes)

```bash
# 1. Install protobuf compiler
brew install swift-protobuf

# 2. Clone Meshtastic protobufs
cd ~/projects/tracker
git clone https://github.com/meshtastic/protobufs.git

# 3. Generate Swift files
cd protobufs
mkdir -p ../ios-bridge/MeshtasticGarminBridge/Protobufs

protoc --swift_out=../ios-bridge/MeshtasticGarminBridge/Protobufs \
    *.proto

# 4. Add generated files to Xcode
# Drag Protobufs folder into Xcode project navigator
# ✅ "Copy items if needed"
# ✅ "Create groups"
# ✅ Add to target: MeshtasticGarminBridge

# 5. Add SwiftProtobuf dependency
# In Xcode: File → Add Package Dependencies
# URL: https://github.com/apple/swift-protobuf
# Version: 1.27.0 or later
```

---

## Detailed Steps

### 1. Install Protobuf Compiler

```bash
# Check if already installed
protoc --version

# Install via Homebrew
brew install swift-protobuf

# Verify
protoc --version           # Should show libprotoc 3.x.x
protoc --swift_out=. --version  # Should not error
```

### 2. Get Meshtastic Protobuf Definitions

```bash
cd ~/projects/tracker

# Clone the official Meshtastic protobufs repo
git clone https://github.com/meshtastic/protobufs.git

cd protobufs

# Check what's available
ls *.proto
```

**Key files:**
- `mesh.proto` - Main protobuf definitions
- `portnums.proto` - Packet types
- `telemetry.proto` - Device metrics
- `admin.proto` - Admin commands
- `config.proto` - Configuration
- And more...

### 3. Generate Swift Code

```bash
# Create output directory
mkdir -p ~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs

# Generate Swift files from all .proto files
protoc --swift_out=~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs \
    *.proto

# Check generated files
ls ~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs/
```

**Generated files should include:**
- `mesh.pb.swift`
- `portnums.pb.swift`
- `telemetry.pb.swift`
- And more...

### 4. Add to Xcode Project

**Option A: Drag & Drop (Easiest)**
1. Open `MeshtasticGarminBridge.xcodeproj` in Xcode
2. In Finder, open `~/projects/tracker/ios-bridge/MeshtasticGarminBridge/Protobufs`
3. Drag `Protobufs` folder into Xcode project navigator
4. When prompted:
   - ✅ "Copy items if needed"
   - ✅ "Create groups" (not folder references)
   - ✅ Add to target: MeshtasticGarminBridge
5. Click "Finish"

**Option B: Add Files (Manual)**
1. Right-click project in navigator → "Add Files to..."
2. Navigate to `Protobufs` folder
3. Select all `.pb.swift` files
4. Same options as above

### 5. Add SwiftProtobuf Package Dependency

**In Xcode:**
1. Select project in navigator
2. Select project (not target) in main pane
3. Select "Package Dependencies" tab
4. Click `+` button
5. Enter URL: `https://github.com/apple/swift-protobuf`
6. Select "Up to Next Major Version": `1.27.0`
7. Click "Add Package"
8. Select target: `MeshtasticGarminBridge`
9. Click "Add Package"

**Verify:**
- Package should appear in Project Navigator under "Package Dependencies"
- No build errors

---

## Update MeshtasticService with Protobuf Parsing

Now update `MeshtasticService.swift` to use the generated protobuf code:

### 1. Add Import

At top of `MeshtasticService.swift`:

```swift
import Foundation
import CoreBluetooth
import CoreLocation
import SwiftProtobuf  // Add this
```

### 2. Replace parseFromRadioPacket()

Find the placeholder `parseFromRadioPacket()` method and replace with:

```swift
/// Parse incoming FROM_RADIO protobuf packet
private func parseFromRadioPacket(_ data: Data) {
    do {
        // Decode FromRadio wrapper
        let fromRadio = try Meshtastic_FromRadio(serializedData: data)

        // Handle different payload types
        if fromRadio.hasPacket {
            handleMeshPacket(fromRadio.packet)
        } else if fromRadio.hasNodeInfo {
            handleNodeInfo(fromRadio.nodeInfo)
        } else if fromRadio.hasConfigCompleteID {
            print("✅ Config complete")
        } else {
            print("📦 Received other packet type")
        }

    } catch {
        print("❌ Protobuf decode error: \(error)")
        print("   Data: \(data.map { String(format: "%02x", $0) }.joined())")
    }
}

/// Handle mesh packet (contains position, telemetry, etc.)
private func handleMeshPacket(_ packet: Meshtastic_MeshPacket) {
    guard packet.hasDecoded else {
        print("📦 Encrypted packet (no decoded data)")
        return
    }

    let decoded = packet.decoded

    // Handle position packets
    if decoded.portnum == .positionApp {
        handlePositionPacket(packet)
    }
    // Handle telemetry (battery, etc.)
    else if decoded.portnum == .telemetryApp {
        handleTelemetryPacket(packet)
    }
    // Handle text messages
    else if decoded.portnum == .textMessageApp {
        let text = String(data: decoded.payload, encoding: .utf8) ?? "?"
        print("💬 Message from \(packet.from): \(text)")
    }
    else {
        print("📦 Packet type: \(decoded.portnum)")
    }
}

/// Parse position packet and create MeshNode
private func handlePositionPacket(_ packet: Meshtastic_MeshPacket) {
    do {
        let position = try Meshtastic_Position(serializedData: packet.decoded.payload)

        // Convert Meshtastic position to MeshNode
        let node = MeshNode(
            nodeId: packet.from,
            shortName: getShortName(for: packet.from),
            longName: getLongName(for: packet.from),
            latitude: Double(position.latitudeI) / 1e7,
            longitude: Double(position.longitudeI) / 1e7,
            altitude: Int16(position.altitude),
            timestamp: Date(timeIntervalSince1970: TimeInterval(position.time)),
            battery: getBatteryLevel(for: packet.from),
            snr: Int8(packet.rxSnr)
        )

        // Update known nodes
        knownNodes[node.id] = node

        // Notify callback
        DispatchQueue.main.async {
            self.lastPacketReceived = Date()
            self.onNodeUpdate?(node)
        }

        print("📍 Position: \(node.shortName) at \(node.latitude), \(node.longitude)")

    } catch {
        print("❌ Position decode error: \(error)")
    }
}

/// Handle telemetry (battery, voltage, etc.)
private func handleTelemetryPacket(_ packet: Meshtastic_MeshPacket) {
    do {
        let telemetry = try Meshtastic_Telemetry(serializedData: packet.decoded.payload)

        if telemetry.hasDeviceMetrics {
            let metrics = telemetry.deviceMetrics
            print("🔋 Device \(packet.from): Battery \(metrics.batteryLevel)%, Voltage \(metrics.voltage)V")

            // Update battery level for this node
            if var node = knownNodes[packet.from] {
                node.batteryLevel = UInt8(metrics.batteryLevel)
                knownNodes[packet.from] = node
            }
        }

    } catch {
        print("❌ Telemetry decode error: \(error)")
    }
}

/// Handle node info (names, hardware, etc.)
private func handleNodeInfo(_ nodeInfo: Meshtastic_NodeInfo) {
    let num = nodeInfo.num

    if nodeInfo.hasUser {
        let user = nodeInfo.user
        print("👤 Node \(num): \(user.longName) (\(user.shortName))")

        // Update or create node
        if var node = knownNodes[num] {
            node.shortName = user.shortName
            node.longName = user.longName
            knownNodes[num] = node
        }
    }
}

// MARK: - Helper Methods

/// Get short name for node (from cache or default)
private func getShortName(for nodeId: UInt32) -> String {
    return knownNodes[nodeId]?.shortName ?? "!\(String(format: "%08x", nodeId).suffix(4))"
}

/// Get long name for node (from cache or default)
private func getLongName(for nodeId: UInt32) -> String {
    return knownNodes[nodeId]?.longName ?? "Node \(String(format: "%08x", nodeId))"
}

/// Get battery level for node (from cache or default)
private func getBatteryLevel(for nodeId: UInt32) -> UInt8 {
    return knownNodes[nodeId]?.batteryLevel ?? 0
}
```

### 3. Update requestNodeDatabase()

Replace the TODO in `requestNodeDatabase()`:

```swift
/// Request initial node database from device
func requestNodeDatabase() {
    guard let characteristic = toRadioCharacteristic,
          let peripheral = connectedDevice else {
        print("⚠️  Not connected")
        return
    }

    do {
        // Create want_config_id request
        var toRadio = Meshtastic_ToRadio()
        toRadio.wantConfigID = UInt32.random(in: 1...UInt32.max)

        let data = try toRadio.serializedData()
        peripheral.writeValue(data, for: characteristic, type: .withResponse)

        print("📋 Requested node database (config_id: \(toRadio.wantConfigID))")

    } catch {
        print("❌ Failed to create request: \(error)")
    }
}
```

---

## Testing Protobuf Integration

### 1. Build the Project

```bash
# In Xcode: Cmd+B
# Should build successfully with no errors
```

**Common Errors:**

**"No such module 'SwiftProtobuf'"**
- Solution: Add SwiftProtobuf package dependency (see step 5 above)

**"Cannot find 'Meshtastic_FromRadio' in scope"**
- Solution: Make sure protobuf files are added to target
- Check Build Phases → Compile Sources

**"Ambiguous use of 'FromRadio'"**
- Solution: Use fully qualified names: `Meshtastic_FromRadio`

### 2. Test with Real Device

1. Build & run on iPhone
2. Tap "Start Bridge"
3. Connect to DUO1 or DUO2
4. Wait for "paws" to send position update
5. Should see in console:
   ```
   📍 Position: paws at 39.5501, -106.0661
   🔋 Device 305419896: Battery 67%, Voltage 4.1V
   ```
6. Node should appear in "Tracked Nodes" list
7. Garmin service should forward to watches

### 3. Debug Protobuf Packets

If packets aren't parsing correctly, add debug logging:

```swift
private func parseFromRadioPacket(_ data: Data) {
    // Log raw bytes
    let hex = data.map { String(format: "%02x", $0) }.joined(separator: " ")
    print("📦 Raw packet (\(data.count) bytes): \(hex)")

    // Try to decode
    do {
        let fromRadio = try Meshtastic_FromRadio(serializedData: data)
        print("✅ Decoded FromRadio: \(fromRadio)")
        // Continue...
    } catch {
        print("❌ Decode failed: \(error)")
    }
}
```

---

## Protobuf Version Compatibility

**Important:** Meshtastic protobuf definitions may change between firmware versions.

**Current version (as of Feb 2025):**
- Firmware: 2.3.x
- Protobufs: Main branch (latest)

**If you get decode errors:**
1. Check your Meshtastic firmware version:
   ```bash
   meshtastic --info | grep Firmware
   ```
2. Check protobufs repo for matching tag:
   ```bash
   cd ~/projects/tracker/protobufs
   git tag | grep 2.3
   git checkout v2.3.x
   ```
3. Regenerate Swift files
4. Rebuild Xcode project

---

## Advanced: Custom Packet Types

If you want to add custom packet types (e.g., avalanche alert):

### 1. Define Custom PortNum

In `portnums.proto`, add:

```protobuf
enum PortNum {
    // ... existing types ...
    AVALANCHE_APP = 512;  // Custom app
}
```

### 2. Define Custom Message

Create `avalanche.proto`:

```protobuf
syntax = "proto3";

package meshtastic;

message AvalancheAlert {
    uint32 node_id = 1;
    float last_latitude = 2;
    float last_longitude = 3;
    uint32 alert_timestamp = 4;
    AlertType alert_type = 5;

    enum AlertType {
        SOS = 0;
        AVALANCHE = 1;
        FALL = 2;
    }
}
```

### 3. Regenerate Swift Files

```bash
protoc --swift_out=. avalanche.proto
```

### 4. Handle in iOS App

```swift
if decoded.portnum.rawValue == 512 {  // AVALANCHE_APP
    let alert = try AvalancheAlert(serializedData: decoded.payload)
    handleAvalancheAlert(alert)
}
```

---

## Troubleshooting

### Protobuf Not Decoding

**Symptom:** All packets fail to decode

**Causes:**
1. Wrong protobuf version (firmware vs protobufs mismatch)
2. Encrypted packets (need channel key)
3. Corrupted BLE data

**Solutions:**
1. Match protobuf version to firmware
2. Check channel encryption settings
3. Add checksum validation

### Battery Level Always 0

**Symptom:** Battery shows 0% for all nodes

**Cause:** Telemetry packets not received yet

**Solution:**
- Position packets don't include battery
- Battery comes from separate telemetry packets
- Wait for telemetry update (every ~15 min by default)
- Or request telemetry: Send admin packet requesting device metrics

### Names Show as !1234

**Symptom:** Node names show as "!ab12" instead of "paws"

**Cause:** NodeInfo not received yet

**Solutions:**
1. Call `requestNodeDatabase()` after connecting
2. Wait for NodeInfo broadcasts from mesh
3. Manually set names in app (fallback)

---

## Performance Tips

**Protobuf Parsing Speed:**
- ~0.1-1ms per packet (fast enough for real-time)
- No need for background queue

**Memory:**
- Keep parsed nodes in memory (knownNodes dict)
- Don't keep raw protobuf Data

**Battery:**
- Protobuf parsing has negligible battery impact

---

## Next Steps

Once protobuf is working:

1. ✅ Test with real mesh (paws, DUO1, DUO2)
2. ✅ Verify all nodes appear in UI
3. ✅ Verify battery levels populate
4. ✅ Test distance/bearing calculations
5. ✅ Test Garmin service forwarding
6. 🚧 Build Garmin Connect IQ app
7. 🚧 Field test in backcountry

---

**Questions?** Check the Meshtastic docs:
- Protobuf API: https://meshtastic.org/docs/developers/protobufs/api
- BLE API: https://meshtastic.org/docs/developers/device/ble-api
