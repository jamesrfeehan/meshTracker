import Foundation
import CoreLocation

/// Represents a Meshtastic node with position and metadata
struct MeshNode: Identifiable, Codable {
    let id: UInt32              // Node ID from Meshtastic
    var shortName: String       // e.g., "paws", "DUO1"
    var longName: String        // e.g., "Dog Tracker", "Skier 1"

    // Position data
    var latitude: Double
    var longitude: Double
    var altitude: Int16
    var timestamp: Date

    // Metadata
    var batteryLevel: UInt8     // 0-100%
    var snr: Int8               // Signal-to-noise ratio
    var lastHeard: Date

    // Computed properties
    var location: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: Double(altitude),
            horizontalAccuracy: 10.0,
            verticalAccuracy: 10.0,
            timestamp: timestamp
        )
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastHeard) > 1800 // 30 minutes
    }

    var age: TimeInterval {
        Date().timeIntervalSince(lastHeard)
    }

    /// Initialize from Meshtastic protobuf packet
    init(nodeId: UInt32, shortName: String, longName: String,
         latitude: Double, longitude: Double, altitude: Int16,
         timestamp: Date, battery: UInt8, snr: Int8) {
        self.id = nodeId
        self.shortName = shortName
        self.longName = longName
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.batteryLevel = battery
        self.snr = snr
        self.lastHeard = Date()
    }

    /// Distance to another location
    func distance(to location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }

    /// Bearing to another location
    func bearing(to location: CLLocation) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = location.coordinate.latitude * .pi / 180
        let dLon = (location.coordinate.longitude - longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension MeshNode {
    /// Example/mock data for testing
    static let example = MeshNode(
        nodeId: 0x12345678,
        shortName: "PAWS",
        longName: "Dog Tracker",
        latitude: 39.5501,
        longitude: -106.0661,
        altitude: 2800,
        timestamp: Date(),
        battery: 67,
        snr: 8
    )

    static let examples: [MeshNode] = [
        MeshNode(nodeId: 1, shortName: "PAWS", longName: "Dog Tracker",
                latitude: 39.5501, longitude: -106.0661, altitude: 2800,
                timestamp: Date(), battery: 67, snr: 8),
        MeshNode(nodeId: 2, shortName: "DUO1", longName: "Skier 1",
                latitude: 39.5505, longitude: -106.0670, altitude: 2850,
                timestamp: Date(), battery: 89, snr: 12),
        MeshNode(nodeId: 3, shortName: "DUO2", longName: "Base Station",
                latitude: 39.5490, longitude: -106.0650, altitude: 2780,
                timestamp: Date(), battery: 100, snr: 15)
    ]
}
