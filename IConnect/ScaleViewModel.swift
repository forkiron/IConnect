//
//  ScaleViewModel.swift
//  IConnect
//

import OpenMultitouchSupport
import SwiftUI
import Combine

@MainActor
final class ScaleViewModel: ObservableObject {
    @Published var currentWeight: Float = 0.0
    @Published var zeroOffset: Float = 0.0
    @Published var isListening = false
    @Published var hasTouch = false
    /// Current touch ellipse shape (major, minor axis) for shape-based device detection.
    @Published var currentTouchShape: (major: Float, minor: Float)? = nil
    
    private let manager = OMSManager.shared
    private var task: Task<Void, Never>?
    private var rawWeight: Float = 0.0
    
    func startListening() {
        if manager.startListening() {
            isListening = true
        }
        
        task = Task { [weak self, manager] in
            for await touchData in manager.touchDataStream {
                await MainActor.run {
                    self?.processTouchData(touchData)
                }
            }
        }
    }
    
    func stopListening() {
        task?.cancel()
        if manager.stopListening() {
            isListening = false
            hasTouch = false
            currentWeight = 0.0
        }
    }
    
    func zeroScale() {
        if hasTouch {
            zeroOffset = rawWeight
        }
    }
    
    private func processTouchData(_ touchData: [OMSTouchData]) {
        if touchData.isEmpty {
            hasTouch = false
            currentWeight = 0.0
            zeroOffset = 0.0
            currentTouchShape = nil
        } else {
            hasTouch = true
            let touch = touchData.first!
            rawWeight = touch.pressure
            currentWeight = max(0, rawWeight - zeroOffset)
            let major = Float(touch.axis.major)
            let minor = Float(touch.axis.minor)
            currentTouchShape = (major: major, minor: minor)
        }
    }
    
    deinit {
        task?.cancel()
        manager.stopListening()
    }
}