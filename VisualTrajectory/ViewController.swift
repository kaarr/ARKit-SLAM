//
//  ViewController.swift
//  VisualTrajectory
//
//  Created by Christian Kaarre on 03/2020.
//  Copyright © 2020 Christian Kaarre. All rights reserved.
//


import UIKit
import SceneKit
import ARKit
import Foundation


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var startPoint = [Float(0), Float(0), Float(0)]
    var sceneNodes = [SCNNode]()
    
    var xPoint = Float(0)
    var yPoint = Float(0)
    var zPoint = Float(0)
    
    var file = ""
    
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        var timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.text = ""
        self.view.addSubview(label)
    }
    
    
    @objc func timerAction() {
        let point = String(xPoint) + " " + String(yPoint) + " " + String(zPoint) + "\n"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            if let fileUpdater = try? FileHandle(forUpdating: fileURL) {
                fileUpdater.seekToEndOfFile()
                fileUpdater.write(point.data(using: .utf8)!)
                fileUpdater.closeFile()
            }
        }
    }
    

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        xPoint = Float(frame.camera.transform.columns.3[0])
        yPoint = Float(frame.camera.transform.columns.3[1])
        zPoint = Float(frame.camera.transform.columns.3[2])
        
        self.label.text = "x: " + String(format: "%.1f", xPoint) +
            "  y: " + String(format: "%.1f", yPoint) +
            "  z: " + String(format: "%.1f", zPoint)
        
        let distancePower = pow(xPoint - startPoint[0], 2) +
            pow(yPoint - startPoint[1], 2) +
            pow(zPoint - startPoint[2], 2)

        if ( sqrt(distancePower) >= 1.0 ) {
            addNodeToScene(xPoint: xPoint, yPoint: yPoint, zPoint: zPoint)
            startPoint = [xPoint, yPoint, zPoint]
        }
    }

    
    func addNodeToScene(xPoint: Float, yPoint: Float, zPoint: Float) {
        
        let ball = SCNSphere(radius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        ball.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(x: xPoint, y: yPoint-0.3, z: zPoint)
        node.geometry = ball
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.autoenablesDefaultLighting = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        
        // Initialize the file
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        file = formatter.string(from: today) + ".txt"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let text = "x z y\n"
            let fileURL = dir.appendingPathComponent(file)
            
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print(error)
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
