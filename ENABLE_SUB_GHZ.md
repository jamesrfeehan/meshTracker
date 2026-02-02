# Enable Sub-GHz on Your Base Duos (Currently 2.4GHz Only)

Quick guide to add Sub-GHz radio to your existing 2.4GHz mesh network.

## Current Situation

✓ 2x Base Duo devices
✓ Using 2.4GHz (working with iPad/iPhone)
✗ Sub-GHz not configured yet
→ ThinkNode M3 needs Sub-GHz to join

## Goal

Enable **both radios simultaneously** on your Base Duos:
- Keep 2.4GHz (fast, 1-2km)
- Add Sub-GHz (long range, 5-10km)
- ThinkNode M3 joins via Sub-GHz

## Two Ways to Configure

### Option 1: Using iPad App (Easiest)

Since you're already comfortable with the iPad app:

#### Base Duo #1

1. **Open Meshtastic app on iPad**
2. **Connect to Base Duo #1** (should already be connected)
3. **Go to Settings → Radio Configuration → LoRa**

4. **Configure Primary Radio (Sub-GHz):**
   - **Region**: US (or your region: EU 868, ANZ 915, etc.)
   - **Modem Preset**: LONG_SLOW (for backcountry range)
   - **TX Power**: 20 (maximum for Sub-GHz)
   - **Hop Limit**: 5
   - Tap **Save**

5. **Device will reboot** - wait 30 seconds

6. **Verify:**
   - Radio Config → LoRa should show your settings
   - Device should still appear in Nodes list

#### Base Duo #2

Repeat the exact same steps for Base Duo #2:
- Region: US (must match Base Duo #1)
- Modem Preset: LONG_SLOW
- TX Power: 20
- Hop Limit: 5

**Important:** Both Base Duos must have identical Sub-GHz settings!

#### Check 2.4GHz Still Active

Your 2.4GHz should remain active. Check in app:
- Settings → Radio Configuration
- Look for both LoRa sections
- Should see primary (Sub-GHz) and secondary (2.4GHz)

### Option 2: Using MacBook (More Control)

If you want to use your MacBook for precise configuration:

#### Step 1: Connect Base Duo #1 to MacBook

```bash
# Find device
ls /dev/tty.usbmodem*

# Should show something like: /dev/tty.usbmodem12345
```

#### Step 2: Check Current Configuration

```bash
PORT=/dev/tty.usbmodem12345  # Use your actual port

# See what's currently configured
meshtastic --port $PORT --info

# Look for:
# - LoRa (primary radio)
# - LoRa Secondary (2.4GHz - probably already configured)
```

#### Step 3: Enable Sub-GHz Radio

```bash
# Configure Sub-GHz (Primary Radio)
meshtastic --port $PORT --set lora.region US  # Change to your region!

# For backcountry use
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 20
meshtastic --port $PORT --set lora.hop_limit 5

# Ensure it's enabled
meshtastic --port $PORT --set lora.tx_enabled true

# Verify
meshtastic --port $PORT --info | grep -A 10 "LoRa"
```

#### Step 4: Repeat for Base Duo #2

Disconnect Base Duo #1, connect Base Duo #2, and run the same commands:

```bash
PORT=/dev/tty.usbmodem67890  # Different port

meshtastic --port $PORT --set lora.region US
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 20
meshtastic --port $PORT --set lora.hop_limit 5
meshtastic --port $PORT --set lora.tx_enabled true
```

## Add Sub-GHz Antennas

**CRITICAL:** You probably only have 2.4GHz antennas attached right now!

### Check Your Antennas

Each Base Duo has **two antenna connectors**:

```
Base Duo Board:
├── SMA connector (larger)
│   └── Sub-GHz antenna (915MHz/868MHz)
│       Must add this!
│
└── U.FL connector (tiny)
    └── 2.4GHz antenna (already attached)
        Keep this!
```

### Add Sub-GHz Antennas

1. **Get Sub-GHz antennas** (should come with Base Duo)
   - Look for larger antenna (915MHz or 868MHz)
   - SMA connector (screw-on type)

2. **Attach to each Base Duo:**
   - Screw onto SMA connector
   - Hand-tight (don't over-torque)
   - Position vertically

3. **Keep 2.4GHz antennas attached:**
   - Small antenna on U.FL connector
   - Should already be there
   - Don't remove!

**You should have 2 antennas on each Base Duo when done!**

## Configure ThinkNode M3

Now add the dog tracker to your mesh:

### Using MacBook

```bash
PORT=/dev/tty.usbmodem*  # ThinkNode M3 port

# Must match Base Duos' Sub-GHz settings!
meshtastic --port $PORT --set lora.region US  # Same as Base Duos

# Backcountry dog tracker config
meshtastic --port $PORT --set device.role TRACKER
meshtastic --port $PORT --set owner.long_name "Dog-Tracker"
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW  # Match Base Duos
meshtastic --port $PORT --set lora.tx_power 22

# GPS - 30 second updates
meshtastic --port $PORT --set position.gps_enabled true
meshtastic --port $PORT --set position.gps_update_interval 30
meshtastic --port $PORT --set position.position_broadcast_secs 30
meshtastic --port $PORT --set position.position_broadcast_smart_enabled false

# Battery optimization
meshtastic --port $PORT --set bluetooth.enabled false
meshtastic --port $PORT --set power.is_power_saving false
meshtastic --port $PORT --set lora.hop_limit 5
```

### Or Use Script

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
# Choose option 1 (ThinkNode M3 only)
```

## Test GPS on ThinkNode M3

Take it outdoors:

```bash
meshtastic --port /dev/tty.usbmodem* --gps-watch
```

Wait for:
- Fix type: 3D
- Satellites: 8+
- Takes 2-3 minutes

## Verify Everything Works

### Check iPad App

1. **Open Meshtastic app**
2. **Go to Nodes tab**
3. **Should now see 3 devices:**
   - Base Duo #1 (you)
   - Base Duo #2 (trailhead/partner)
   - Dog-Tracker (new!)

4. **Go to Map tab**
5. **Should see all 3 positions:**
   - Base Duos: Fixed or GPS positions
   - Dog-Tracker: GPS position (updating every 30s)

6. **Wait 2-3 minutes for mesh to form**

### Your Network Now

```
┌──────────────────────────────────────────────┐
│                                               │
│  Base Duo #1 ←── 2.4GHz (fast) ──→ Base Duo #2
│       ↕                                ↕      │
│   Sub-GHz                          Sub-GHz   │
│   915MHz                           915MHz    │
│       ↕                                ↕      │
│       └──────→ ThinkNode M3 ←─────────┘      │
│              (Dog - Sub-GHz only)            │
│                                               │
└──────────────────────────────────────────────┘

All visible in iPad Meshtastic app!
```

## Troubleshooting

### ThinkNode M3 Not Appearing

**Check region matches:**

Using iPad app:
1. Connect to Base Duo → Settings → Radio Config → LoRa
2. Note the "Region" (should be US, EU_868, etc.)
3. Connect to ThinkNode M3 temporarily (enable BT):
   ```bash
   meshtastic --port /dev/tty.usbmodem* --set bluetooth.enabled true
   ```
4. Check its region matches exactly

Using MacBook:
```bash
# Check Base Duo
meshtastic --port /dev/tty.usbmodemXXXX --get lora.region

# Check ThinkNode M3
meshtastic --port /dev/tty.usbmodemYYYY --get lora.region

# Must be identical!
```

### Base Duos Not Talking on Sub-GHz

**Check Sub-GHz antennas attached:**
- SMA antennas screwed on both Base Duos
- Never power on without antennas!

**Check Sub-GHz enabled:**
Using iPad app:
- Settings → Radio Config → LoRa
- Should show Region (US, EU_868, etc.)
- If blank or shows 2.4GHz only, Sub-GHz not configured

**Re-apply settings via app or MacBook**

### 2.4GHz Stopped Working

**2.4GHz should still work!** Check:

Using iPad app:
- Settings → Radio Config
- Look for secondary radio section
- Should show 2.4GHz settings

If missing, re-enable:
```bash
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.enabled true
meshtastic --port /dev/tty.usbmodem* --set lora_secondary.region ISM_2400
```

### No GPS Position on Dog Tracker

- ThinkNode M3 must be outdoors
- Wait 2-3 minutes for first GPS lock
- Check: `meshtastic --gps-watch`

## Region Reference

**Choose your region based on location:**

| Location | Region Setting | Frequency |
|----------|---------------|-----------|
| United States | US | 915 MHz |
| Canada | US | 915 MHz |
| Europe (most) | EU_868 | 868 MHz |
| UK | EU_868 | 868 MHz |
| Australia | ANZ | 915 MHz |
| New Zealand | ANZ | 915 MHz |
| Japan | JP | 920 MHz |

**CRITICAL:** All 3 devices must use the same region!

## Quick Command Reference (MacBook)

```bash
# Find connected devices
ls /dev/tty.usbmodem*

# Check configuration
meshtastic --port /dev/tty.usbmodem* --info

# Enable Sub-GHz on Base Duo
meshtastic --port /dev/tty.usbmodem* --set lora.region US
meshtastic --port /dev/tty.usbmodem* --set lora.modem_preset LONG_SLOW

# Configure ThinkNode M3
# (Use script or manual commands above)

# Test GPS
meshtastic --port /dev/tty.usbmodem* --gps-watch

# Send test message
meshtastic --port /dev/tty.usbmodem* --sendtext "Test"

# Check all nodes
meshtastic --port /dev/tty.usbmodem* --nodes
```

## What You'll Have When Done

✓ **Base Duo #1**: Sub-GHz + 2.4GHz (both active)
✓ **Base Duo #2**: Sub-GHz + 2.4GHz (both active)
✓ **ThinkNode M3**: Sub-GHz only (joins via 915MHz)
✓ **All 3 visible in iPad app**
✓ **Real-time dog tracking on map**

### Benefits

**2.4GHz between Base Duos:**
- Fast messaging when close (<1km)
- High bandwidth
- What you're using now

**Sub-GHz for everything:**
- Long range (5-10km)
- Dog tracker works at distance
- Better terrain penetration
- What you need for backcountry

**Automatic routing:**
- Base Duos use 2.4GHz when close (fast)
- Fall back to Sub-GHz when far (range)
- Dog always uses Sub-GHz (long range)

## Battery Life Expectations

| Device | Configuration | Battery Life |
|--------|--------------|--------------|
| ThinkNode M3 | 30s updates, Sub-GHz | 6-10 hours |
| Base Duo #1 | Dual-band active | 8-10 hours |
| Base Duo #2 | Dual-band active | 8-10 hours |

Running both radios uses slightly more power, but not much.
In cold weather, expect 20-30% reduction.

## Next Steps

1. **Enable Sub-GHz on both Base Duos** (via iPad app or MacBook)
2. **Attach Sub-GHz antennas** (SMA connectors)
3. **Configure ThinkNode M3** (via MacBook)
4. **Test GPS lock outdoors** (2-3 minutes)
5. **Verify all 3 devices in iPad app** (Nodes tab)
6. **Check map shows positions** (Map tab)
7. **Test range at your skiing location**

## Need Help?

**iPad app not showing new settings?**
- Try disconnecting and reconnecting
- Reboot Base Duo (power cycle)
- Check firmware version (Settings → Device)

**MacBook commands not working?**
- Check USB cable is data-capable
- Try: `ls /dev/tty.*` to see all ports
- Install Meshtastic CLI: `pip3 install meshtastic`

**Can't find Sub-GHz antennas?**
- Should come with Base Duo
- Look for 915MHz or 868MHz antenna
- SMA connector (screw-on type)
- Can order from Muzi Works if missing

Ready to get started? The iPad app method is easiest if you're comfortable with it!
