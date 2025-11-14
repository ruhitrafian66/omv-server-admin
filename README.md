# OMV Server Admin

iOS app for managing OpenMediaVault servers on your local network.

## Features

- Server power management (shutdown/restart)
- CPU utilization monitoring (current + hourly history)
- Memory usage monitoring
- File system usage for all disks
- System update checking and installation
- Secure credential storage with auto-connect
- Background monitoring: Checks server availability when connected to "DeadLock" WiFi
- Push notifications when server becomes unavailable
- Drive storage alerts: Notifications when any file system exceeds 90% capacity

## Setup

1. Open the project in Xcode 15+
2. Build and run on iOS 16+ device or simulator
3. Enter your OMV server details on first launch

## Requirements

- iOS 16.0+
- Xcode 15.0+
- OpenMediaVault server on local network


## Background Monitoring

The app monitors your server availability in the background when:
- Your iPhone is connected to the "DeadLock" WiFi network
- The app has been opened at least once
- Notification permissions are granted

iOS will wake the app approximately every 15-30 minutes to check server status. If the server is unreachable, you'll receive a notification.

**Note:** Background monitoring stops if you force-quit the app. Simply open it again to resume monitoring.

## Testing Background Monitoring

To test in Xcode:
1. Run the app on a device
2. Tap the menu (•••) → "Test Background Check"
3. Background the app
4. In Xcode: Debug → Simulate Background Fetch
5. Check console for "Connected to DeadLock, checking server..."

## Xcode Setup

1. Select your target → Signing & Capabilities
2. Add "Background Modes" capability (should already be configured)
3. Ensure "Background fetch" and "Background processing" are checked
4. Add "Access WiFi Information" capability for WiFi SSID detection
