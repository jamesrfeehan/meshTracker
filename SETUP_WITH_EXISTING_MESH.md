# Adding ThinkNode M3 to Your Existing Base Duo Mesh

Quick guide for adding the dog tracker to your working Base Duo network.

## Your Current Setup

✓ 2x Base Duo devices (already communicating)
✓ iPhone & iPad with Meshtastic app
✓ MacBook for configuration
✓ Using 2.4GHz between Base Duos

## Key Info

**ThinkNode M3 only supports Sub-GHz** (915MHz/868MHz)
**Does NOT support 2.4GHz**

This is actually perfect! Your Base Duos are dual-band, so:
- **Sub-GHz**: Long-range dog tracking (5-10km)
- **2.4GHz**: Fast Base Duo mesh (1-2km)

## Quick Setup (10 minutes)

### Step 1: Check Your Base Duo Settings

Connect one Base Duo to MacBook:

```bash
# Find device
ls /dev/tty.usbmodem*

# Check configuration
meshtastic --port /dev/tty.usbmodem* --info
```

**Note these values:**
- `lora.region`: (US, EU_868, etc.)
- `lora.modem_preset`: (LONG_FAST, LONG_SLOW, etc.)
- Channel PSK (if custom)

### Step 2: Configure ThinkNode M3

Connect ThinkNode M3 to MacBook:

```bash
PORT=/dev/tty.usbmodem*  # Your actual port

# Must match your Base Duos!
meshtastic --port $PORT --set lora.region US  # Use YOUR region

# Backcountry dog tracker settings
meshtastic --port $PORT --set device.role TRACKER
meshtastic --port $PORT --set owner.long_name "Dog-Tracker"
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22

# GPS - 30 second updates
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 30
meshtastic --port $PORT --set position.position_broadcast_secs 30
meshtastic --port $PORT --set position.position_broadcast_smart_enabled false

# Battery optimization
meshtastic --port $PORT --set bluetooth.enabled false
meshtastic --port $PORT --set power.is_power_saving false

# Mesh routing
meshtastic --port $PORT --set lora.hop_limit 5
```

**Or use the automated script:**

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Choose option 1 (ThinkNode M3 only).

### Step 3: Test GPS Lock

Take ThinkNode M3 outdoors:

```bash
meshtastic --port /dev/tty.usbmodem* --gps-watch
```

Wait for:
- Fix type: **3D**
- Satellites: **8+**
- Usually takes 2-3 minutes

### Step 4: Verify in App

1. Power on all 3 devices
2. Open Meshtastic app on iPhone or iPad
3. **Nodes tab**: Should see all 3 devices
4. **Map tab**: Should see dog tracker position
5. Wait 2-3 minutes for mesh to form

## Your Network Architecture

```
┌─────────────────────────────────────────┐
│                                          │
│  Base Duo #1 ←─2.4GHz (fast)─→ Base Duo #2
│       ↕                            ↕     │
│   Sub-GHz                      Sub-GHz   │
│   915MHz                       915MHz    │
│       ↕                            ↕     │
│       └──────→ ThinkNode M3 ←─────┘     │
│              (Dog - Sub-GHz only)        │
│                                          │
└─────────────────────────────────────────┘

iPhone/iPad connect via Bluetooth
```

**How it works:**
- ThinkNode M3 sends position on **Sub-GHz** (long range)
- Both Base Duos receive (they listen on Sub-GHz)
- Base Duos relay to each other on **2.4GHz** (when close)
- iPhone/iPad get updates via Bluetooth

## Backcountry Deployment

### Recommended Setup

**Base Duo #1**: You carry (in pocket, connected to iPhone)
**Base Duo #2**: Leave at car/trailhead (relay + logger)
**ThinkNode M3**: On dog's collar

**Range:**
- Dog to Handheld: 5-10km (Sub-GHz)
- Handheld to Trailhead: 5-10km (Sub-GHz)
- **Total: 10-15km+ coverage**

### At Trailhead

**Base Duo #2 (Car):**
- Connect to car USB (12V adapter)
- Attach Sub-GHz antenna (vertical)
- Mount antenna outside or on roof
- Logs everything to 8MB flash

**Base Duo #1 (You):**
- Connect to battery pack
- Keep in jacket pocket (antenna up)
- iPhone connects via Bluetooth

**ThinkNode M3 (Dog):**
- Secure on collar
- Power on outdoors (GPS lock)
- Keep close to body in cold weather

## Troubleshooting

### ThinkNode M3 not appearing in app

Check region matches:
```bash
# Base Duo
meshtastic --port /dev/tty.usbmodemXXXX --get lora.region

# ThinkNode M3
meshtastic --port /dev/tty.usbmodemYYYY --get lora.region

# Must be identical!
```

### No GPS position

- Must be outdoors with clear sky
- Wait 2-3 minutes
- Check: `meshtastic --gps-watch`

### Weak signal

- Check antennas attached to Base Duos
- Test outdoors (buildings block signal)
- Start close (10-20m) then test range

## Battery Life

| Device | Expected Life |
|--------|--------------|
| ThinkNode M3 | 6-10 hours |
| Base Duo #1 (handheld) | 8-12 hours |
| Base Duo #2 (car USB) | All day |

**Cold weather reduces by 20-30%**

## Quick Commands (MacBook)

```bash
# Find devices
ls /dev/tty.usbmodem*

# Check config
meshtastic --port /dev/tty.usbmodem* --info

# Monitor GPS
meshtastic --port /dev/tty.usbmodem* --gps-watch

# Send test message
meshtastic --port /dev/tty.usbmodem* --sendtext "Test"

# Check all nodes
meshtastic --port /dev/tty.usbmodem* --nodes

# Export trip data
meshtastic --port /dev/tty.usbmodem* --export-db trip.json
```

## Configuration Checklist

All 3 devices must match:
- [ ] Region (US, EU_868, etc.)
- [ ] Channel name (default: "LongFast")
- [ ] Channel PSK (default or your custom one)
- [ ] Modem preset (recommend LONG_SLOW for backcountry)

ThinkNode M3 specific:
- [ ] GPS enabled
- [ ] 30-second update interval
- [ ] TRACKER role
- [ ] Bluetooth disabled (battery saving)
- [ ] Max TX power (22 dBm)

## After Your Trip

Export complete GPS history from Base Duo #2:

```bash
meshtastic --port /dev/tty.usbmodem* --export-db trip-$(date +%Y-%m-%d).json
```

This saves the complete track of both you and your dog!

## Full Documentation

- `docs/add-thinknode-to-existing-mesh.md` - Detailed guide
- `docs/backcountry-guide.md` - Backcountry operations
- `docs/two-base-duo-setup.md` - Dual Base Duo setup
- `BACKCOUNTRY_SETUP.md` - Quick reference

## Ready to Configure?

**Option 1: Automated**
```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

**Option 2: Manual**
Use commands in Step 2 above.

---

**Questions?** See `docs/add-thinknode-to-existing-mesh.md` for detailed troubleshooting.

**Safe skiing! 🎿🐕**
