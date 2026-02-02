import Foundation
import CoreLocation
import Combine

/// Coordinates data flow between Meshtastic (BLE Central) and Garmin (BLE Peripheral)
/// This is the "brain" that connects the two BLE services
class BridgeCoordinator: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isActive = false
    @Published var trackedNodes: [MeshNode] = []
    @Published var selectedNodeId: UInt32?
    @Published var statistics = BridgeStatistics()

    struct BridgeStatistics {
        var packetsReceived: Int = 0
        var packetsForwarded: Int = 0
        var lastForwardTime: Date?
        var connectedGarminDevices: Int = 0
    }

    // MARK: - Services
    let meshtasticService: MeshtasticService
    let garminService: GarminService
    let locationManager: CLLocationManager

    // MARK: - Settings
    var maxDistanceFilter: Double = 10000.0  // 10km - only track nodes within this range
    var maxAge: TimeInterval = 1800          // 30 minutes - ignore stale nodes
    var updateInterval: TimeInterval = 5.0   // Minimum seconds between updates to Garmin
    var autoSelectClosest = true             // Auto-select closest node for tracking

    // MARK: - Internal State
    private var lastUpdateTime: [UInt32: Date] = [:]
    private var myLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(meshtasticService: MeshtasticService = MeshtasticService(),
         garminService: GarminService = GarminService()) {
        self.meshtasticService = meshtasticService
        self.garminService = garminService
        self.locationManager = CLLocationManager()

        super.init()

        setupLocationManager()
        setupMeshtasticCallback()
        setupGarminObservers()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func setupMeshtasticCallback() {
        // Called whenever Meshtastic receives a position update
        meshtasticService.onNodeUpdate = { [weak self] node in
            self?.handleNodeUpdate(node)
        }
    }

    private func setupGarminObservers() {
        // Monitor Garmin connections
        garminService.$connectedCentrals
            .sink { [weak self] centrals in
                self?.statistics.connectedGarminDevices = centrals.count
                print("📊 Garmin watches connected: \(centrals.count)")
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Start the bridge (connect both services)
    func start() {
        guard !isActive else { return }

        print("🌉 Starting Meshtastic → Garmin bridge")

        // Start Garmin advertising
        garminService.startAdvertising()

        // Start Meshtastic scanning
        meshtasticService.startScanning()

        isActive = true
    }

    /// Stop the bridge
    func stop() {
        guard isActive else { return }

        print("🛑 Stopping bridge")

        garminService.stopAdvertising()
        meshtasticService.disconnect()
        meshtasticService.stopScanning()

        isActive = false
    }

    /// Connect to a specific Meshtastic device
    func connectToMeshtastic(_ peripheral: CBPeripheral) {
        meshtasticService.connect(to: peripheral)
    }

    /// Select a specific node to track
    func selectNode(_ nodeId: UInt32) {
        selectedNodeId = nodeId
        autoSelectClosest = false

        if let node = trackedNodes.first(where: { $0.id == nodeId }) {
            updateGarminForNode(node)
            print("🎯 Selected node: \(node.shortName)")
        }
    }

    /// Clear node selection (return to auto mode)
    func clearNodeSelection() {
        selectedNodeId = nil
        autoSelectClosest = true
        print("🔄 Auto-select mode enabled")
    }

    // MARK: - Node Update Handling

    private func handleNodeUpdate(_ node: MeshNode) {
        print("📍 Received position for \(node.shortName): \(node.latitude), \(node.longitude)")

        statistics.packetsReceived += 1

        // Update or add node to tracked list
        if let index = trackedNodes.firstIndex(where: { $0.id == node.id }) {
            trackedNodes[index] = node
        } else {
            trackedNodes.append(node)
        }

        // Filter stale nodes
        filterStaleNodes()

        // Apply distance filter if we have location
        if let myLoc = myLocation {
            filterDistantNodes(relativeTo: myLoc)
        }

        // Decide which node to forward to Garmin
        if shouldUpdateGarmin(for: node) {
            if let targetNode = getNodeToForward() {
                updateGarminForNode(targetNode)
            }
        }
    }

    /// Check if we should forward this update to Garmin
    private func shouldUpdateGarmin(for node: MeshNode) -> Bool {
        // Rate limiting - don't spam Garmin watch
        if let lastUpdate = lastUpdateTime[node.id] {
            let elapsed = Date().timeIntervalSince(lastUpdate)
            if elapsed < updateInterval {
                return false  // Too soon
            }
        }

        return true
    }

    /// Determine which node to forward to Garmin
    private func getNodeToForward() -> MeshNode? {
        // If user selected specific node, use that
        if let nodeId = selectedNodeId {
            return trackedNodes.first { $0.id == nodeId }
        }

        // Auto mode: find closest node
        if autoSelectClosest, let myLoc = myLocation {
            return trackedNodes.min(by: { node1, node2 in
                let dist1 = node1.distance(to: myLoc)
                let dist2 = node2.distance(to: myLoc)
                return dist1 < dist2
            })
        }

        // Fallback: most recently updated
        return trackedNodes.max(by: { $0.timestamp < $1.timestamp })
    }

    /// Forward node position to Garmin watches
    private func updateGarminForNode(_ node: MeshNode) {
        garminService.updateNodePosition(node)

        lastUpdateTime[node.id] = Date()
        statistics.packetsForwarded += 1
        statistics.lastForwardTime = Date()

        print("→ Forwarded to Garmin: \(node.shortName)")

        // Also update node list (for multi-node display)
        if let myLoc = myLocation {
            garminService.updateNodeList(trackedNodes, relativeTo: myLoc)
        }
    }

    // MARK: - Filtering

    /// Remove nodes that haven't been heard from recently
    private func filterStaleNodes() {
        let beforeCount = trackedNodes.count
        trackedNodes.removeAll { $0.isStale }

        if trackedNodes.count < beforeCount {
            print("🧹 Removed \(beforeCount - trackedNodes.count) stale nodes")
        }
    }

    /// Remove nodes beyond max distance
    private func filterDistantNodes(relativeTo location: CLLocation) {
        let beforeCount = trackedNodes.count

        trackedNodes.removeAll { node in
            let distance = node.distance(to: location)
            return distance > maxDistanceFilter
        }

        if trackedNodes.count < beforeCount {
            print("🧹 Removed \(beforeCount - trackedNodes.count) distant nodes")
        }
    }

    // MARK: - Statistics

    func getStatisticsSummary() -> String {
        """
        Bridge Statistics:
        - Packets received: \(statistics.packetsReceived)
        - Packets forwarded: \(statistics.packetsForwarded)
        - Tracked nodes: \(trackedNodes.count)
        - Garmin watches: \(statistics.connectedGarminDevices)
        - Last update: \(statistics.lastForwardTime?.formatted() ?? "Never")
        """
    }
}

// MARK: - CLLocationManagerDelegate

extension BridgeCoordinator: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        myLocation = location

        // Refilter nodes based on new location
        filterDistantNodes(relativeTo: location)

        // Update Garmin with new relative distances
        if !trackedNodes.isEmpty {
            garminService.updateNodeList(trackedNodes, relativeTo: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️  Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location authorized")
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ Location access denied")
        case .notDetermined:
            print("⏳ Location authorization pending")
        @unknown default:
            break
        }
    }
}

// MARK: - CBPeripheral Import
import CoreBluetooth
