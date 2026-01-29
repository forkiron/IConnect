//
//  PinArtViewModel.swift
//  IConnect
//
//  3D pin art: grid of depths driven by multi-touch + pressure. Pins extend "back" (z) from pressure.
//

import OpenMultitouchSupport
import SwiftUI

@MainActor
final class PinArtViewModel: ObservableObject {
    /// Grid dimensions (pins)
    static let gridWidth = 48
    static let gridHeight = 32
    
    /// Depth per pin [0, 1]. Row-major: index = y * width + x.
    @Published private(set) var depths: [Float]
    
    /// Pressure scale: raw pressure * this = depth contribution (clamped to 1).
    private let pressureScale: Float = 0.015
    /// Falloff radius in grid cells (how many pins one touch affects).
    private let touchRadius: Int = 4
    /// Decay per update (0–1). Higher = pins spring back faster.
    private let decayRate: Float = 0.92
    
    private let manager = OMSManager.shared
    private var task: Task<Void, Never>?
    private var decayTask: Task<Void, Never>?
    
    init() {
        depths = Array(repeating: 0, count: Self.gridWidth * Self.gridHeight)
    }
    
    func startListening() {
        if manager.startListening() {
            task = Task { [weak self, manager] in
                for await touchData in manager.touchDataStream {
                    await MainActor.run {
                        self?.processTouchData(touchData)
                    }
                }
            }
            startDecay()
        }
    }
    
    func stopListening() {
        task?.cancel()
        decayTask?.cancel()
        if manager.stopListening() {
            decayTask = nil
        }
    }
    
    private func startDecay() {
        decayTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_666_667) // ~60 fps
                await MainActor.run {
                    self?.tickDecay()
                }
            }
        }
    }
    
    private func processTouchData(_ touchData: [OMSTouchData]) {
        for touch in touchData {
            let x = Float(touch.position.x)
            let y = Float(1.0 - touch.position.y)
            let pressure = Float(touch.pressure)
            let depth = min(1.0, pressure * pressureScale)
            applyTouch(x: x, y: y, depth: depth)
        }
    }
    
    /// Apply a touch at normalized (x,y) 0–1 with depth 0–1. Affects pins in radius with falloff.
    private func applyTouch(x: Float, y: Float, depth: Float) {
        let px = Int(x * Float(Self.gridWidth))
        let py = Int(y * Float(Self.gridHeight))
        let cx = min(max(px, 0), Self.gridWidth - 1)
        let cy = min(max(py, 0), Self.gridHeight - 1)
        
        for dy in -touchRadius...touchRadius {
            for dx in -touchRadius...touchRadius {
                let gx = cx + dx
                let gy = cy + dy
                guard gx >= 0, gx < Self.gridWidth, gy >= 0, gy < Self.gridHeight else { continue }
                let dist = sqrt(Float(dx * dx + dy * dy))
                guard dist <= Float(touchRadius) else { continue }
                let falloff = 1.0 - (dist / Float(touchRadius)) * 0.6
                let idx = gy * Self.gridWidth + gx
                let add = depth * falloff
                depths[idx] = min(1.0, depths[idx] + add)
            }
        }
    }
    
    private func tickDecay() {
        for i in depths.indices {
            depths[i] *= decayRate
            if depths[i] < 0.005 { depths[i] = 0 }
        }
    }
    
    func depthAt(x: Int, y: Int) -> Float {
        guard x >= 0, x < Self.gridWidth, y >= 0, y < Self.gridHeight else { return 0 }
        return depths[y * Self.gridWidth + x]
    }
    
    deinit {
        task?.cancel()
        decayTask?.cancel()
        manager.stopListening()
    }
}
