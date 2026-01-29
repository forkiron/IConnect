//
//  ScaleView.swift
//  IConnect
//

import SwiftUI

struct ScaleView: View {
    @StateObject private var viewModel = ScaleViewModel()
    @State private var scaleCompression: CGFloat = 0
    @State private var displayShake = false
    @State private var keyMonitor: Any?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.06) {
                Spacer()
                
                // Big display: scale visualization + raw weight (grams)
                HStack {
                    Spacer()
                    CartoonScaleView(
                        weight: viewModel.currentWeight,
                        hasTouch: viewModel.hasTouch,
                        compression: $scaleCompression,
                        displayShake: $displayShake,
                        scaleFactor: min(geometry.size.width / 700, geometry.size.height / 500)
                    )
                    Spacer()
                }
                
                Spacer()
                
                // Zero scale (spacebar or button)
                VStack(spacing: 10) {
                    if viewModel.hasTouch {
                        Text("Press spacebar or click to zero")
                            .font(.system(size: min(max(geometry.size.width * 0.018, 12), 16), weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    Button(action: { viewModel.zeroScale() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: min(max(geometry.size.width * 0.02, 14), 18), weight: .semibold))
                            Text("Zero")
                                .font(.system(size: min(max(geometry.size.width * 0.02, 14), 18), weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(width: min(max(geometry.size.width * 0.2, 140), 180),
                               height: min(max(geometry.size.height * 0.08, 40), 55))
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(colors: [.blue, .teal], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(viewModel.hasTouch ? 1 : 0)
                    .scaleEffect(viewModel.hasTouch ? 1 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasTouch)
                }
                .frame(height: min(max(geometry.size.height * 0.15, 80), 100))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, max(geometry.size.width * 0.05, 20))
            .padding(.vertical, max(geometry.size.height * 0.03, 20))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .modifier(FocusEffectModifier())
        .onChange(of: viewModel.currentWeight) { newWeight in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scaleCompression = CGFloat(min(newWeight / 100.0, 0.2))
            }
        }
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

struct CartoonScaleView: View {
    let weight: Float
    let hasTouch: Bool
    @Binding var compression: CGFloat
    @Binding var displayShake: Bool
    let scaleFactor: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Scale platform (top) - responsive to weight
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200 * scaleFactor, height: 12 * scaleFactor)
                .offset(y: compression * 15)
            
            // Scale body
            ZStack {
                // Main body
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.95, blue: 0.97),
                                Color(red: 0.85, green: 0.85, blue: 0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 250 * scaleFactor, height: 150 * scaleFactor)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                
                // Display screen
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black)
                    .frame(width: 180 * scaleFactor, height: 60 * scaleFactor)
                    .offset(y: -10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.teal.opacity(0.8), .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 176 * scaleFactor, height: 56 * scaleFactor)
                            .offset(y: -10)
                    )
                
                // Weight display
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 32 * scaleFactor, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(color: .teal, radius: hasTouch ? 2 : 0)
                        .animation(.easeInOut(duration: 0.2), value: weight)
                    
                    Text("grams")
                        .font(.system(size: 12 * scaleFactor, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .offset(y: -10)
                
                // Status indicator - simple and clean
                if hasTouch {
                    Circle()
                        .fill(.teal)
                        .frame(width: 8 * scaleFactor, height: 8 * scaleFactor)
                        .offset(x: 90 * scaleFactor, y: -50 * scaleFactor)
                }
                
                // Fun face on the scale - positioned below the display screen
                VStack(spacing: 8 * scaleFactor) {
                    // Eyes
                    HStack(spacing: 15 * scaleFactor) {
                        Circle()
                            .fill(.black)
                            .frame(width: 8 * scaleFactor, height: 8 * scaleFactor)
                        Circle()
                            .fill(.black)
                            .frame(width: 8 * scaleFactor, height: 8 * scaleFactor)
                    }
                    
                    // Responsive mouth expression
                    Group {
                        if hasTouch && weight > 5 {
                            // Happy mouth when weighing something substantial
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addQuadCurve(to: CGPoint(x: 20, y: 0), control: CGPoint(x: 0, y: 15))
                            }
                            .stroke(.black, lineWidth: 2 * scaleFactor)
                            .frame(width: 20 * scaleFactor, height: 10 * scaleFactor)
                        } else {
                            // Neutral mouth
                            Rectangle()
                                .fill(.black)
                                .frame(width: 12 * scaleFactor, height: 2 * scaleFactor)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: weight > 5)
                }
                .offset(y: 60 * scaleFactor) // Position well below the display screen
            }
            
            // Scale legs
            HStack(spacing: 140 * scaleFactor) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.7))
                        .frame(width: 12 * scaleFactor, height: 25 * scaleFactor)
                        .offset(y: compression * 3)
                }
            }
            .offset(y: -5)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: compression)
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
