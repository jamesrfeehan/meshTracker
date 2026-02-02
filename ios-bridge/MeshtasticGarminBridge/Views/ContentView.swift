import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var coordinator = BridgeCoordinator()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Status Section
                statusSection

                Divider()

                // MARK: - Meshtastic Section
                meshtasticSection

                Divider()

                // MARK: - Garmin Section
                garminSection

                Divider()

                // MARK: - Tracked Nodes
                trackedNodesSection

                Spacer()
            }
            .padding()
            .navigationTitle("Mesh → Garmin Bridge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(coordinator.isActive ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                Text(coordinator.isActive ? "Bridge Active" : "Bridge Inactive")
                    .font(.headline)
                Spacer()
            }

            if coordinator.isActive {
                VStack(alignment: .leading, spacing: 4) {
                    statsRow(label: "Packets RX", value: "\(coordinator.statistics.packetsReceived)")
                    statsRow(label: "Packets TX", value: "\(coordinator.statistics.packetsForwarded)")
                    statsRow(label: "Tracked Nodes", value: "\(coordinator.trackedNodes.count)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Button(action: {
                if coordinator.isActive {
                    coordinator.stop()
                } else {
                    coordinator.start()
                }
            }) {
                Text(coordinator.isActive ? "Stop Bridge" : "Start Bridge")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(coordinator.isActive ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
        }
    }

    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Meshtastic Section

    private var meshtasticSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                Text("Meshtastic")
                    .font(.headline)
                Spacer()
                statusBadge(coordinator.meshtasticService.connectionState.rawValue)
            }

            if coordinator.meshtasticService.connectedDevice != nil {
                deviceRow(
                    name: coordinator.meshtasticService.connectedDevice?.name ?? "Unknown",
                    detail: "Connected"
                )
            } else if coordinator.meshtasticService.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Discovered Devices:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if coordinator.meshtasticService.discoveredDevices.isEmpty {
                        Text("Scanning...")
                            .font(.caption)
                            .italic()
                    } else {
                        ForEach(coordinator.meshtasticService.discoveredDevices, id: \.identifier) { device in
                            Button(action: {
                                coordinator.connectToMeshtastic(device)
                            }) {
                                deviceRow(
                                    name: device.name ?? "Unknown",
                                    detail: "Tap to connect"
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Garmin Section

    private var garminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.orange)
                Text("Garmin")
                    .font(.headline)
                Spacer()
                statusBadge(coordinator.garminService.isAdvertising ? "Advertising" : "Stopped")
            }

            HStack {
                Text("Connected Watches:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(coordinator.statistics.connectedGarminDevices)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            if coordinator.garminService.isAdvertising {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Visible to Garmin watches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Tracked Nodes Section

    private var trackedNodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("Tracked Nodes")
                    .font(.headline)
                Spacer()
                Text("\(coordinator.trackedNodes.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if coordinator.trackedNodes.isEmpty {
                Text("No nodes tracked yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(coordinator.trackedNodes) { node in
                            nodeRow(node: node)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func nodeRow(node: MeshNode) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.shortName)
                    .font(.headline)
                Text(node.longName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "battery.100")
                        .font(.caption)
                    Text("\(node.batteryLevel)%")
                        .font(.caption)
                }
                Text(formatAge(node.age))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if coordinator.selectedNodeId == node.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            if coordinator.selectedNodeId == node.id {
                coordinator.clearNodeSelection()
            } else {
                coordinator.selectNode(node.id)
            }
        }
    }

    // MARK: - Helper Views

    private func statusBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(4)
    }

    private func deviceRow(name: String, detail: String) -> some View {
        HStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.subheadline)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatAge(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s ago"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else {
            return "\(Int(seconds / 3600))h ago"
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
