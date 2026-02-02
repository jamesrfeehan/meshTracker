# Hardware Setup Guide

This guide covers the physical setup and assembly of your dog tracking system.

## What You'll Need

### Required Hardware
- Elecrow ThinkNode M3 tracker
- Muzi Works Base Duo
- Dog collar or harness with secure attachment point
- Micro USB cable (for initial firmware flashing)
- Mobile phone with Bluetooth (iOS or Android)

### Optional Hardware
- External antenna for Base Duo (for extended range)
- Solar panel for Base Duo (for continuous outdoor operation)
- Protective case/pouch for ThinkNode M3
- Mounting bracket for Base Duo

## ThinkNode M3 Setup (Dog Collar Unit)

### 1. Initial Inspection

- Verify IP66 waterproof rating seal is intact
- Check magnetic charging contacts (4 pogo pins)
- Ensure device powers on (LED indicator)
- Test all buttons are responsive

### 2. Charging

The ThinkNode M3 uses magnetic charging:

1. Align the magnetic charging base with the 4 pogo pins
2. The magnets will snap into place
3. Connect USB cable to charging base
4. LED will indicate charging status:
   - Red: Charging
   - Green: Fully charged
5. Initial charge takes approximately 2-3 hours for 770mAh battery

### 3. GPS Test

Before mounting on collar, test GPS functionality:

1. Power on the device
2. Place outdoors with clear sky view
3. Wait 1-3 minutes for initial GPS lock (cold start)
4. LED will indicate GPS status
5. Verify position accuracy using Meshtastic app

**GPS Performance:**
- Cold start: <30 seconds (typical)
- Hot start: <1 second
- Sensitivity: -148 dBm (acquisition), -162 dBm (tracking)
- Accuracy: <1.5 meters

### 4. Collar Mounting

**Safety First:**
- Device weight: 40g (suitable for dogs >10 lbs / 4.5 kg)
- Ensure collar fits properly (two-finger rule)
- Position device on top/side of neck, not under throat
- Regular checks for rubbing or irritation

**Mounting Options:**

#### Option A: Direct Attachment
1. Use the fixed base (68×68×10.2mm) that comes with device
2. Thread collar through base slots
3. Snap ThinkNode M3 onto magnetic base
4. Ensure secure fit

#### Option B: Pouch Method
1. Place ThinkNode M3 in protective pouch
2. Attach pouch to collar with velcro or clips
3. Ensures easy removal for charging
4. Provides extra protection

#### Option C: Integrated Collar
1. Use collar with built-in electronics pocket
2. Insert ThinkNode M3 into pocket
3. Most secure option for active dogs

### 5. Environmental Considerations

The ThinkNode M3 is rated IP66:
- **Protected from**: Rain, snow, splashing, dust
- **Not protected from**: Full submersion (swimming)
- **Operating range**: -20°C to +60°C

**Best Practices:**
- Remove during swimming/bathing
- Wipe clean after muddy walks
- Check seal integrity monthly
- Store at room temperature when not in use

## Base Duo Setup (Home Station)

### 1. Unboxing and Inspection

Verify your Base Duo includes:
- Base Duo board (42×32mm)
- USB-C cable
- Antenna(s) - SMA for Sub-GHz, U.FL for 2.4GHz
- Documentation

### 2. Antenna Installation

**Sub-GHz Antenna (Primary):**
1. Screw SMA antenna onto Sub-GHz connector
2. Hand-tighten only (do not over-torque)
3. Position vertically for optimal omni-directional coverage

**2.4GHz Antenna (Optional):**
1. Connect U.FL connector carefully (very delicate!)
2. Push straight down until it clicks
3. Never pull at an angle (connector damage)

**Important:** Never power on without antennas connected (can damage radio)

### 3. Power Options

The Base Duo supports multiple power sources:

#### Option A: USB-C Power (Recommended for Indoor)
1. Connect USB-C cable to wall adapter (5V, 1-2A)
2. Device will power on immediately
3. Most reliable for permanent installation

#### Option B: Battery Power
1. Connect Li-ion or LFP battery to 3-pin Molex PicoBlade connector
2. Supported: 3.7V Li-ion or 3.2V LiFePO4
3. Charging: 500mA default, 1A fast-charge mode
4. Battery protection: Overvoltage, undervoltage, short circuit, thermal

#### Option C: Solar + Battery
1. Connect solar panel to solar input
2. Connect battery for nighttime operation
3. Ideal for outdoor permanent installations
4. Recommended: 5-6V, 2W+ solar panel

### 4. Physical Mounting

**Indoor Installation:**
- Mount near window for best range
- Elevate 6+ feet off ground
- Away from metal objects and electronics
- USB-C power recommended

**Outdoor Installation:**
- Weatherproof enclosure required (Base Duo is NOT waterproof)
- Mount high for line-of-sight
- Use solar + battery power
- Protect from direct rain/snow

**Using Mounting Holes:**
- Three M2 mounting holes provided
- Use standoffs to allow airflow
- Secure wiring to prevent strain

### 5. Range Optimization

To maximize the 5-6km range:

1. **Elevation**: Mount as high as safely possible
2. **Line of Sight**: Clear path between tracker and base
3. **Antenna**: Vertical orientation, away from metal
4. **Environment**:
   - Urban: 1-2km typical
   - Suburban: 3-4km typical
   - Rural/Open: 5-6km+ possible

## System Integration

### Connecting the System

1. **Power on Base Duo** (will start in router mode)
2. **Power on ThinkNode M3** (will start GPS acquisition)
3. **Wait 2-3 minutes** for mesh network to establish
4. **Verify LED activity** on both devices
5. **Test with mobile app** (see mobile-app-setup.md)

### LED Indicators

**ThinkNode M3:**
- Solid: Device on
- Blinking: GPS acquisition
- Fast blink: Transmitting data
- Off: Device sleeping/off

**Base Duo:**
- Solid: Powered and operational
- Blinking: Receiving/transmitting data
- Off: No power

## Testing Checklist

Before deploying on your dog:

- [ ] ThinkNode M3 fully charged
- [ ] GPS lock achieved (outdoor test)
- [ ] Base Duo powered and antenna connected
- [ ] Mesh network established (visible in app)
- [ ] Location updates received at base
- [ ] Collar fit tested and comfortable
- [ ] Range tested in your area
- [ ] Battery life tested (at least 1 cycle)

## Maintenance

### Daily
- Check ThinkNode M3 is securely attached to collar
- Verify GPS position in mobile app

### Weekly
- Recharge ThinkNode M3 (if needed)
- Clean device with damp cloth
- Check collar fit (growing puppies!)

### Monthly
- Verify IP66 seal integrity
- Check antenna connections on Base Duo
- Test backup battery on Base Duo
- Review stored location history

## Troubleshooting

### ThinkNode M3 won't power on
- Place on charging base for 10+ minutes
- Check magnetic contact alignment
- Try different USB power source

### No GPS lock
- Must be outdoors with sky view
- Wait 3-5 minutes for cold start
- Move away from tall buildings
- Check GPS is enabled in config

### Short battery life
- Reduce update frequency (see config)
- Lower LoRa transmit power if range adequate
- Verify battery health
- Check temperature (extreme temps reduce capacity)

### Base Duo not receiving
- Verify antenna connected before powering on
- Check mesh network configuration
- Test with devices closer together
- Verify correct frequency band (US915 vs EU868)

## Safety Reminders

- Monitor dog's comfort with collar device
- Remove device during high-water activities
- Check for skin irritation regularly
- Ensure collar fit allows emergency release
- Never rely solely on tracker - supervise your dog
- Keep firmware updated for best performance

## Next Steps

Once hardware is set up and tested:
1. [Configure Meshtastic Firmware](firmware-config.md)
2. [Set Up Mobile App](mobile-app-setup.md)
3. Perform range testing in your area
4. Set up geofencing alerts
5. Configure backup devices (optional)
