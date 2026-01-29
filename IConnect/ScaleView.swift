//
//  ScaleView.swift
//  IConnect
//

import SwiftUI

struct ScaleView: View {
    @StateObject private var viewModel = ScaleViewModel()
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var keyMonitor: Any?
    
    /// When touch shape matches a known gadget (e.g. AirPods oval), suggest Bluetooth connect.
    private var matchedShapeProfile: ShapeProfile? {
        guard viewModel.hasTouch, let shape = viewModel.currentTouchShape else { return nil }
        return ShapeProfile.presets.first { $0.matches(major: shape.major, minor: shape.minor) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
//                    LinearGradient(
//                        colors: [
//                            Color(red: 0.95, green: 0.97, blue: 1.0),
//                            Color(red: 0.85, green: 0.92, blue: 0.98)
//                        ],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                    .ignoresSafeArea()
                
                VStack(spacing: geometry.size.height * 0.06) {
                    // Title with subtitle directly underneath
                    VStack(spacing: 8) {
                        Text("IConnect")
                            .font(.system(size: min(max(geometry.size.width * 0.05, 24), 42), weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text("Rest AirPods (or case) on trackpad—connect by shape")
                            .font(.system(size: min(max(geometry.size.width * 0.022, 14), 18), weight: .medium))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: geometry.size.width * 0.8)
                            .opacity(viewModel.hasTouch ? 0 : 1)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.hasTouch)
                    }
                    .frame(height: max(geometry.size.height * 0.15, 80)) // Fixed height for title + subtitle
                    .frame(maxWidth: .infinity) // Ensure full width for centering
                    
                    Spacer()
                    
                    // Weight display
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", viewModel.currentWeight))
                            .font(.system(size: min(max(geometry.size.width * 0.12, 48), 96), weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .animation(.easeInOut(duration: 0.2), value: viewModel.currentWeight)
                        Text("grams")
                            .font(.system(size: min(max(geometry.size.width * 0.03, 18), 28), weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Shape-to-connect: if touch shape matches (e.g. AirPods oval), offer Bluetooth connect
                    if let profile = matchedShapeProfile {
                        VStack(spacing: 8) {
                            Text("Likely: \(profile.name)")
                                .font(.system(size: min(max(geometry.size.width * 0.022, 14), 18), weight: .semibold))
                                .foregroundStyle(.teal)
                            Button(action: {
                                bluetoothManager.connectToHeadphones()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "airpodspro")
                                    Text("Connect via Bluetooth")
                                        .font(.system(size: min(max(geometry.size.width * 0.018, 12), 16), weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(.teal))
                            }
                            .buttonStyle(.plain)
                            .disabled(bluetoothManager.isConnecting)
                        }
                        .padding(.bottom, 4)
                    }
                    
                    // Fixed container for button to prevent jumping
                    VStack(spacing: 10) {
                        if viewModel.hasTouch {
                            Text("Press spacebar or click to zero")
                                .font(.system(size: min(max(geometry.size.width * 0.018, 12), 16), weight: .medium))
                                .foregroundStyle(.gray)
                        }
                        
                        Button(action: {
                            viewModel.zeroScale()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: min(max(geometry.size.width * 0.02, 14), 18), weight: .semibold))
                                Text("Zero Scale")
                                    .font(.system(size: min(max(geometry.size.width * 0.02, 14), 18), weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(width: min(max(geometry.size.width * 0.2, 140), 180), 
                                   height: min(max(geometry.size.height * 0.08, 40), 55))
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .teal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(viewModel.hasTouch ? 1 : 0)
                        .scaleEffect(viewModel.hasTouch ? 1 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasTouch)
                    }
                    .frame(height: min(max(geometry.size.height * 0.15, 80), 100)) // Fixed space for button + instruction
                    .frame(maxWidth: .infinity) // Ensure full width for centering
                }
                .padding(.horizontal, max(geometry.size.width * 0.05, 20))
                .padding(.vertical, max(geometry.size.height * 0.03, 20))
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the VStack takes full available space
            }
        }
        .focusable()
        .modifier(FocusEffectModifier())
        .onAppear {
            viewModel.startListening()
            setupKeyMonitoring()
        }
        .onDisappear {
            viewModel.stopListening()
            removeKeyMonitoring()
        }
    }
    
    private func setupKeyMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Space key code is 49
            if event.keyCode == 49 && viewModel.hasTouch {
                viewModel.zeroScale()
            }
            return event
        }
    }
    
    private func removeKeyMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

struct FocusEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.focusEffectDisabled()
        } else {
            content
        }
    }
}

#Preview {
    ScaleView()
}
