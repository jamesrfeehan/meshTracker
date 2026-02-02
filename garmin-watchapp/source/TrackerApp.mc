import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy as Ble;

/**
 * Main application class for Mesh Tracker
 * Handles app lifecycle and BLE initialization
 */
class TrackerApp extends Application.AppBase {

    private var _bleManager as BLEManager?;
    private var _view as TrackerView?;

    /**
     * Constructor
     */
    function initialize() {
        AppBase.initialize();
    }

    /**
     * Handle app startup
     * @param state Startup state
     */
    function onStart(state as Dictionary?) as Void {
        // Initialize BLE manager
        _bleManager = new BLEManager();

        // Start scanning for iOS bridge
        _bleManager.startScanning();
    }

    /**
     * Handle app stop
     * @param state Stop state
     */
    function onStop(state as Dictionary?) as Void {
        // Clean up BLE connection
        if (_bleManager != null) {
            _bleManager.disconnect();
            _bleManager = null;
        }
    }

    /**
     * Return the initial view
     * @return Array [View, Delegate]
     */
    function getInitialView() as Array<Views or InputDelegates>? {
        _view = new TrackerView(_bleManager);
        return [_view, new TrackerDelegate(_view, _bleManager)] as Array<Views or InputDelegates>;
    }

    /**
     * Get BLE manager instance
     * @return BLE manager
     */
    function getBLEManager() as BLEManager {
        return _bleManager;
    }

    /**
     * Handle settings changes
     * @return true if settings changed
     */
    function onSettingsChanged() as Void {
        // Reload settings
        if (_view != null) {
            _view.onSettingsChanged();
        }
    }
}

/**
 * Delegate for handling input
 */
class TrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TrackerView;
    private var _bleManager as BLEManager;

    /**
     * Constructor
     * @param view The tracker view
     * @param bleManager BLE manager
     */
    function initialize(view as TrackerView, bleManager as BLEManager) {
        BehaviorDelegate.initialize();
        _view = view;
        _bleManager = bleManager;
    }

    /**
     * Handle menu button press
     * @return true if handled
     */
    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Tracker"});

        menu.addItem(new WatchUi.MenuItem(
            "Reconnect",
            "Scan for bridge",
            :reconnect,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Select Target",
            "Choose node",
            :select_target,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Settings",
            "App settings",
            :settings,
            {}
        ));

        WatchUi.pushView(menu, new TrackerMenuDelegate(_view, _bleManager), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    /**
     * Handle select button
     * @return true if handled
     */
    function onSelect() as Boolean {
        // Toggle between views or refresh connection
        _bleManager.requestUpdate();
        return true;
    }

    /**
     * Handle back button
     * @return true if handled
     */
    function onBack() as Boolean {
        // Exit app
        return false;
    }
}

/**
 * Menu delegate
 */
class TrackerMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as TrackerView;
    private var _bleManager as BLEManager;

    function initialize(view as TrackerView, bleManager as BLEManager) {
        Menu2InputDelegate.initialize();
        _view = view;
        _bleManager = bleManager;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();

        if (id == :reconnect) {
            _bleManager.disconnect();
            _bleManager.startScanning();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :select_target) {
            // Show target selection menu
            // TODO: Implement node list
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :settings) {
            // Open settings
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

/**
 * App entry point
 */
function getApp() as TrackerApp {
    return Application.getApp() as TrackerApp;
}
