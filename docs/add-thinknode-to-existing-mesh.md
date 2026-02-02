# Adding ThinkNode M3 to Your Existing Base Duo Mesh

Guide for adding the ThinkNode M3 dog tracker to your working Base Duo network.

## Your Current Setup

✓ **2x Base Duo devices** - Already communicating
✓ **iPhone & iPad** - Connected via Meshtastic app
✓ **MacBook** - For development/configuration
✓ **Using 2.4GHz** - Between Base Duos (fast, short range)

## Key Constraint

**ThinkNode M3 only supports Sub-GHz** (915MHz or 868MHz depending on region)
- Does NOT support 2.4GHz
- This is actually perfect for your use case!

## Optimal Network Architecture

Your Base Duos are **dual-band capable**, so use both frequencies:

```
┌─────────────────────────────────────────────────┐
│              Your Mesh Network                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  Base Duo #1 ←──2.4GHz (fast)──→ Base Duo #2   │
│       ↕                                ↕         │
│   Sub-GHz                          Sub-GHz      │
│       ↕                                ↕         │
│  ThinkNode M3 (Dog) ←──Sub-GHz──→ Both Duos    │
│                                                  │
└─────────────────────────────────────────────────┘

iPhone/iPad connect to Base Duos via Bluetooth
```

### Why This is Perfect

1. **Base Duos talk on 2.4GHz**: Fast, high data rate between themselves
2. **Dog tracker uses Sub-GHz**: Long range (5-10km), better terrain penetration
3. **Best of both worlds**: Fast local mesh + long-range dog tracking

## Quick Setup Steps

### Step 1: Check Your Base Duo Configuration

On your MacBook, connect one Base Duo via USB:

```bash
# Find the device
ls /dev/tty.usbmodem*

# Check current config
meshtastic --port /dev/tty.usbmodem* --info
```

**Important info to note:**
- What's your `lora.region`? (US, EU_868, etc.)
- What's your channel PSK? (if you customized it)
- What's your `lora.modem_preset`?

### Step 2: Configure ThinkNode M3 to Match

The ThinkNode M3 must match your Base Duos' **Sub-GHz settings**.

**Connect ThinkNode M3 via USB:**

```bash
# Find device
ls /dev/tty.usbmodem*

# Set to match your Base Duos
PORT=/dev/tty.usbmodem12345  # Replace with your actual port

# Critical: Must match Base Duos
meshtastic --port $PORT --set lora.region US  # Or EU_868, ANZ, etc.

# Device role
meshtastic --port $PORT --set device.role TRACKER

# Node name
meshtastic --port $PORT --set owner.long_name "Dog-Tracker"
meshtastic --port $PORT --set owner.short_name "DOG"

# Match your Base Duos' modem preset
# If you're using default, this is likely LONG_FAST
# For backcountry, use LONG_SLOW
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW

# Backcountry-optimized GPS settings
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 30
meshtastic --port $PORT --set position.position_broadcast_secs 30
meshtastic --port $PORT --set position.position_broadcast_smart_enabled false

# Max power for range
meshtastic --port $PORT --set lora.tx_power 22  # or 20

# Disable Bluetooth to save battery
meshtastic --port $PORT --set bluetooth.enabled false

# Disable power saving (real-time tracking)
meshtastic --port $PORT --set power.is_power_saving false

# Mesh routing
meshtastic --port $PORT --set lora.hop_limit 5

# Verify
meshtastic --port $PORT --info
```

### Step 3: Match Channel/PSK (If Custom)

If you changed your channel PSK from default:

```bash
# On Base Duo, check channel
meshtastic --port /dev/tty.usbmodem* --ch-index 0

# Copy PSK to ThinkNode M3
meshtastic --port /dev/tty.usbmodem* --ch-set psk YOUR_PSK_HERE --ch-index 0
```

If using default PSK, skip this step.

### Step 4: Test Outdoors

1. **Get GPS lock on ThinkNode M3:**
   ```bash
   meshtastic --port /dev/tty.usbmodem* --gps-watch
   ```
   Wait for "3D Fix" and 8+ satellites (2-3 minutes)

2. **Power on all devices**

3. **Check iPhone/iPad Meshtastic app:**
   - Open "Nodes" tab
   - Should see all 3 devices:
     - Base Duo #1
     - Base Duo #2
     - Dog-Tracker
   - Wait 2-3 minutes for mesh to form

4. **Check "Map" tab:**
   - Should see dog tracker position
   - Position updates every 30 seconds

## Understanding Your Dual-Band Network

### Sub-GHz (Primary - Dog Tracking)

**Frequency:** 915MHz (US) or 868MHz (EU)
**Used by:** All 3 devices (2 Base Duos + ThinkNode M3)
**Range:** 5-10km in open terrain
**Purpose:** Long-range dog tracking

**All devices communicate on Sub-GHz:**
- ThinkNode M3 → Base Duo #1
- ThinkNode M3 → Base Duo #2
- Base Duo #1 ↔ Base Duo #2

### 2.4GHz (Secondary - Base Duo Mesh)

**Frequency:** 2.4GHz
**Used by:** Only the 2 Base Duos (ThinkNode M3 can't use this)
**Range:** 1-2km
**Purpose:** Fast data between Base Duos when close

**Configuration on Base Duos:**

```bash
# Primary radio: Sub-GHz (already configured)
meshtastic --set lora.region US
meshtastic --set lora.modem_preset LONG_SLOW

# Secondary radio: 2.4GHz (optional)
meshtastic --set lora_secondary.enabled true
meshtastic --set lora_secondary.modem_preset SHORT_FAST
```

**Note:** You may already have this configured if Base Duos are talking on 2.4GHz.

### How Messages Route

**Example:** Dog sends position update

```
1. ThinkNode M3 sends on Sub-GHz (915MHz)
   ↓
2. Both Base Duos receive (Sub-GHz radios)
   ↓
3. Base Duos relay to each other on 2.4GHz (if needed)
   ↓
4. Base Duos relay to iPhone/iPad via Bluetooth
```

## Automated Configuration Script

For convenience, use the backcountry script:

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Choose option 1 (just ThinkNode M3), and it will:
- Prompt for your region
- Configure for backcountry use
- Match your existing mesh settings

## Verify Everything Works

### Checklist

- [ ] ThinkNode M3 GPS has lock (3D fix)
- [ ] All 3 devices visible in Meshtastic app "Nodes"
- [ ] Dog tracker position shows on "Map"
- [ ] "Last Heard" stays current (<2 minutes)
- [ ] Signal strength (SNR) is positive
- [ ] Battery level showing on all devices

### Test Commands (MacBook)

```bash
# Check ThinkNode M3 config
meshtastic --port /dev/tty.usbmodem* --info

# Monitor GPS
meshtastic --port /dev/tty.usbmodem* --gps-watch

# Send test message
meshtastic --port /dev/tty.usbmodem* --sendtext "Test from dog tracker"

# Check mesh nodes
meshtastic --port /dev/tty.usbmodem* --nodes
```

## Troubleshooting

### ThinkNode M3 Not Appearing in App

**Check region match:**
```bash
# On Base Duo
meshtastic --port /dev/tty.usbmodemXXXX --get lora.region

# On ThinkNode M3
meshtastic --port /dev/tty.usbmodemYYYY --get lora.region

# Should be identical (e.g., both "US")
```

**Check channel/PSK:**
```bash
# On Base Duo
meshtastic --port /dev/tty.usbmodemXXXX --ch-index 0

# On ThinkNode M3
meshtastic --port /dev/tty.usbmodemYYYY --ch-index 0

# Should match
```

### No GPS Position

ThinkNode M3 needs:
- Clear sky view (outdoors)
- 2-3 minutes for first lock
- 8+ satellites visible

```bash
meshtastic --port /dev/tty.usbmodem* --gps-watch
```

### Weak Signal

If SNR is negative or "Last Heard" is >5 minutes:
- Check antenna on Base Duos (must be attached!)
- Try outdoors (buildings block signal)
- Increase TX power: `meshtastic --set lora.tx_power 22`
- Check distance (start close, 10-20m, then test range)

## Configuration Summary

### Your Network

| Device | Radio(s) | Frequency | Role |
|--------|----------|-----------|------|
| Base Duo #1 | Sub-GHz + 2.4GHz | 915MHz + 2.4GHz | CLIENT/ROUTER |
| Base Duo #2 | Sub-GHz + 2.4GHz | 915MHz + 2.4GHz | CLIENT/ROUTER |
| ThinkNode M3 | Sub-GHz only | 915MHz | TRACKER |

### Critical Matches

All devices must match:
- ✓ Region (US, EU_868, etc.)
- ✓ Channel name (default: "LongFast")
- ✓ Channel PSK (default or custom)
- ✓ Modem preset (LONG_FAST or LONG_SLOW)

## Backcountry Deployment

### Recommended Roles

Since you already have the Base Duos working:

**Option A: Both Base Duos Mobile**
- Base Duo #1: You carry (connected to iPhone)
- Base Duo #2: Partner carries (connected to iPad)
- ThinkNode M3: On dog
- All see each other's positions

**Option B: One Base at Trailhead**
- Base Duo #1: You carry (connected to iPhone/iPad)
- Base Duo #2: Left at car (relay + logger)
- ThinkNode M3: On dog
- Extended range, data logging

**Option C: Maximum Coverage**
- Base Duo #1: You carry
- Base Duo #2: At trailhead
- ThinkNode M3: On dog
- One of you also carries iPhone/iPad for monitoring

### My Recommendation: Option B

```
Trailhead (Base Duo #2)
   ↓ Sub-GHz: 5-10km
You skiing (Base Duo #1 + iPhone)
   ↓ Sub-GHz: 5-10km
Dog (ThinkNode M3)

Total coverage: 10-15km
Base Duos also talk on 2.4GHz when close
```

## Advanced: Optimizing Dual-Band

### Current Setup Check

```bash
# Check if 2.4GHz is enabled on Base Duos
meshtastic --port /dev/tty.usbmodem* --get lora_secondary.enabled
```

### If You Want to Enable 2.4GHz Between Base Duos

```bash
# On both Base Duos
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.enabled true
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.modem_preset SHORT_FAST
```

**Benefits:**
- Fast communication when Base Duos are close (<1km)
- Higher bandwidth for messaging
- Automatic fallback to Sub-GHz when far apart

**Note:** ThinkNode M3 always uses Sub-GHz, unaffected by this.

## MacBook Development Setup

### Useful Commands

```bash
# Quick info on all connected devices
for port in /dev/tty.usbmodem*; do
  echo "=== $port ==="
  meshtastic --port $port --info | grep -E "Owner|Role|Region|Modem"
done

# Monitor multiple devices
# Terminal 1: Base Duo
meshtastic --port /dev/tty.usbmodem12345 --debug

# Terminal 2: ThinkNode M3
meshtastic --port /dev/tty.usbmodem67890 --debug

# Export configuration for backup
meshtastic --port /dev/tty.usbmodem* --export-config > thinknode-m3-backup.yaml
```

### Python Scripting (Optional)

If you want to write custom tracking scripts:

```python
import meshtastic
import meshtastic.serial_interface

# Connect to Base Duo via USB
interface = meshtastic.serial_interface.SerialInterface('/dev/tty.usbmodem12345')

# Listen for position updates
def on_receive(packet, interface):
    if 'position' in packet['decoded']:
        pos = packet['decoded']['position']
        print(f"Dog position: {pos['latitude']}, {pos['longitude']}")
        print(f"Altitude: {pos.get('altitude', 'N/A')}m")

interface.on_receive = on_receive

# Keep running
while True:
    time.sleep(1)
```

## Data Export After Trip

```bash
# Connect Base Duo #2 (if used as trailhead logger)
meshtastic --port /dev/tty.usbmodem* --export-db ~/skiing-trips/$(date +%Y-%m-%d).json

# Parse with Python
import json
with open('trip-data.json') as f:
    data = json.load(f)
    for entry in data['positions']:
        print(f"{entry['time']}: {entry['lat']}, {entry['lon']}")
```

## Quick Reference Card

Save this for field use:

```
DEVICE FREQUENCIES
==================
Base Duo #1: 915MHz (Sub-GHz) + 2.4GHz
Base Duo #2: 915MHz (Sub-GHz) + 2.4GHz
ThinkNode M3: 915MHz (Sub-GHz) ONLY

MUST MATCH
==========
Region: US (or EU_868, ANZ)
Channel: Default or custom PSK
Modem: LONG_SLOW for backcountry

CONNECT TO MAC
==============
ls /dev/tty.usbmodem*
meshtastic --port /dev/tty.usbmodem* --info

GPS CHECK
=========
meshtastic --port /dev/tty.usbmodem* --gps-watch
Wait for: 3D Fix, 8+ satellites

VERIFY MESH
===========
iPhone/iPad Meshtastic app
-> Nodes tab: Should see all 3 devices
-> Map tab: Should see positions

BATTERY LIFE
============
ThinkNode M3: 6-10 hours (30s updates)
Base Duo: 8-12 hours (on battery)
```

## Next Steps

1. **Connect ThinkNode M3 to MacBook via USB**
2. **Run configuration** (manual commands above or script)
3. **Test GPS lock outdoors** (2-3 minutes)
4. **Verify all 3 devices in app**
5. **Test range** at your skiing location
6. **Read backcountry guide** for deployment strategy

## Summary

Your setup is ideal:
- ✓ **Sub-GHz for dog tracking** (long range, terrain penetration)
- ✓ **2.4GHz between Base Duos** (fast local mesh)
- ✓ **Dual-band Base Duos** (best of both worlds)
- ✓ **MacBook for development** (easy configuration)
- ✓ **iPhone/iPad for monitoring** (real-time app)

The ThinkNode M3 only needs Sub-GHz, which is exactly what you want for long-range dog tracking in the backcountry!

Ready to configure? Connect the ThinkNode M3 and run:
```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Or use the manual commands above. Let me know if you need help with any step!
