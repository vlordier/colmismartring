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
    
    // Setup the 3D scene with a cube and lighting
    private func setupScene() {
        // Create a cube geometry
        let cubeGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let cubeMaterial = SCNMaterial()
        cubeMaterial.diffuse.contents = UIColor.blue
        cubeGeometry.materials = [cubeMaterial]
        
        // Add the cube to the scene
        let cubeNode = SCNNode(geometry: cubeGeometry)
        scene.rootNode.addChildNode(cubeNode)
        
        // Add ambient light to the scene
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Add directional light to the scene
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(directionalLightNode)
    }
    
    // Update the rotation of the cube based on the latest accelerometer data
    func updateRotation(x: Float, y: Float, z: Float) {
        let cubeNode = scene.rootNode.childNodes.first
        cubeNode?.eulerAngles = SCNVector3(x: x, y: y, z: z)
    }
}
