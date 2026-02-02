# iOS Bridge Architecture

Technical architecture for senior developers.

## System Overview

```
┌────────────────────────────────────────────────────────────────┐
│                        iOS Bridge App                           │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────┐          ┌──────────────────────┐      │
│  │ MeshtasticService │          │   GarminService      │      │
│  │   (BLE Central)   │          │  (BLE Peripheral)    │      │
│  │                   │          │                      │      │
│  │ • Scan devices    │          │ • Advertise service  │      │
│  │ • Connect to DUO  │   ┌──────│ • GATT server        │      │
│  │ • Subscribe       │   │      │ • Notify watches     │      │
│  │ • Parse protobuf  │───┤      │ • 20-byte packets    │      │
│  └───────────────────┘   │      └──────────────────────┘      │
│           ▲              │                   │                 │
│           │              ▼                   ▼                 │
│  ┌────────┴──────────────────────────────────┴──────────────┐ │
│  │              BridgeCoordinator                           │ │
│  │  • Receive node updates                                  │ │
│  │  • Filter stale/distant nodes                            │ │
│  │  • Auto-select closest OR user-selected                  │ │
│  │  • Rate limiting                                          │ │
│  │  • Statistics tracking                                    │ │
│  └────────────────────────────────────────────────────────┬─┘ │
│           ▲                                                │   │
│           │                                                ▼   │
│  ┌────────┴────────┐                              ┌──────────┐│
│  │ CLLocationMgr   │                              │ SwiftUI  ││
│  │ • GPS position  │                              │ • State  ││
│  │ • Relative dist │                              │ • UI     ││
│  └─────────────────┘                              └──────────┘│
│                                                                 │
└────────────────────────────────────────────────────────────────┘
         ▲                                              │
         │ BLE                                          │ BLE
         │ (CBCentralManager)                           │ (Garmin scans)
         │                                              ▼
  ┌──────┴─────┐                              ┌─────────────────┐
  │ Meshtastic │                              │  Garmin Watch   │
  │ Base Duo   │                              │  (Fenix 6 Pro)  │
  │ (DUO1/2)   │                              │                 │
  └────────────┘                              └─────────────────┘
         ▲
         │ LoRa Mesh
         │
  ┌──────┴─────┐
  │ ThinkNode  │
  │  (paws)    │
  └────────────┘
```

---

## Component Responsibilities

### 1. MeshtasticService (BLE Central)

**Role:** Connect to Meshtastic devices and receive position updates from the mesh network.

**Responsibilities:**
- Scan for Meshtastic BLE peripherals (service UUID: `6BA1B218-...`)
- Manage connection lifecycle (connect, disconnect, reconnect)
- Subscribe to `FROM_RADIO` characteristic
- Parse incoming protobuf packets
- Notify coordinator of node updates via callback

**State Management:**
- `@Published var connectedDevice: CBPeripheral?`
- `@Published var connectionState: ConnectionState`
- `@Published var discoveredDevices: [CBPeripheral]`

**Key Methods:**
```swift
func startScanning()
func connect(to peripheral: CBPeripheral)
func disconnect()
private func parseFromRadioPacket(_ data: Data)  // TODO: Implement with protobuf
```

**Nordic BLE Equivalent:**
- Similar to Nordic's `ble_gap_scan_start()` + `ble_gap_connect()`
- Uses Apple's CBCentralManager instead of SoftDevice
- Notification pattern same as Nordic's BLE_GATTS_EVT_HVN

---

### 2. GarminService (BLE Peripheral)

**Role:** Advertise a custom GATT service that Garmin watches can connect to and receive position data.

**Responsibilities:**
- Setup GATT service with custom UUIDs
- Advertise as "Meshtastic Bridge"
- Accept connections from Garmin watches
- Update characteristic values (20-byte position packets)
- Notify subscribed centrals (watches)

**State Management:**
- `@Published var isAdvertising: Bool`
- `@Published var connectedCentrals: [CBCentral]`
- `@Published var lastUpdate: Date?`

**Key Methods:**
```swift
func startAdvertising()
func stopAdvertising()
func updateNodePosition(_ node: MeshNode)
func updateNodeList(_ nodes: [MeshNode], relativeTo: CLLocation)
private func createPositionPacket(for node: MeshNode) -> Data
```

**Binary Packet Format:**
```c
// 20 bytes total
struct GarminPositionPacket {
    uint32_t node_id;        // 4 bytes
    float    latitude;       // 4 bytes
    float    longitude;      // 4 bytes
    int16_t  altitude;       // 2 bytes
    uint32_t timestamp;      // 4 bytes (Unix seconds)
    uint8_t  battery;        // 1 byte (0-100%)
    int8_t   snr;            // 1 byte (signal strength)
} __attribute__((packed));
```

**Nordic BLE Equivalent:**
- Similar to Nordic's `ble_advertising_start()`
- Uses Apple's CBPeripheralManager instead of SoftDevice
- GATT service creation same as Nordic's `sd_ble_gatts_service_add()`
- Notification pattern same as `sd_ble_gatts_hvx()`

---

### 3. BridgeCoordinator (Business Logic)

**Role:** Orchestrate data flow between Meshtastic and Garmin services. Implement filtering, selection, and rate limiting logic.

**Responsibilities:**
- Wire up MeshtasticService → GarminService data flow
- Track all nodes received from mesh
- Filter stale nodes (>30 min old)
- Filter distant nodes (>10km away, configurable)
- Auto-select closest node OR respect user selection
- Rate limiting (don't spam Garmin every second)
- Manage GPS location for relative distance calculations
- Statistics tracking

**State Management:**
- `@Published var trackedNodes: [MeshNode]`
- `@Published var selectedNodeId: UInt32?`
- `@Published var statistics: BridgeStatistics`

**Configuration Properties:**
```swift
var maxDistanceFilter: Double = 10000.0  // meters
var maxAge: TimeInterval = 1800          // seconds
var updateInterval: TimeInterval = 5.0   // seconds
var autoSelectClosest: Bool = true
```

**Key Methods:**
```swift
func start()  // Start both services
func stop()   // Stop both services
func selectNode(_ nodeId: UInt32)
func clearNodeSelection()
private func handleNodeUpdate(_ node: MeshNode)
private func shouldUpdateGarmin(for node: MeshNode) -> Bool
private func getNodeToForward() -> MeshNode?
private func updateGarminForNode(_ node: MeshNode)
```

**Decision Logic:**

```swift
// Which node to forward to Garmin?
1. If user selected specific node → use that
2. Else if autoSelectClosest → closest by distance
3. Else → most recently updated
```

---

### 4. MeshNode (Data Model)

**Role:** Represent a single tracked node with position and metadata.

**Properties:**
```swift
struct MeshNode: Identifiable, Codable {
    let id: UInt32              // Node ID from Meshtastic
    var shortName: String       // "paws", "DUO1"
    var longName: String        // "Dog Tracker", "Skier 1"
    var latitude: Double
    var longitude: Double
    var altitude: Int16
    var timestamp: Date         // Position timestamp
    var batteryLevel: UInt8
    var snr: Int8               // Signal strength
    var lastHeard: Date         // When we last got update
}
```

**Computed Properties:**
```swift
var location: CLLocation        // CoreLocation wrapper
var isStale: Bool               // Age > 30 min?
var age: TimeInterval           // Seconds since lastHeard

func distance(to location: CLLocation) -> CLLocationDistance
func bearing(to location: CLLocation) -> Double  // Haversine formula
```

---

## Data Flow

### Position Update Flow (Typical Path)

```
1. "paws" (ThinkNode M3) sends LoRa position packet
       ↓ LoRa mesh (915MHz)
2. DUO1 (Base Duo) receives packet, forwards via BLE
       ↓ BLE notification (FROM_RADIO)
3. MeshtasticService receives BLE notification
       ↓ parseFromRadioPacket()
4. Decode protobuf → extract Position message
       ↓ Create MeshNode struct
5. MeshtasticService.onNodeUpdate?(node)
       ↓ Callback to coordinator
6. BridgeCoordinator.handleNodeUpdate(node)
       ↓ Update trackedNodes array
       ↓ Filter stale/distant
       ↓ Check rate limiting
       ↓ Decide which node to forward
7. BridgeCoordinator.updateGarminForNode(node)
       ↓ Call GarminService
8. GarminService.updateNodePosition(node)
       ↓ Create 20-byte binary packet
       ↓ CBPeripheralManager.updateValue()
9. Garmin watch receives BLE notification
       ↓ Parse 20-byte packet
10. Garmin displays: "paws - 243m NE"
```

**Latency Estimate:**
- LoRa transmission: ~1-2s (depends on SF, bandwidth)
- BLE notification: <100ms
- Protobuf parsing: <10ms
- Coordinator logic: <10ms
- BLE to Garmin: <100ms
- **Total: 1-3 seconds end-to-end**

---

## BLE Protocol Details

### Meshtastic BLE Service (Central Side)

**Service UUID:** `6BA1B218-15A8-461F-9FA8-5DCAE273EAFD`

**Characteristics:**
- `FROM_RADIO` (2C55E69E-...): **Read + Notify** → Position updates
- `TO_RADIO` (F75C76D2-...): **Write** → Send commands
- `FROM_NUM` (ED9DA18C-...): **Read + Notify** → Packet counter

**Connection Process:**
1. Scan for service UUID
2. Connect to peripheral (DUO1 or DUO2)
3. Discover characteristics
4. Subscribe to FROM_RADIO
5. Receive notifications (protobuf packets)

**Packet Structure:**
```protobuf
message FromRadio {
    oneof payload_variant {
        MeshPacket packet = 1;      // Position updates
        NodeInfo node_info = 2;     // Node database
        ConfigComplete config_complete_id = 3;
        // ... more
    }
}

message MeshPacket {
    uint32 from = 1;
    uint32 to = 2;
    bytes encrypted = 3;
    Data decoded = 4;
    // ... more
}

message Position {
    fixed32 latitude_i = 1;   // Degrees * 1e7
    fixed32 longitude_i = 2;  // Degrees * 1e7
    int32 altitude = 3;       // Meters
    fixed32 time = 4;         // Unix seconds
    // ... more
}
```

---

### Garmin BLE Service (Peripheral Side)

**Custom Service UUID:** `D8F8A001-MESH-4000-8000-00805F9B34FB`

**Characteristics:**
- `POSITION_CHAR` (D8F8A002-...): **Read + Notify** → Single node position (20 bytes)
- `NODELIST_CHAR` (D8F8A003-...): **Read + Notify** → Multi-node list (12 bytes per node)

**Properties:**
- Read: Watch can read current value
- Notify: Watch gets updates when value changes
- Permissions: Readable

**Advertising:**
```swift
[
    CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
    CBAdvertisementDataLocalNameKey: "Meshtastic Bridge"
]
```

**Packet Formats:**

**Position Packet (20 bytes):**
```
Offset | Type    | Field
-------|---------|----------
0-3    | uint32  | node_id
4-7    | float   | latitude (degrees)
8-11   | float   | longitude (degrees)
12-13  | int16   | altitude (meters)
14-17  | uint32  | timestamp (Unix seconds)
18     | uint8   | battery (0-100%)
19     | int8    | snr (dBm)
```

**Node List Entry (12 bytes per node):**
```
Offset | Type    | Field
-------|---------|----------
0-3    | uint32  | node_id
4-7    | float   | distance (meters from you)
8-9    | int16   | bearing (0-359 degrees)
10-11  | uint16  | last_seen (seconds ago)
```

---

## State Management

### Connection States

**Meshtastic Connection:**
```
Disconnected → Scanning → Connecting → Connected → Subscribing → Ready
       ↓                                                             ↑
       └─────────────────── disconnect/error ──────────────────────┘
```

**Garmin Advertising:**
```
Stopped → Advertising → [0-N watches connected]
   ↓                              ↓
   └───────── stopAdvertising ────┘
```

### Node Lifecycle

```
New node received → Add to trackedNodes
                    ↓
                Check if stale (age > 30 min) → Remove
                    ↓
                Check if distant (>10km) → Remove
                    ↓
                Check rate limit (last update <5s ago) → Skip
                    ↓
                Select node to forward
                    ↓
                Forward to Garmin
```

---

## Threading Model

All BLE operations happen on **main thread** (Apple requirement).

**Main Thread:**
- CBCentralManager callbacks
- CBPeripheralManager callbacks
- CLLocationManager callbacks
- SwiftUI @Published updates

**Background Work:**
- None currently (protobuf parsing is fast enough)
- If needed later: Dispatch protobuf parsing to background queue

---

## Memory Management

**Tracked Nodes:**
- Stored in memory only (no persistence)
- Auto-pruned when stale
- Limit to max 100 nodes (reasonable for mesh)

**BLE Buffers:**
- CoreBluetooth manages buffers internally
- updateValue() returns false if queue full (we log, don't retry yet)

**Protobuf:**
- Decode packets on-the-fly
- Don't keep raw protobuf data in memory

---

## Error Handling

**Current State:**
- Basic print() logging
- Connection failures logged
- Invalid data ignored

**TODO (Production):**
- Structured logging (OSLog)
- User-facing error alerts
- Automatic reconnection on disconnect
- Retry logic for failed updates
- Crash reporting (optional)

---

## Performance Considerations

### BLE Throughput

**Meshtastic → iOS:**
- Typical position update: ~50-100 bytes protobuf
- Frequency: Variable (depends on mesh activity)
- Worst case: 10 nodes × 1 update/min = 1KB/min (negligible)

**iOS → Garmin:**
- Position packet: 20 bytes
- Node list: 12 bytes × 10 nodes = 120 bytes
- Update interval: 5 seconds (configurable)
- Throughput: ~30 bytes/sec average (negligible)

**Bottleneck:** None. BLE easily handles this.

### Battery Impact

**Estimated drain:**
- BLE Central scanning: ~0.5% / hour
- BLE Central connected: ~0.1% / hour
- BLE Peripheral advertising: ~0.3% / hour
- GPS location updates: ~2-3% / hour (biggest drain)
- **Total: 3-4% / hour**

**Target:** <5% / hour (achievable)

**Optimization:**
- Reduce GPS accuracy when stationary
- Increase update interval to 10-15s
- Pause scanning once connected

### Memory Usage

**Estimated:**
- App code: ~5 MB
- Protobuf library: ~1 MB
- Tracked nodes (100 nodes): ~50 KB
- **Total: <10 MB**

**No memory leaks expected** (ARC handles everything)

---

## Security Considerations

### Data Privacy

- **No cloud uploads** - Everything stays on device
- **No analytics/telemetry** - Zero tracking
- **No internet required** - 100% offline

### BLE Security

**Meshtastic connection:**
- BLE encryption (standard iOS/macOS security)
- Meshtastic packets already encrypted with channel key
- We decrypt via Meshtastic's protobuf layer

**Garmin connection:**
- BLE encryption (standard iOS/Garmin security)
- No authentication required (anyone can connect)
- Position data sent in plaintext binary (not encrypted)

**Risk Assessment:**
- **Low risk** - Data only exposed to devices in BLE range (~10m)
- **Mitigation** - User controls when bridge is active
- **Future** - Could add PIN-based pairing

---

## Testing Strategy

### Unit Tests
- MeshNode distance/bearing calculations
- Packet encoding/decoding
- Node filtering logic

### Integration Tests
- BLE scanning/connection
- Protobuf parsing
- End-to-end data flow

### Field Tests
- Backcountry with real mesh
- Battery drain over 8+ hours
- Multiple nodes (3-5 people)
- Edge cases (node goes offline, out of range, etc.)

---

## Known Limitations

### iPhone Required
- iPad doesn't always support BLE peripheral mode
- Must be iPhone (or iPad with cellular)

### BLE Range
- Garmin must stay near iPhone (~10m)
- Solution: Keep iPhone in pocket, watch on wrist

### Background Mode
- iOS limits background BLE after ~3 hours
- App may need periodic wakeups
- Not guaranteed to work indefinitely

### Single Node Forwarding
- Garmin only sees one node at a time (by design)
- User can switch which node to track
- Future: Multi-node watch face (more complex UI)

---

## Comparison to Nordic BLE Architecture

Since you have **Nordic BLE SDK experience**, here's the mapping:

| Nordic SoftDevice | iOS CoreBluetooth | Notes |
|-------------------|-------------------|-------|
| `ble_gap_scan_start()` | `centralManager.scanForPeripherals()` | Same concept |
| `ble_gap_connect()` | `centralManager.connect()` | Same concept |
| `ble_gattc_char_value_notify()` | `peripheral.setNotifyValue(true)` | Subscribe to notifications |
| `ble_gatts_service_add()` | `peripheralManager.add(service)` | Add GATT service |
| `ble_advertising_start()` | `peripheralManager.startAdvertising()` | Start advertising |
| `sd_ble_gatts_hvx()` | `peripheralManager.updateValue()` | Send notification |
| `BLE_GAP_EVT_CONNECTED` | `centralManager(_:didConnect:)` | Connection callback |
| `BLE_GATTS_EVT_WRITE` | `peripheralManager(_:didReceiveWrite:)` | Write callback |

**Key Differences:**
- iOS uses delegation pattern (not event queue)
- iOS manages connection parameters automatically (no manual GAP params)
- iOS has stricter background limitations
- iOS provides higher-level abstractions (no direct HCI access)

---

## Next Steps

1. **Build & run** - Test basic UI and BLE scanning
2. **Add protobuf** - Critical for parsing real data
3. **Field test** - Take to backcountry with your mesh
4. **Garmin app** - Build Connect IQ watch app
5. **Polish** - Map view, settings, error handling
6. **Open source** - Release to community

---

**Questions?** Open an issue or reach out on Meshtastic Discord!
