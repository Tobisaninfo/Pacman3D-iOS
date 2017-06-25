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
import SpriteKit
import CoreMotion

class GameViewController: UIViewController, SKSceneDelegate ,SCNPhysicsContactDelegate{

    var motionManager: CMMotionManager?
    var scene: SCNScene!
    
    let wallCollision =   0b01 //1
    let pacmanCollision = 0b10 //2
    
    var isRotating: Bool = false
    
    var direction: Player.Direction = .north
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let level = Level(named: "level")
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        for (y, line) in level.data.enumerated() {
            for (x, block) in line.enumerated() {
                if block == .wall {
                    let box = SCNBox(width: 5, height: 2, length: 5, chamferRadius: 0)
                    let node = SCNNode(geometry: box)
                    node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
                    node.physicsBody?.categoryBitMask = wallCollision
                    //node.physicsBody?.collisionBitMask = pacmanCollision
                    node.physicsBody?.contactTestBitMask = pacmanCollision
                    node.position = SCNVector3(x: Float(x * 5), y: 1, z:Float(y * 5))
                    scene.rootNode.addChildNode(node)
                }
            }
        }
        
        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        let pacmanBox = SCNBox(width: 5, height: 2, length: 5, chamferRadius: 0)
        pacmanBox.firstMaterial?.diffuse.contents = UIColor.clear
        let boxNode = SCNNode(geometry: pacmanBox)
        pacman.addChildNode(boxNode)
        pacman.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: pacmanBox, options: nil))
        pacman.physicsBody?.categoryBitMask = pacmanCollision
        //pacman.physicsBody?.collisionBitMask = wallCollision
        pacman.physicsBody?.contactTestBitMask = wallCollision
        pacman.physicsBody?.isAffectedByGravity = false
        //scene.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        scene.physicsWorld.contactDelegate = self
        
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
        scnView.allowsCameraControl = false
        
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
                let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
                let direction: Float = rotate < 0 ? 1.0 : -1.0
                if abs(rotate) > 0.3 {
                    if !self.isRotating {
                        let action = SCNAction.rotateBy(x: 0, y: CGFloat(direction * Float.pi * 0.5), z: 0, duration: 0.25)
                        pacman.runAction(action, completionHandler: { 
                            self.isContact = false
                        })
                        self.isRotating = true
                        
                        var directionVal = self.direction.rawValue + Int(direction)
                        if directionVal == 5 {
                            directionVal = 1
                        }
                        if directionVal == 0 {
                            directionVal = 4
                        }
                        self.direction = Player.Direction(rawValue: directionVal)!
                    }
                } else {
                    self.isRotating = false
                }
            })
        }
        if (motionManager?.isDeviceMotionAvailable)! {
            motionManager?.deviceMotionUpdateInterval = 0.1
            motionManager?.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                if let data = data {
                    //self.handleRotation(data: data)
//                    if data.userAcceleration.z < -0.1 {
//                        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
//                        
//                        pacman.position.x += -Float(data.userAcceleration.z) * pacman.rotation.x * 200000.0
//                        pacman.position.z += -Float(data.userAcceleration.z) * pacman.rotation.z * 200000.0
//                        
//                        print(pacman.position)
//                    }
                }
            })
        }
        
        if let view = self.view as? SCNView {
            view.overlaySKScene = createOverlay()
        }
    }
    
    private var lastRotation: Float = 0
    
    func handleRotation(data: CMDeviceMotion) {
        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        if abs(lastRotation - Float(data.attitude.yaw)) > 0.02 {
            pacman.eulerAngles.y = Float(data.attitude.yaw)
            lastRotation = Float(data.attitude.yaw)
        }
    }
    
    var isContact: Bool = false
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //print("\(contact.nodeA.name) \(contact.nodeB.name)"
        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        
        print(" X: \(contact.contactPoint.x) \(pacman.position.x)")
         print(" Z: \(contact.contactPoint.z) \(pacman.position.z)")
        
        print()
        
        if(contact.nodeA == pacman && contact.nodeB.physicsBody?.categoryBitMask == wallCollision) || (contact.nodeA.physicsBody?.categoryBitMask == wallCollision && contact.nodeB == pacman){
            
            func block() {
                if let box = contact.nodeA.geometry as? SCNBox {
                    box.firstMaterial?.diffuse.contents = UIColor.blue
                }
                
                if let box = contact.nodeB.geometry as? SCNBox {
                    box.firstMaterial?.diffuse.contents = UIColor.blue
                }
                print("Idiot \(contact.contactNormal)")
                isContact = true
            }
            
            print("\(contact.contactNormal)")
            
            if direction == .north {
                if contact.contactNormal.x == 1.0 {
                    block()
                }
            } else if direction == .east {
                if contact.contactNormal.z == -1.0 {
                    block()
                }
            } else if direction == .south {
                if contact.contactNormal.x == -1.0 {
                    block()
                }
            } else if direction == .west {
                if contact.contactNormal.z == 1.0 {
                    block()
                }
            }
            
            print("aua")
        }
    }
    
    func createOverlay() -> SKScene {
        let scene = SKScene(size: self.view.frame.size)
        let node = SKSpriteNode(imageNamed: "run.png")
        node.position = CGPoint(x: 100, y: 100)
        node.size = CGSize(width: 50, height: 100)
        //scene.addChild(node)
        return scene
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        if isContact {
            return
        }
        
        let pacman = scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        if direction == .north {
            pacman.position.x += 5
        } else if direction == .east {
            pacman.position.z -= 5
        } else if direction == .south {
            pacman.position.x -= 5
        } else if direction == .west {
            pacman.position.z += 5
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
