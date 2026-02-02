# Two Base Duo Setup for Backcountry Skiing

Optimal configuration using ThinkNode M3 + 2x Muzi Works Base Duo devices.

## Your Hardware

- **ThinkNode M3**: GPS tracker on dog's collar
- **Base Duo #1**: Handheld/portable device you carry while skiing
- **Base Duo #2**: Trailhead relay station (at car/base camp)

## Why This Setup is Excellent

### Advantages of Two Base Duos

1. **Extended Range**
   - Each Base Duo: 5-6km range
   - Together: 10-15km+ effective range (mesh routing)
   - Trailhead relay extends coverage back to parking

2. **Dual-Band Capability**
   - Base Duo supports Sub-GHz (long range) + 2.4GHz
   - Can use 2.4GHz between handheld and dog (faster updates)
   - Sub-GHz for long-range back to trailhead

3. **Data Logging**
   - Trailhead base logs all positions to 8MB flash
   - Complete trip history preserved
   - Can review tracks after trip

4. **Redundancy**
   - If handheld loses dog signal, trailhead may still have it
   - Multiple routing paths
   - Battery backup options

5. **Power Options**
   - Trailhead: USB + battery + solar
   - Handheld: Battery pack for all-day operation
   - Can swap devices if one dies

## Recommended Configuration

### Device Roles

| Device | Role | Location | Battery Life |
|--------|------|----------|--------------|
| ThinkNode M3 | TRACKER | Dog collar | 6-10 hours |
| Base Duo #1 | CLIENT | In your pocket/pack | 8-12 hours |
| Base Duo #2 | ROUTER | Trailhead/car | All day (USB) |

## Setup Instructions

### Base Duo #1 (Your Handheld)

**Purpose:** Receive dog tracker updates, connect to phone app

**Configuration:**

```bash
PORT=/dev/tty.usbmodem*  # Replace with your port

# Device role - CLIENT (you're mobile too)
meshtastic --port $PORT --set device.role CLIENT

# Node name
meshtastic --port $PORT --set owner.long_name "Skier-Handheld"
meshtastic --port $PORT --set owner.short_name "SKIER"

# Region (set yours)
meshtastic --port $PORT --set lora.region US

# LoRa - Optimized for backcountry
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22  # Max power

# Enable YOUR GPS position too
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 60
meshtastic --port $PORT --set position.position_broadcast_secs 60

# Power - No sleep while skiing
meshtastic --port $PORT --set power.is_power_saving false

# Bluetooth ON for phone connection
meshtastic --port $PORT --set bluetooth.enabled true

# Hop limit for mesh
meshtastic --port $PORT --set lora.hop_limit 5
```

**Hardware Setup:**
- Attach Sub-GHz antenna (SMA connector) - REQUIRED
- Optional: Attach 2.4GHz antenna (U.FL) for dual-band
- Connect to battery pack (Li-ion or LFP)
- Keep in jacket pocket or pack top for antenna clearance
- Connect phone via Bluetooth

### Base Duo #2 (Trailhead Router)

**Purpose:** Extend range, relay messages, log all data

**Configuration:**

```bash
PORT=/dev/tty.usbmodem*  # Replace with your port

# Device role - ROUTER (stationary relay)
meshtastic --port $PORT --set device.role ROUTER

# Node name
meshtastic --port $PORT --set owner.long_name "Trailhead-Base"
meshtastic --port $PORT --set owner.short_name "BASE"

# Region (MUST MATCH other devices)
meshtastic --port $PORT --set lora.region US

# LoRa - Match other devices
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22

# Fixed position at trailhead
meshtastic --port $PORT --set position.gps_enabled false
meshtastic --port $PORT --set position.fixed_position true

# Set trailhead coordinates (get from Google Maps)
meshtastic --port $PORT --set position.latitude 39.5501
meshtastic --port $PORT --set position.longitude -106.0661
meshtastic --port $PORT --set position.altitude 2800

# Power - Stay awake always (router role)
meshtastic --port $PORT --set power.is_power_saving false

# Bluetooth ON for initial setup (can disable later)
meshtastic --port $PORT --set bluetooth.enabled true

# Hop limit
meshtastic --port $PORT --set lora.hop_limit 5

# Enable RX boost for better reception
meshtastic --port $PORT --set lora.sx126x_rx_boosted_gain true
```

**Hardware Setup:**
- Attach Sub-GHz antenna (SMA) - REQUIRED
- Optional: 2.4GHz antenna (U.FL)
- Connect to USB power in car (12V adapter or power bank)
- Optional: Solar panel + battery for multi-day
- Mount antenna outside vehicle or on roof for best range
- Position with clear line-of-sight up valley/mountain

### ThinkNode M3 (Dog Tracker)

Use the backcountry configuration (already covered in main guide):

```bash
# Use the automated script
cd ~/projects/tracker/scripts
./configure-backcountry.sh

# Or manually apply backcountry config
meshtastic --port $PORT --configure-from-file config/backcountry-m3-config.yaml
```

Key settings:
- 30-second updates
- LONG_SLOW preset
- No power saving
- Max TX power

## Quick Setup Script

For convenience, use the automated script:

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Choose option 4 (Complete Setup) and configure:
1. ThinkNode M3 as tracker
2. Base Duo #1 as handheld
3. Base Duo #2 as trailhead base

## Deployment Strategy

### Before Leaving Home

1. **Charge Everything Fully**
   - ThinkNode M3: 100%
   - Base Duo #1: 100%
   - Base Duo #2: 100%
   - Phone: 100%
   - Bring USB battery packs

2. **Test Mesh Network**
   - Power on all three devices
   - Open Meshtastic app on phone
   - Should see all 3 devices in "Nodes" list
   - Verify positions showing

3. **Pack Smart**
   - Handheld Base Duo: Accessible pocket
   - Battery pack: Inner pocket (warmth)
   - Cables: Labeled and organized
   - Trailhead antenna: Protected

### At Trailhead

**Base Duo #2 Setup (5 minutes):**

1. **Set Exact Position:**
   - Get coordinates from phone GPS
   - Update via phone app or USB:
     ```bash
     meshtastic --set position.latitude YOUR_LAT
     meshtastic --set position.longitude YOUR_LON
     ```

2. **Power Setup:**
   - Connect to car USB (12V adapter)
   - Or connect battery pack (10,000+ mAh)
   - Verify device powered on

3. **Antenna Placement:**
   - Mount antenna outside vehicle
   - Magnetic mount on roof (best)
   - Or prop against window inside
   - Point antenna vertically
   - Aim for line-of-sight up valley

4. **Verify Connection:**
   - Check phone app shows "Trailhead-Base"
   - Should see your handheld and dog tracker too
   - Signal strength (SNR) should be strong (>5)

**Final Check:**
- [ ] All 3 devices visible in app
- [ ] Dog tracker showing GPS position
- [ ] Handheld showing your position
- [ ] Trailhead base at parking coordinates
- [ ] All battery levels 100% (or noted)

### While Skiing

**Your Handheld Base Duo:**
- Keep in jacket pocket or pack top pocket
- Antenna should be vertical
- Connect phone via Bluetooth
- Check app every 10-15 minutes

**Monitoring:**
- Dog tracker updates every 30 seconds
- Your position updates every 60 seconds
- Trailhead relays all messages
- "Last Heard" should stay <1 minute

**Mesh Network Benefits:**

```
Dog Tracker ←→ Your Handheld ←→ Trailhead Base
   (M3)           (Base Duo #1)    (Base Duo #2)

   5km range       5km range        5km range

   = 10-15km total effective coverage
```

If you're 8km from trailhead but dog is 3km from you:
- Direct: Dog → Handheld (3km) ✓
- Relayed: Handheld → Trailhead (8km) via mesh ✓
- All positions logged at trailhead ✓

### After Skiing

**Retrieve Data from Trailhead Base:**

```bash
# Connect Base Duo #2 via USB
meshtastic --port /dev/tty.usbmodem* --export-db trip-data.json

# This exports all logged positions from 8MB flash
```

You'll have:
- Complete GPS track of dog
- Complete GPS track of you
- All timestamps
- Signal strength data
- Can visualize in mapping software

## Dual-Band Configuration (Advanced)

The Base Duo supports both Sub-GHz and 2.4GHz. You can use both:

### Strategy

**Sub-GHz (Primary):** Long-range communication
- All devices use this
- Dog → Handheld → Trailhead

**2.4GHz (Secondary):** Short-range, faster updates
- Between handheld and dog when close
- Higher data rate
- Better in dense forest (less foliage loss)

### Enable Dual-Band on Base Duo #1

```bash
# Primary: Sub-GHz (already configured)
meshtastic --set lora.region US
meshtastic --set lora.modem_preset LONG_SLOW

# Secondary: 2.4GHz
meshtastic --set lora_secondary.enabled true
meshtastic --set lora_secondary.frequency 2400
meshtastic --set lora_secondary.modem_preset SHORT_FAST
```

**Note:** ThinkNode M3 only has Sub-GHz, so it won't use 2.4GHz. This is more useful if you add more Base Duo devices.

## Battery Life Optimization

### Expected Battery Life

| Device | Configuration | Battery Life |
|--------|--------------|--------------|
| ThinkNode M3 | 30s updates, max power | 6-10 hours |
| Base Duo #1 (handheld) | CLIENT, GPS enabled | 8-12 hours |
| Base Duo #2 (trailhead) | ROUTER, USB powered | Unlimited |

### Extending Battery Life

**If Base Duo #1 battery running low:**

1. **Disable your position broadcast:**
   ```bash
   # Via app or USB
   meshtastic --set position.position_broadcast_secs 0
   ```
   - Still receives dog tracker
   - Saves ~20% battery

2. **Increase hop limit (rely on trailhead relay):**
   - Keep handheld close to trailhead line-of-sight
   - Let trailhead base do the heavy lifting

3. **Reduce screen brightness** (if using device with screen)

4. **Connect to battery pack** (keep in pocket for warmth)

### Cold Weather Battery Tips

**Problem:** Batteries lose capacity in cold

**Solutions:**

1. **Keep Devices Warm:**
   - Inner jacket pockets
   - Body heat maintains capacity
   - Never in outer pack pockets

2. **Use Battery Packs:**
   - Keep USB battery pack in inner pocket
   - Connect via short cable
   - Pack stays warm = full capacity

3. **Trailhead Base in Vehicle:**
   - Car stays warmer than outside
   - Run car heater periodically if needed
   - Or insulated box with hand warmers

## Range Expectations

### Typical Range with Two Base Duos

**Open Terrain (Line of Sight):**
- Dog to Handheld: 5-10km
- Handheld to Trailhead: 5-10km
- Total coverage: 15-20km from trailhead

**Forest/Trees:**
- Dog to Handheld: 2-4km
- Handheld to Trailhead: 3-5km
- Total coverage: 6-10km from trailhead

**Behind Ridge/Mountain:**
- Direct: May fail
- Via mesh: Often still works (relay around obstacle)
- Depends on terrain

### Real-World Example

**Scenario:** Skiing in Colorado Rockies

```
Trailhead (2800m)
    ↓ 4km through trees
Your position (3100m) on slope
    ↓ 1.5km, line of sight
Dog position (2900m) in valley

Total distance: 5.5km
```

**With two Base Duos:**
- ✓ Dog → Handheld: 1.5km (strong signal)
- ✓ Handheld → Trailhead: 4km (good signal via mesh)
- ✓ All positions logged
- ✓ Real-time updates

**With only one device:**
- ? Dog → Handheld: 1.5km (strong signal)
- ✗ Handheld → Trailhead: 4km + trees (may fail)
- ✗ No logging at base
- ? Less reliable

## Troubleshooting

### Can't See All Three Devices in App

**Check:**
1. All on same region (US vs EU vs ANZ)
2. All on same channel (default is fine)
3. All powered on
4. Wait 2-3 minutes for mesh to form

**Fix:**
```bash
# Verify region on each device
meshtastic --port PORT --get lora.region

# Should all show same (e.g., "US")
```

### Trailhead Base Not Relaying Messages

**Check:**
1. Device role is ROUTER (not CLIENT)
2. hop_limit is 3+ (5 recommended)
3. Antenna attached and vertical
4. Power connected

**Fix:**
```bash
meshtastic --port PORT --set device.role ROUTER
meshtastic --port PORT --set lora.hop_limit 5
meshtastic --port PORT --reboot
```

### Short Battery Life on Handheld

**Possible causes:**
1. Cold weather (expected)
2. GPS enabled (uses power)
3. High transmit power
4. Screen on (if device has screen)

**Solutions:**
- Connect to battery pack
- Keep in warm pocket
- Disable your GPS if not needed:
  ```bash
  meshtastic --set position.gps_enabled false
  ```

### Dog Tracker Lost Connection

**Check:**
1. Last known position (time stamp)
2. Terrain between you and dog
3. Battery level on tracker

**Actions:**
1. Gain elevation (climb to high point)
2. Move toward last position
3. Check if trailhead base still has signal (mesh)
4. Wait for dog to move to better position

## Advanced: Triple Range with Third Device

If you ski with a partner who also has Meshtastic:

```
Trailhead ←→ You ←→ Partner ←→ Dog

10km      5km    3km       2km

= 20km total coverage
```

Everyone sees everyone's position + dog.

## Maintenance After Trip

1. **Export Data:**
   ```bash
   # From trailhead Base Duo #2
   meshtastic --export-db ~/backcountry-trips/$(date +%Y-%m-%d).json
   ```

2. **Charge Everything:**
   - Wipe snow/moisture off
   - Warm to room temp first
   - Then charge fully

3. **Review Trip:**
   - Analyze positions
   - Check max distances
   - Note any connection issues
   - Adjust config if needed

4. **Check Hardware:**
   - Inspect antennas
   - Check USB-C ports
   - Test buttons
   - Verify weatherproofing

## Shopping List (What You Already Have)

- [x] ThinkNode M3 (dog tracker)
- [x] Base Duo #1 (handheld)
- [x] Base Duo #2 (trailhead base)

**Additional Items to Consider:**

- [ ] USB battery pack (10,000+ mAh) - for handheld
- [ ] 12V car USB adapter - for trailhead base
- [ ] Magnetic antenna mount - for car roof
- [ ] Waterproof cases - for devices
- [ ] Extra USB-C cables - labeled
- [ ] Solar panel (optional) - for multi-day
- [ ] Second battery for each Base Duo (optional)

## Quick Reference

**Three Device Configuration:**

```bash
# ThinkNode M3 (Dog)
Role: TRACKER
Updates: 30s
GPS: Enabled
BT: Disabled

# Base Duo #1 (You)
Role: CLIENT
Updates: 60s
GPS: Enabled
BT: Enabled (for phone)

# Base Duo #2 (Trailhead)
Role: ROUTER
GPS: Disabled (fixed position)
Power: USB (always on)
```

**All devices must match:**
- Region (US/EU/ANZ)
- LoRa preset (LONG_SLOW)
- Channel/PSK (default is fine)

## Summary

Your two Base Duos setup is ideal for backcountry skiing:

✓ **Extended Range:** 10-15km+ coverage via mesh
✓ **Redundancy:** Multiple routing paths
✓ **Data Logging:** 8MB flash at trailhead
✓ **Dual-Band:** Sub-GHz + 2.4GHz capability
✓ **Power Options:** USB, battery, solar
✓ **Real-time Tracking:** 30-second dog updates

You have professional-grade backcountry tracking system!

Ready to configure? Run:
```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Choose option 4 for complete setup of all three devices.
