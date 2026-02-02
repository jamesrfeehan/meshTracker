# Backcountry Skiing Dog Tracker Guide

Complete guide for using your Meshtastic tracker in backcountry skiing environments.

## Why This Setup is Perfect for Backcountry

### Advantages
- **No Cell Service Required**: LoRa mesh networking works completely off-grid
- **Long Range**: 5-6km+ in open mountain terrain (line of sight)
- **Penetrates Terrain**: LoRa signals go through trees better than cellular
- **Multiple Devices**: Create mesh network with ski partners
- **Low Power**: 6-10 hours of tracking on single charge
- **Cold Weather**: Rated to -20°C operation
- **Avalanche Detection**: Accelerometer can detect sudden stops/burial
- **Real-time Tracking**: Know your dog's location every 30 seconds

### Challenges to Consider
- **Line of Sight**: Mountains/ridges can block signal
- **Cold Reduces Battery**: Expect 20-30% less capacity in extreme cold
- **GPS in Canyons**: Deep valleys may have poor GPS coverage
- **Range Varies**: Terrain dramatically affects range

## Equipment Setup

### What You Need

**On Your Dog:**
- ThinkNode M3 tracker (configured for backcountry)
- Secure collar or harness mount
- Insulated pouch (recommended for extreme cold)

**On You (Choose One):**

**Option A: Phone + Meshtastic Device**
- Second Meshtastic device (another Base Duo, or handheld like ThinkNode M2/M5)
- Phone with Meshtastic app
- Phone in waterproof case
- Extra battery pack for phone

**Option B: Dedicated Handheld**
- Meshtastic handheld with screen (ThinkNode M5, RAKwireless, etc.)
- No phone needed
- Better battery life
- More rugged

**Option C: Trailhead Base + Handheld**
- Base Duo at car/trailhead (relay/logger)
- Handheld device with you
- Extends range, logs all positions

**Recommended: Option C** - Best range and redundancy

### Configuration Differences from Home Use

| Setting | Home Use | Backcountry Use |
|---------|----------|-----------------|
| Update Interval | 60-120s | 30s |
| LoRa Preset | LONG_FAST | LONG_SLOW |
| Smart Position | Enabled | Disabled |
| Power Saving | Enabled | Disabled |
| Transmit Power | 20 dBm | 22 dBm (max) |
| Hop Limit | 3 | 5 |
| Battery Life | 18 hours | 6-10 hours |

## Pre-Trip Configuration

### Configure ThinkNode M3 for Backcountry

Use the specialized config file:

```bash
cd ~/projects/tracker
meshtastic --port /dev/tty.usbmodem* --configure-from-file config/backcountry-m3-config.yaml
```

Or configure manually:

```bash
PORT=/dev/tty.usbmodem*  # Replace with your port

# Critical: Use LONG_SLOW for better terrain penetration
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW

# Frequent updates - safety priority
meshtastic --port $PORT --set position.gps_update_interval 30
meshtastic --port $PORT --set position.position_broadcast_secs 30

# Disable smart position (always send)
meshtastic --port $PORT --set position.position_broadcast_smart_enabled false

# Maximum power
meshtastic --port $PORT --set lora.tx_power 22  # or 20 if 22 not supported

# Disable power saving
meshtastic --port $PORT --set power.is_power_saving false

# Higher hop limit for mesh routing
meshtastic --port $PORT --set lora.hop_limit 5

# Enable altitude and heading
meshtastic --port $PORT --set position.position_flags 7
```

### Configure Your Handheld Device

If carrying a second device:

```bash
# Use CLIENT role (not ROUTER) since you're also moving
meshtastic --port $PORT --set device.role CLIENT

# Match tracker settings
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22
meshtastic --port $PORT --set lora.hop_limit 5

# Keep Bluetooth on for phone connection
meshtastic --port $PORT --set bluetooth.enabled true

# Enable your GPS too
meshtastic --port $PORT --set position.gps_enabled true
```

### Optional: Trailhead Base Station

Leave Base Duo at car as relay and logger:

```bash
# Set as ROUTER
meshtastic --port $PORT --set device.role ROUTER

# Set fixed position at trailhead
meshtastic --port $PORT --set position.fixed_position true
meshtastic --port $PORT --set position.latitude YOUR_TRAILHEAD_LAT
meshtastic --port $PORT --set position.longitude YOUR_TRAILHEAD_LON

# Match other settings
meshtastic --port $PORT --set lora.modem_preset LONG_SLOW
meshtastic --port $PORT --set lora.tx_power 22
meshtastic --port $PORT --set lora.hop_limit 5

# Connect battery + USB for all-day operation
```

This creates a relay point and logs all positions to 8MB flash.

## Cold Weather Preparation

### Battery Optimization

**The Problem:**
- LiPo batteries lose 20-30% capacity below 0°C
- ThinkNode M3: 18 hours @ 20°C → 10-12 hours @ -10°C

**Solutions:**

1. **Keep Tracker Warm:**
   - Mount close to dog's body (body heat keeps it warmer)
   - Use insulated pouch in extreme cold (<-10°C)
   - Under jacket/coat layer if dog wears one

2. **Start with Full Charge:**
   - Charge devices the night before
   - Charge in warm environment
   - Bring charged to room temp before going out

3. **Spare Battery:**
   - Carry charged backup devices
   - Swap at halfway point
   - Keep spares in inner jacket pocket (body heat)

4. **Reduce Updates If Needed:**
   - If battery critical, increase interval to 60s:
   ```bash
   meshtastic --set position.position_broadcast_secs 60
   ```

### Protect from Elements

**Waterproofing:**
- ThinkNode M3 is IP66 (rain/snow resistant)
- NOT submersion proof
- Keep charging port covered
- Wipe snow/ice off regularly

**Physical Protection:**
- Use protective pouch or case
- Secure mounting (dogs crash through brush)
- Check security after each run
- Backup attachment method (zip tie)

### Pre-Trip Checklist

- [ ] All devices fully charged
- [ ] Firmware updated to latest stable
- [ ] Backcountry config applied
- [ ] GPS lock tested outdoors
- [ ] Mesh network tested (all devices see each other)
- [ ] Phone app connected and working
- [ ] Tracker securely mounted on collar
- [ ] Spare batteries/devices packed
- [ ] Emergency contact info in phone
- [ ] Avalanche beacon, probe, shovel (separate from tracker!)

## During Your Trip

### At the Trailhead

1. **Power Everything On:**
   - ThinkNode M3 on dog
   - Your handheld device
   - Base station (if using)

2. **Verify GPS Lock:**
   - Check app shows both positions
   - Wait 2-3 minutes for solid lock
   - Verify altitude is correct

3. **Test Range:**
   - Walk 50-100m away
   - Check "Last Heard" stays current
   - Verify SNR is positive

4. **Set Expectations:**
   - Note battery levels (should be 100%)
   - Estimated trip time
   - Expected battery at return

### While Skiing

**Monitor Frequently:**
- Check app every 10-15 minutes
- Watch "Last Heard" time (should be <1 minute)
- Monitor signal strength (SNR)
- Check battery levels

**Position Updates:**
- Dog's position updates every 30 seconds
- Your position updates every 60 seconds (if enabled)
- Map shows both locations + altitude

**Understanding the Map:**
- Blue dot/icon = Your position
- Dog icon = Dog's position
- Line shows path history
- Altitude shows elevation
- Speed shows movement rate

**If Dog Gets Separated:**

1. **Don't Panic** - You have their location
2. **Check Last Position:**
   - Note exact coordinates
   - Note elevation
   - Note time stamp
3. **Check Signal:**
   - If "Last Heard" is recent (<2 min) → Still connected
   - If "Last Heard" is old (>5 min) → Out of range or issue
4. **Navigate to Last Known Position:**
   - Use map view in app
   - Follow path history
   - Call for dog while moving
5. **Signal Strength:**
   - Watch SNR improve as you get closer
   - When SNR goes positive, you're in range

### Range Considerations

**Expected Range in Mountains:**

| Terrain | Typical Range | Max Range |
|---------|--------------|-----------|
| Open ridgeline (LOS) | 5-10km | 15km+ |
| Light forest | 2-4km | 6km |
| Dense forest | 1-2km | 3km |
| Behind ridge/peak | 100m-1km | Variable |
| Deep canyon | 500m-2km | Variable |

**Factors Affecting Range:**
- **Line of Sight**: Best case scenario
- **Terrain Blocking**: Mountains block signal
- **Tree Density**: Dense forest reduces range
- **Snow Load**: Heavy wet snow on trees reduces range
- **Altitude**: Higher = better range (less obstruction)

**Improving Range:**

1. **Get Higher:** Climb to ridge/peak for better signal
2. **Use Mesh Routing:** Devices relay through each other
3. **Move to Clearing:** Trees block signal
4. **Switch Sides:** Other side of ridge may work
5. **Wait:** If dog returns to LOS, signal resumes

### Mesh Network Benefits

If skiing with partners who have Meshtastic:

**Benefits:**
- **Extended Range**: Messages relay through all devices
- **Redundancy**: Multiple people can track the dog
- **Communication**: Text messages between skiers
- **Shared Maps**: Everyone sees everyone's position

**Setup:**
- All devices on same channel/PSK
- All devices same region
- Everyone should use LONG_SLOW preset
- Hop limit 5+ for routing

**Example: 3 Skiers + Dog**
- Range: Each device 5km apart
- Total coverage: 15km+ chain
- Dog tracker relays through any device
- If you lose signal, partners may have it

## Emergency Scenarios

### Dog Separated - Signal Lost

**Scenario:** "Last Heard" >10 minutes ago

**Likely Causes:**
1. Dog behind terrain blocking signal
2. Too far away
3. Device powered off/dead
4. Tracker buried in snow

**Actions:**

1. **Go to Last Known Position:**
   - Navigate to exact coordinates shown
   - Check altitude - may be above/below you

2. **Gain Elevation:**
   - Climb to nearest high point
   - Check if signal reappears

3. **Search Pattern:**
   - Start at last known position
   - Search in expanding circles
   - Call frequently
   - Listen for barking

4. **Check Likely Paths:**
   - Dog may follow scent trail
   - Check downhill (dogs often run down)
   - Check your skin track back

5. **Activate Emergency Plan:**
   - Contact ski patrol if available
   - Call for help if needed
   - Use avalanche beacon to search if buried

### Low Battery Warning

**When battery <30%:**

1. **Reduce Update Frequency:**
   - Can't change remotely (Bluetooth disabled)
   - Note remaining time: ~30% = 2-3 hours

2. **Prioritize Return:**
   - Begin heading back
   - Keep dog closer
   - Monitor more frequently

3. **Prepare for Loss:**
   - Note current position
   - Take screenshot
   - Use visual contact

### Device Malfunction

**Tracker not updating:**

1. **Check Your Device:** Is your handheld working?
2. **Move for LOS:** May just be terrain
3. **Check Battery:** May be dead
4. **Visual Contact:** Keep eyes on dog
5. **Use Backup:** If you brought spare device

### Avalanche Scenario

**If avalanche occurs:**

1. **Primary: Use Avalanche Beacon**
   - Never rely solely on Meshtastic tracker
   - Tracker is backup only

2. **Meshtastic Can Help:**
   - Last known position before avalanche
   - Accelerometer shows sudden stop
   - May still transmit if not deeply buried
   - Can help narrow search area

3. **Search Priority:**
   - Avalanche beacon first
   - Visual clues
   - Probe likely areas
   - Check Meshtastic for position updates

**Important:** Meshtastic is NOT a substitute for proper avalanche safety equipment and training!

## After Your Trip

### Data Review

1. **Export Track History:**
   ```bash
   # If using base station with logging
   meshtastic --port /dev/tty.usbmodem* --export-db trip-data.json
   ```

2. **Review Map:**
   - See full path of dog and yourself
   - Check max distance from dog
   - Identify where signal was lost
   - Learn terrain effects

3. **Battery Analysis:**
   - Check actual battery consumption
   - Adjust settings if needed
   - Plan charging for next trip

### Maintenance

1. **Dry Equipment:**
   - Wipe down all devices
   - Check for snow/ice in ports
   - Let dry completely before charging

2. **Charge Devices:**
   - Bring to room temperature first
   - Then charge fully
   - Store at room temp

3. **Check for Damage:**
   - Inspect collar mount
   - Check antennas
   - Test all functions

4. **Adjust Configuration:**
   - If battery didn't last, increase intervals
   - If range was poor, try different settings
   - Document what worked

## Advanced Features

### Waypoint Marking

Mark important locations:
- Trailhead
- Campsites
- Dangerous areas
- Emergency shelters

Use app to save waypoints with notes.

### Geofencing (If Configured)

Set perimeter around safe area:
- Alert if dog goes beyond radius
- Requires custom scripting (see mobile-app-setup.md)

### Multi-Day Trips

**Battery Strategy:**
- Bring multiple charged devices
- Rotate devices daily
- Solar charger for base station
- Conserve power overnight (disable tracking)

**Overnight Storage:**
- Keep devices in warm sleeping bag
- Prevents battery drain from cold
- Charge from battery bank if possible

### Integration with Other Tools

**Garmin inReach/Satellite Communicators:**
- Use both systems
- Meshtastic for real-time local tracking
- Satellite for emergency SOS
- Complementary systems

**Avalanche Beacons:**
- ALWAYS use proper avalanche beacon
- Meshtastic is supplementary only
- Different frequencies, don't interfere

## Recommended Settings Summary

### Backcountry Optimized (6-10 hour trips)

```yaml
# ThinkNode M3
device.role: TRACKER
lora.modem_preset: LONG_SLOW
lora.tx_power: 22
position.gps_update_interval: 30
position.position_broadcast_secs: 30
position.position_broadcast_smart_enabled: false
power.is_power_saving: false
bluetooth.enabled: false
lora.hop_limit: 5
```

### Extended Battery (10-14 hour trips)

```yaml
# Sacrifice some update frequency for battery
position.gps_update_interval: 60
position.position_broadcast_secs: 60
lora.tx_power: 20  # Reduce power slightly
# Keep everything else the same
```

### Maximum Range (Open terrain)

```yaml
# Slowest but longest range
lora.modem_preset: LONG_SLOW
lora.tx_power: 22
lora.spread_factor: 12  # If LONG_SLOW isn't slow enough
# May reduce battery life further
```

## Safety Reminders

### Technology Limitations

- **Tracker is NOT a substitute for:**
  - Voice/visual control of your dog
  - Proper avalanche safety equipment
  - Backcountry skills and experience
  - Emergency communication (satellite)

- **Can Fail Due To:**
  - Battery depletion
  - Extreme cold
  - Physical damage
  - Terrain blocking
  - User error

### Best Practices

1. **Always Have Backup Plan:**
   - Keep dog in sight when possible
   - Train reliable recall
   - Know your dog's tendencies
   - Bring traditional backup (bell, reflective gear)

2. **Avalanche Safety:**
   - Dog should wear avalanche beacon if in avy terrain
   - Never replace proper equipment
   - Tracker helps but isn't primary tool

3. **Weather Awareness:**
   - Monitor conditions
   - Know when to turn back
   - Don't rely on tracker to "save" a bad situation

4. **Trip Planning:**
   - Tell someone your plans
   - Carry emergency contact info
   - Bring first aid (dog and human)
   - Know your limits

## Troubleshooting in the Field

### Quick Fixes

**No GPS Lock:**
- Move to clearing (away from trees)
- Wait 3-5 minutes
- Check device is powered on
- Altitude may still work with weak GPS

**Short Range:**
- Climb to high point
- Check antenna not damaged
- Verify same channel on all devices
- Consider terrain blocking

**Battery Draining Fast:**
- Cold weather is likely culprit
- Keep device warm
- Reduce to critical tracking only
- Plan return earlier

**Device Frozen:**
- Try reboot (hold reset button)
- May need to warm up device
- Bring spare if possible

### Can't Fix in Field - Adapt

- Use visual contact
- Keep dog closer
- Note last known position
- Continue trip cautiously or turn back

## Final Thoughts

Meshtastic is an incredible tool for backcountry dog tracking, but it's one part of a comprehensive safety system. Use it to enhance your adventures, not replace good judgment and preparation.

**The Perfect Backcountry Setup:**
- Well-trained dog with good recall
- Meshtastic tracker for real-time location
- Avalanche safety equipment
- Satellite communicator for emergencies
- Proper winter gear and skills
- Trip plan shared with others

Enjoy your backcountry adventures with peace of mind!

## Quick Reference Card

Print and laminate this for field reference:

```
BACKCOUNTRY DOG TRACKER QUICK REF
==================================
Battery Life: 6-10 hours (30s updates)
Update Interval: 30 seconds
Range: 2-10km (terrain dependent)

CHECK BEFORE TRIP:
☐ Full battery (100%)
☐ GPS lock verified
☐ Mesh network connected
☐ Secure mounting
☐ Phone app working

DURING TRIP:
- Check app every 10-15 min
- Watch "Last Heard" time
- Monitor battery level
- Keep LOS when possible

IF DOG SEPARATED:
1. Check last position (lat/lon/alt)
2. Navigate to coordinates
3. Gain elevation for signal
4. Search from last known position
5. Call frequently

EMERGENCY:
- Primary: Visual/Voice
- Secondary: Track to coordinates
- Backup: Traditional search
- Always: Avalanche beacon if in avy terrain

Device Ports:
Mac: /dev/tty.usbmodem*
Linux: /dev/ttyACM*

Key Commands:
meshtastic --port PORT --info
meshtastic --port PORT --gps-watch
meshtastic --port PORT --reboot
```
