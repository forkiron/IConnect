//
//  PinArtView.swift
//  IConnect
//
//  3D pin art: grid of pins (dots → lines backward) driven by trackpad pressure + multi-touch.
//

import SwiftUI
import SceneKit

private let pinSpacing: CGFloat = 0.12
private let maxPinLength: CGFloat = 2.0
private let pinRadius: CGFloat = 0.04

struct PinArtView: View {
    @StateObject private var viewModel = PinArtViewModel()
    
    var body: some View {
        ZStack {
            PinArtSceneView(depths: viewModel.depths)
                .ignoresSafeArea()
            VStack {
                Text("Pin Art")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2)
                Text("Use trackpad: press with one or more fingers")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 1)
                Spacer()
            }
            .padding(.top, 12)
        }
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }
}

// MARK: - SceneKit 3D pin grid

struct PinArtSceneView: NSViewRepresentable {
    let depths: [Float]
    
    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = true
        view.backgroundColor = NSColor(white: 0.08, alpha: 1)
        view.antialiasingMode = .multisampling4X
        return view
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        context.coordinator.updatePinDepths(depths)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    @MainActor
    final class Coordinator {
        let scene: SCNScene
        let cameraNode: SCNNode
        var pinNodes: [SCNNode]
        
        init() {
            self.scene = SCNScene()
            self.cameraNode = SCNNode()
            self.pinNodes = []
            setupCamera()
            setupLights()
            createPinGrid()
        }
        
        private func setupCamera() {
            let cam = SCNCamera()
            cam.zNear = 0.1
            cam.zFar = 1000
            cameraNode.camera = cam
            let gw = PinArtViewModel.gridWidth
            let gh = PinArtViewModel.gridHeight
            cameraNode.position = SCNVector3(
                Float(gw) * Float(pinSpacing) * 0.5,
                Float(gh) * Float(pinSpacing) * 0.5,
                18
            )
            cameraNode.look(at: SCNVector3(
                Float(gw) * Float(pinSpacing) * 0.5,
                Float(gh) * Float(pinSpacing) * 0.5,
                0
            ))
            scene.rootNode.addChildNode(cameraNode)
        }
        
        private func setupLights() {
            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 400
            scene.rootNode.addChildNode(ambient)
            let dir = SCNNode()
            dir.light = SCNLight()
            dir.light?.type = .directional
            dir.light?.intensity = 600
            dir.position = SCNVector3(5, 5, 15)
            dir.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(dir)
        }
        
        private func createPinGrid() {
            let gw = PinArtViewModel.gridWidth
            let gh = PinArtViewModel.gridHeight
            let container = SCNNode()
            for y in 0..<gh {
                for x in 0..<gw {
                    let pin = SCNNode()
                    let cyl = SCNCylinder(radius: pinRadius, height: 0.01)
                    cyl.firstMaterial?.diffuse.contents = NSColor(white: 0.85, alpha: 1)
                    cyl.firstMaterial?.specular.contents = NSColor.white
                    cyl.firstMaterial?.shininess = 0.4
                    pin.geometry = cyl
                    pin.position = SCNVector3(
                        Float(x) * Float(pinSpacing),
                        Float(y) * Float(pinSpacing),
                        0
                    )
                    pin.eulerAngles.x = -.pi / 2
                    pin.name = "pin-\(y * gw + x)"
                    container.addChildNode(pin)
                    pinNodes.append(pin)
                }
            }
            scene.rootNode.addChildNode(container)
        }
        
        func updatePinDepths(_ depths: [Float]) {
            guard depths.count == pinNodes.count else { return }
            for (i, node) in pinNodes.enumerated() {
                let d = depths[i]
                guard let cyl = node.geometry as? SCNCylinder else { continue }
                let h = CGFloat(d) * maxPinLength
                cyl.height = max(0.02, h)
                node.position.z = -h / 2
            }
        }
    }
}

#Preview {
    PinArtView()
        .frame(width: 700, height: 500)
}
