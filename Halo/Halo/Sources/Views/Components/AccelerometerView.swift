import SwiftUI
import SceneKit

struct AccelerometerView: View {
    @ObservedObject var ringManager: RingSessionManager
    @State private var scene = SCNScene()
    @State private var xRotation: Float = 0
    @State private var yRotation: Float = 0
    @State private var zRotation: Float = 0
    
    var body: some View {
        SceneView(
            scene: scene,
            options: [.allowsCameraControl]
        )
        .frame(height: 300)
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        // Create a cube
        let boxGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        boxGeometry.materials = [material]
        
        let boxNode = SCNNode(geometry: boxGeometry)
        scene.rootNode.addChildNode(boxNode)
        
        // Add ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Add directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(directionalNode)
    }
    
    func updateRotation(x: Float, y: Float, z: Float) {
        let boxNode = scene.rootNode.childNodes.first
        boxNode?.eulerAngles = SCNVector3(x: x, y: y, z: z)
    }
}
