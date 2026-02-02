# Mesh Network Status

**Date:** 2026-02-02
**Status:** ✅ LIVE and ACTIVE

## Connected Devices (via USB-C)

### DUO 1 (!b4458cbb)
- **Port:** `/dev/cu.usbmodem14101`
- **Node ID:** 3024456891
- **Hardware:** MUZI_BASE
- **Firmware:** 2.7.18.fb3bf78
- **Role:** CLIENT
- **Battery:** 101% (3.845V)
- **Uptime:** 66 seconds
- **MAC:** d8:e3:b4:45:8c:bb
- **GPS:** ✅ Enabled (External source)
- **Last Position:** 39.9704064, -105.2573696 (Alt: 1686m)
- **Bluetooth:** ✅ Enabled (PIN: 123456)
- **Nodes Visible:** 8 total

### DUO2 (!45a248b6)
- **Port:** `/dev/cu.usbmodem14201`
- **Node ID:** 1168263350
- **Hardware:** MUZI_BASE
- **Firmware:** 2.7.18.fb3bf78
- **Role:** CLIENT
- **Battery:** 98% (4.042V)
- **Uptime:** 606 seconds (10 min)
- **MAC:** f9:dc:45:a2:48:b6
- **GPS:** ✅ Enabled
- **Bluetooth:** ✅ Enabled (PIN: 123456)
- **Nodes Visible:** 2 (DUO1 + self)

## Mesh Network Topology

```
                    [Internet/MQTT - DISABLED]
                              |
         ┌────────────────────┴────────────────────┐
         │         Meshtastic Mesh Network          │
         │          LoRa 2.4 GHz LONG_FAST          │
         │         Bandwidth: 250 / SF: 11          │
         └───────────────────┬──────────────────────┘
                             |
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
  [DUO 1 - HUB]         [DUO2]              [Paws (ThinkNode)]
  !b4458cbb           !45a248b6              !e8588aea
  SNR: Self           SNR: 6.75              SNR: 11.25
  Hops: 0             Hops: 0                Hops: 0
  Battery: 101%       Battery: 98%           Last heard: 26hr ago
       │
       ├─── [Meshtastic 77bc] - RAK4631
       │    !52bc77bc - SNR: -19.0 - 3 hops - Battery: 101%
       │
       ├─── [Fuzzy Pumper 👀] - HELTEC_V4
       │    !69842820 - SNR: -20.0 - 5 hops - GPS: 40.22572, -105.275171
       │
       ├─── [circle 1] - TBEAM
       │    !6c73c328 - SNR: -12.25 - GPS: 39.97696, -105.250816
       │
       ├─── [Yukon_209c] - HELTEC_V3
       │    !335c209c - No recent data
       │
       └─── [BLKOutCOmm (Solar Node 4)] - RAK4631
            !e0f1c83e - No recent data
```

## Network Statistics

### Channel Configuration
- **Primary Channel:** Default PSK (ID: 0)
- **Secondary Channel:** "C1" with encryption
- **Region:** LORA_24 (2.4 GHz band)
- **Modem Preset:** LONG_FAST
- **Hop Limit:** 3
- **TX Power:** 10 dBm

### Range & Signal Quality
| Node | Distance from DUO1 | SNR | Hops | Status |
|------|-------------------|-----|------|--------|
| DUO2 | Direct contact | 6.75 | 0 | ✅ Active |
| Paws | Unknown | 11.25 | 0 | ⚠️ Last heard 26hr ago |
| 77bc | ~5-10km (estimate) | -19.0 | 3 | ✅ Active |
| Fuzzy Pumper | ~15-20km (estimate) | -20.0 | 5 | ✅ Active |
| circle 1 | ~5km (GPS-based) | -12.25 | 0 | ✅ Active |
| Yukon | Unknown | N/A | N/A | ❌ Offline |
| BLKOutCOmm | Unknown | N/A | N/A | ❌ Offline |

### Position Data Available
| Node | Latitude | Longitude | Altitude | Last Update |
|------|----------|-----------|----------|-------------|
| DUO 1 | 39.9704064 | -105.2573696 | 1686m | Recent |
| Fuzzy Pumper | 40.22572 | -105.275171 | 1643m | 27hr ago |
| circle 1 | 39.97696 | -105.250816 | 1654m | 28hr ago |

## Key Findings for iOS Bridge

### ✅ What Works
1. **BLE Advertising:** Both DUOs have Bluetooth enabled with PIN 123456
2. **Position Broadcasting:** DUO1 has valid GPS coordinates
3. **Mesh Connectivity:** DUO1 sees 8 nodes, forming a working mesh
4. **LoRa Performance:** Good SNR on nearby nodes (6.75 to 11.25)
5. **Multi-hop Working:** Nodes reachable up to 5 hops away

### ⚠️ Challenges
1. **Paws Offline:** ThinkNode hasn't been heard from in 26 hours
2. **Weak Signals:** Some nodes at -19 to -20 dB SNR (functional but marginal)
3. **GPS on DUO2:** No position data yet (may need time to acquire)
4. **Remote Nodes:** 2 nodes have no recent telemetry

### 🎯 Perfect for Testing
- **DUO1 ↔ DUO2:** Direct line-of-sight, excellent SNR (6.75 dB)
- **Position Updates:** DUO1 broadcasts every 3600s (smart enabled)
- **BLE Ready:** Both devices advertising and ready for iOS connection
- **Real Mesh Data:** 8 nodes providing realistic test scenarios

## iOS Bridge Integration Points

### 1. BLE Service UUIDs (to discover)
```swift
// Standard Meshtastic BLE UUIDs (verify with nRF Connect)
let MESHTASTIC_SERVICE = CBUUID(string: "6ba1b218-15a8-461f-9fa8-5dcae273eafd")
let FROM_RADIO = CBUUID(string: "2c55e69e-4993-11ed-b878-0242ac120002")
let TO_RADIO = CBUUID(string: "f75c76d2-129e-4dad-a1dd-7866124401e7")
```

### 2. Target Nodes for Tracking
Primary test scenario: **Track DUO2 from DUO1's perspective**
- DUO1 = Base station (connected via BLE to iPhone)
- DUO2 = Target node to track
- Expected update rate: Every 300-3600 seconds

### 3. Protobuf Packet Structure
FROM_RADIO will contain:
- `MeshPacket` with position updates
- Node IDs: `!45a248b6` (DUO2), `!e8588aea` (Paws), etc.
- GPS coordinates in `latitudeI/longitudeI` format (degrees × 10^7)
- Timestamps, SNR, hop count, battery levels

## CLI Test Commands

```bash
# Monitor DUO1 for incoming packets
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --debug

# Send test message from DUO1
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --sendtext "Test from DUO1"

# Request position update
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --request-position !45a248b6

# Monitor both devices simultaneously
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14101 --debug &
~/Library/Python/3.9/bin/meshtastic --port /dev/cu.usbmodem14201 --debug
```

## Next Steps for Development

1. ✅ Mesh is confirmed live and working
2. ✅ Both DUOs have BLE enabled and ready
3. ⏭ Use nRF Connect app to verify BLE service UUIDs
4. ⏭ Update MeshtasticService.swift with correct UUIDs
5. ⏭ Test iOS bridge BLE connection to DUO1
6. ⏭ Parse incoming FROM_RADIO protobuf packets
7. ⏭ Display DUO2's position on iOS app
8. ⏭ Advertise selected node to Garmin watch
