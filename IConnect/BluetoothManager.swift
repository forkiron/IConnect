//
//  BluetoothManager.swift
//  IConnect
//
//  Lists paired Bluetooth devices and connects by name when you weigh a gadget (e.g. AirPods).
//

import Foundation
import AppKit

#if os(macOS)
import IOBluetooth
#endif

@MainActor
final class BluetoothManager: ObservableObject {
    @Published var pairedDeviceNames: [String] = []
    @Published var isConnecting = false
    @Published var lastError: String?
    
    init() {}
    
    /// Refresh list of paired Bluetooth device names.
    func refreshPairedDevices() {
        lastError = nil
        #if os(macOS)
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            pairedDeviceNames = []
            return
        }
        pairedDeviceNames = paired.map { $0.name ?? $0.addressString }
        #else
        pairedDeviceNames = []
        #endif
    }
    
    /// Connect to a paired device by name (e.g. "John's AirPods"). Opens Bluetooth prefs if not found.
    func connect(toDeviceName name: String) {
        lastError = nil
        isConnecting = true
        defer { isConnecting = false }
        
        #if os(macOS)
        if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
           let device = paired.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(name) || ($0.addressString ?? "").contains(name) }) {
            if device.isConnected() { return }
            device.openConnection(nil)
            return
        }
        #endif
        openBluetoothPreferences()
    }
    
    /// Open System Preferences > Bluetooth for manual connect.
    func openBluetoothPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!
        NSWorkspace.shared.open(url)
    }
}
