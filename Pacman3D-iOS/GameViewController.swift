//
//  GameViewController.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 19.06.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class GameViewController: UIViewController {

    var motionManager: CMMotionManager?
    
    var isRotating: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let level = Level(named: "level")
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        for (y, line) in level.data.enumerated() {
            for (x, block) in line.enumerated() {
                if block == .wall {
                    let box = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 0)
                    let node = SCNNode(geometry: box)
                    node.position = SCNVector3(x: Float(x * 5), y: 2.5, z:Float(y * 5))
                    scene.rootNode.addChildNode(node)
                }
            }
        }
        
//        // create and add a light to the scene
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = .omni
//        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
//        scene.rootNode.addChildNode(lightNode)
//        
//        // create and add an ambient light to the scene
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light!.type = .ambient
//        ambientLightNode.light!.color = UIColor.darkGray
//        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        motionManager = CMMotionManager()
        if (motionManager?.isAccelerometerAvailable)! {
            motionManager?.accelerometerUpdateInterval = 0.1
            motionManager?.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                let rotate = data!.acceleration.y
                //print(rotate)
                let pacman = scene.rootNode.childNode(withName: "Pacman", recursively: true)!
                let direction: Float = rotate < 0 ? 1.0 : -1.0
                if abs(rotate) > 0.3 {
                    if !self.isRotating {
                        let action = SCNAction.rotateBy(x: 0, y: CGFloat(direction * Float.pi * 0.5), z: 0, duration: 0.25)
                        pacman.runAction(action)
                        self.isRotating = true
                    }
                } else {
                    self.isRotating = false
                }
            })
        }
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscape
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
