#!/usr/bin/env python3
"""
Real-time Mesh Network Monitor
Live dashboard showing position updates and mesh status
"""

import subprocess
import re
import time
import sys
from datetime import datetime
from collections import defaultdict

class MeshMonitor:
    """Real-time monitor for mesh network activity"""

    MESHTASTIC_CLI = '/Users/jimmyfeehan/Library/Python/3.9/bin/meshtastic'
    PORTS = {
        'DUO1': '/dev/cu.usbmodem14101',
        'DUO2': '/dev/cu.usbmodem14201'
    }

    def __init__(self, device='DUO1'):
        self.device = device
        self.port = self.PORTS[device]
        self.packet_counts = defaultdict(int)
        self.positions = {}
        self.start_time = time.time()

    def clear_screen(self):
        """Clear terminal screen"""
        print('\033[2J\033[H', end='')

    def print_header(self):
        """Print dashboard header"""
        runtime = time.time() - self.start_time
        print("="*80)
        print(f"🛰️  MESHTASTIC MESH MONITOR - {self.device} ({self.port})")
        print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Runtime: {int(runtime)}s")
        print("="*80)
        print()

    def print_stats(self):
        """Print packet statistics"""
        print("📊 PACKET STATISTICS:")
        print("-" * 40)
        for packet_type, count in sorted(self.packet_counts.items()):
            print(f"  {packet_type:20s}: {count:4d}")
        print()

    def print_positions(self):
        """Print position updates"""
        if self.positions:
            print("📍 POSITION UPDATES:")
            print("-" * 80)
            for node_id, pos in self.positions.items():
                print(f"  {node_id}: {pos['lat']:.6f}, {pos['lon']:.6f} @ {pos['time']}")
            print()

    def parse_line(self, line: str):
        """Parse a line from meshtastic debug output"""
        # Position updates
        if 'POSITION_APP' in line:
            self.packet_counts['POSITION'] += 1
            # Try to extract coordinates
            lat_match = re.search(r'lat[^0-9-]+([-0-9.]+)', line, re.IGNORECASE)
            lon_match = re.search(r'lon[^0-9-]+([-0-9.]+)', line, re.IGNORECASE)
            node_match = re.search(r'from[^!]*(![\da-f]+)', line, re.IGNORECASE)

            if lat_match and lon_match and node_match:
                node_id = node_match.group(1)
                self.positions[node_id] = {
                    'lat': float(lat_match.group(1)),
                    'lon': float(lon_match.group(1)),
                    'time': datetime.now().strftime('%H:%M:%S')
                }

        elif 'NODEINFO_APP' in line:
            self.packet_counts['NODEINFO'] += 1

        elif 'TELEMETRY_APP' in line:
            self.packet_counts['TELEMETRY'] += 1

        elif 'TEXT_MESSAGE' in line:
            self.packet_counts['MESSAGE'] += 1
            print(f"\n💬 Message: {line.strip()}\n")

        elif 'ADMIN_APP' in line:
            self.packet_counts['ADMIN'] += 1

        elif 'ROUTING_APP' in line:
            self.packet_counts['ROUTING'] += 1

        # Track general RX/TX
        if 'Received packet' in line or 'RX' in line:
            self.packet_counts['RX_TOTAL'] += 1
        elif 'Sending packet' in line or 'TX' in line:
            self.packet_counts['TX_TOTAL'] += 1

    def monitor(self, update_interval=2):
        """Start monitoring mesh activity"""
        print(f"Starting mesh monitor on {self.device}...")
        print("Press Ctrl+C to stop\n")
        time.sleep(1)

        # Start meshtastic debug mode
        cmd = [self.MESHTASTIC_CLI, '--port', self.port, '--debug']

        try:
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            last_update = time.time()

            while True:
                line = process.stdout.readline()
                if not line:
                    break

                # Parse the line
                self.parse_line(line)

                # Update display every N seconds
                if time.time() - last_update >= update_interval:
                    self.clear_screen()
                    self.print_header()
                    self.print_stats()
                    self.print_positions()
                    print("Press Ctrl+C to stop...")
                    last_update = time.time()

        except KeyboardInterrupt:
            print("\n\n⏹️  Monitor stopped by user")
            process.terminate()
        except Exception as e:
            print(f"\n❌ Error: {e}")
            process.terminate()

        # Final summary
        print("\n" + "="*80)
        print("FINAL SUMMARY")
        print("="*80)
        self.print_stats()
        self.print_positions()

def main():
    if len(sys.argv) > 1:
        device = sys.argv[1]
    else:
        device = 'DUO1'

    update_interval = 2
    if len(sys.argv) > 2:
        try:
            update_interval = int(sys.argv[2])
        except:
            pass

    monitor = MeshMonitor(device)
    monitor.monitor(update_interval)

if __name__ == '__main__':
    main()
