# USA Region Setup - Complete Configuration Guide

Quick setup for your dog tracker system in the United States (915 MHz).

## Your Hardware

✓ 2x Base Duo (currently 2.4GHz only)
✓ 1x ThinkNode M3 (dog tracker)
✓ iPad with Meshtastic app
✓ MacBook for configuration

## Configuration Steps

### Step 1: Enable Sub-GHz on Base Duo #1 (iPad)

1. **Open Meshtastic app on iPad**
2. **Ensure connected to Base Duo #1**
3. **Tap the device name** at top
4. **Tap Settings icon** (gear/cog)
5. **Navigate to: Radio Configuration → LoRa**

6. **Configure these settings:**
   ```
   Region: US
   Modem Preset: LONG_SLOW
   Frequency Slot: 0 (default)
   Hop Limit: 5
   TX Power: 20
   TX Enabled: ON
   ```

7. **Tap Save** (top right)
8. **Device will reboot** - wait 30 seconds
9. **Reconnect in app**

### Step 2: Enable Sub-GHz on Base Duo #2 (iPad)

1. **Switch to Base Duo #2** in app (tap device switcher)
2. **Or disconnect and reconnect to Base Duo #2**
3. **Repeat exact same settings:**
   ```
   Region: US
   Modem Preset: LONG_SLOW
   Frequency Slot: 0
   Hop Limit: 5
   TX Power: 20
   TX Enabled: ON
   ```
4. **Save and reboot**

**Critical:** Both Base Duos must have IDENTICAL Sub-GHz settings!

### Step 3: Attach Sub-GHz Antennas

Each Base Duo needs **two antennas**:

**Check your Base Duos:**
```
┌─────────────────────┐
│    Base Duo Board   │
├─────────────────────┤
│                     │
│  [SMA] ← Screw on 915MHz antenna (larger)
│   ↑                 │
│   ADD THIS!         │
│                     │
│  [U.FL] ← 2.4GHz antenna (small, already there)
│   ↑                 │
│   KEEP THIS!        │
│                     │
└─────────────────────┘
```

**Attach 915MHz antennas:**
1. Find the 915MHz antennas (came with Base Duos)
   - Larger than 2.4GHz antennas
   - SMA screw-on connector
   - Usually labeled "915MHz" or "Sub-GHz"

2. Screw onto SMA connector on each Base Duo
   - Hand-tight, don't over-torque
   - Position vertically

3. Keep 2.4GHz antennas attached (U.FL connector)

**Result:** Each Base Duo now has 2 antennas

### Step 4: Verify Base Duos Still Communicating

1. **Open Meshtastic app**
2. **Go to Nodes tab**
3. **Should see both Base Duos**
4. **Try sending message between them**
5. **Both 2.4GHz and Sub-GHz should work now**

### Step 5: Configure ThinkNode M3 (MacBook)

#### Option A: Automated Script (Recommended)

```bash
# Navigate to project
cd ~/projects/tracker/scripts

# Run configuration script
./configure-backcountry.sh
```

**When prompted:**
- Choose: **1** (Configure ThinkNode M3 only)
- Region: **1** (US - United States)
- Follow prompts

**Done!** Script configures everything automatically.

#### Option B: Manual Configuration (If you prefer)

```bash
# Connect ThinkNode M3 to MacBook via USB

# Find device port
ls /dev/tty.usbmodem*
# Note the port, e.g., /dev/tty.usbmodem12345

# Set port variable
PORT=/dev/tty.usbmodem12345  # Replace with YOUR port

# Configure for USA
meshtastic --port $PORT --set lora.region US
meshtastic --port $PORT --set device.role TRACKER
meshtastic --port $PORT --set owner.long_name "Dog-Tracker"
meshtastic --port $PORT --set owner.short_name "DOG"

# Backcountry-optimized settings
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22  # Max for ThinkNode M3
meshtastic --port $PORT --set lora.hop_limit 5

# GPS configuration - 30 second updates
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 30
meshtastic --port $PORT --set position.position_broadcast_secs 30
meshtastic --port $PORT --set position.position_broadcast_smart_enabled false
meshtastic --port $PORT --set position.position_flags 7  # Alt + heading + speed

# Battery optimization
meshtastic --port $PORT --set bluetooth.enabled false
meshtastic --port $PORT --set power.is_power_saving false
meshtastic --port $PORT --set power.mesh_sds_timeout_secs 0
meshtastic --port $PORT --set power.sds_secs 0
meshtastic --port $PORT --set power.ls_secs 0

# Telemetry (temp, humidity, battery)
meshtastic --port $PORT --set telemetry.device_update_interval 300
meshtastic --port $PORT --set telemetry.environment_update_interval 300
meshtastic --port $PORT --set telemetry.environment_measurement_enabled true

# Enable motion detection
meshtastic --port $PORT --set detection_sensor.enabled true

# Verify configuration
meshtastic --port $PORT --info
```

### Step 6: Test GPS Lock (IMPORTANT)

**Take ThinkNode M3 outdoors** (must have clear sky view):

```bash
# Monitor GPS acquisition
meshtastic --port /dev/tty.usbmodem* --gps-watch
```

**Wait for:**
- **Fix Type: 3D** (not 2D or NO_FIX)
- **Satellites: 8+** (more is better)
- **Latitude/Longitude: Valid coordinates**
- **Altitude: Your elevation in meters**

**Typically takes:** 2-3 minutes for first lock

**Press Ctrl+C** to exit when you see good lock

### Step 7: Verify Complete System (iPad)

1. **Power on all 3 devices**
2. **Open Meshtastic app on iPad**
3. **Go to Nodes tab**

**You should see:**
```
✓ Base Duo #1 (green = online)
✓ Base Duo #2 (green = online)
✓ Dog-Tracker (green = online, new!)
```

4. **Go to Map tab**

**You should see:**
```
✓ Base Duo #1 position
✓ Base Duo #2 position
✓ Dog-Tracker position (GPS coordinates)
```

5. **Tap Dog-Tracker node**

**You should see:**
```
✓ Last Heard: <1 minute ago
✓ SNR: Positive number (signal strength)
✓ Battery: Percentage
✓ Latitude/Longitude
✓ Altitude
✓ Temperature/Humidity
```

**Wait 2-3 minutes for mesh network to fully establish**

## Your Complete USA Configuration

### All Devices Settings

| Setting | Base Duo #1 | Base Duo #2 | ThinkNode M3 |
|---------|-------------|-------------|--------------|
| **Region** | US | US | US |
| **Frequency** | 915 MHz | 915 MHz | 915 MHz |
| **Modem Preset** | LONG_SLOW | LONG_SLOW | LONG_SLOW |
| **TX Power** | 20 dBm | 20 dBm | 22 dBm |
| **Hop Limit** | 5 | 5 | 5 |
| **Role** | CLIENT | CLIENT | TRACKER |
| **GPS** | Optional | Optional | Enabled (30s) |
| **Bluetooth** | Enabled | Enabled | Disabled |
| **2.4GHz** | Enabled | Enabled | N/A |

### Network Architecture

```
┌────────────────────────────────────────────────┐
│          USA 915 MHz Mesh Network               │
├────────────────────────────────────────────────┤
│                                                 │
│  Base Duo #1 ←─── 2.4GHz (1-2km) ───→ Base Duo #2
│       ↕                                   ↕     │
│   Sub-GHz                             Sub-GHz  │
│   915MHz                              915MHz   │
│   (5-10km)                            (5-10km) │
│       ↕                                   ↕     │
│       └──────────→ ThinkNode M3 ←───────┘      │
│              (Dog - 915MHz only)                │
│                                                 │
│  All visible in iPad Meshtastic app             │
│  Real-time tracking every 30 seconds            │
│                                                 │
└────────────────────────────────────────────────┘
```

## Troubleshooting

### ThinkNode M3 Not Appearing in App

**Check 1: Region matches**
```bash
# On MacBook, check ThinkNode M3
meshtastic --port /dev/tty.usbmodem* --get lora.region
# Should return: US

# Compare to Base Duo (via iPad app or MacBook)
# Settings → Radio Configuration → LoRa → Region
# Must be: US
```

**Check 2: Wait longer**
- Mesh network takes 2-3 minutes to form
- Be patient, check Nodes tab periodically

**Check 3: Distance**
- Start with all 3 devices close together (same room)
- Verify connection first
- Then test range

**Check 4: GPS lock**
- ThinkNode M3 may not appear until GPS locks
- Take outdoors, wait 3-5 minutes
- Run: `meshtastic --gps-watch`

### No GPS Position Showing

**Symptoms:** Device appears in Nodes but no position on Map

**Fix:**
- ThinkNode M3 must be outdoors
- Clear sky view required
- Wait 3-5 minutes for first lock
- Check: `meshtastic --port /dev/tty.usbmodem* --gps-watch`

### Base Duos Lost 2.4GHz Connection

**Symptoms:** Base Duos can't see each other anymore

**Check:** 2.4GHz antenna still attached (U.FL connector)

**Fix via iPad app:**
1. Settings → Radio Configuration
2. Look for secondary radio section
3. Ensure 2.4GHz enabled

**Fix via MacBook:**
```bash
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.enabled true
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.region ISM_2400
```

### Weak Signal / Short Range

**Check antennas:**
- Both antennas attached to each Base Duo
- 915MHz antenna vertical
- 2.4GHz antenna vertical
- Not touching metal

**Increase power (if needed):**
```bash
# Base Duos (already at max 20 for Sub-GHz)
# ThinkNode M3 (already at max 22)
# You're already maxed out!
```

**Try outdoors:**
- Buildings block signals significantly
- Test range outdoors first
- Urban: 1-2km typical
- Suburban: 3-5km typical
- Open: 5-10km typical

## Expected Performance (USA 915 MHz)

### Range Expectations

| Environment | Sub-GHz Range | 2.4GHz Range |
|-------------|---------------|--------------|
| Open terrain/ridgeline | 5-10km | 1-2km |
| Light forest | 2-4km | 500m-1km |
| Dense forest | 1-2km | 300-500m |
| Urban/buildings | 1-2km | 300-800m |
| Mountains (LOS) | 10-15km+ | 1-3km |

### Battery Life (30s updates)

| Device | Expected Life |
|--------|--------------|
| ThinkNode M3 | 6-10 hours |
| Base Duo #1 (dual-band) | 8-10 hours |
| Base Duo #2 (dual-band) | 8-10 hours |

**Cold weather (-10°C / 14°F):** Reduce by 20-30%

## Backcountry Deployment

### Recommended Setup

**Base Duo #1:**
- You carry in pocket
- Connected to iPad/iPhone
- Battery pack for all-day use

**Base Duo #2:**
- Leave at car/trailhead
- Connect to car USB (12V adapter)
- Acts as relay and data logger
- Mount 915MHz antenna on roof or outside

**ThinkNode M3:**
- Secure on dog's collar
- Keep close to body in extreme cold
- Check battery before each outing

### Coverage Example

```
Trailhead (Base Duo #2)
    ↓ 6km (Sub-GHz through trees)
You skiing (Base Duo #1)
    ↓ 2km (Sub-GHz, line of sight)
Dog (ThinkNode M3)

Total coverage: 8km from trailhead
Real-time updates every 30 seconds
```

## Testing Checklist

Before your first backcountry trip:

- [ ] All 3 devices show in iPad app (Nodes tab)
- [ ] Dog position showing on Map tab
- [ ] GPS lock achieved (3D fix, 8+ satellites)
- [ ] "Last Heard" stays current (<2 minutes)
- [ ] Signal strength (SNR) is positive
- [ ] Both antennas on each Base Duo
- [ ] Battery levels at 100%
- [ ] Test range in your area (start close, go farther)
- [ ] ThinkNode M3 secure on collar
- [ ] Know your expected battery life

## Quick Command Reference (MacBook)

```bash
# Find connected device
ls /dev/tty.usbmodem*

# Check configuration
meshtastic --port /dev/tty.usbmodem* --info

# Check region
meshtastic --port /dev/tty.usbmodem* --get lora.region

# Monitor GPS
meshtastic --port /dev/tty.usbmodem* --gps-watch

# Send test message
meshtastic --port /dev/tty.usbmodem* --sendtext "Testing from dog tracker"

# Check all nodes
meshtastic --port /dev/tty.usbmodem* --nodes

# Export trip data (from Base Duo #2)
meshtastic --port /dev/tty.usbmodem* --export-db trip-$(date +%Y-%m-%d).json

# Reboot device
meshtastic --port /dev/tty.usbmodem* --reboot
```

## After Configuration

### Mount ThinkNode M3 on Collar

1. **Use secure attachment method:**
   - Magnetic base (included)
   - Protective pouch
   - Integrated collar pocket

2. **Position on top/side of neck** (not underneath)

3. **Check fit:**
   - Two-finger rule for collar tightness
   - Device secure but removable
   - Dog comfortable

4. **For extreme cold (<0°F / -18°C):**
   - Use insulated pouch
   - Keep close to body heat

### Pre-Trip Routine

1. **Night before:**
   - Charge all devices to 100%
   - Check firmware versions
   - Test GPS lock

2. **At trailhead:**
   - Set up Base Duo #2 in car
   - Power on all devices
   - Verify mesh network (iPad app)
   - Check GPS lock on dog tracker
   - Note battery levels

3. **During trip:**
   - Check iPad app every 10-15 minutes
   - Monitor "Last Heard" times
   - Watch battery levels
   - Keep handheld in pocket (warm)

4. **After trip:**
   - Export data from Base Duo #2
   - Charge all devices
   - Review tracks
   - Check for hardware issues

## Summary - You're Ready!

✓ **Region: US (915 MHz)** - Legal for USA
✓ **All 3 devices configured** - Ready to mesh
✓ **Sub-GHz + 2.4GHz** - Dual-band operation
✓ **30-second updates** - Real-time tracking
✓ **6-10 hour battery** - Full day skiing
✓ **5-10km range** - Backcountry coverage
✓ **iPad app ready** - Easy monitoring

Your dog tracking system is now configured for backcountry skiing in the USA!

## Need Help?

- **Hardware setup:** `docs/hardware-setup.md`
- **Backcountry guide:** `docs/backcountry-guide.md`
- **Troubleshooting:** `docs/troubleshooting.md`
- **Dual-band details:** `docs/dual-band-simultaneous-operation.md`

**Ready to ski! 🎿🐕**
