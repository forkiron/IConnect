//
//  BluetoothManager.swift
//  IConnect
//
//  Finds preexisting paired headphone/audio devices and connects. Turns Bluetooth on first if off
//  (via blueutil when available), then uses BluetoothConnector CLI or IOBluetooth.
//

import Foundation
import AppKit

#if os(macOS)
import IOBluetooth
#endif

/// Bluetooth Class of Device: Major class 0x04 = Audio (headphones, earbuds, etc.)
private let kBluetoothDeviceClassMajorAudio: UInt32 = 0x04
private let kBluetoothDeviceClassMajorMask: UInt32 = 0x1F

/// Address format for BluetoothConnector CLI: dashes (00-00-00-00-00-00). IOBluetooth may return colons.
private func addressForCLI(_ addressString: String?) -> String? {
    guard let s = addressString, !s.isEmpty else { return nil }
    return s.replacingOccurrences(of: ":", with: "-")
}

@MainActor
final class BluetoothManager: ObservableObject {
    @Published var pairedDeviceNames: [String] = []
    @Published var isConnecting = false
    @Published var lastError: String?
    @Published var bluetoothWasOff = false
    
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
    
    /// Returns true if Bluetooth is powered on. Uses blueutil if available, else plist.
    func isBluetoothPoweredOn() -> Bool {
        if let on = blueutilPowerState() { return on }
        return bluetoothPowerStateFromPlist()
    }
    
    /// Turn Bluetooth on. Uses blueutil -p 1 if installed, else opens System Settings.
    func turnBluetoothOn() {
        bluetoothWasOff = true
        if runBlueutil(power: 1) {
            lastError = "Bluetooth turned on. Tap Connect again to connect headphones."
            return
        }
        lastError = "Turn on Bluetooth in System Settings, then tap Connect again."
        openBluetoothSettings()
    }
    
    /// Connect to a preexisting paired headphone/audio device. Turns Bluetooth on first if off, then connects.
    func connectToHeadphones() {
        lastError = nil
        bluetoothWasOff = false
        isConnecting = true
        defer { isConnecting = false }
        
        #if os(macOS)
        if !isBluetoothPoweredOn() {
            turnBluetoothOn()
            return
        }
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            openBluetoothSettings()
            return
        }
        let audioDevices = paired.filter { device in
            let major = (device.classOfDevice >> 8) & kBluetoothDeviceClassMajorMask
            return major == kBluetoothDeviceClassMajorAudio
        }
        let deviceToUse = audioDevices.first(where: { !$0.isConnected() }) ?? audioDevices.first
        guard let device = deviceToUse else {
            openBluetoothSettings()
            return
        }
        if let address = addressForCLI(device.addressString), runBluetoothConnector(connect: address) {
            return
        }
        device.openConnection(nil)
        #else
        openBluetoothSettings()
        #endif
    }
    
    /// Run BluetoothConnector CLI (brew install bluetoothconnector). Returns true if launched successfully.
    private func runBluetoothConnector(connect address: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["BluetoothConnector", "--connect", address, "--notify"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Connect to a paired device by name (fallback). Tries BluetoothConnector first if we have an address.
    func connect(toDeviceName name: String) {
        lastError = nil
        isConnecting = true
        defer { isConnecting = false }
        
        #if os(macOS)
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
              let device = paired.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(name) || ($0.addressString ?? "").contains(name) }) else {
            connectToHeadphones()
            return
        }
        if let address = addressForCLI(device.addressString), runBluetoothConnector(connect: address) {
            return
        }
        if !device.isConnected() {
            device.openConnection(nil)
        }
        #else
        connectToHeadphones()
        #endif
    }
    
    /// Open System Settings > Bluetooth (main Bluetooth pane with on/off toggle).
    func openBluetoothSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.BluetoothSettings",
            "x-apple.systempreferences:com.apple.preference.bluetooth",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"
        ]
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            NSWorkspace.shared.open(url)
            return
        }
    }
    
    // MARK: - Bluetooth power state (blueutil or plist)
    
    /// Run blueutil -p and parse "Power: 1" or "Power: 0". Returns nil if blueutil not installed.
    private func blueutilPowerState() -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["blueutil", "-p"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let out = String(data: data, encoding: .utf8) else { return nil }
        if out.contains("Power: 1") { return true }
        if out.contains("Power: 0") { return false }
        return nil
    }
    
    /// Read Bluetooth power from system plist. Returns true if on or unreadable (assume on).
    private func bluetoothPowerStateFromPlist() -> Bool {
        let path = "/Library/Preferences/com.apple.Bluetooth.plist"
        guard let plist = NSDictionary(contentsOfFile: path),
              let state = plist["ControllerPowerState"] as? Int else { return true }
        return state == 1
    }
    
    /// Run blueutil -p <0|1>. Returns true if exit code 0.
    private func runBlueutil(power: Int) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["blueutil", "-p", "\(power)"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return false }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
