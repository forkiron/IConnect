//
//  DeviceProfile.swift
//  IConnect
//
//  Weight range or touch shape (oval) → Bluetooth device. Match by shape (e.g. AirPods oval on trackpad).
//

import Foundation

// MARK: - Shape-based detection (oval shape on trackpad, e.g. AirPods case)
struct ShapeProfile: Identifiable {
    let id = UUID()
    let name: String
    let bluetoothSearchTerm: String
    /// Aspect ratio (major/minor) range for the oval – AirPods case resting on trackpad is elongated.
    let aspectRatioMin: Float
    let aspectRatioMax: Float
    /// Optional: ignore very small touches (noise).
    let minMajor: Float

    func matches(major: Float, minor: Float) -> Bool {
        guard major >= minMajor, minor > 0 else { return false }
        let ratio = major / minor
        return ratio >= aspectRatioMin && ratio <= aspectRatioMax
    }

    static let airPodsOval = ShapeProfile(
        name: "AirPods",
        bluetoothSearchTerm: "AirPods",
        aspectRatioMin: 1.2,
        aspectRatioMax: 4.0,
        minMajor: 3.0
    )
    static let presets: [ShapeProfile] = [.airPodsOval]
}

// MARK: - Weight-based (legacy)
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
