# Quick Backcountry Setup - ThinkNode M3 + 2x Base Duo

Your optimal setup for backcountry skiing with your dog.

## Your Hardware

✓ **ThinkNode M3** - GPS tracker on dog
✓ **Base Duo #1** - Handheld device you carry
✓ **Base Duo #2** - Trailhead base station at car

## Quick Install (20 minutes)

### Step 1: Install Software (3 min)

```bash
pip3 install --upgrade meshtastic
```

### Step 2: Configure All Devices (12 min)

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

**Choose option 4** (Complete Setup), then follow prompts:

1. **Connect ThinkNode M3** → Configure as tracker
2. **Connect Base Duo #1** → Configure as handheld
3. **Connect Base Duo #2** → Configure as trailhead base

The script will ask for:
- Your region (US, EU, ANZ)
- Trailhead coordinates (can update later)

### Step 3: Attach Antennas (2 min)

**CRITICAL:** Never power on Base Duos without antennas attached!

- **Base Duo #1 (Handheld):** Screw on Sub-GHz antenna (SMA)
- **Base Duo #2 (Trailhead):** Screw on Sub-GHz antenna (SMA)

### Step 4: Test GPS (3 min)

Take ThinkNode M3 outdoors:

```bash
meshtastic --port /dev/tty.usbmodem* --gps-watch
```

Wait for "3D Fix" and 8+ satellites.

## Deployment

### At Home Before Trip

**Charge everything to 100%:**
- ThinkNode M3: ~2-3 hours
- Base Duo #1: ~2-3 hours
- Base Duo #2: ~2-3 hours
- Phone: 100%
- Battery pack for handheld

### At Trailhead (5 min setup)

1. **Setup Base Duo #2 in Car:**
   - Connect to car USB (12V adapter)
   - Attach antenna, point vertical
   - Mount antenna outside or on roof (best range)
   - Power on, verify LED

2. **Prepare Base Duo #1 (Handheld):**
   - Connect to battery pack
   - Keep in jacket pocket (antenna vertical)
   - Connect phone via Bluetooth

3. **Mount ThinkNode M3 on Dog:**
   - Secure on collar (top/side of neck)
   - In extreme cold: use insulated pouch
   - Power on

4. **Verify Mesh Network:**
   - Open Meshtastic app on phone
   - Should see all 3 devices in "Nodes"
   - Check positions showing
   - Wait 2-3 minutes for GPS locks

### While Skiing

- Check app every 10-15 minutes
- Dog updates every 30 seconds
- "Last Heard" should stay <1 minute
- Monitor battery levels

## Your System Advantages

### Extended Range via Mesh Network

```
Dog Tracker ←5km→ Your Handheld ←5km→ Trailhead Base
   (M3)              (Base Duo #1)      (Base Duo #2)

Total effective coverage: 10-15km from trailhead
```

### Key Benefits

✓ **10-15km+ Range:** Mesh routing extends coverage
✓ **Data Logging:** Trailhead base logs everything to 8MB flash
✓ **Redundancy:** Multiple routing paths around terrain
✓ **Dual-Band:** Base Duos support Sub-GHz + 2.4GHz
✓ **Real-time:** 30-second position updates
✓ **Off-grid:** No cell service needed

## Battery Life

| Device | Expected Life |
|--------|--------------|
| ThinkNode M3 (dog) | 6-10 hours |
| Base Duo #1 (handheld) | 8-12 hours |
| Base Duo #2 (trailhead) | All day (USB powered) |

**Cold weather reduces by 20-30%** - Keep devices warm!

## Configuration Summary

All devices configured with:
- **LoRa Mode:** LONG_SLOW (best terrain penetration)
- **TX Power:** 22 dBm (maximum)
- **Region:** US/EU/ANZ (must match)
- **Hop Limit:** 5 (mesh routing)
- **Updates:** 30s (dog), 60s (you)

## Mobile App

1. Install "Meshtastic" from App Store / Play Store
2. Connect to Base Duo #1 (handheld) via Bluetooth
3. View "Map" tab - see dog and your position
4. "Nodes" tab - see all devices and signal strength

## If Dog Gets Separated

1. **Check last position** in app (coordinates + altitude)
2. **Check "Last Heard"** time
   - <2 minutes: Still connected
   - >5 minutes: Out of range or issue
3. **Navigate to last position** using map
4. **Gain elevation** for better signal
5. **Check mesh network** - trailhead may still have signal

## After Trip

**Export trip data:**
```bash
# Connect Base Duo #2 (trailhead)
meshtastic --port /dev/tty.usbmodem* --export-db trip-$(date +%Y-%m-%d).json
```

This saves complete GPS history of dog + you!

## Important Safety Notes

⚠️ **This tracker is supplementary to:**
- Visual/voice control of your dog
- Proper avalanche safety equipment (beacon, probe, shovel)
- Good backcountry judgment and skills
- Emergency satellite communicator

**Never rely solely on technology for safety!**

## Troubleshooting

**Can't see all devices in app:**
- Wait 2-3 minutes for mesh to form
- Verify all same region (US/EU/ANZ)
- Check antennas attached
- Power cycle devices

**Short battery life:**
- Expected in cold weather
- Keep devices in warm pockets
- Connect to battery packs
- Reduce update intervals if needed

**No GPS lock:**
- Must be outdoors with clear sky
- Wait 3-5 minutes
- Move away from tall buildings/dense trees

**Lost signal to dog:**
- Climb to high point
- Move toward last position
- Check terrain blocking
- Wait for dog to move to clearing

## Full Documentation

- **Two Base Duo Guide:** `docs/two-base-duo-setup.md`
- **Backcountry Guide:** `docs/backcountry-guide.md`
- **Troubleshooting:** `docs/troubleshooting.md`
- **General Setup:** `QUICK_START.md`

## Ready to Configure?

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

Choose option 4 for complete setup!

---

**Questions?** See detailed docs or the troubleshooting guide.

**Safe skiing! 🎿🐕**
