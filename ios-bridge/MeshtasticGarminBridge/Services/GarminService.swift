import Foundation
import CoreBluetooth

/// BLE Peripheral service that broadcasts position data to Garmin watches
/// Similar to Nordic's BLE Peripheral role
class GarminService: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isAdvertising = false
    @Published var connectedCentrals: [CBCentral] = []
    @Published var lastUpdate: Date?

    // MARK: - BLE Service/Characteristic UUIDs
    static let serviceUUID = CBUUID(string: "D8F8A001-MESH-4000-8000-00805F9B34FB")
    static let positionCharUUID = CBUUID(string: "D8F8A002-MESH-4000-8000-00805F9B34FB")
    static let nodeListCharUUID = CBUUID(string: "D8F8A003-MESH-4000-8000-00805F9B34FB")

    // MARK: - BLE Components
    private var peripheralManager: CBPeripheralManager!
    private var positionCharacteristic: CBMutableCharacteristic!
    private var nodeListCharacteristic: CBMutableCharacteristic!

    // MARK: - Initialization
    override init() {
        super.init()
        setupPeripheralManager()
    }

    private func setupPeripheralManager() {
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: "MeshtasticGarminBridge"
            ]
        )
    }

    // MARK: - Public API

    /// Update position for a specific node
    /// This is what you'll call when you receive Meshtastic position updates
    func updateNodePosition(_ node: MeshNode) {
        guard peripheralManager.state == .poweredOn else {
            print("⚠️  Peripheral not powered on")
            return
        }

        let packet = createPositionPacket(for: node)
        updateCharacteristic(positionCharacteristic, with: packet)
        lastUpdate = Date()

        print("📡 Updated position for \(node.shortName): \(node.latitude), \(node.longitude)")
    }

    /// Update list of all nodes (for multi-node tracking)
    func updateNodeList(_ nodes: [MeshNode], relativeTo myLocation: CLLocation) {
        guard peripheralManager.state == .poweredOn else { return }

        let packet = createNodeListPacket(nodes: nodes, relativeTo: myLocation)
        updateCharacteristic(nodeListCharacteristic, with: packet)
    }

    // MARK: - Packet Creation

    /// Create 20-byte position packet for Garmin
    /// Format matches C struct in README
    private func createPositionPacket(for node: MeshNode) -> Data {
        var data = Data(capacity: 20)

        // Node ID (4 bytes)
        var nodeId = node.id
        data.append(Data(bytes: &nodeId, count: 4))

        // Latitude (4 bytes, float)
        var lat = Float(node.latitude)
        data.append(Data(bytes: &lat, count: 4))

        // Longitude (4 bytes, float)
        var lon = Float(node.longitude)
        data.append(Data(bytes: &lon, count: 4))

        // Altitude (2 bytes, int16)
        var alt = node.altitude
        data.append(Data(bytes: &alt, count: 2))

        // Timestamp (4 bytes, uint32)
        var timestamp = UInt32(node.timestamp.timeIntervalSince1970)
        data.append(Data(bytes: &timestamp, count: 4))

        // Battery (1 byte)
        data.append(node.batteryLevel)

        // SNR (1 byte, signed)
        var snr = node.snr
        data.append(Data(bytes: &snr, count: 1))

        assert(data.count == 20, "Position packet must be exactly 20 bytes")
        return data
    }

    /// Create node list packet (12 bytes per node)
    private func createNodeListPacket(nodes: [MeshNode], relativeTo myLocation: CLLocation) -> Data {
        var data = Data()

        for node in nodes.prefix(10) { // Max 10 nodes = 120 bytes
            // Node ID (4 bytes)
            var nodeId = node.id
            data.append(Data(bytes: &nodeId, count: 4))

            // Distance (4 bytes, float, meters)
            var distance = Float(node.distance(to: myLocation))
            data.append(Data(bytes: &distance, count: 4))

            // Bearing (2 bytes, int16, degrees)
            var bearing = Int16(node.bearing(to: myLocation))
            data.append(Data(bytes: &bearing, count: 2))

            // Last seen (2 bytes, uint16, seconds ago)
            var lastSeen = UInt16(min(node.age, 65535))
            data.append(Data(bytes: &lastSeen, count: 2))
        }

        return data
    }

    /// Update characteristic and notify subscribers
    private func updateCharacteristic(_ characteristic: CBMutableCharacteristic, with data: Data) {
        let didUpdate = peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil // Notify all subscribed centrals
        )

        if !didUpdate {
            print("⚠️  Update failed - queue full, will retry")
            // In production, implement retry logic
        }
    }

    // MARK: - Advertising

    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            print("⚠️  Cannot advertise - Bluetooth not powered on")
            return
        }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [GarminService.serviceUUID],
            CBAdvertisementDataLocalNameKey: "Meshtastic Bridge"
        ]

        peripheralManager.startAdvertising(advertisementData)
        print("📢 Started advertising Garmin service")
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        isAdvertising = false
        print("🛑 Stopped advertising")
    }
}

// MARK: - CBPeripheralManagerDelegate

extension GarminService: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("📱 Peripheral state: \(peripheral.state.description)")

        switch peripheral.state {
        case .poweredOn:
            setupService()
        case .poweredOff:
            isAdvertising = false
        case .unsupported:
            print("❌ BLE not supported on this device")
        case .unauthorized:
            print("❌ BLE not authorized")
        case .resetting:
            print("🔄 BLE resetting")
        default:
            break
        }
    }

    private func setupService() {
        // Create characteristics
        positionCharacteristic = CBMutableCharacteristic(
            type: GarminService.positionCharUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        nodeListCharacteristic = CBMutableCharacteristic(
            type: GarminService.nodeListCharUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        // Create service
        let service = CBMutableService(type: GarminService.serviceUUID, primary: true)
        service.characteristics = [positionCharacteristic, nodeListCharacteristic]

        // Add service to peripheral
        peripheralManager.add(service)
        print("✅ Added Garmin BLE service")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error adding service: \(error.localizedDescription)")
            return
        }

        print("✅ Service added successfully: \(service.uuid)")
        startAdvertising()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("❌ Error advertising: \(error.localizedDescription)")
            return
        }

        DispatchQueue.main.async {
            self.isAdvertising = true
        }
        print("✅ Advertising started")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral,
                          didSubscribeTo characteristic: CBCharacteristic) {
        print("✅ Central subscribed: \(central.identifier)")
        DispatchQueue.main.async {
            if !self.connectedCentrals.contains(where: { $0.identifier == central.identifier }) {
                self.connectedCentrals.append(central)
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral,
                          didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("👋 Central unsubscribed: \(central.identifier)")
        DispatchQueue.main.async {
            self.connectedCentrals.removeAll { $0.identifier == central.identifier }
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("✅ Ready to send more data")
        // Implement queued updates if needed
    }
}

// MARK: - CBManagerState Extension

extension CBManagerState: CustomStringConvertible {
    public var description: String {
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
