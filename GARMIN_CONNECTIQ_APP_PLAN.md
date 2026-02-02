# Meshtastic Connect IQ App - Detailed Development Plan

Complete plan for building a Garmin Connect IQ app that displays real-time Meshtastic position data on Garmin watches.

## Project Overview

**Goal:** Create a Garmin Connect IQ app that receives Meshtastic position updates via iPhone/Android companion app and displays distance/bearing to tracked nodes (like "paws") on Garmin watches.

**Target Devices:**
- Garmin Fenix 6/7 Pro
- Garmin Epix
- Garmin Forerunner 945/955/965
- Other watches with Connect IQ 3.0+

**Core Features:**
1. Show distance to tracked Meshtastic node
2. Show bearing/direction arrow
3. Auto-update every 30-60 seconds
4. Display multiple nodes
5. Works offline (no internet needed)

## Technical Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                     System Flow                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Meshtastic Device (Base Duo #1)                       │
│         ↓ Bluetooth                                      │
│  Companion App (iOS/Android)                            │
│    - Meshtastic official app OR                         │
│    - Custom companion app                               │
│         ↓ Bluetooth Low Energy (BLE)                    │
│  Garmin Watch (Fenix 6 Pro)                            │
│    - Connect IQ app                                     │
│    - Displays position data                             │
│    - Updates distance/bearing                           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Communication Protocol

**Option A: Via Garmin Connect Mobile App**
- Companion app sends data to Garmin Connect Mobile
- Connect IQ app receives via Communications.makeWebRequest()
- Requires internet connection (won't work backcountry)
- ❌ Not suitable for our use case

**Option B: Direct BLE Communication**
- iPhone/Android companion app acts as BLE peripheral
- Connect IQ app connects as BLE central
- Direct data transfer watch ↔ phone
- ✅ Works offline
- ✅ Best for backcountry

**Option C: ANT+ Custom Device Profile**
- Create custom ANT+ device profile
- Companion app broadcasts on ANT+
- Watch receives ANT+ data
- ✅ Works offline
- Requires ANT+ licensing

**Recommended: Option B (BLE) or hybrid B+C**

## Development Phases

### Phase 1: Research & Setup (Week 1)

#### 1.1 Environment Setup
```bash
# Install Connect IQ SDK
# macOS
brew install connectiq-sdk

# Or download from:
# https://developer.garmin.com/connect-iq/sdk/

# Install Visual Studio Code
# Install Monkey C extension
```

#### 1.2 Learn Connect IQ Development
- Complete Garmin Connect IQ tutorials
- Study sample apps
- Understand Monkey C language
- Review BLE API documentation

#### 1.3 Study Meshtastic Protocol
```bash
# Clone Meshtastic repos
git clone https://github.com/meshtastic/firmware
git clone https://github.com/meshtastic/Meshtastic-Apple
git clone https://github.com/meshtastic/Meshtastic-Android

# Study protobuf definitions
# Understand position packet structure
# Review BLE GATT characteristics
```

#### 1.4 Research BLE Communication
- Connect IQ BLE documentation
- Garmin BLE API capabilities
- GATT service/characteristic design
- Data serialization formats

**Deliverables:**
- Development environment configured
- Connect IQ SDK installed
- Sample apps running on simulator
- Understanding of Meshtastic data structures

### Phase 2: Proof of Concept (Week 2-3)

#### 2.1 Create Minimal Connect IQ App

**Basic watch app structure:**

```monkey-c
// manifest.xml
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application id="meshtastic-tracker" type="watchface">
        <iq:products>
            <iq:product id="fenix6pro"/>
            <iq:product id="fenix7"/>
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="Positioning"/>
            <iq:uses-permission id="Communications"/>
            <iq:uses-permission id="BluetoothLowEnergy"/>
        </iq:permissions>
    </iq:application>
</iq:manifest>
```

```monkey-c
// MeshtasticTrackerApp.mc
using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;

class MeshtasticTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function getInitialView() {
        return [new MeshtasticTrackerView()];
    }

    function onPosition(info) {
        // Handle position updates
    }
}
```

#### 2.2 Create Companion App (iOS)

**Option A: Extend Meshtastic iOS app**
- Fork Meshtastic-Apple repo
- Add BLE peripheral service
- Broadcast position data

**Option B: Standalone companion app**
- Simpler, focused app
- Connects to Meshtastic device via Bluetooth
- Exposes BLE service for Garmin watch

**Minimal iOS companion app structure:**

```swift
// Swift iOS app
import CoreBluetooth
import Meshtastic

class MeshtasticBridge: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    var meshtasticManager: MeshtasticManager!

    // Custom GATT service for Garmin
    let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    let positionCharUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abd")

    func startBLEPeripheral() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

        // Create GATT service
        let positionChar = CBMutableCharacteristic(
            type: positionCharUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [positionChar]

        peripheralManager.add(service)
    }

    func updatePosition(lat: Double, lon: Double, nodeName: String) {
        // Pack data for Garmin
        let data = packPositionData(lat: lat, lon: lon, name: nodeName)

        // Update characteristic
        peripheralManager.updateValue(
            data,
            for: positionCharacteristic,
            onSubscribedCentrals: nil
        )
    }
}
```

#### 2.3 Test BLE Communication

**Test setup:**
1. Run companion app on iPhone
2. Run Connect IQ app in simulator
3. Test BLE discovery
4. Test data transfer
5. Verify position decoding

**Deliverables:**
- Basic Connect IQ app running
- Companion app broadcasting BLE
- Successful BLE pairing
- Data successfully transmitted

### Phase 3: Core Features (Week 4-6)

#### 3.1 Position Data Handling

**Data structure:**

```monkey-c
class MeshtasticNode {
    var name as String;           // "paws"
    var latitude as Double;       // 39.5501
    var longitude as Double;      // -106.0661
    var altitude as Number;       // 2800m
    var timestamp as Number;      // Unix timestamp
    var batteryLevel as Number;   // 0-100%
    var signalStrength as Number; // SNR/RSSI
}

class PositionTracker {
    var myPosition as Position.Location;
    var nodes as Array<MeshtasticNode>;

    function updateNode(nodeData) {
        // Parse BLE data
        // Update node in array
        // Calculate distance/bearing
    }

    function getDistanceTo(node) {
        return calculateDistance(
            myPosition.latitude,
            myPosition.longitude,
            node.latitude,
            node.longitude
        );
    }

    function getBearingTo(node) {
        return calculateBearing(
            myPosition.latitude,
            myPosition.longitude,
            node.latitude,
            node.longitude
        );
    }
}
```

#### 3.2 Distance/Bearing Calculations

```monkey-c
function calculateDistance(lat1, lon1, lat2, lon2) {
    // Haversine formula
    var R = 6371000; // Earth radius in meters
    var phi1 = Math.toRadians(lat1);
    var phi2 = Math.toRadians(lat2);
    var deltaPhi = Math.toRadians(lat2 - lat1);
    var deltaLambda = Math.toRadians(lon2 - lon1);

    var a = Math.sin(deltaPhi/2) * Math.sin(deltaPhi/2) +
            Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda/2) * Math.sin(deltaLambda/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c; // Distance in meters
}

function calculateBearing(lat1, lon1, lat2, lon2) {
    var phi1 = Math.toRadians(lat1);
    var phi2 = Math.toRadians(lat2);
    var deltaLambda = Math.toRadians(lon2 - lon1);

    var y = Math.sin(deltaLambda) * Math.cos(phi2);
    var x = Math.cos(phi1) * Math.sin(phi2) -
            Math.sin(phi1) * Math.cos(phi2) * Math.cos(deltaLambda);
    var theta = Math.atan2(y, x);

    return (Math.toDegrees(theta) + 360) % 360; // Bearing in degrees
}
```

#### 3.3 User Interface Design

**Watch face/data field layout:**

```
┌─────────────────────────┐
│                         │
│       🐕 PAWS          │
│                         │
│      ↗ 850m            │
│                         │
│   Bearing: 045°        │
│   Updated: 12s ago     │
│   Battery: 67%         │
│                         │
└─────────────────────────┘
```

**Multiple node view:**

```
┌─────────────────────────┐
│  🐕 Paws    ↗ 850m     │
│  📍 Base    ↙ 2.3km    │
│  👤 DUO1    → 450m     │
└─────────────────────────┘
```

#### 3.4 UI Implementation

```monkey-c
class MeshtasticTrackerView extends WatchUi.View {
    var tracker as PositionTracker;

    function initialize() {
        View.initialize();
        tracker = new PositionTracker();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();

        var node = tracker.getNode("paws");
        if (node != null) {
            var distance = tracker.getDistanceTo(node);
            var bearing = tracker.getBearingTo(node);

            // Draw distance
            dc.drawText(
                dc.getWidth()/2,
                dc.getHeight()/3,
                Graphics.FONT_LARGE,
                formatDistance(distance),
                Graphics.TEXT_JUSTIFY_CENTER
            );

            // Draw direction arrow
            drawDirectionArrow(dc, bearing);

            // Draw additional info
            drawNodeInfo(dc, node);
        } else {
            dc.drawText(
                dc.getWidth()/2,
                dc.getHeight()/2,
                Graphics.FONT_MEDIUM,
                "No data from Paws",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function drawDirectionArrow(dc, bearing) {
        // Draw arrow pointing in direction of bearing
        // Relative to current heading
    }
}
```

**Deliverables:**
- Position data parsing working
- Distance/bearing calculations accurate
- Basic UI displaying data
- Updates in real-time

### Phase 4: Advanced Features (Week 7-8)

#### 4.1 Multiple Node Support

```monkey-c
class NodeSelector {
    var nodes as Array<MeshtasticNode>;
    var selectedIndex as Number = 0;

    function nextNode() {
        selectedIndex = (selectedIndex + 1) % nodes.size();
        return nodes[selectedIndex];
    }

    function previousNode() {
        selectedIndex = (selectedIndex - 1 + nodes.size()) % nodes.size();
        return nodes[selectedIndex];
    }
}
```

#### 4.2 Settings/Configuration

```monkey-c
// properties.xml
<properties>
    <property id="UpdateInterval" type="number">30</property>
    <property id="DistanceUnits" type="number">0</property> <!-- 0=metric, 1=imperial -->
    <property id="ShowMultipleNodes" type="boolean">true</property>
    <property id="AutoSelectClosest" type="boolean">false</property>
</properties>
```

#### 4.3 Notifications/Alerts

```monkey-c
function checkProximityAlerts() {
    var node = tracker.getNode("paws");
    var distance = tracker.getDistanceTo(node);

    if (distance > MAX_DISTANCE) {
        Attention.playTone(Attention.TONE_ALARM);
        showAlert("Paws is far away: " + formatDistance(distance));
    }
}
```

#### 4.4 Data Field Version

```monkey-c
// For use during activities
class MeshtasticDataField extends WatchUi.DataField {

    function compute(info) {
        var node = tracker.getNode("paws");
        if (node != null) {
            return tracker.getDistanceTo(node);
        }
        return 0;
    }

    function onUpdate(dc) {
        var distance = compute(null);
        dc.drawText(
            dc.getWidth()/2,
            dc.getHeight()/2,
            Graphics.FONT_LARGE,
            formatDistance(distance),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
```

**Deliverables:**
- Multi-node support
- User settings
- Alerts system
- Data field version

### Phase 5: Companion App Polish (Week 9-10)

#### 5.1 iOS Companion App Features

```swift
class MeshtasticCompanionApp {
    // Core features
    func connectToMeshtastic() {
        // Bluetooth connection to Base Duo
    }

    func startBLEBroadcast() {
        // Advertise to Garmin watches
    }

    func handlePositionUpdate(packet: MeshtasticPacket) {
        // Parse position from Meshtastic
        // Update BLE characteristic
        // Notify Garmin watch
    }

    // UI features
    func showConnectionStatus() {}
    func displayTrackedNodes() {}
    func configureSettings() {}
}
```

#### 5.2 Android Version

```kotlin
class MeshtasticCompanionAndroid : AppCompatActivity() {

    private lateinit var bleManager: BlePeripheralManager
    private lateinit var meshtasticConnection: MeshtasticConnection

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Setup BLE peripheral
        bleManager = BlePeripheralManager(this)
        bleManager.startAdvertising()

        // Connect to Meshtastic
        meshtasticConnection = MeshtasticConnection()
        meshtasticConnection.connect()
    }

    fun onPositionUpdate(position: Position) {
        bleManager.updatePosition(position)
    }
}
```

#### 5.3 Background Operation

```swift
// iOS - Background BLE peripheral
func setupBackgroundMode() {
    // Configure app for background BLE peripheral mode
    // Required: Background Modes → Uses Bluetooth LE accessories

    peripheralManager = CBPeripheralManager(
        delegate: self,
        queue: nil,
        options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: "MeshtasticBridge"
        ]
    )
}
```

**Deliverables:**
- Polished iOS companion app
- Android companion app
- Background operation
- Connection management

### Phase 6: Testing (Week 11-12)

#### 6.1 Simulator Testing
- Test all UI states
- Test data updates
- Test error conditions
- Test multiple nodes

#### 6.2 Real Device Testing
```
Test matrix:
- Garmin Fenix 6 Pro
- Garmin Fenix 7
- Garmin Epix
- iPhone 12+ (iOS 16+)
- Android 10+ devices
```

#### 6.3 Field Testing
- Backcountry skiing scenario
- Test range limits
- Test battery life
- Test in cold weather
- Test with gloves

#### 6.4 Edge Cases
- Connection loss handling
- Stale data warnings
- Battery low alerts
- GPS unavailable
- Multiple watches connecting

**Deliverables:**
- Test suite complete
- Bugs identified and fixed
- Field testing report
- Performance optimization

### Phase 7: Distribution (Week 13-14)

#### 7.1 App Store Submission

**Connect IQ Store:**
```
Required:
- App description
- Screenshots (all supported devices)
- Privacy policy
- Support contact
- Testing notes
- Device compatibility list
```

**iOS App Store:**
```
Required:
- App description
- Screenshots
- Privacy policy
- App review notes (explain Meshtastic + BLE usage)
- TestFlight beta testing
```

**Google Play Store:**
```
Required:
- Same as iOS
- APK/AAB bundle
- Content rating
- Target API level
```

#### 7.2 Documentation

**User Guide:**
1. Installation instructions
2. Pairing watch with phone
3. Connecting to Meshtastic
4. Using the app while skiing
5. Troubleshooting

**Developer Documentation:**
- API documentation
- BLE protocol specification
- Contributing guidelines
- Build instructions

#### 7.3 Open Source Release

```bash
# GitHub repository structure
meshtastic-garmin/
├── connectiq-app/          # Garmin watch app
│   ├── source/
│   ├── resources/
│   ├── manifest.xml
│   └── README.md
├── ios-companion/          # iOS companion app
│   ├── MeshtasticBridge/
│   ├── MeshtasticBridge.xcodeproj
│   └── README.md
├── android-companion/      # Android companion app
│   ├── app/
│   ├── build.gradle
│   └── README.md
├── docs/                   # Documentation
│   ├── USER_GUIDE.md
│   ├── API.md
│   └── PROTOCOL.md
├── LICENSE
└── README.md
```

**Deliverables:**
- Apps published to stores
- Complete documentation
- Open source repository
- Community support channels

## Technical Specifications

### BLE Protocol Design

**Custom GATT Service:**

```
Service UUID: 12345678-1234-1234-1234-123456789abc
Service Name: "Meshtastic Position Service"

Characteristics:
1. Position Data (UUID: ...789abd)
   - Properties: Read, Notify
   - Format:
     Byte 0-3: Node ID (uint32)
     Byte 4-7: Latitude (float32, degrees)
     Byte 8-11: Longitude (float32, degrees)
     Byte 12-13: Altitude (int16, meters)
     Byte 14-17: Timestamp (uint32, Unix time)
     Byte 18: Battery (uint8, percent)
     Byte 19: Signal (int8, SNR)
     Byte 20-35: Node Name (16 char string)

2. Configuration (UUID: ...789abe)
   - Properties: Read, Write
   - Format: Settings data

3. Status (UUID: ...789abf)
   - Properties: Read, Notify
   - Format: Connection status, errors
```

### Data Update Protocol

```
1. Companion app receives Meshtastic position packet
2. Parse packet (protobuf)
3. Convert to BLE format (binary struct)
4. Update BLE characteristic
5. Notify subscribed centrals (Garmin watch)
6. Watch receives notification
7. Parse binary data
8. Calculate distance/bearing
9. Update UI
```

### Performance Requirements

- **Update latency**: <2 seconds from Meshtastic to watch
- **Battery impact**: <5% additional drain per hour
- **Memory usage**: <500KB on watch
- **BLE reconnection**: <10 seconds
- **Position accuracy**: ±10 meters
- **Distance calc accuracy**: ±1%

## Development Tools

### Required Software

```bash
# Connect IQ SDK
# Download from: https://developer.garmin.com/connect-iq/sdk/

# Visual Studio Code
# Install from: https://code.visualstudio.com/

# Monkey C extension for VS Code
code --install-extension garmin.monkey-c

# Xcode (for iOS development)
# Install from Mac App Store

# Android Studio (for Android development)
# Download from: https://developer.android.com/studio

# Git
brew install git

# Meshtastic CLI (for testing)
pip3 install meshtastic
```

### Testing Tools

```bash
# Connect IQ Simulator
# Included with SDK

# Real device testing
# Requires Garmin watch with Connect IQ 3.0+

# BLE testing tools
# LightBlue (iOS/macOS)
# nRF Connect (iOS/Android)
```

## Cost Estimate

### Development Time
- **Phase 1:** 40 hours (1 week)
- **Phase 2-3:** 120 hours (3 weeks)
- **Phase 4-5:** 80 hours (2 weeks)
- **Phase 6:** 80 hours (2 weeks)
- **Phase 7:** 40 hours (1 week)
- **Total:** ~360 hours (9 weeks)

### Cost Breakdown
- **Developer time**: $50-150/hour × 360 hours = $18,000-$54,000
- **Apple Developer Account**: $99/year
- **Google Play Developer Account**: $25 one-time
- **Test devices**: $500-1000 (if needed)
- **Total**: ~$20,000-$55,000

### Free/Open Source Option
- Develop as open source project
- Community contributions
- No cost except time
- Crowdfunding for hardware

## Success Criteria

### Minimum Viable Product (MVP)
- ✓ Shows distance to one Meshtastic node
- ✓ Shows bearing/direction
- ✓ Updates every 30-60 seconds
- ✓ Works on Fenix 6 Pro
- ✓ iOS companion app
- ✓ Offline operation

### Full Release
- ✓ Multiple node support
- ✓ Configurable settings
- ✓ Alerts/notifications
- ✓ Data field version
- ✓ iOS + Android companion apps
- ✓ Support 10+ Garmin devices
- ✓ Published to Connect IQ Store
- ✓ Complete documentation

## Risks & Mitigation

### Technical Risks

**Risk 1: BLE limitations on Connect IQ**
- Mitigation: Test early in Phase 2
- Fallback: Use ANT+ instead

**Risk 2: Background BLE on iOS**
- Mitigation: Test background modes early
- Fallback: Require app to be foreground

**Risk 3: Battery drain**
- Mitigation: Optimize update frequency
- Fallback: User-configurable intervals

**Risk 4: Garmin approval delays**
- Mitigation: Follow guidelines strictly
- Fallback: Beta test via sideloading

### Non-Technical Risks

**Risk 1: Limited developer resources**
- Mitigation: Open source, community help
- Fallback: Focus on MVP only

**Risk 2: User adoption**
- Mitigation: Clear documentation, demos
- Fallback: Focus on specific use case (backcountry)

## Next Steps

### Immediate Actions (You Can Do Now)

1. **Register for Garmin Developer Account**
   - https://developer.garmin.com/
   - Free registration
   - Access to SDK and docs

2. **Install Connect IQ SDK**
   ```bash
   # Download and install
   # Test with simulator
   ```

3. **Study Sample Apps**
   - Download sample Connect IQ apps
   - Understand Monkey C syntax
   - Learn UI patterns

4. **Prototype iOS Companion**
   - Create simple iOS app
   - Connect to your Base Duo
   - Print position data
   - Test BLE peripheral mode

5. **Join Communities**
   - Garmin Developer Forums
   - Meshtastic Discord
   - r/Meshtastic subreddit
   - Ask if anyone else is working on this

### Finding Developers

**Where to find help:**
- Garmin Developer Forums (post project)
- Meshtastic Discord (community may help)
- GitHub (open source project)
- Freelance platforms (Upwork, Fiverr)
- Local developer meetups

**Skills needed:**
- Connect IQ / Monkey C
- iOS Swift development
- Android Kotlin development
- Bluetooth LE expertise
- Meshtastic protocol knowledge

## Alternative: Simpler Short-Term Solutions

While building the full app, consider:

1. **Shortcuts/Automation**
   - iOS Shortcuts to copy coordinates
   - Voice commands
   - Faster than full app development

2. **Web-Based Tool**
   - Progressive Web App (PWA)
   - Access Meshtastic data via Bluetooth Web API
   - Display on phone, not watch
   - Easier to develop

3. **Existing Apps**
   - Check if any generic BLE → Garmin bridges exist
   - Adapt for Meshtastic data

## Conclusion

Building a Meshtastic Connect IQ app is **definitely possible** but requires:
- Significant development effort (360 hours)
- Multiple skillsets (Garmin, iOS, Android, BLE)
- Testing on real hardware
- Time to market (3+ months)

**Recommendation:**
1. Start with MVP focus (Phase 1-3 only)
2. Open source from day 1
3. Seek community contributions
4. Consider crowdfunding for development costs

**Best first step:**
Create proof-of-concept iOS app that shows it's possible, then gauge community interest for full development.

Would you like me to help you start with Phase 1 (environment setup) or create a prototype iOS companion app?
