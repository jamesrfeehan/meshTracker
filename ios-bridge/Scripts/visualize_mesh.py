#!/usr/bin/env python3
"""
Mesh Network Visualizer
Create ASCII art visualization of mesh topology
"""

import subprocess
import re
import json
from collections import defaultdict

class MeshVisualizer:
    """Visualize mesh network topology"""

    MESHTASTIC_CLI = '/Users/jimmyfeehan/Library/Python/3.9/bin/meshtastic'
    PORTS = {
        'DUO1': '/dev/cu.usbmodem14101',
        'DUO2': '/dev/cu.usbmodem14201'
    }

    def __init__(self):
        self.nodes = {}
        self.connections = defaultdict(list)

    def get_nodes_from_device(self, device):
        """Fetch node list from device"""
        port = self.PORTS.get(device)
        if not port:
            return

        cmd = [self.MESHTASTIC_CLI, '--port', port, '--nodes']
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

        # Parse output
        current_node = None
        for line in result.stdout.split('\n'):
            # Node ID line
            if re.match(r'^\s*"![a-f0-9]+":', line):
                node_id = re.search(r'"(![\da-f]+)"', line).group(1)
                current_node = node_id
                if node_id not in self.nodes:
                    self.nodes[node_id] = {
                        'id': node_id,
                        'name': node_id,
                        'hw': 'Unknown',
                        'snr': None,
                        'hops': None,
                        'position': None,
                        'seen_by': device
                    }

            # Parse node details
            if current_node:
                if '"longName":' in line:
                    name = re.search(r'"longName":\s*"([^"]+)"', line)
                    if name:
                        self.nodes[current_node]['name'] = name.group(1)

                elif '"shortName":' in line:
                    name = re.search(r'"shortName":\s*"([^"]+)"', line)
                    if name and len(name.group(1)) < 10:
                        self.nodes[current_node]['short_name'] = name.group(1)

                elif '"hwModel":' in line:
                    hw = re.search(r'"hwModel":\s*"([^"]+)"', line)
                    if hw:
                        self.nodes[current_node]['hw'] = hw.group(1)

                elif '"snr":' in line:
                    snr = re.search(r'"snr":\s*([-\d.]+)', line)
                    if snr:
                        self.nodes[current_node]['snr'] = float(snr.group(1))

                elif '"hopsAway":' in line:
                    hops = re.search(r'"hopsAway":\s*(\d+)', line)
                    if hops:
                        self.nodes[current_node]['hops'] = int(hops.group(1))

                elif '"latitude":' in line:
                    lat = re.search(r'"latitude":\s*([-\d.]+)', line)
                    if lat:
                        if not self.nodes[current_node].get('position'):
                            self.nodes[current_node]['position'] = {}
                        self.nodes[current_node]['position']['lat'] = float(lat.group(1))

                elif '"longitude":' in line:
                    lon = re.search(r'"longitude":\s*([-\d.]+)', line)
                    if lon:
                        if not self.nodes[current_node].get('position'):
                            self.nodes[current_node]['position'] = {}
                        self.nodes[current_node]['position']['lon'] = float(lon.group(1))

    def build_topology(self):
        """Build network topology based on hop counts"""
        # Group nodes by hop count
        by_hops = defaultdict(list)
        for node_id, data in self.nodes.items():
            hops = data.get('hops', 0)
            by_hops[hops].append(node_id)

        return by_hops

    def visualize_ascii(self):
        """Create ASCII art visualization"""
        print("\n" + "="*80)
        print("MESH NETWORK TOPOLOGY VISUALIZATION")
        print("="*80)

        # Fetch data from both devices
        print("\n🔍 Scanning DUO1...")
        self.get_nodes_from_device('DUO1')

        print("🔍 Scanning DUO2...")
        self.get_nodes_from_device('DUO2')

        # Build topology
        by_hops = self.build_topology()

        print("\n" + "="*80)
        print("NETWORK STRUCTURE")
        print("="*80 + "\n")

        # Display by hop distance
        max_hops = max(by_hops.keys()) if by_hops else 0

        for hop_level in range(max_hops + 1):
            nodes_at_level = by_hops.get(hop_level, [])

            if hop_level == 0:
                print("📡 HUB (0 hops):")
                print("┌" + "─"*76 + "┐")
            else:
                print(f"\n{'  '*hop_level}↓ {hop_level} hop{'s' if hop_level > 1 else ''}")
                print(f"{'  '*hop_level}┌" + "─"*(76-hop_level*2) + "┐")

            for node_id in sorted(nodes_at_level):
                data = self.nodes[node_id]
                name = data.get('name', node_id)
                hw = data.get('hw', 'Unknown')
                snr = data.get('snr')
                pos = data.get('position')

                # Format line
                indent = "  " * hop_level
                line = f"{'│':>2} {name:20s} ({node_id}) - {hw:15s}"

                if snr is not None:
                    snr_str = f"SNR: {snr:+.1f} dB"
                    if snr > 5:
                        snr_str += " ✅"
                    elif snr > -5:
                        snr_str += " ⚠️ "
                    else:
                        snr_str += " ❌"
                    line += f" | {snr_str}"

                if pos and 'lat' in pos:
                    line += f" | 📍 GPS"

                print(indent + line)

            if hop_level == 0:
                print("└" + "─"*76 + "┘")
            else:
                print(f"{'  '*hop_level}└" + "─"*(76-hop_level*2) + "┘")

        # Summary statistics
        print("\n" + "="*80)
        print("NETWORK STATISTICS")
        print("="*80)

        total_nodes = len(self.nodes)
        nodes_with_gps = sum(1 for n in self.nodes.values() if n.get('position'))
        avg_snr = sum(n.get('snr', 0) for n in self.nodes.values() if n.get('snr')) / max(1, sum(1 for n in self.nodes.values() if n.get('snr')))

        print(f"\nTotal Nodes:        {total_nodes}")
        print(f"Nodes with GPS:     {nodes_with_gps}")
        print(f"Max Hop Distance:   {max_hops}")
        print(f"Average SNR:        {avg_snr:.2f} dB")

        # Hardware breakdown
        hw_counts = defaultdict(int)
        for node in self.nodes.values():
            hw_counts[node.get('hw', 'Unknown')] += 1

        print(f"\nHardware Types:")
        for hw, count in sorted(hw_counts.items(), key=lambda x: -x[1]):
            print(f"  {hw:20s}: {count}")

        # GPS positions
        print(f"\nNodes with Positions:")
        for node_id, data in self.nodes.items():
            pos = data.get('position')
            if pos and 'lat' in pos:
                name = data.get('name', node_id)
                lat = pos['lat']
                lon = pos['lon']
                print(f"  {name:20s}: {lat:.6f}, {lon:.6f}")
                print(f"    → https://www.google.com/maps?q={lat},{lon}")

        print("\n" + "="*80)

    def export_json(self, filename='mesh_topology.json'):
        """Export topology to JSON"""
        output = {
            'timestamp': subprocess.check_output(['date']).decode().strip(),
            'nodes': self.nodes,
            'topology': dict(self.build_topology())
        }

        with open(filename, 'w') as f:
            json.dump(output, f, indent=2)

        print(f"\n📄 Topology exported to: {filename}")

def main():
    viz = MeshVisualizer()
    viz.visualize_ascii()
    viz.export_json('/tmp/mesh_topology.json')

if __name__ == '__main__':
    main()
