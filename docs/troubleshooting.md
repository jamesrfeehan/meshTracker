# Troubleshooting Guide

Common issues and solutions for your dog tracking system.

## Device Issues

### ThinkNode M3 Won't Power On

**Symptoms:**
- No LED activity
- Device appears dead
- Doesn't respond when button pressed

**Solutions:**

1. **Charge the Device:**
   - Place on magnetic charging base
   - Connect to USB power (5V, 1A minimum)
   - Leave charging for 30+ minutes
   - LED should turn red while charging, green when full

2. **Check Charging Contacts:**
   - Ensure 4 pogo pins are clean
   - Wipe with dry cloth
   - Check magnetic alignment
   - Try different USB cable/adapter

3. **Try Different Power Source:**
   - Try computer USB port
   - Try wall adapter
   - Ensure cable is data-capable (not charge-only)

4. **Hard Reset:**
   - Hold reset button for 10 seconds
   - Release and wait 5 seconds
   - Try powering on again

**Still Not Working?**
- Battery may be deeply discharged - leave charging overnight
- Contact Elecrow support if under warranty

### Base Duo Not Responding

**Symptoms:**
- No LED when powered
- Not detected by computer
- Bluetooth not visible

**Solutions:**

1. **Check Power Connection:**
   - Ensure USB-C cable fully inserted
   - Try different USB-C cable
   - Try different power adapter (5V, 1-2A)
   - Check battery if using battery power

2. **Verify Antenna Attached:**
   - Never power on without antenna!
   - Check SMA antenna is screwed on
   - Hand-tighten only (don't over-torque)

3. **Enter Bootloader Mode:**
   - Double-tap reset button quickly
   - LED should change pattern
   - Device should appear as USB drive

4. **Re-flash Firmware:**
   - Download latest Base Duo firmware
   - Enter bootloader mode
   - Copy UF2 file to device

## GPS Issues

### No GPS Lock on ThinkNode M3

**Symptoms:**
- GPS icon shows "searching"
- No position data in app
- Coordinates show 0,0 or invalid

**Solutions:**

1. **Environmental Check:**
   - Must be outdoors with clear sky view
   - Move away from tall buildings
   - Avoid dense tree cover
   - Move away from power lines

2. **Wait Longer:**
   - Cold start: 1-3 minutes typical
   - First ever lock: up to 5 minutes
   - Be patient, keep device still

3. **Check Configuration:**
   ```bash
   meshtastic --port /dev/ttyACM0 --info
   ```
   - Verify `gps_enabled: true`
   - Check `gps_update_interval` is set (e.g., 60)

4. **Monitor GPS Status:**
   ```bash
   meshtastic --port /dev/ttyACM0 --gps-watch
   ```
   - Should show satellites acquired
   - Fix type should be "3D"
   - Check HDOP (lower is better, <2.5 is good)

5. **Firmware Issue:**
   - Update to latest Meshtastic firmware
   - Some versions have GPS bugs
   - Check release notes

**Expected Performance:**
- Cold start: 30-180 seconds
- Warm start: <30 seconds
- Hot start: <5 seconds
- Satellites needed: 4+ (8+ ideal)

### GPS Accuracy Poor

**Symptoms:**
- Position jumps around
- Shows wrong location (100m+ off)
- Erratic movement on map

**Solutions:**

1. **Satellite Count:**
   - Need 8+ satellites for best accuracy
   - Wait for more satellites to lock
   - Check `satellites_in_view` in app

2. **Check HDOP:**
   - HDOP <2.5 = good
   - HDOP 2.5-5 = moderate
   - HDOP >5 = poor (wait longer)

3. **Avoid Multipath:**
   - Move away from buildings
   - Avoid canyons/valleys
   - Clear sky view in all directions

4. **Antenna Issue:**
   - Ensure GPS antenna not blocked
   - Keep away from metal collar parts
   - Check antenna not damaged

## Connectivity Issues

### Devices Not Communicating

**Symptoms:**
- Tracker not visible in app
- Base Duo shows offline
- "Last Heard" time is old (>5 minutes)

**Solutions:**

1. **Check Region Settings:**
   - MUST match on both devices
   - US: region = US, freq = US915
   - EU: region = EU_868, freq = EU868
   - Verify:
     ```bash
     meshtastic --port /dev/ttyACM0 --get lora.region
     ```

2. **Check Channel/PSK:**
   - Both devices must use same channel
   - Default: "LongFast" with default PSK
   - If you changed PSK, must match exactly
   - Verify:
     ```bash
     meshtastic --port /dev/ttyACM0 --ch-index 0
     ```

3. **Distance Too Far:**
   - Start with devices 1-5m apart
   - Gradually increase distance
   - Check SNR (should be >0)
   - Urban: expect 1-2km
   - Suburban: 3-4km
   - Rural: 5-6km+

4. **Check Hop Limit:**
   - Set to 3 for mesh routing
   - Verify:
     ```bash
     meshtastic --port /dev/ttyACM0 --get lora.hop_limit
     ```

5. **Antenna Issues:**
   - Ensure antennas attached to both devices
   - Antennas should be vertical
   - Keep away from metal objects
   - Check antenna connections tight

6. **Power Saving Mode:**
   - Tracker may be in deep sleep
   - Try moving tracker (wake via accelerometer)
   - Temporarily disable power saving:
     ```bash
     meshtastic --set power.is_power_saving false
     ```

### Weak Signal / Short Range

**Symptoms:**
- SNR is negative
- RSSI very low (<-120)
- Connection drops frequently
- Range much less than expected

**Solutions:**

1. **Increase Transmit Power:**
   ```bash
   meshtastic --set lora.tx_power 20  # Maximum
   ```

2. **Optimize Antenna Placement:**
   - **Base Duo:**
     - Mount high (6+ feet)
     - Near window
     - Antenna vertical
     - Away from metal/electronics
   - **ThinkNode M3:**
     - On top/side of dog's neck
     - Not underneath
     - Keep antenna clear

3. **Change LoRa Settings:**
   - Try LONG_SLOW preset:
     ```bash
     meshtastic --set lora.modem_preset LONG_SLOW
     ```
   - Slower but more reliable
   - Better penetration

4. **Environmental Factors:**
   - Urban areas have much shorter range
   - Buildings, trees, hills block signal
   - Rain/snow reduces range
   - Test in different locations

5. **Add Relay Node:**
   - Add another Base Duo or device between
   - Acts as mesh repeater
   - Extends range significantly

## Battery Issues

### ThinkNode M3 Battery Drains Fast

**Symptoms:**
- Battery lasts <8 hours (expected: 18 hours)
- Battery percentage drops rapidly
- Device dies unexpectedly

**Solutions:**

1. **Check Position Broadcast Interval:**
   - Default 60s is aggressive
   - Increase to 120-180s:
     ```bash
     meshtastic --set position.position_broadcast_secs 120
     ```

2. **Enable Smart Position:**
   ```bash
   meshtastic --set position.position_broadcast_smart_enabled true
   meshtastic --set position.broadcast_smart_minimum_distance 50
   ```
   - Only sends when moved >50m

3. **Disable Bluetooth:**
   - Saves ~30% battery
   ```bash
   meshtastic --set bluetooth.enabled false
   ```
   - Use Base Duo as BT gateway

4. **Reduce Transmit Power:**
   - If range adequate, reduce power:
   ```bash
   meshtastic --set lora.tx_power 17  # Instead of 20
   ```
   - Each 3 dBm saves ~25% power

5. **Reduce GPS Update Interval:**
   ```bash
   meshtastic --set position.gps_update_interval 120
   ```
   - GPS is biggest battery drain

6. **Enable Power Saving:**
   ```bash
   meshtastic --set power.is_power_saving true
   ```

7. **Check for Background Activity:**
   - Disable range test if enabled
   - Disable store-and-forward
   - Check telemetry intervals not too frequent

8. **Battery Health:**
   - LiPo batteries degrade over time
   - After 300-500 cycles, capacity reduces
   - Cold weather reduces capacity (normal)

**Optimal Battery Settings:**
```bash
meshtastic --set position.position_broadcast_secs 180
meshtastic --set position.gps_update_interval 120
meshtastic --set position.position_broadcast_smart_enabled true
meshtastic --set bluetooth.enabled false
meshtastic --set power.is_power_saving true
meshtastic --set lora.tx_power 17
```

### Base Duo Not Charging Battery

**Symptoms:**
- Battery voltage not increasing
- Battery depletes even when plugged in
- Charging LED not on

**Solutions:**

1. **Check Battery Connection:**
   - 3-pin Molex PicoBlade connector
   - Ensure fully inserted
   - Check polarity (should be keyed)

2. **Check USB-C Power:**
   - Need 5V, 1A minimum
   - Try different adapter
   - Try different USB-C cable

3. **Battery Type Setting:**
   - Base Duo supports Li-ion (3.7V) and LFP (3.2V)
   - Check configuration matches battery
   - May need to configure charger IC

4. **Battery Protection:**
   - Built-in protection may trip
   - Disconnect battery for 30 seconds
   - Reconnect and try again

5. **Solar Panel (if used):**
   - Need 5-6V, 2W+ panel
   - Check polarity
   - Verify sunlight adequate

## Mobile App Issues

### Can't Connect to Base Duo

**Symptoms:**
- Device not appearing in Bluetooth list
- Connection fails
- Timeout errors

**Solutions:**

1. **Check Bluetooth on Base Duo:**
   ```bash
   meshtastic --port /dev/ttyACM0 --get bluetooth.enabled
   ```
   - Should be `true`
   - Enable if disabled:
     ```bash
     meshtastic --set bluetooth.enabled true
     ```

2. **Phone Bluetooth:**
   - Enable Bluetooth on phone
   - Try turning off and on
   - Forget device and re-pair

3. **Proximity:**
   - Must be within 10m
   - Walls reduce range
   - Move closer

4. **Reset Bluetooth:**
   - On Base Duo:
     ```bash
     meshtastic --set bluetooth.enabled false
     meshtastic --set bluetooth.enabled true
     ```

5. **Check PIN:**
   - Default PIN: 123456
   - Or mode: RANDOM_PIN
   - Try both methods

6. **App Permissions:**
   - Location permission required (Android)
   - Bluetooth permission required
   - Check phone settings

### App Showing Old Position

**Symptoms:**
- Position not updating
- "Last Heard" time increasing
- Position stuck on map

**Solutions:**

1. **Check Tracker GPS Lock:**
   - GPS must have 3D fix
   - Check tracker is outdoors
   - Verify GPS enabled

2. **Check LoRa Connection:**
   - Is tracker in range?
   - Check signal strength (SNR)
   - Verify devices communicating

3. **Refresh App:**
   - Pull down to refresh
   - Close and reopen app
   - Force stop and restart

4. **Check Position Broadcast:**
   - Verify interval not too long
   - Check smart position settings
   - Has dog moved enough? (>25m default)

5. **Time Sync:**
   - Tracker clock may be wrong
   - Power cycle tracker
   - Will sync time from GPS

## Configuration Issues

### Configuration Changes Not Saving

**Symptoms:**
- Settings revert after reboot
- Changes don't take effect
- Commands return errors

**Solutions:**

1. **Use Correct Command Format:**
   ```bash
   # Wrong:
   meshtastic --set lora.region US915

   # Correct:
   meshtastic --set lora.region US
   ```

2. **Save Configuration:**
   - Some changes require explicit save
   - Use `--info` to verify changes

3. **Reboot After Changes:**
   ```bash
   meshtastic --reboot
   ```

4. **Factory Reset (Last Resort):**
   ```bash
   meshtastic --factory-reset
   ```
   - **WARNING:** Erases all settings!
   - Must reconfigure from scratch

### Can't Flash Firmware

**Symptoms:**
- Flash process fails
- Error messages during flash
- Device stuck in bootloader

**Solutions:**

1. **Enter Bootloader Correctly:**
   - Double-press reset button quickly
   - Should see USB drive appear (UF2 mode)
   - Or use DFU mode

2. **Try Different Method:**
   - UF2 bootloader (easiest)
   - Meshtastic CLI
   - Web flasher: https://flasher.meshtastic.org
   - nRF Connect (for nRF52 devices)

3. **USB Connection:**
   - Try different USB cable
   - Use USB 2.0 port (not 3.0)
   - Try different computer
   - Check cable supports data (not charge-only)

4. **Permissions (Linux):**
   ```bash
   sudo usermod -a -G dialout $USER
   ```
   - Log out and back in

5. **Recovery Mode:**
   - Hold reset while connecting USB
   - Should force bootloader

## Environmental Issues

### Device Too Hot/Cold

**Symptoms:**
- Device shutting down
- Battery draining fast
- Erratic behavior

**Solutions:**

1. **Operating Range:**
   - Rated: -20°C to +60°C
   - Optimal: 10°C to 40°C

2. **Hot Weather:**
   - Keep out of direct sun
   - Ensure airflow around collar
   - Consider lighter color collar
   - Reduce transmit power (less heat)

3. **Cold Weather:**
   - Battery capacity reduces (normal)
   - Keep close to dog's body heat
   - Use insulated pouch
   - Charge before use

### Water Damage

**Symptoms:**
- After exposure to water
- Device not working
- Corrosion visible

**ThinkNode M3 (IP66):**
- Should survive rain, snow, splashing
- NOT submersion (swimming)
- If water got in:
  1. Power off immediately
  2. Remove from collar
  3. Wipe dry with cloth
  4. Leave in warm, dry place 24-48 hours
  5. Do NOT charge while wet
  6. Check charging contacts for corrosion

**Base Duo (NOT waterproof):**
- Must be in weatherproof enclosure if outdoors
- If water exposure:
  1. Disconnect power immediately
  2. Pat dry with cloth
  3. Remove battery if installed
  4. Dry thoroughly 48+ hours
  5. Check for corrosion
  6. May need replacement if damaged

## Getting Help

### Before Asking for Help

Collect this information:

1. **Firmware Versions:**
   ```bash
   meshtastic --info
   ```

2. **Configuration:**
   ```bash
   meshtastic --export-config > my-config.yaml
   ```

3. **Device Logs:**
   ```bash
   meshtastic --debug
   ```

4. **Photos:**
   - Hardware setup
   - Antenna connections
   - LED status
   - App screenshots

### Support Resources

1. **Meshtastic Community:**
   - Forum: https://meshtastic.discourse.group
   - Discord: Meshtastic Community
   - GitHub: https://github.com/meshtastic/firmware/issues

2. **Hardware Vendors:**
   - Elecrow: support@elecrow.com
   - Muzi Works: contact via website

3. **Documentation:**
   - Official docs: https://meshtastic.org/docs
   - This project: See README.md

### Common Error Messages

**"No response from device"**
- Device not connected
- Wrong port specified
- Device in deep sleep
- Baud rate mismatch

**"Region not set"**
- Must configure region before use
- Use `--set lora.region US` (or your region)

**"Invalid configuration"**
- Check command syntax
- Verify parameter names
- Check value ranges

**"GPS timeout"**
- Not outdoors with sky view
- GPS disabled
- Antenna issue
- Wait longer

**"Bluetooth pairing failed"**
- Wrong PIN
- Bluetooth disabled
- Out of range
- Already connected to another device

## Diagnostic Commands

Quick reference for troubleshooting:

```bash
# Device info
meshtastic --info

# Monitor GPS
meshtastic --gps-watch

# Monitor debug output
meshtastic --debug

# Test mesh (send message)
meshtastic --sendtext "Test message"

# Check battery
meshtastic --get telemetry.device_update_interval

# Verify configuration
meshtastic --get lora.region
meshtastic --get position.gps_enabled
meshtastic --get bluetooth.enabled

# Reboot device
meshtastic --reboot

# Factory reset (careful!)
meshtastic --factory-reset

# Export full config
meshtastic --export-config > backup.yaml
```

## Still Having Issues?

1. Try the opposite: if you changed something, change it back
2. Test with minimal configuration (defaults)
3. Test devices very close together (1m)
4. Test each device independently
5. Compare with working example configurations
6. Ask the community (forum/Discord)

Remember: Most issues are configuration problems, not hardware failures!
