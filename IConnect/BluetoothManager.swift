//
//  BluetoothManager.swift
//  IConnect
//
//  Finds preexisting paired headphone/audio devices and connects to them.
//

import Foundation
import AppKit

#if os(macOS)
import IOBluetooth
#endif

/// Bluetooth Class of Device: Major class 0x04 = Audio (headphones, earbuds, etc.)
private let kBluetoothDeviceClassMajorAudio: UInt32 = 0x04
private let kBluetoothDeviceClassMajorMask: UInt32 = 0x1F

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
    
    /// Connect to a preexisting paired headphone/audio device. Picks first disconnected audio device and connects.
    func connectToHeadphones() {
        lastError = nil
        isConnecting = true
        defer { isConnecting = false }
        
        #if os(macOS)
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            openBluetoothPreferences()
            return
        }
        let audioDevices = paired.filter { device in
            let major = (device.classOfDevice >> 8) & kBluetoothDeviceClassMajorMask
            return major == kBluetoothDeviceClassMajorAudio
        }
        if let device = audioDevices.first(where: { !$0.isConnected() }) {
            device.openConnection(nil)
            return
        }
        if let device = audioDevices.first {
            device.openConnection(nil)
            return
        }
        #endif
        openBluetoothPreferences()
    }
    
    /// Connect to a paired device by name (fallback). Opens Bluetooth prefs if not found.
    func connect(toDeviceName name: String) {
        lastError = nil
        isConnecting = true
        defer { isConnecting = false }
        
        #if os(macOS)
        if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
           let device = paired.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(name) || ($0.addressString ?? "").contains(name) }) {
            if !device.isConnected() {
                device.openConnection(nil)
            }
            return
        }
        #endif
        connectToHeadphones()
    }
    
    /// Open System Preferences > Bluetooth for manual connect.
    func openBluetoothPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!
        NSWorkspace.shared.open(url)
    }
}
