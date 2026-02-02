import Foundation
import CoreBluetooth
import CoreLocation

/// BLE Central service that connects to Meshtastic devices and receives position updates
/// Scans for, connects to, and subscribes to notifications from Meshtastic radios
class MeshtasticService: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isScanning = false
    @Published var connectedDevice: CBPeripheral?
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastPacketReceived: Date?

    enum ConnectionState: String {
        case disconnected = "Disconnected"
        case scanning = "Scanning..."
        case connecting = "Connecting..."
        case connected = "Connected"
        case subscribing = "Subscribing..."
        case ready = "Ready"
    }

    // MARK: - Meshtastic BLE Service/Characteristic UUIDs
    // From Meshtastic protobuf definitions
    static let serviceUUID = CBUUID(string: "6BA1B218-15A8-461F-9FA8-5DCAE273EAFD")
    static let fromRadioUUID = CBUUID(string: "2C55E69E-4993-11ED-B878-0242AC120002")  // Notifications FROM device
    static let toRadioUUID = CBUUID(string: "F75C76D2-129E-4DAD-A1DD-7866124401E7")    // Write TO device
    static let fromNumUUID = CBUUID(string: "ED9DA18C-A800-4F66-A670-AA7547E34453")    // Packet counter

    // MARK: - BLE Components
    private var centralManager: CBCentralManager!
    private var fromRadioCharacteristic: CBCharacteristic?
    private var toRadioCharacteristic: CBCharacteristic?

    // MARK: - Callback for position updates
    var onNodeUpdate: ((MeshNode) -> Void)?

    // MARK: - Known nodes (tracking state)
    private var knownNodes: [UInt32: MeshNode] = [:]

    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: "MeshtasticBridge",
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    // MARK: - Public API

    /// Start scanning for Meshtastic devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("⚠️  Bluetooth not powered on")
            return
        }

        connectionState = .scanning
        isScanning = true
        discoveredDevices.removeAll()

        // Scan for devices advertising Meshtastic service
        centralManager.scanForPeripherals(
            withServices: [MeshtasticService.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        print("🔍 Scanning for Meshtastic devices...")
    }

    /// Stop scanning
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if connectionState == .scanning {
            connectionState = .disconnected
        }
        print("🛑 Stopped scanning")
    }

    /// Connect to a specific Meshtastic device
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectionState = .connecting
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("🔌 Connecting to \(peripheral.name ?? "Unknown")...")
    }

    /// Disconnect from current device
    func disconnect() {
        guard let device = connectedDevice else { return }
        centralManager.cancelPeripheralConnection(device)
        print("👋 Disconnecting from \(device.name ?? "Unknown")")
    }

    /// Request initial node database from device
    func requestNodeDatabase() {
        // TODO: Implement when we add protobuf support
        // This would send a "want_config" packet to get all known nodes
        print("📋 Requesting node database...")
    }
}

// MARK: - CBCentralManagerDelegate

extension MeshtasticService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("📱 Central state: \(central.state.description)")

        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth ready - you can start scanning")
        case .poweredOff:
            connectionState = .disconnected
            isScanning = false
            print("⚠️  Bluetooth is off")
        case .unauthorized:
            print("❌ Bluetooth not authorized")
        case .unsupported:
            print("❌ Bluetooth not supported")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {

        let name = peripheral.name ?? "Unknown"
        print("📡 Found device: \(name) (RSSI: \(RSSI))")

        // Add to discovered list if not already present
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredDevices.append(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to \(peripheral.name ?? "Unknown")")

        DispatchQueue.main.async {
            self.connectedDevice = peripheral
            self.connectionState = .connected
        }

        // Discover Meshtastic service
        peripheral.discoverServices([MeshtasticService.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        print("👋 Disconnected from \(peripheral.name ?? "Unknown")")

        DispatchQueue.main.async {
            self.connectedDevice = nil
            self.connectionState = .disconnected
            self.fromRadioCharacteristic = nil
            self.toRadioCharacteristic = nil
        }

        if let error = error {
            print("⚠️  Disconnect error: \(error.localizedDescription)")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension MeshtasticService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == MeshtasticService.serviceUUID {
                print("✅ Found Meshtastic service")
                connectionState = .subscribing

                // Discover characteristics
                peripheral.discoverCharacteristics([
                    MeshtasticService.fromRadioUUID,
                    MeshtasticService.toRadioUUID,
                    MeshtasticService.fromNumUUID
                ], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case MeshtasticService.fromRadioUUID:
                print("✅ Found FROM_RADIO characteristic")
                fromRadioCharacteristic = characteristic
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)

            case MeshtasticService.toRadioUUID:
                print("✅ Found TO_RADIO characteristic")
                toRadioCharacteristic = characteristic

            case MeshtasticService.fromNumUUID:
                print("✅ Found FROM_NUM characteristic")
                // Could subscribe to packet counter if needed

            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateNotificationStateFor characteristic: CBCharacteristic,
                   error: Error?) {
        if let error = error {
            print("❌ Error subscribing: \(error.localizedDescription)")
            return
        }

        if characteristic.uuid == MeshtasticService.fromRadioUUID {
            if characteristic.isNotifying {
                print("✅ Subscribed to position updates")
                DispatchQueue.main.async {
                    self.connectionState = .ready
                }

                // Request initial node database
                requestNodeDatabase()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        if let error = error {
            print("❌ Error receiving data: \(error.localizedDescription)")
            return
        }

        guard characteristic.uuid == MeshtasticService.fromRadioUUID,
              let data = characteristic.value else { return }

        lastPacketReceived = Date()

        // Parse the protobuf packet
        parseFromRadioPacket(data)
    }

    // MARK: - Packet Parsing

    /// Parse incoming FROM_RADIO protobuf packet
    private func parseFromRadioPacket(_ data: Data) {
        print("📦 Received packet: \(data.count) bytes")

        do {
            // Decode FromRadio protobuf wrapper
            let fromRadio = try FromRadio(serializedData: data)

            // Handle different payload types
            if case .packet(let meshPacket)? = fromRadio.payloadVariant {
                handleMeshPacket(meshPacket)
            } else if case .nodeInfo(let nodeInfo)? = fromRadio.payloadVariant {
                handleNodeInfo(nodeInfo)
            } else if case .myInfo(let myInfo)? = fromRadio.payloadVariant {
                print("📱 My Node ID: \(myInfo.myNodeNum)")
            } else {
                print("ℹ️ Other packet type received")
            }
        } catch {
            print("❌ Error parsing protobuf: \(error)")
            let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
            print("   Raw data: \(hexString)")
        }
    }

    /// Handle MeshPacket (contains position/telemetry/messages)
    private func handleMeshPacket(_ meshPacket: MeshPacket) {
        guard meshPacket.hasDecoded else {
            print("⚠️ Encrypted packet (no decoded data)")
            return
        }

        let decoded = meshPacket.decoded
        let portNum = decoded.portnum

        // Check if this is a position packet
        if portNum == .positionApp {
            parsePositionPacket(decoded.payload, from: meshPacket.from)
        } else if portNum == .nodeInfoApp {
            print("📋 NodeInfo packet from \(meshPacket.from)")
        } else if portNum == .telemetryApp {
            parseTelemetryPacket(decoded.payload, from: meshPacket.from)
        } else {
            print("📨 Packet type: \(portNum) from \(meshPacket.from)")
        }
    }

    /// Parse position packet and update node database
    private func parsePositionPacket(_ payload: Data, from nodeNum: UInt32) {
        do {
            let position = try Position(serializedData: payload)

            // Convert from integer format (degrees × 10^7)
            let latitude = Double(position.latitudeI) / 1e7
            let longitude = Double(position.longitudeI) / 1e7
            let altitude = Double(position.altitude)

            // Create/update MeshNode
            let nodeID = String(format: "!%08x", nodeNum)
            var node = knownNodes[nodeID] ?? MeshNode(
                id: nodeID,
                num: nodeNum,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                shortName: nodeID,
                longName: "Unknown"
            )

            // Update position
            node.latitude = latitude
            node.longitude = longitude
            node.altitude = altitude
            node.lastHeard = Date()

            if position.time > 0 {
                node.timestamp = Date(timeIntervalSince1970: TimeInterval(position.time))
            }

            // Store updated node
            knownNodes[nodeID] = node

            // Notify callback
            DispatchQueue.main.async {
                self.onNodeUpdate?(node)
            }

            print("📍 Position: \(node.shortName) at (\(latitude), \(longitude)) alt: \(Int(altitude))m")
        } catch {
            print("❌ Error parsing position: \(error)")
        }
    }

    /// Handle NodeInfo packet (contains user details)
    private func handleNodeInfo(_ nodeInfo: NodeInfo) {
        let nodeNum = nodeInfo.num
        let user = nodeInfo.user
        let position = nodeInfo.hasPosition ? nodeInfo.position : nil

        let nodeID = String(format: "!%08x", nodeNum)

        // Get existing node or create new one
        var node = knownNodes[nodeID] ?? MeshNode(
            id: nodeID,
            num: nodeNum,
            latitude: 0,
            longitude: 0,
            altitude: 0,
            shortName: user.shortName,
            longName: user.longName
        )

        // Update user info
        node.shortName = user.shortName.isEmpty ? nodeID : user.shortName
        node.longName = user.longName.isEmpty ? node.shortName : user.longName
        node.hwModel = "\(user.hwModel)"

        // Update position if available
        if let pos = position, pos.hasLatitudeI && pos.hasLongitudeI {
            node.latitude = Double(pos.latitudeI) / 1e7
            node.longitude = Double(pos.longitudeI) / 1e7
            node.altitude = Double(pos.altitude)
            if pos.time > 0 {
                node.timestamp = Date(timeIntervalSince1970: TimeInterval(pos.time))
            }
        }

        // Update SNR and lastHeard
        if nodeInfo.hasSnr {
            node.snr = nodeInfo.snr
        }
        node.lastHeard = Date()

        // Store updated node
        knownNodes[nodeID] = node

        // Notify callback
        DispatchQueue.main.async {
            self.onNodeUpdate?(node)
        }

        print("👤 NodeInfo: \(node.longName) (\(node.shortName)) - HW: \(node.hwModel)")
    }

    /// Parse telemetry packet (battery, temperature, etc.)
    private func parseTelemetryPacket(_ payload: Data, from nodeNum: UInt32) {
        // Implementation would parse Telemetry protobuf
        // For now, just log receipt
        let nodeID = String(format: "!%08x", nodeNum)
        print("📊 Telemetry from \(nodeID)")

        // Could parse battery level, temperature, etc. and update MeshNode
    }

    /// Send data to Meshtastic device (for future commands)
    func sendToRadio(_ data: Data) {
        guard let characteristic = toRadioCharacteristic,
              let peripheral = connectedDevice else {
            print("⚠️  Cannot send - not connected")
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBManagerState Extension (reuse from GarminService if needed)

extension CBCentralManagerState {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Unknown State"
        }
    }
}
