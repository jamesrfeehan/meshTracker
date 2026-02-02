import Toybox.BluetoothLowEnergy as Ble;
import Toybox.Lang;
import Toybox.System;

/**
 * BLE Manager - Handles connection to iOS bridge
 */
class BLEManager {

    // Service and Characteristic UUIDs (must match iOS bridge)
    private const SERVICE_UUID = Ble.stringToUuid("0000181A-0000-1000-8000-00805f9b34fb");
    private const POSITION_CHAR_UUID = Ble.stringToUuid("00002A67-0000-1000-8000-00805f9b34fb");
    private const STATUS_CHAR_UUID = Ble.stringToUuid("00002A68-0000-1000-8000-00805f9b34fb");

    // BLE objects
    private var _device as Ble.Device?;
    private var _profileManager as Ble.ProfileManager?;
    private var _positionChar as Ble.Characteristic?;
    private var _statusChar as Ble.Characteristic?;

    // Connection state
    private var _isScanning as Boolean = false;
    private var _isConnected as Boolean = false;

    // Position data
    private var _latitude as Float = 0.0;
    private var _longitude as Float = 0.0;
    private var _altitude as Number = 0;
    private var _timestamp as Number = 0;
    private var _nodeId as Number = 0;
    private var _snr as Float = 0.0;

    // Status data
    private var _meshConnected as Boolean = false;
    private var _nodesSeen as Number = 0;
    private var _updateCount as Number = 0;

    // Callbacks
    private var _onDataUpdate as Method?;

    /**
     * Constructor
     */
    function initialize() {
        System.println("BLEManager initialized");
    }

    /**
     * Start scanning for iOS bridge
     */
    function startScanning() as Void {
        if (_isScanning) {
            System.println("Already scanning");
            return;
        }

        System.println("Starting BLE scan for iOS bridge...");
        _isScanning = true;

        // Set up scan callback
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);

        // Note: In real implementation, would use:
        // var scanResult = Ble.scanResults();
        // Then iterate through results to find device advertising SERVICE_UUID
    }

    /**
     * Stop scanning
     */
    function stopScanning() as Void {
        if (!_isScanning) {
            return;
        }

        System.println("Stopping BLE scan");
        _isScanning = false;
        Ble.setScanState(Ble.SCAN_STATE_OFF);
    }

    /**
     * Connect to a BLE device
     * @param device The device to connect to
     */
    function connect(device as Ble.Device) as Void {
        System.println("Connecting to device: " + device.getName());

        _device = device;

        // Define the profile we want to use
        var profileDef = {
            Ble.UuidService => SERVICE_UUID,
            Ble.UuidCharacteristic => [
                POSITION_CHAR_UUID,
                STATUS_CHAR_UUID
            ]
        };

        try {
            // Register profile and connect
            _profileManager = Ble.registerProfile(
                device,
                profileDef,
                method(:onProfileRegistered)
            );
        } catch (ex) {
            System.println("Error connecting: " + ex.getErrorMessage());
            _isConnected = false;
        }
    }

    /**
     * Disconnect from current device
     */
    function disconnect() as Void {
        if (_device != null) {
            System.println("Disconnecting from device");
            Ble.unpairDevice(_device);
            _device = null;
            _profileManager = null;
            _isConnected = false;
        }
    }

    /**
     * Callback when profile is registered
     * @param status Registration status
     */
    function onProfileRegistered(status as Ble.Status) as Void {
        System.println("Profile registration status: " + status);

        if (status == Ble.STATUS_SUCCESS) {
            _isConnected = true;

            // Get characteristics
            var service = _profileManager.getService(SERVICE_UUID);
            if (service != null) {
                _positionChar = service.getCharacteristic(POSITION_CHAR_UUID);
                _statusChar = service.getCharacteristic(STATUS_CHAR_UUID);

                // Subscribe to position notifications
                if (_positionChar != null) {
                    _positionChar.enableNotifications();
                    _positionChar.setDescriptor(
                        Ble.stringToUuid("2902"),  // CCCD
                        [0x01, 0x00] as Array<Number>  // Enable notifications
                    );
                    System.println("Subscribed to position updates");
                }

                // Read initial status
                requestUpdate();
            }
        } else {
            _isConnected = false;
            System.println("Failed to register profile");
        }
    }

    /**
     * Request data update
     */
    function requestUpdate() as Void {
        if (!_isConnected) {
            return;
        }

        // Read position
        if (_positionChar != null) {
            var data = _positionChar.read();
            if (data != null) {
                parsePositionData(data);
            }
        }

        // Read status
        if (_statusChar != null) {
            var data = _statusChar.read();
            if (data != null) {
                parseStatusData(data);
            }
        }
    }

    /**
     * Parse position characteristic data
     * Format: [lat(4), lon(4), alt(2), time(4), nodeID(4), snr(2)] = 20 bytes
     * @param data Raw bytes
     */
    private function parsePositionData(data as ByteArray) as Void {
        if (data.size() < 20) {
            System.println("Invalid position data size: " + data.size());
            return;
        }

        // Extract fields (Little Endian)
        _latitude = bytesToFloat(data.slice(0, 4));
        _longitude = bytesToFloat(data.slice(4, 8));
        _altitude = bytesToInt16(data.slice(8, 10));
        _timestamp = bytesToUInt32(data.slice(10, 14));
        _nodeId = bytesToUInt32(data.slice(14, 18));
        _snr = bytesToFloat(data.slice(18, 22));

        System.println("Position update: " + _latitude + ", " + _longitude);

        // Notify callback
        if (_onDataUpdate != null) {
            _onDataUpdate.invoke();
        }
    }

    /**
     * Parse status characteristic data
     * Format: [connected(1), nodes(1), updates(4), battery(2)] = 8 bytes
     * @param data Raw bytes
     */
    private function parseStatusData(data as ByteArray) as Void {
        if (data.size() < 8) {
            return;
        }

        _meshConnected = data[0] != 0;
        _nodesSeen = data[1];
        _updateCount = bytesToUInt32(data.slice(2, 6));

        System.println("Status: connected=" + _meshConnected + ", nodes=" + _nodesSeen);
    }

    // Helper functions for byte conversion

    private function bytesToFloat(bytes as ByteArray) as Float {
        // Convert 4 bytes to float (IEEE 754)
        // This is a simplified implementation
        // Real implementation would use proper bit manipulation
        return 0.0;  // TODO: Implement proper conversion
    }

    private function bytesToInt16(bytes as ByteArray) as Number {
        return (bytes[0] & 0xFF) | ((bytes[1] & 0xFF) << 8);
    }

    private function bytesToUInt32(bytes as ByteArray) as Number {
        return (bytes[0] & 0xFF) |
               ((bytes[1] & 0xFF) << 8) |
               ((bytes[2] & 0xFF) << 16) |
               ((bytes[3] & 0xFF) << 24);
    }

    // Getters

    function isConnected() as Boolean {
        return _isConnected;
    }

    function isScanning() as Boolean {
        return _isScanning;
    }

    function getLatitude() as Float {
        return _latitude;
    }

    function getLongitude() as Float {
        return _longitude;
    }

    function getAltitude() as Number {
        return _altitude;
    }

    function getTimestamp() as Number {
        return _timestamp;
    }

    function getNodeId() as Number {
        return _nodeId;
    }

    function getSNR() as Float {
        return _snr;
    }

    function getMeshConnected() as Boolean {
        return _meshConnected;
    }

    function getNodesSeen() as Number {
        return _nodesSeen;
    }

    function getUpdateCount() as Number {
        return _updateCount;
    }

    /**
     * Set callback for data updates
     * @param callback Method to call on update
     */
    function setOnDataUpdate(callback as Method) as Void {
        _onDataUpdate = callback;
    }
}
