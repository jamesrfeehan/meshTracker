# Mobile App Setup Guide

This guide covers setting up the Meshtastic mobile app to track your dog's location and configure your devices.

## App Installation

### iOS (iPhone/iPad)
1. Open App Store
2. Search for "Meshtastic"
3. Download and install (Free)
4. Requires iOS 14.0 or later

### Android
1. Open Google Play Store
2. Search for "Meshtastic"
3. Download and install (Free)
4. Requires Android 5.0 or later

**Official Links:**
- iOS: https://apps.apple.com/app/meshtastic/id1586432531
- Android: https://play.google.com/store/apps/details?id=com.geeksville.mesh

## Initial Setup

### First Launch

1. **Open Meshtastic App**
2. **Grant Permissions:**
   - Location: Required for GPS and map
   - Bluetooth: Required for device connection
   - Notifications: Recommended for alerts

3. **Welcome Screen:**
   - Tap "Get Started"
   - Choose "I have a radio" (not "I don't have a radio yet")

### Connect to Base Duo

The Base Duo acts as your primary gateway to the mesh network.

1. **Enable Bluetooth:**
   - Ensure phone Bluetooth is on
   - Power on Base Duo

2. **Add Device:**
   - Tap "+" button (top right)
   - Select "Bluetooth"
   - Wait for scan to complete

3. **Select Device:**
   - Look for "Home-Base" in device list
   - Tap to connect
   - If prompted for PIN: default is 123456

4. **Connection Success:**
   - Green indicator shows connection
   - Device info appears in app
   - You should see Base Duo on map

### Configure Base Duo via App

1. **Open Settings:**
   - Tap device name "Home-Base"
   - Tap "Settings" icon

2. **Radio Configuration:**
   - Navigate to "Radio Config" → "LoRa"
   - Verify settings:
     - Region: US (or your region)
     - Modem Preset: LONG_FAST
     - Hop Limit: 3

3. **Set Fixed Position:**
   - Go to "Radio Config" → "Position"
   - Enable "Fixed Position"
   - Tap "Set to Current Location" (if at home)
   - Or manually enter coordinates:
     - Latitude: 37.7749 (example)
     - Longitude: -122.4194 (example)

4. **Device Role:**
   - Go to "Radio Config" → "Device"
   - Set Role: ROUTER
   - Enable "Is Router"

5. **Save Settings:**
   - Tap "Save" or "Apply"
   - Device will reboot

### Connect to ThinkNode M3 (Initial Setup)

The tracker has Bluetooth disabled by default to save battery. Enable it temporarily for configuration:

1. **Enable Bluetooth on Tracker:**
   - Connect tracker to computer via USB
   - Run: `meshtastic --set bluetooth.enabled true`
   - Or use configuration script

2. **Connect in App:**
   - Tap "+" → "Bluetooth"
   - Select "Dog-Tracker"
   - PIN: 123456 (if prompted)

3. **Configure Tracker:**
   - Go to "Radio Config" → "Device"
   - Set Role: TRACKER
   - Region: US (MUST MATCH BASE DUO)

4. **GPS Settings:**
   - Go to "Radio Config" → "Position"
   - Enable "GPS"
   - GPS Update Interval: 60s
   - Position Broadcast: 60s
   - Enable "Smart Position"
   - Minimum Distance: 25m

5. **Disable Bluetooth (Save Battery):**
   - After configuration complete
   - Reconnect via USB
   - Run: `meshtastic --set bluetooth.enabled false`
   - Or leave disabled in config

## Using the App

### Main Interface

The Meshtastic app has four main tabs:

1. **Messages:** Chat with mesh network
2. **Map:** See device locations
3. **Nodes:** List of all mesh devices
4. **Settings:** Configuration and options

### Tracking Your Dog

#### Map View

1. **Open Map Tab:**
   - Tap "Map" at bottom
   - Map shows all nodes in network

2. **Finding Your Dog:**
   - Look for "Dog-Tracker" icon on map
   - Blue dot = Home-Base (fixed position)
   - Moving icon = Dog's current location

3. **Map Features:**
   - Pinch to zoom
   - Tap node for details
   - Long press for options
   - Path shows movement history

4. **Position Updates:**
   - Updates every 60 seconds (by default)
   - Only when dog has moved >25m (smart position)
   - Timestamp shows last update time

#### Nodes List

1. **Open Nodes Tab:**
   - Shows all devices on network
   - Green = online and connected
   - Gray = offline or out of range

2. **Dog-Tracker Entry Shows:**
   - Last seen time
   - GPS coordinates
   - Distance from you
   - Battery level
   - Signal strength (SNR/RSSI)

3. **Tap Node for Details:**
   - Position history
   - Environmental data (temp/humidity)
   - Device metrics
   - Message node directly

### Setting Up Alerts

#### Position Alerts

The app can notify you of position changes:

1. **Enable Notifications:**
   - Phone Settings → Meshtastic → Notifications → ON

2. **Node Notifications:**
   - Go to Nodes tab
   - Tap "Dog-Tracker"
   - Enable "Notify on Position Update"

#### Geofencing (Advanced)

Geofencing requires custom configuration:

1. **Define Safe Zone:**
   - Determine home area radius (e.g., 500m)
   - Note home coordinates

2. **Configure Alert:**
   - This requires scripting or automation
   - Use MQTT + Home Assistant, or
   - Use Meshtastic Python API

Example Python script:
```python
import meshtastic
from geopy.distance import geodesic

HOME_LAT = 37.7749
HOME_LON = -122.4194
SAFE_RADIUS = 500  # meters

def on_position(packet):
    if packet['from_id'] == 'dog-tracker':
        dog_pos = (packet['lat'], packet['lon'])
        home_pos = (HOME_LAT, HOME_LON)
        distance = geodesic(home_pos, dog_pos).meters

        if distance > SAFE_RADIUS:
            print(f"ALERT: Dog is {distance}m from home!")
            # Send notification

interface = meshtastic.StreamInterface()
interface.on_position = on_position
```

### Viewing Tracker Data

#### Environmental Sensors

ThinkNode M3 sends temperature, humidity, and battery data:

1. **Open Nodes → Dog-Tracker**
2. **Scroll to Telemetry section:**
   - Temperature: Current ambient temp
   - Humidity: Current humidity %
   - Battery: Voltage and percentage
   - Update: Every 15 minutes

#### Motion Detection

The accelerometer can detect activity:

1. **In Node Details:**
   - Look for "Detection Sensor" data
   - Shows if dog is moving/stationary

2. **Activity Tracking:**
   - Movement triggers position updates
   - Smart position only sends when moved

### Message Your Dog (Fun!)

While the dog can't read, you can send messages:

1. **Go to Messages Tab**
2. **Tap "+" to create message**
3. **Select "Dog-Tracker" as recipient**
4. **Type message and send**

More practical: Send messages to yourself or other mesh users about dog's status.

## Advanced Features

### MQTT Integration

Stream data to cloud/home automation:

1. **Configure on Base Duo:**
   - Settings → Radio Config → MQTT
   - Enable MQTT
   - Enter broker address
   - Username/password if needed

2. **Home Assistant Integration:**
   ```yaml
   mqtt:
     sensor:
       - name: "Dog Location"
         state_topic: "meshtastic/2/position"
         json_attributes_topic: "meshtastic/2/position"
   ```

3. **Receive Position Updates:**
   - Topic: `meshtastic/2/position`
   - Payload: JSON with lat/lon/alt/time

### Data Logging

The Base Duo can log position history:

1. **8MB Flash Storage:**
   - Stores thousands of position reports
   - Accessible via serial/USB

2. **Export Data:**
   - Connect Base Duo to computer
   - Use Meshtastic CLI:
     ```bash
     meshtastic --export-db positions.json
     ```

3. **Visualize History:**
   - Import JSON to mapping software
   - Google Earth, QGIS, or custom tools

### Multiple Trackers

Track multiple dogs or add redundancy:

1. **Add Second ThinkNode M3:**
   - Configure as "Dog-2-Tracker"
   - Same region and channel
   - Both appear on map

2. **Mesh Network Benefits:**
   - Trackers relay messages for each other
   - Extends range
   - More reliable tracking

### Channels and Privacy

Secure your mesh network:

1. **Default Channel:**
   - Name: "LongFast"
   - PSK: Default (everyone can see)

2. **Create Private Channel:**
   - Settings → Channels
   - Primary Channel → Edit
   - Tap "Generate Random PSK"
   - Share with trusted devices only

3. **Apply to All Devices:**
   - Must set same PSK on:
     - Base Duo
     - ThinkNode M3
     - Any other mesh nodes

## Troubleshooting

### Can't Connect to Device

1. **Check Bluetooth:**
   - Phone BT enabled
   - Device powered on
   - Within 10m range

2. **Reset Connection:**
   - Remove device from app
   - Forget in phone BT settings
   - Re-pair from scratch

3. **Check Device Settings:**
   - Bluetooth enabled on device?
   - Correct PIN (123456)?

### No Position Updates

1. **Check GPS Lock:**
   - Nodes → Dog-Tracker
   - GPS status should show "3D Fix"
   - Satellites: 8+ visible

2. **Check LoRa Connection:**
   - Last Heard should be recent (<2 min)
   - SNR should be positive (>0)
   - Distance should be within range

3. **Check Configuration:**
   - GPS enabled on tracker?
   - Position broadcast interval set?
   - Device not in deep sleep?

### Position Not Accurate

1. **GPS Issues:**
   - Needs clear sky view
   - Tall buildings affect accuracy
   - Indoor positioning uses WiFi/BLE (less accurate)

2. **Improve Accuracy:**
   - Wait for more satellites (12+ best)
   - Avoid dense urban areas
   - Keep antenna clear

### App Crashes or Slow

1. **Clear App Cache:**
   - Phone Settings → Apps → Meshtastic
   - Clear Cache (not Data)

2. **Update App:**
   - Check for latest version
   - App Store / Play Store

3. **Restart App:**
   - Force close
   - Reopen

### Battery Draining on Phone

1. **Background Refresh:**
   - App runs in background for notifications
   - Disable if not needed

2. **Reduce Update Frequency:**
   - Configure tracker for less frequent updates
   - Disable real-time notifications

## Tips and Best Practices

### Optimizing Battery Life

**Tracker:**
- Increase position interval: 120-180s
- Enable smart position
- Disable Bluetooth when not configuring
- Reduce transmit power if range adequate

**Phone:**
- Use WiFi when home (not LTE)
- Disable background refresh if not needed
- Close app when not actively tracking

### Maximizing Range

**Hardware:**
- Elevate Base Duo (high shelf, attic)
- Mount near window
- Ensure antennas are vertical
- Keep away from metal objects

**Software:**
- Use LONG_FAST preset
- Maximize transmit power (20 dBm)
- Increase hop limit for mesh routing

### Safety Tips

1. **Don't Rely Solely on Tracker:**
   - Technology can fail
   - Always supervise your dog
   - Use tracker as backup safety

2. **Regular Testing:**
   - Test weekly in your area
   - Know your range limits
   - Check battery before outings

3. **Update Firmware:**
   - Keep Meshtastic firmware current
   - Bug fixes and improvements

4. **Have Backup Plan:**
   - Traditional collar with ID tag
   - Microchip registration
   - Recent photo of dog

## Using on Walks

### Pre-Walk Checklist

- [ ] Tracker battery >50%
- [ ] GPS lock verified (outdoors)
- [ ] Base Duo online
- [ ] Phone connected to Base Duo
- [ ] App notifications enabled

### During Walk

1. **Monitor app periodically**
2. **Check position updates arriving**
3. **Note signal strength (SNR)**
4. **Observe max range in your area**

### After Walk

1. **Review path on map**
2. **Check battery remaining**
3. **Charge tracker if needed**
4. **Note any connection issues**

## Next Steps

Now that your app is configured:

1. **Test System:**
   - Short walk around block
   - Verify position updates
   - Check signal strength

2. **Optimize Settings:**
   - Adjust update intervals
   - Tune for battery vs. accuracy
   - Set up preferred alerts

3. **Advanced Setup:**
   - MQTT integration
   - Data logging
   - Geofencing scripts

4. **Expand Network:**
   - Add more mesh nodes
   - Improve coverage
   - Share channel with family

## Resources

- Meshtastic Documentation: https://meshtastic.org/docs
- Meshtastic Forum: https://meshtastic.discourse.group
- GitHub: https://github.com/meshtastic
- Discord: Meshtastic Community Server
