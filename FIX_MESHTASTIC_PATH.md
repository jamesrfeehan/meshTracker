# Fix Meshtastic Command Not Found

The `meshtastic` command is installed but not in your PATH. Here are three ways to fix it:

## Option 1: Quick Fix (Restart Terminal)

The PATH was already added to your `~/.bash_profile`. Simply:

1. **Close your current Terminal window**
2. **Open a new Terminal window**
3. **Test it works:**
   ```bash
   meshtastic --version
   ```

This should now work!

## Option 2: Reload in Current Terminal

If you don't want to restart Terminal:

```bash
source ~/.bash_profile
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
meshtastic --version
```

## Option 3: Use Full Path (Temporary)

Until you restart Terminal, use the full path:

```bash
~/Library/Python/3.9/bin/meshtastic --version
```

## For the Configuration Script

### After Restarting Terminal (Recommended)

```bash
cd ~/projects/tracker/scripts
./configure-backcountry.sh
```

This will now work!

### Without Restarting (Alternative)

If you want to run it now without restarting, you can manually configure the ThinkNode M3 using the commands below instead of the script.

## Manual Configuration (If Script Still Fails)

Connect ThinkNode M3 to your MacBook via USB, then run:

```bash
# Find the device port
ls /dev/tty.usbmodem*

# Set it as a variable (replace with your actual port)
PORT=/dev/tty.usbmodem12345

# Use full path to meshtastic command
MESHTASTIC=~/Library/Python/3.9/bin/meshtastic

# Configure for USA
$MESHTASTIC --port $PORT --set lora.region US
$MESHTASTIC --port $PORT --set device.role TRACKER
$MESHTASTIC --port $PORT --set owner.long_name "Dog-Tracker"
$MESHTASTIC --port $PORT --set owner.short_name "DOG"

# Backcountry settings
$MESHTASTIC --port $PORT --set lora.modem_preset LONG_SLOW
$MESHTASTIC --port $PORT --set lora.tx_power 22
$MESHTASTIC --port $PORT --set lora.hop_limit 5

# GPS - 30 second updates
$MESHTASTIC --port $PORT --set position.gps_enabled true
$MESHTASTIC --port $PORT --set position.gps_update_interval 30
$MESHTASTIC --port $PORT --set position.position_broadcast_secs 30
$MESHTASTIC --port $PORT --set position.position_broadcast_smart_enabled false
$MESHTASTIC --port $PORT --set position.position_flags 7

# Battery optimization
$MESHTASTIC --port $PORT --set bluetooth.enabled false
$MESHTASTIC --port $PORT --set power.is_power_saving false
$MESHTASTIC --port $PORT --set power.mesh_sds_timeout_secs 0
$MESHTASTIC --port $PORT --set power.sds_secs 0
$MESHTASTIC --port $PORT --set power.ls_secs 0

# Telemetry
$MESHTASTIC --port $PORT --set telemetry.device_update_interval 300
$MESHTASTIC --port $PORT --set telemetry.environment_update_interval 300
$MESHTASTIC --port $PORT --set telemetry.environment_measurement_enabled true

# Motion detection
$MESHTASTIC --port $PORT --set detection_sensor.enabled true

# Verify
$MESHTASTIC --port $PORT --info
```

## Verify It's Working

After restart or reload:

```bash
meshtastic --version
# Should show: 2.7.7
```

## What Was Done

Your `~/.bash_profile` now includes:
```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
```

This adds the Python bin directory (where `meshtastic` is installed) to your PATH.

## Why This Happened

When you ran `pip3 install meshtastic`, it installed to:
```
/Users/jimmyfeehan/Library/Python/3.9/bin/meshtastic
```

But this directory wasn't in your PATH, so the shell couldn't find the `meshtastic` command.

Now it's fixed!
