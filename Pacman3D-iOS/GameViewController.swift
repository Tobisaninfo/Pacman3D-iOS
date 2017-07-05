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

class GameViewController: UIViewController, SKSceneDelegate ,SCNPhysicsContactDelegate, SCNSceneRendererDelegate {

    var motionManager: CMMotionManager?
    var scene: SCNScene!
    
    static let wallCollision =     0b001 //1
    static let pacmanCollision =   0b010 //2
    static let monsterCollision =  0b011 //3
    static let pointsCollision =   0b100 //4
    
    var isRotating: Bool = false
    
    var direction: Direction = .north
    
    // overlay
    var pointsLabel: SKLabelNode!
    var lifeLabel: SKLabelNode!
    
    var player: Player = Player()
    var monsters: [Monster] = []

    
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
        
        for (x, line) in level.data.enumerated() {
            for (z, block) in line.enumerated() {
                if block == .wall {
                    let box = SCNBox(width: 5, height: 2, length: 5, chamferRadius: 0)
                    let node = SCNNode(geometry: box)
                    node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
                    node.physicsBody?.categoryBitMask = GameViewController.wallCollision
                    node.physicsBody?.contactTestBitMask = GameViewController.pacmanCollision
                    node.position = SCNVector3(x: Float(x * 5), y: 1, z:Float(z * 5))
                    node.name = "\(x) \(z)"
                    scene.rootNode.addChildNode(node)
                } else if block == .blank {
                    let shere = SCNSphere(radius: 0.5)
                    shere.firstMaterial?.diffuse.contents = UIColor.blue
                    let node = SCNNode(geometry: shere)
                    node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
                    node.physicsBody?.categoryBitMask = GameViewController.pointsCollision
                    node.physicsBody?.contactTestBitMask = GameViewController.pacmanCollision
                    node.name = "Point"
                    node.position = SCNVector3(x: Float(x * 5), y: 1, z:Float(z * 5))
                    self.scene.rootNode.addChildNode(node)
                }
            }
        }
        
        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        let pacmanBox = SCNBox(width: 5, height: 2, length: 5, chamferRadius: 0)
        pacmanBox.firstMaterial?.diffuse.contents = UIColor.clear
        let boxNode = SCNNode(geometry: pacmanBox)
        pacman.addChildNode(boxNode)
        pacman.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: pacmanBox, options: nil))
        pacman.physicsBody?.categoryBitMask = GameViewController.pacmanCollision
        pacman.physicsBody?.contactTestBitMask = GameViewController.wallCollision
        pacman.physicsBody?.isAffectedByGravity = false
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
        scnView.delegate = self
        scnView.isPlaying = true
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
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
                        self.direction = Direction(rawValue: directionVal)!
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
        
        for _ in 1...1 {
            let postion = level.nextFreeSpace()
            let monster = Monster(position: SCNVector3(5 * postion.x, 1, 5 * postion.z), level: level, scene: scene)
            monster.addToScene(rootScene: self.scene)
            monsters.append(monster)
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
        if contact.nodeA.name ?? "" == "Monster" && contact.nodeB.name ?? "" == "Monster" {
            return
        }
        let pacman = self.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        
        if contact.nodeA.name ?? "" == "Monster" && contact.nodeB.name ?? "" == "Pacman" ||
            contact.nodeB.name ?? "" == "Monster" && contact.nodeA.name ?? "" == "Pacman" {
            player.life = player.life - 1
            if player.life >= 0 {
                lifeLabel.text = String(repeating: "♥️", count: player.life)
            }
            
            pacman.position = SCNVector3(5, 2, 5)
            // TODO Restart
            
            if player.life == 0 {
                //exit(0) // TODO Game Menu
            }
        }
        
        if contact.nodeA.name ?? "" == "Point" && contact.nodeB.name ?? "" == "Pacman" ||
            contact.nodeB.name ?? "" == "Point" && contact.nodeA.name ?? "" == "Pacman" {
            player.points = player.points + 10
            
            pacman.position = SCNVector3(5, 2, 5)
            pointsLabel.text = "\(player.points) Punkte"
            if contact.nodeA.name ?? "" == "Point" {
                contact.nodeA.removeFromParentNode()
            } else if contact.nodeB.name ?? "" == "Point" {
                contact.nodeB.removeFromParentNode()
            }
        }
        
        if(contact.nodeA == pacman && contact.nodeB.physicsBody?.categoryBitMask == GameViewController.wallCollision) || (contact.nodeA.physicsBody?.categoryBitMask == GameViewController.wallCollision && contact.nodeB == pacman){
            
            func block() {
                if let box = contact.nodeA.geometry as? SCNBox {
                    box.firstMaterial?.diffuse.contents = UIColor.blue
                }
                
                if let box = contact.nodeB.geometry as? SCNBox {
                    box.firstMaterial?.diffuse.contents = UIColor.blue
                }
                isContact = true
            }
            
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
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for monster in monsters {
            monster.move()
        }
    }
    
    func createOverlay() -> SKScene {
        let scene = SKScene(size: CGSize(width: self.view.frame.size.height, height: self.view.frame.size.width))
        pointsLabel = SKLabelNode(fontNamed: "Chalkduster")
        pointsLabel.text = "0 Punkte"
        pointsLabel.fontColor = UIColor.red
        pointsLabel.position = CGPoint(x: 100, y: self.view.frame.width - 30)
        scene.addChild(pointsLabel)
        
        lifeLabel = SKLabelNode(fontNamed: "Chalkduster")
        lifeLabel.text = "♥️♥️♥️"
        lifeLabel.fontColor = UIColor.red
        lifeLabel.position = CGPoint(x: self.view.frame.height - 50, y: 5)
        scene.addChild(lifeLabel)
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
