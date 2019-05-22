//
//  ViewController.swift
//  Basketball
//
//  Created by Denis Bystruev on 21/05/2019.
//  Copyright © 2019 Denis Bystruev. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    /// Counts vertical planes
    var planeCounter = 0
    
    /// True when hoop placed
    var isHoopPlaced = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Allow vertical plane detection
        configuration.planeDetection = [.vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}

// MARK: - Custom Methods
extension ViewController {
    /// Places hoop at hit test point
    ///
    /// - Parameter result: ARHitTestResult point
    func addHoop(at result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/Hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else { return }
        
        backboardTexture: if let backboardImage = UIImage(named: "art.scnassets/backboard.jpeg") {
            guard let backboardNode = hoopNode.childNode(withName: "backboard", recursively: false) else {
                break backboardTexture
            }
            guard let backboard = backboardNode.geometry as? SCNBox else { break backboardTexture }
            
            backboard.firstMaterial?.diffuse.contents = backboardImage
        }
        
        
        // Place the hoop in correct position
//        let planePosition = result.worldTransform.columns.3
//        hoopNode.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)
        
        hoopNode.simdTransform = result.worldTransform
        hoopNode.eulerAngles.x -= .pi / 2
        
        // Remove all walls
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
        
        // Add the hoop to the scene
        sceneView.scene.rootNode.addChildNode(hoopNode)
        isHoopPlaced = true
    }
}

// MARK: - IB Actions
extension ViewController {
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if isHoopPlaced {
            // TODO: Implement throwing balls
        } else {
            let location = sender.location(in: sceneView)
            guard let result = sceneView.hitTest(location, types: [.existingPlaneUsingExtent]).first else { return }
            addHoop(at: result)
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        guard !isHoopPlaced else { return }
        
        let extent = anchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.name = "Wall"
        planeNode.opacity = 0.125
        
        node.addChildNode(planeNode)
        planeCounter += 1
        print(#line, #function, "Planes added: \(planeCounter)")
    }
}
