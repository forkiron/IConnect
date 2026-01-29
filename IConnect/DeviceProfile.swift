//
//  DeviceProfile.swift
//  IConnect
//
//  Weight range → Bluetooth device name. When scale weight matches, we suggest auto-connect.
//

import Foundation

struct DeviceProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String           // e.g. "AirPods case"
    var weightMin: Float       // grams
    var weightMax: Float       // grams
    /// Search term for Bluetooth (e.g. "AirPods" so we match "John's AirPods"). If nil, uses first word of name.
    var bluetoothSearchTerm: String?
    
    init(id: UUID = UUID(), name: String, weightMin: Float, weightMax: Float, bluetoothSearchTerm: String? = nil) {
        self.id = id
        self.name = name
        self.weightMin = weightMin
        self.weightMax = weightMax
        self.bluetoothSearchTerm = bluetoothSearchTerm ?? name.components(separatedBy: " ").first ?? name
    }
    
    func matches(weight: Float) -> Bool {
        weight >= weightMin && weight <= weightMax
    }
    
    var bluetoothConnectSearchTerm: String { bluetoothSearchTerm ?? name }
    
    /// Built-in presets for common gadgets (approximate weights in grams).
    static let presets: [DeviceProfile] = [
        DeviceProfile(name: "AirPods case", weightMin: 38, weightMax: 52, bluetoothSearchTerm: "AirPods"),
        DeviceProfile(name: "AirPods Pro case", weightMin: 45, weightMax: 58, bluetoothSearchTerm: "AirPods"),
        DeviceProfile(name: "Small earbuds case", weightMin: 25, weightMax: 45, bluetoothSearchTerm: nil),
        DeviceProfile(name: "USB stick", weightMin: 5, weightMax: 25, bluetoothSearchTerm: nil),
    ]
}
