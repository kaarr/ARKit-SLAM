//
//  ViewController.swift
//  Spatial Pictures
//
//  Created by Christian Kaarre on 02/2020.
//  Copyright © 2020 Christian Kaarre. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // PROPERTIES
    
    // number of images to be added into scene
    let numberOfImages = 30
    // distance between images in meters
    let distanceOfImages = Float(0.2)
    // boolean flag for saving the images and camera parameters
    // true -> save, false -> don't save
    let imageSaving = false
    // compression of the .jpeg-images
    // 1 -> no compression
    let compressionRate = CGFloat(0.5)
    
    // updated after distanceOfImages has been reached
    var startPoint = [Float(0), Float(0), Float(0)]
    // arrays for saving images and camera parameters
    var arFrameImages = [UIImage]()
    var arFrameCoordinates = [simd_float3]()
    var arFrameAngles = [simd_float3]()
    
    // array of the nodes in the scene
    var sceneNodes = [SCNNode]()
    // boolean flag for adding the images into root node
    var nodesAdded = false
    
    // user's directory URLs for saving data and images
    var imageFolderURL: URL!
    var dataFileURL: URL!
    
    
    /* viewDidLoad
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
    }
    
    
    /* ARSession's 'didUpdate' delegate-method
     Handles the ARFrame objects
     1. calculates the Euclidean distance between specified points
        1. calls addNodesToScene()
        2. calls saveImageAndData()
     2. calls addToRootNode()
    */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if (arFrameImages.count < numberOfImages) {
            let xPoint = Float(frame.camera.transform.columns.3[0])
            let yPoint = Float(frame.camera.transform.columns.3[1])
            let zPoint = Float(frame.camera.transform.columns.3[2])
            
            let distancePower = pow(xPoint - startPoint[0], 2) +
                pow(yPoint - startPoint[1], 2) +
                pow(zPoint - startPoint[2], 2)
  
            if ( sqrt(distancePower) >= distanceOfImages ) {
                //print("Distance has been reached, distance: " + String(sqrt(distancePower)))
                
                let roll = Float(frame.camera.eulerAngles[0])
                let pitch = Float(frame.camera.eulerAngles[1])
                let yaw = Float(frame.camera.eulerAngles[2])
                
                let imageFromScene:UIImage = sceneView.snapshot()
                
                arFrameImages.append(imageFromScene)
                arFrameCoordinates.append([xPoint, yPoint, zPoint])
                arFrameAngles.append([roll, pitch, yaw])

                addNodeToScene(xPoint: xPoint, yPoint: yPoint, zPoint: zPoint,
                               roll: roll, pitch: pitch, yaw: yaw,
                               image: imageFromScene)
                startPoint = [xPoint, yPoint, zPoint]
                
                if (imageSaving == true) {
                    let fx = frame.camera.intrinsics[0][0]
                    let fy = frame.camera.intrinsics[1][1]
                    let px = frame.camera.intrinsics[2][0]
                    let py = frame.camera.intrinsics[2][1]
                    
                    let image = CIImage(cvPixelBuffer: frame.capturedImage)
                    let ciImage: CIImage? = image
                    let uiimage = UIImage(ciImage: ciImage!)
                    
                    let imageName = String(arFrameImages.count + 1) + ".jpg"
                    let position = String(xPoint) + " " + String(yPoint) + " " + String(zPoint) + " " +
                        String(roll) + " " + String(pitch) + " " + String(yaw) + " " +
                        String(fx) + " " + String(fy) + " " + String(px) + " " + String(py) + "\n"
                    
                    saveImageAndData(imageName: imageName, image: uiimage, position: position)
                }
            }
        } else {
            if (nodesAdded == false) {
                addToRootNode()
                nodesAdded = true
            }
        }
    }
    
    
    /* Saves images and data into user's .documentDirectory
     1. Converts the images to .jpeg, performs compression and adds
        image to imageFolderURL
     2. writes the camera parameters into data.txt
     */
    func saveImageAndData(imageName: String, image: UIImage, position: String) {

        let fileName = imageName
        let fileURL = imageFolderURL!.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: compressionRate) else { return }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print(removeError)
            }
        }

        do {
            try data.write(to: fileURL)
        } catch let error {
            print(error)
        }
        
        if let fileUpdater = try? FileHandle(forUpdating: dataFileURL) {
            fileUpdater.seekToEndOfFile()
            fileUpdater.write(position.data(using: .utf8)!)
            fileUpdater.closeFile()
        }

    }

    
    /* CURRENTLY NOT IN USE
     */
    func addNodes(){
        for i in 0 ... (arFrameImages.count-1) {
            addNodeToScene(xPoint: arFrameCoordinates[i][0],
                           yPoint: arFrameCoordinates[i][1],
                           zPoint: arFrameCoordinates[i][2],
                           roll: arFrameAngles[i][0],
                           pitch: arFrameAngles[i][1],
                           yaw: arFrameAngles[i][2],
                           image: arFrameImages[i])
        }
    }
    
    
    /* Creates plane-node based on the 6DoF with image-texture
     and appends the node into sceneNodes-array
     */
    func addNodeToScene(xPoint: Float, yPoint: Float, zPoint: Float,
                        roll: Float, pitch: Float, yaw: Float,
                        image: UIImage) {
        
        let im_ratio = image.size.width/image.size.height
        let plane = SCNPlane(width: im_ratio*0.11, height: 0.11)
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = true
        plane.materials = [material]
        
        let node = SCNNode()
        let z_distance = Float(0.01)
        node.position = SCNVector3(x: xPoint-(tan(pitch)*z_distance),
                                   y: yPoint+(tan(roll)*z_distance),
                                   z: zPoint - z_distance)
        node.geometry = plane
        node.eulerAngles.x = roll
        node.eulerAngles.y = pitch
        node.eulerAngles.z = yaw + Float.pi/2
        node.opacity = 0.7
        //sceneView.autoenablesDefaultLighting = true
        
        sceneNodes.append(node)
    }
    
    
    /* Reads the predefied nodes from the sceneNodes and adds the nodes
     into sceneView's rootNode
     */
    func addToRootNode() {
        for i in 0 ... (sceneNodes.count - 1) {
            sceneView.scene.rootNode.addChildNode(sceneNodes[i])
        }
        nodesAdded = true
    }
    
    
    /* viewWillAppear
     1. creates a structure into user's documentsDirectory
        1. Images folder for images
        2. data.txt file for camera parameters
     2. defines the session's configuration as ARWorldTrackingConfiguration
        and sets the plane detection
     3. runs the session
     */
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let time = formatter.string(from: today)
        let file = "data.txt"
        let text = "x z y roll pitch yaw fx fy px py\n"

        let folderName = time
        let fileManager = FileManager.default
        let documentsFolder = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let folderURL = documentsFolder.appendingPathComponent(folderName)
        let folderExists = (try? folderURL.checkResourceIsReachable()) ?? false
        
        do {
            if !folderExists {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false)
                imageFolderURL = folderURL.appendingPathComponent("Images")
                try fileManager.createDirectory(at: imageFolderURL, withIntermediateDirectories: false)
                dataFileURL = folderURL.appendingPathComponent(file)
                try text.write(to: dataFileURL, atomically: true, encoding: .utf8)
            }
        } catch { print(error) }
        
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    
    /* viewWillDisappear
     */
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
