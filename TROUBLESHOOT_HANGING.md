# Fix Meshtastic Command Hanging

The `meshtastic` command is connecting to your ThinkNode M3 but hanging. Here's how to fix it:

## Problem

The meshtastic CLI is trying to establish a connection but getting stuck. This is usually due to:
1. Device in bootloader mode
2. Serial port permissions
3. Device needs reset
4. Conflicting software accessing the port

## Solutions (Try in Order)

### Solution 1: Reset the ThinkNode M3

**Physical reset:**
1. Unplug USB cable from ThinkNode M3
2. Wait 5 seconds
3. Plug it back in
4. Wait 10 seconds for device to boot
5. Try the command again:
   ```bash
   export PATH="$HOME/Library/Python/3.9/bin:$PATH"
   meshtastic --port /dev/tty.usbmodem14201 --info
   ```

### Solution 2: Try Different USB Port/Cable

1. Disconnect ThinkNode M3
2. Try different USB port on MacBook
3. Or try different USB cable (must be data cable, not charge-only)
4. Reconnect and test

### Solution 3: Check for Bootloader Mode

The device might be in bootloader mode:

1. **Check if you see a USB drive appear:**
   ```bash
   ls /Volumes/ | grep -i THINK
   ```

2. **If you see "THINKNODE" drive:**
   - Device is in bootloader mode
   - Press reset button ONCE (not double-press)
   - Wait for device to boot normally
   - USB drive should disappear

3. **Test again:**
   ```bash
   meshtastic --port /dev/tty.usbmodem14201 --info
   ```

### Solution 4: Use Minimal Commands (What to Try Now)

Instead of the full script, let's try commands one at a time with Ctrl+C ready:

```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# This should respond quickly (2-3 seconds max)
meshtastic --port /dev/tty.usbmodem14201 --set lora.region US

# If it hangs >5 seconds, press Ctrl+C and try Solution 1 (reset device)
```

### Solution 5: iPad App Configuration (Alternative)

Since your Base Duos work fine with the iPad app, you can configure the ThinkNode M3 the same way:

**Enable Bluetooth temporarily:**
```bash
# Quick command - should work even if others hang
meshtastic --port /dev/tty.usbmodem14201 --set bluetooth.enabled true
```

**Then use iPad:**
1. Open Meshtastic app
2. Connect to "Dog-Tracker" or "ThinkNode M3" via Bluetooth
3. Configure via app:
   - Region: US
   - Device Role: TRACKER
   - Modem Preset: LONG_SLOW
   - TX Power: 20 (max in app)
   - GPS: Enabled
   - Position Interval: 30 seconds

**Then disable Bluetooth to save battery:**
```bash
meshtastic --port /dev/tty.usbmodem14201 --set bluetooth.enabled false
```

## Recommended Approach Right Now

**Try this sequence:**

1. **Unplug and replug ThinkNode M3**

2. **Wait 10 seconds**

3. **Try ONE command:**
   ```bash
   export PATH="$HOME/Library/Python/3.9/bin:$PATH"
   meshtastic --port /dev/tty.usbmodem14201 --set lora.region US
   ```

4. **If it hangs >10 seconds:**
   - Press **Ctrl+C**
   - Use the iPad app method instead (Solution 5)

5. **If it works (responds in 2-3 seconds):**
   - Continue with rest of configuration
   - One command at a time
   - Each should respond quickly

## Quick iPad Configuration Steps

If CLI keeps hanging, use iPad (easier anyway):

1. **Enable Bluetooth on ThinkNode M3:**
   ```bash
   meshtastic --port /dev/tty.usbmodem14201 --set bluetooth.enabled true
   ```
   (Even if this hangs, it might still work - wait 30 seconds, then disconnect USB)

2. **Open Meshtastic app on iPad**

3. **Add ThinkNode M3:**
   - Tap "+"
   - Choose Bluetooth
   - Select device (might be "ThinkNode M3" or "Meshtastic_XXXX")

4. **Configure via Settings:**
   - Radio Configuration → LoRa:
     - Region: **US**
     - Modem Preset: **LONG_SLOW**
     - TX Power: **20**
     - Hop Limit: **5**

   - Radio Configuration → Device:
     - Device Role: **TRACKER**
     - Node Name: **Dog-Tracker**

   - Radio Configuration → Position:
     - GPS Enabled: **ON**
     - GPS Update Interval: **30** seconds
     - Position Broadcast: **30** seconds
     - Smart Position: **OFF**
     - Broadcast Flags: **All** (altitude, speed, heading)

5. **Save and reboot**

6. **After configured, disable Bluetooth:**
   - Radio Configuration → Bluetooth: **OFF**
   (Saves 30% battery)

## Why CLI Might Be Hanging

**Common causes:**
- ThinkNode M3 firmware needs update
- Device in wrong mode
- Serial buffer issues
- MacOS serial driver quirks

**The good news:**
- Your Base Duos work fine with iPad app
- ThinkNode M3 will work the same way
- iPad app is actually easier for initial config
- CLI is better for automation/scripting

## What to Do Next

**My recommendation:**

1. Try unplugging/replugging ThinkNode M3
2. If CLI still hangs, use iPad app to configure
3. Once configured via iPad, you can verify with CLI later

The iPad app will work perfectly for this!
