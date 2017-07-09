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

class GameViewController: UIViewController, SKSceneDelegate, SCNPhysicsContactDelegate, SCNSceneRendererDelegate {

    var motionManager: CMMotionManager?
    var scene: SCNScene!
    
    static let wallCollision =     0b001 //1
    static let pacmanCollision =   0b010 //2
    static let monsterCollision =  0b011 //3
    static let pointsCollision =   0b100 //4
    
    // MARK: - Overlay
    
    var pointsLabel: SKLabelNode!
    var lifeLabel: SKLabelNode!
    
    // MARK: - Game Objects
    
    var player: Player!
    var monsters: [Monster] = []

    // MARK: - Input Handler
    private var touchInputHandler: TouchInputHandler!
    private var motionInput: MotionInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let level = Level(named: "level")
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        let pacman = scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        player = Player(node: pacman, scene: scene, level: level)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        scene.physicsWorld.contactDelegate = self
        
        level.createLevelEnviroment(scene: scene)
        
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
        touchInputHandler = TouchInputHandler(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(touchInputHandler)
        
        self.motionInput = MotionInput(gameScene: self)
        motionManager = CMMotionManager()
        if (motionManager?.isAccelerometerAvailable)! {
            motionManager?.accelerometerUpdateInterval = 0.1
            motionManager?.startAccelerometerUpdates(to: OperationQueue.main, withHandler: motionInput!.handleMotionInput)
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
        
        for _ in 1...10 {
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
    }
    
    private var lastTime: TimeInterval = 0
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for monster in monsters {
            monster.move()
        }
        
        
        if time - lastTime > 0.25 {
            if touchInputHandler.isTouchDown {
                player.move()
            }
            lastTime = time
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
