#!/usr/bin/env python3
"""
Position Comparison Tool
Compare GPS coordinates from different sources to verify accuracy
"""

import subprocess
import re
import time
from math import radians, cos, sin, asin, sqrt

def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    Returns distance in meters
    """
    # Convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])

    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371000  # Radius of earth in meters
    return c * r

def get_mesh_position(port):
    """Get position from Meshtastic device"""
    cmd = [
        '/Users/jimmyfeehan/Library/Python/3.9/bin/meshtastic',
        '--port', port,
        '--nodes'
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    output = result.stdout

    # Parse position from node info
    # Look for "position": { "latitudeI": ..., "longitudeI": ... }
    lat_match = re.search(r'"latitudeI":\s*([-\d]+)', output)
    lon_match = re.search(r'"longitudeI":\s*([-\d]+)', output)

    if lat_match and lon_match:
        # Convert from integer format (degrees × 10^7)
        lat = int(lat_match.group(1)) / 1e7
        lon = int(lon_match.group(1)) / 1e7
        return lat, lon

    # Try decimal format
    lat_match = re.search(r'"latitude":\s*([-\d.]+)', output)
    lon_match = re.search(r'"longitude":\s*([-\d.]+)', output)

    if lat_match and lon_match:
        lat = float(lat_match.group(1))
        lon = float(lon_match.group(1))
        return lat, lon

    return None, None

def main():
    print("="*60)
    print("MESH POSITION COMPARISON TOOL")
    print("="*60)
    print()

    # Get positions from both DUOs
    print("Fetching DUO1 position...")
    duo1_lat, duo1_lon = get_mesh_position('/dev/cu.usbmodem14101')

    print("Fetching DUO2 position...")
    duo2_lat, duo2_lon = get_mesh_position('/dev/cu.usbmodem14201')

    # Display results
    print("\n" + "="*60)
    print("RESULTS")
    print("="*60)

    if duo1_lat and duo1_lon:
        print(f"\n✅ DUO1 Position:")
        print(f"   Latitude:  {duo1_lat:.7f}")
        print(f"   Longitude: {duo1_lon:.7f}")
        print(f"   Google Maps: https://www.google.com/maps?q={duo1_lat},{duo1_lon}")
    else:
        print(f"\n❌ DUO1: No position data available")

    if duo2_lat and duo2_lon:
        print(f"\n✅ DUO2 Position:")
        print(f"   Latitude:  {duo2_lat:.7f}")
        print(f"   Longitude: {duo2_lon:.7f}")
        print(f"   Google Maps: https://www.google.com/maps?q={duo2_lat},{duo2_lon}")
    else:
        print(f"\n❌ DUO2: No position data available")

    # Calculate distance between them
    if duo1_lat and duo1_lon and duo2_lat and duo2_lon:
        distance = haversine(duo1_lat, duo1_lon, duo2_lat, duo2_lon)
        print(f"\n📏 Distance between DUO1 and DUO2: {distance:.2f} meters")

        if distance < 10:
            print("   ✅ Devices are co-located (< 10m)")
        elif distance < 100:
            print("   ⚠️  Devices are nearby (< 100m)")
        else:
            print(f"   📍 Devices are {distance/1000:.2f} km apart")

    # Known reference position (update with your actual location if testing)
    reference_lat = 39.9704064  # From mesh status
    reference_lon = -105.2573696

    print(f"\n📍 Reference Position:")
    print(f"   Latitude:  {reference_lat:.7f}")
    print(f"   Longitude: {reference_lon:.7f}")

    if duo1_lat and duo1_lon:
        ref_distance = haversine(reference_lat, reference_lon, duo1_lat, duo1_lon)
        print(f"\n   DUO1 vs Reference: {ref_distance:.2f}m")

    print("\n" + "="*60)

if __name__ == '__main__':
    main()
