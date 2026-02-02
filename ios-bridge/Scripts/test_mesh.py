#!/usr/bin/env python3
"""
Meshtastic Mesh Network Testing Tool
Automated testing for DUO1, DUO2, and mesh connectivity
"""

import subprocess
import json
import time
import sys
from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime

@dataclass
class MeshNode:
    """Represents a node in the mesh network"""
    node_id: str
    long_name: str
    short_name: str
    hw_model: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: Optional[int] = None
    snr: Optional[float] = None
    hops_away: Optional[int] = None
    last_heard: Optional[int] = None
    battery_level: Optional[int] = None

class MeshtasticTester:
    """Test harness for Meshtastic mesh network"""

    PORTS = {
        'DUO1': '/dev/cu.usbmodem14101',
        'DUO2': '/dev/cu.usbmodem14201'
    }

    MESHTASTIC_CLI = '/Users/jimmyfeehan/Library/Python/3.9/bin/meshtastic'

    def __init__(self):
        self.nodes: Dict[str, Dict[str, MeshNode]] = {
            'DUO1': {},
            'DUO2': {}
        }

    def run_command(self, device: str, args: List[str], timeout: int = 30) -> str:
        """Run meshtastic CLI command"""
        port = self.PORTS.get(device)
        if not port:
            raise ValueError(f"Unknown device: {device}")

        cmd = [self.MESHTASTIC_CLI, '--port', port] + args
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.stdout
        except subprocess.TimeoutExpired:
            return f"ERROR: Command timed out after {timeout}s"
        except Exception as e:
            return f"ERROR: {str(e)}"

    def get_device_info(self, device: str) -> Dict:
        """Get device information"""
        print(f"\n{'='*60}")
        print(f"Testing {device} ({self.PORTS[device]})")
        print(f"{'='*60}")

        output = self.run_command(device, ['--info'])
        print(output)
        return self.parse_info(output)

    def parse_info(self, output: str) -> Dict:
        """Parse device info output"""
        info = {
            'owner': None,
            'node_num': None,
            'firmware': None,
            'hw_model': None,
            'nodes_count': 0,
            'nodes': []
        }

        lines = output.split('\n')
        for line in lines:
            if 'Owner:' in line:
                info['owner'] = line.split('Owner:')[1].strip()
            elif '"myNodeNum":' in line:
                try:
                    info['node_num'] = int(line.split(':')[1].strip().rstrip(','))
                except:
                    pass
            elif '"firmwareVersion":' in line:
                info['firmware'] = line.split('"')[3]
            elif '"hwModel":' in line:
                info['hw_model'] = line.split('"')[3]

        return info

    def get_nodes(self, device: str) -> List[MeshNode]:
        """Get list of nodes visible to device"""
        output = self.run_command(device, ['--nodes'])
        nodes = []

        # Parse node info from output
        # This is simplified - would need full JSON parsing for production
        current_node = None
        for line in output.split('\n'):
            if line.startswith('  "!'):
                node_id = line.split('"')[1]
                current_node = node_id
            elif '"longName":' in line and current_node:
                long_name = line.split('"')[3]
            elif '"shortName":' in line and current_node:
                short_name = line.split('"')[3]

        return nodes

    def test_connectivity(self, device: str) -> bool:
        """Test if device is connected and responding"""
        output = self.run_command(device, ['--info'], timeout=10)
        return 'Connected to radio' in output

    def test_position_broadcast(self, device: str, duration: int = 60):
        """Monitor position broadcasts for a duration"""
        print(f"\n🔍 Monitoring {device} for {duration} seconds...")
        print(f"Watching for position updates...\n")

        # Start debug mode in background
        # Note: This is a simplified version - real implementation would
        # use asyncio or threading to monitor in real-time
        output = self.run_command(device, ['--debug'], timeout=duration)

        # Count position packets
        position_count = output.count('POSITION_APP')
        print(f"✅ Received {position_count} position packets")
        return position_count > 0

    def test_node_reachability(self, from_device: str, to_node: str) -> bool:
        """Test if a specific node is reachable"""
        output = self.run_command(from_device, ['--nodes'])
        return to_node in output

    def send_test_message(self, from_device: str, message: str) -> bool:
        """Send a test message to the mesh"""
        output = self.run_command(from_device, ['--sendtext', message])
        return 'ERROR' not in output

    def run_full_test_suite(self):
        """Run comprehensive test suite"""
        print("\n" + "="*60)
        print("MESHTASTIC MESH NETWORK TEST SUITE")
        print("="*60)

        results = {
            'timestamp': datetime.now().isoformat(),
            'tests_passed': 0,
            'tests_failed': 0,
            'devices': {}
        }

        # Test 1: Device Connectivity
        print("\n[TEST 1] Device Connectivity")
        for device in ['DUO1', 'DUO2']:
            if self.test_connectivity(device):
                print(f"  ✅ {device} connected")
                results['tests_passed'] += 1
                results['devices'][device] = {'connected': True}
            else:
                print(f"  ❌ {device} not responding")
                results['tests_failed'] += 1
                results['devices'][device] = {'connected': False}

        # Test 2: Device Information
        print("\n[TEST 2] Device Information")
        for device in ['DUO1', 'DUO2']:
            if results['devices'][device].get('connected'):
                info = self.get_device_info(device)
                results['devices'][device]['info'] = info

        # Test 3: Node Discovery
        print("\n[TEST 3] Node Discovery")
        duo1_sees_duo2 = self.test_node_reachability('DUO1', '!45a248b6')
        duo2_sees_duo1 = self.test_node_reachability('DUO2', '!b4458cbb')

        if duo1_sees_duo2 and duo2_sees_duo1:
            print("  ✅ DUO1 ↔ DUO2 mutual visibility")
            results['tests_passed'] += 1
        else:
            print("  ❌ DUO1 ↔ DUO2 visibility issue")
            print(f"     DUO1 sees DUO2: {duo1_sees_duo2}")
            print(f"     DUO2 sees DUO1: {duo2_sees_duo1}")
            results['tests_failed'] += 1

        # Test 4: Message Sending
        print("\n[TEST 4] Message Transmission")
        test_msg = f"Test message from automated suite @ {time.time()}"
        if self.send_test_message('DUO1', test_msg):
            print("  ✅ Message sent successfully from DUO1")
            results['tests_passed'] += 1
        else:
            print("  ❌ Failed to send message from DUO1")
            results['tests_failed'] += 1

        # Test 5: Position Broadcast (Optional - takes time)
        # Uncomment to enable
        # print("\n[TEST 5] Position Broadcast Monitoring")
        # if self.test_position_broadcast('DUO1', duration=30):
        #     results['tests_passed'] += 1
        # else:
        #     results['tests_failed'] += 1

        # Summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        print(f"Passed: {results['tests_passed']}")
        print(f"Failed: {results['tests_failed']}")
        print(f"Success Rate: {results['tests_passed']/(results['tests_passed']+results['tests_failed'])*100:.1f}%")

        # Save results
        with open('/tmp/mesh_test_results.json', 'w') as f:
            json.dump(results, f, indent=2, default=str)
        print(f"\nResults saved to: /tmp/mesh_test_results.json")

        return results['tests_failed'] == 0

def main():
    """Main entry point"""
    tester = MeshtasticTester()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == 'info':
            device = sys.argv[2] if len(sys.argv) > 2 else 'DUO1'
            tester.get_device_info(device)

        elif command == 'test':
            success = tester.run_full_test_suite()
            sys.exit(0 if success else 1)

        elif command == 'monitor':
            device = sys.argv[2] if len(sys.argv) > 2 else 'DUO1'
            duration = int(sys.argv[3]) if len(sys.argv) > 3 else 60
            tester.test_position_broadcast(device, duration)

        elif command == 'send':
            device = sys.argv[2] if len(sys.argv) > 2 else 'DUO1'
            message = sys.argv[3] if len(sys.argv) > 3 else 'Test message'
            tester.send_test_message(device, message)

        else:
            print(f"Unknown command: {command}")
            print_usage()
    else:
        # Run full test suite by default
        tester.run_full_test_suite()

def print_usage():
    """Print usage information"""
    print("""
Meshtastic Mesh Network Tester

Usage:
    test_mesh.py                    # Run full test suite
    test_mesh.py info [DUO1|DUO2]   # Get device info
    test_mesh.py test               # Run all tests
    test_mesh.py monitor [device] [duration]  # Monitor for position updates
    test_mesh.py send [device] [message]      # Send test message

Examples:
    ./test_mesh.py
    ./test_mesh.py info DUO1
    ./test_mesh.py monitor DUO1 30
    ./test_mesh.py send DUO2 "Hello from automation"
""")

if __name__ == '__main__':
    main()
