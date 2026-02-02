import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Math;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

/**
 * Main view displaying tracker information
 */
class TrackerView extends WatchUi.View {

    private var _bleManager as BLEManager;

    // Current position
    private var _myLat as Float = 0.0;
    private var _myLon as Float = 0.0;
    private var _myAlt as Number = 0;

    // Calculated values
    private var _distance as Float = 0.0;  // meters
    private var _bearing as Float = 0.0;   // degrees
    private var _altitudeDelta as Number = 0;

    // Display options
    private var _useMetric as Boolean = true;

    /**
     * Constructor
     * @param bleManager BLE manager instance
     */
    function initialize(bleManager as BLEManager) {
        View.initialize();
        _bleManager = bleManager;

        // Set up position callback
        _bleManager.setOnDataUpdate(method(:onDataUpdate));

        // Start position tracking
        Position.enableLocationEvents(
            Position.LOCATION_CONTINUOUS,
            method(:onPosition)
        );

        // Load settings
        loadSettings();
    }

    /**
     * Load settings from app properties
     */
    function loadSettings() as Void {
        var app = Application.getApp();
        var units = app.getProperty("Units");
        _useMetric = (units == null || units.equals("metric"));
    }

    /**
     * Handle settings changed
     */
    function onSettingsChanged() as Void {
        loadSettings();
        WatchUi.requestUpdate();
    }

    /**
     * Called when GPS position updates
     * @param info Position info
     */
    function onPosition(info as Position.Info) as Void {
        if (info.accuracy >= Position.QUALITY_USABLE) {
            var coords = info.position.toDegrees();
            _myLat = coords[0];
            _myLon = coords[1];

            if (info has :altitude && info.altitude != null) {
                _myAlt = info.altitude as Number;
            }

            // Recalculate distance/bearing
            calculateDistanceAndBearing();
            WatchUi.requestUpdate();
        }
    }

    /**
     * Called when BLE data updates
     */
    function onDataUpdate() as Void {
        calculateDistanceAndBearing();
        WatchUi.requestUpdate();
    }

    /**
     * Calculate distance and bearing to target
     */
    private function calculateDistanceAndBearing() as Void {
        var targetLat = _bleManager.getLatitude();
        var targetLon = _bleManager.getLongitude();
        var targetAlt = _bleManager.getAltitude();

        if (targetLat == 0.0 && targetLon == 0.0) {
            return;  // No position data yet
        }

        // Calculate distance using Haversine formula
        _distance = haversineDistance(_myLat, _myLon, targetLat, targetLon);

        // Calculate bearing
        _bearing = calculateBearing(_myLat, _myLon, targetLat, targetLon);

        // Altitude delta
        _altitudeDelta = targetAlt - _myAlt;
    }

    /**
     * Haversine distance formula
     * @param lat1 Starting latitude
     * @param lon1 Starting longitude
     * @param lat2 Ending latitude
     * @param lon2 Ending longitude
     * @return Distance in meters
     */
    private function haversineDistance(
        lat1 as Float,
        lon1 as Float,
        lat2 as Float,
        lon2 as Float
    ) as Float {
        var R = 6371000.0;  // Earth radius in meters

        var dLat = Math.toRadians(lat2 - lat1);
        var dLon = Math.toRadians(lon2 - lon1);

        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) *
                Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);

        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    /**
     * Calculate bearing between two points
     * @param lat1 Starting latitude
     * @param lon1 Starting longitude
     * @param lat2 Ending latitude
     * @param lon2 Ending longitude
     * @return Bearing in degrees (0-360)
     */
    private function calculateBearing(
        lat1 as Float,
        lon1 as Float,
        lat2 as Float,
        lon2 as Float
    ) as Float {
        var dLon = Math.toRadians(lon2 - lon1);
        var lat1Rad = Math.toRadians(lat1);
        var lat2Rad = Math.toRadians(lat2);

        var y = Math.sin(dLon) * Math.cos(lat2Rad);
        var x = Math.cos(lat1Rad) * Math.sin(lat2Rad) -
                Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);

        var bearing = Math.toDegrees(Math.atan2(y, x));
        return (bearing + 360) % 360;  // Normalize to 0-360
    }

    /**
     * Convert bearing to cardinal direction
     * @param bearing Bearing in degrees
     * @return Cardinal direction (N, NE, E, etc.)
     */
    private function bearingToCardinal(bearing as Float) as String {
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        var index = ((bearing + 22.5) / 45).toNumber() % 8;
        return directions[index];
    }

    /**
     * Format distance for display
     * @param meters Distance in meters
     * @return Formatted string
     */
    private function formatDistance(meters as Float) as String {
        if (_useMetric) {
            if (meters < 1000) {
                return meters.format("%.0f") + "m";
            } else {
                return (meters / 1000.0).format("%.2f") + "km";
            }
        } else {
            // Imperial (feet/miles)
            var feet = meters * 3.28084;
            if (feet < 5280) {
                return feet.format("%.0f") + "ft";
            } else {
                return (feet / 5280.0).format("%.2f") + "mi";
            }
        }
    }

    /**
     * Load layout resources
     * @param dc Device context
     */
    function onLayout(dc as Graphics.Dc) as Void {
        // Layout will be defined in XML or programmatically
    }

    /**
     * Update the view
     * @param dc Device context
     */
    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        // Draw status at top
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            5,
            Graphics.FONT_TINY,
            "MESH TRACKER",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (!_bleManager.isConnected()) {
            // Show connection status
            dc.drawText(
                centerX,
                centerY - 20,
                Graphics.FONT_MEDIUM,
                "Searching for",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_MEDIUM,
                "iOS Bridge...",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            if (_bleManager.isScanning()) {
                dc.drawText(
                    centerX,
                    height - 30,
                    Graphics.FONT_TINY,
                    "Scanning...",
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }
        } else {
            // Connected - show tracker info
            drawTrackerInfo(dc, centerX, centerY);
        }
    }

    /**
     * Draw tracker information
     * @param dc Device context
     * @param centerX Center X coordinate
     * @param centerY Center Y coordinate
     */
    private function drawTrackerInfo(
        dc as Graphics.Dc,
        centerX as Number,
        centerY as Number
    ) as Void {
        // Draw compass
        drawCompass(dc, centerX, centerY - 40, 50, _bearing);

        // Draw distance
        var distStr = formatDistance(_distance);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 20,
            Graphics.FONT_NUMBER_MEDIUM,
            distStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw direction
        var cardinalDir = bearingToCardinal(_bearing);
        dc.drawText(
            centerX,
            centerY + 50,
            Graphics.FONT_MEDIUM,
            cardinalDir + " " + _bearing.format("%.0f") + "°",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw altitude delta
        if (_altitudeDelta != 0) {
            var altStr = _altitudeDelta > 0 ? "+" : "";
            altStr += _altitudeDelta.format("%d") + "m";
            dc.drawText(
                centerX,
                centerY + 75,
                Graphics.FONT_TINY,
                altStr,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // Draw status footer
        var statusStr = "SNR:" + _bleManager.getSNR().format("%.1f") + "dB";
        if (_bleManager.getMeshConnected()) {
            statusStr += " | Nodes:" + _bleManager.getNodesSeen();
        }
        dc.drawText(
            centerX,
            dc.getHeight() - 20,
            Graphics.FONT_XTINY,
            statusStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    /**
     * Draw compass rose
     * @param dc Device context
     * @param x Center X
     * @param y Center Y
     * @param radius Compass radius
     * @param bearing Current bearing
     */
    private function drawCompass(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        radius as Number,
        bearing as Float
    ) as Void {
        // Draw compass circle
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, radius);

        // Draw cardinal directions
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - radius - 15, Graphics.FONT_TINY, "N", Graphics.TEXT_JUSTIFY_CENTER);

        // Draw bearing arrow
        var arrowLen = radius - 10;
        var bearingRad = Math.toRadians(bearing - 90);  // -90 to start from top
        var endX = x + (arrowLen * Math.cos(bearingRad));
        var endY = y + (arrowLen * Math.sin(bearingRad));

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(x, y, endX, endY);

        // Draw arrowhead
        var arrowSize = 8;
        var angle1 = bearingRad + Math.toRadians(150);
        var angle2 = bearingRad - Math.toRadians(150);

        var point1X = endX + (arrowSize * Math.cos(angle1));
        var point1Y = endY + (arrowSize * Math.sin(angle1));
        var point2X = endX + (arrowSize * Math.cos(angle2));
        var point2Y = endY + (arrowSize * Math.sin(angle2));

        dc.fillPolygon([
            [endX, endY],
            [point1X, point1Y],
            [point2X, point2Y]
        ]);
    }
}
