# iOS Bridge - TODO List

Work remaining to complete the Meshtastic → Garmin bridge.

## Phase 1: Core Bridge ✅ (DONE)

- [x] Project structure
- [x] BLE Central (MeshtasticService)
- [x] BLE Peripheral (GarminService)
- [x] Bridge Coordinator
- [x] MeshNode data model
- [x] Basic SwiftUI UI
- [x] Permissions & Info.plist
- [x] Documentation

**Status**: Ready to build in Xcode!

---

## Phase 2: Protobuf Integration 🚧 (CRITICAL)

### 2.1 Setup Protobuf Compiler
- [ ] Install swift-protobuf: `brew install swift-protobuf`
- [ ] Clone Meshtastic protobufs: `git clone https://github.com/meshtastic/protobufs.git`
- [ ] Generate Swift files: `protoc --swift_out=...`
- [ ] Add generated files to Xcode project

### 2.2 Integrate Protobuf Parsing
- [ ] Import generated protobuf Swift files
- [ ] Implement `parseFromRadioPacket()` in MeshtasticService.swift:178
- [ ] Decode `FromRadio` wrapper
- [ ] Extract `MeshPacket`
- [ ] Check `portnum == POSITION_APP`
- [ ] Decode `Position` message
- [ ] Create `MeshNode` from decoded data

### 2.3 Node Database
- [ ] Implement `requestNodeDatabase()` in MeshtasticService.swift:96
- [ ] Send `ToRadio` packet with `want_config_id`
- [ ] Handle `NodeInfo` responses
- [ ] Populate shortName/longName from node database
- [ ] Handle battery level from node metrics

**Estimated Time**: 4-6 hours

---

## Phase 3: Testing & Refinement 🧪

### 3.1 Local Testing
- [ ] Build & run in Xcode
- [ ] Grant Bluetooth/Location permissions
- [ ] Scan for Base Duo devices
- [ ] Connect to DUO1 or DUO2
- [ ] Verify connection status shows "Ready"
- [ ] Wait for position updates from "paws"
- [ ] Verify node appears in "Tracked Nodes" list
- [ ] Check battery level, SNR, timestamp

### 3.2 BLE Peripheral Testing
- [ ] Install LightBlue app on second device
- [ ] Verify "Meshtastic Bridge" is advertising
- [ ] Connect to bridge service
- [ ] Find service UUID: D8F8A001-MESH-4000-8000-00805F9B34FB
- [ ] Subscribe to position characteristic
- [ ] Verify 20-byte packets are received
- [ ] Decode packets manually (check byte order)

### 3.3 Multi-Node Testing
- [ ] Test with multiple nodes (paws, DUO1, DUO2)
- [ ] Verify all nodes appear in tracked list
- [ ] Test node selection (tap to select)
- [ ] Test auto-select closest mode
- [ ] Verify distance filtering (>10km)
- [ ] Verify stale node filtering (>30 min)

**Estimated Time**: 2-4 hours

---

## Phase 4: UI Improvements 🎨

### 4.1 Map View
- [ ] Add MapKit import
- [ ] Create MapView.swift
- [ ] Show user location
- [ ] Show all tracked nodes as pins
- [ ] Highlight selected node
- [ ] Show distance/bearing labels
- [ ] Pan/zoom controls

### 4.2 Node List View
- [ ] Create NodeListView.swift
- [ ] Sortable list (by distance, time, battery)
- [ ] Swipe actions (select, remove, details)
- [ ] Search/filter nodes
- [ ] Node detail sheet (full info)

### 4.3 Settings View
- [ ] Create SettingsView.swift
- [ ] Max distance filter slider
- [ ] Max age slider
- [ ] Update interval selector
- [ ] Auto-select toggle
- [ ] Background mode toggle
- [ ] Statistics/debug info

### 4.4 Polish
- [ ] App icon (create in Assets.xcassets)
- [ ] Launch screen
- [ ] Error alerts
- [ ] Loading indicators
- [ ] Empty states
- [ ] Dark mode support

**Estimated Time**: 6-8 hours

---

## Phase 5: Background Mode 🌙

### 5.1 State Preservation
- [ ] Test app backgrounding
- [ ] Verify BLE central continues
- [ ] Verify BLE peripheral continues
- [ ] Handle state restoration
- [ ] Reconnect on app launch

### 5.2 Notifications
- [ ] Local notifications for new nodes
- [ ] Alerts for nodes going offline
- [ ] Low battery warnings
- [ ] Distance threshold alerts

### 5.3 Battery Optimization
- [ ] Reduce update frequency in background
- [ ] Pause scanning when connected
- [ ] Throttle location updates
- [ ] Test battery drain over 8 hours

**Estimated Time**: 4-6 hours

---

## Phase 6: Garmin Connect IQ App 🎯 (BIG LIFT)

See `GARMIN_CONNECTIQ_APP_PLAN.md` for detailed 9-week plan.

### 6.1 Setup
- [ ] Install Connect IQ SDK
- [ ] Install Eclipse or VS Code extension
- [ ] Create data field project
- [ ] Configure Fenix 6 Pro as target device

### 6.2 BLE Scanning
- [ ] Scan for iOS bridge service UUID
- [ ] Connect to bridge peripheral
- [ ] Subscribe to position characteristic
- [ ] Parse 20-byte position packet

### 6.3 Display
- [ ] Show distance with units (m/km/mi)
- [ ] Show bearing with arrow icon
- [ ] Show node name
- [ ] Show battery level
- [ ] Show time since last update

### 6.4 Testing
- [ ] Simulator testing
- [ ] Physical Fenix 6 Pro testing
- [ ] Field testing in backcountry

**Estimated Time**: 80-120 hours (see detailed plan)

---

## Phase 7: Production Ready 🚀

### 7.1 Error Handling
- [ ] Handle BLE disconnections gracefully
- [ ] Retry logic for failed connections
- [ ] Timeout handling
- [ ] User-friendly error messages
- [ ] Crash reporting (optional)

### 7.2 Performance
- [ ] Profile memory usage
- [ ] Optimize protobuf parsing
- [ ] Reduce UI redraws
- [ ] Lazy loading for large node lists
- [ ] Binary packet caching

### 7.3 Documentation
- [ ] User guide (non-technical)
- [ ] API documentation (comments)
- [ ] Architecture diagrams
- [ ] Video tutorials
- [ ] FAQ

### 7.4 App Store Submission
- [ ] Screenshots (required sizes)
- [ ] App description
- [ ] Privacy policy
- [ ] TestFlight beta testing
- [ ] Submit to App Store review

**Estimated Time**: 10-15 hours

---

## Phase 8: Advanced Features 🌟 (Future)

### 8.1 History & Logging
- [ ] Local database (CoreData/Realm)
- [ ] Position history per node
- [ ] Trip recording
- [ ] Export to GPX/KML
- [ ] Share tracks

### 8.2 Avalanche Integration (Conceptual)
- [ ] SOS/emergency packet type
- [ ] Last known position before avalanche
- [ ] Alert notifications
- [ ] Integration with RECCO (if possible)

### 8.3 Group Features
- [ ] Create/join groups
- [ ] Track group members only
- [ ] Group messaging (via Meshtastic)
- [ ] Meeting point coordination

### 8.4 Advanced Filtering
- [ ] Geofencing
- [ ] Custom node priorities
- [ ] Signal strength filtering
- [ ] Multi-hop distance estimation

**Estimated Time**: 40-60 hours

---

## Known Issues & Limitations

### Current Limitations
- ❌ **Protobuf parsing not implemented** - Critical blocker for real data
- ❌ **iPhone must stay near watch** - BLE range ~10m
- ❌ **Single node forwarding** - Garmin only sees one node at a time (by design)
- ❌ **No internet required** - Works 100% offline ✅ (this is a feature!)

### iOS Limitations
- BLE peripheral mode requires iPhone (not all iPads support it)
- Background BLE has iOS limitations (may pause after ~3 hours)
- CoreLocation in background drains battery

### Meshtastic Limitations
- ThinkNode M3 only supports Sub-GHz (not 2.4GHz)
- Multiple BLE centrals can't connect simultaneously
- Protobuf format may change between Meshtastic versions

---

## Quick Start Priority

If you want to **test the bridge TODAY**, focus on:

1. **Phase 1** ✅ Already done!
2. **Phase 2.1-2.2** 🚧 Protobuf integration (4-6 hours)
3. **Phase 3.1** 🧪 Basic testing (1 hour)

That gets you a **working prototype** that shows real position data!

Then add:
4. **Phase 4.1** 🎨 Map view (2 hours) - Makes it actually usable
5. **Phase 6** 🎯 Garmin app (long-term)

---

## Resources

- Meshtastic Protobufs: https://github.com/meshtastic/protobufs
- Meshtastic BLE Docs: https://meshtastic.org/docs/developers/device/ble-api
- Swift Protobuf: https://github.com/apple/swift-protobuf
- Connect IQ SDK: https://developer.garmin.com/connect-iq/sdk/

---

## Your Current Setup

**Hardware:**
- 2x Muzi Works Base Duo (DUO1, DUO2) - 915MHz + 2.4GHz
- 1x Elecrow ThinkNode M3 (paws) - 915MHz only
- 1x Garmin Fenix 6 Pro watch

**Network Config:**
- Channel 0 (default): Sub-GHz (915MHz) - All 3 devices
- Channel 1 (C1): 2.4GHz encrypted - DUO1 ↔ DUO2 only
- All meshed and communicating ✅

**Your Experience:**
- Senior software architect ✅
- Nordic BLE SDK experience ✅
- Familiar with BLE patterns ✅
- Perfect for this project! 🎉

---

**Next Step**: Open Xcode and build the project! 🚀
