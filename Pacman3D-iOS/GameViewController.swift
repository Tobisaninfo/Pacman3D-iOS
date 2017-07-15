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

class GameViewController: UIViewController, SKSceneDelegate, SCNPhysicsContactDelegate, SCNSceneRendererDelegate, PlayerDelegate {

    var motionManager: CMMotionManager?
    var scene: SCNScene!
    
    static let wallCollision =     0b001 //1
    static let pacmanCollision =   0b010 //2
    static let monsterCollision =  0b011 //3
    static let pointsCollision =   0b100 //4
    
    // MARK: - Overlay
    
    var pointsLabel: SKLabelNode!
    var lifeLabel: SKLabelNode!
    var backButton: SKSpriteNode!
    
    var minimap: [[SKSpriteNode]] = []
    
    var restartButton: SKLabelNode!
    
    // MARK: - Game Objects
    
    let monsterCount = 6
    
    var level: Level!
    var player: Player!
    var monsters: [Monster]!

    // MARK: - Input Handler
    private var touchInputHandler: TouchInputHandler!
    private var motionInput: MotionInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monsters = []
        
        level = Level(named: "level")
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        let pacman = scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        player = Player(node: pacman, scene: scene, level: level)
        player.delegate = self
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        scene.physicsWorld.contactDelegate = self
        
        level.createLevelEnviroment(scene: scene)
        
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
        
        // Create overlay
        if let view = self.view as? SCNView {
            view.overlaySKScene = createOverlay()
        }
        
        // add a tap gesture recognizer
        if touchInputHandler != nil {
            scnView.removeGestureRecognizer(touchInputHandler)
        }
        
        touchInputHandler = TouchInputHandler(target: self, action: #selector(handleTap(_:)))
        touchInputHandler.scene = (self.view as? SCNView)?.overlaySKScene
        touchInputHandler.gameController = self
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
        
        for _ in 1...monsterCount {
            let postion = level.nextFreeSpace()
            let monster = Monster(position: SCNVector3(5 * postion.x, 1, 5 * postion.z), level: level, scene: scene)
            monster.addToScene(rootScene: self.scene)
            monsters.append(monster)
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
        
        if contact.nodeA.name ?? "" == "Monster" && contact.nodeB.name ?? "" == "Pacman" ||
            contact.nodeB.name ?? "" == "Monster" && contact.nodeA.name ?? "" == "Pacman" {
            player.life = player.life - 1
            if player.life >= 0 {
                lifeLabel.text = String(repeating: "♥️", count: player.life)
            }
            
            let monster = contact.nodeA.name ?? "" == "Monster" ? contact.nodeA : contact.nodeB
            monster.removeFromParentNode()
            
            for m in monsters {
                if let n =  m.node {
                    if n == monster {
                        monsters.remove(object: m)
                        break
                    }
                }
            }
            
            if player.life <= 0 {
                self.scene.isPaused = true
                restartButton.isHidden = false
            }
        }
    }
    
    func player(_ player: Player, scoreDidUpdate score: Int) {
        pointsLabel.text = "\(player.points) Punkte"
    }
    
    func player(_ player: Player, didCollectScoreAt position: (x: Int, z: Int)) {
        if let node = scene.rootNode.childNode(withName: "Score.\(position.x).\(position.z)", recursively: true) {
            node.removeFromParentNode()
        }
    }
    
    private var lastTime: TimeInterval = 0
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !scene.isPaused {
            for monster in monsters {
                monster.move()
            }
            
            if time - lastTime > 0.25 {
                if touchInputHandler.isTouchDown {
                    player.move()
                }
                lastTime = time
            }
            
            updateMinimap()
        }
    }
    
    func createOverlay() -> SKScene {
        let scene = SKScene(size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height))
        pointsLabel = SKLabelNode(fontNamed: "Chalkduster")
        pointsLabel.text = "0 Punkte"
        pointsLabel.fontSize = 20
        pointsLabel.fontColor = UIColor.red
        pointsLabel.position = CGPoint(x: 100, y: self.view.frame.height - 30)
        scene.addChild(pointsLabel)
        
        lifeLabel = SKLabelNode(fontNamed: "Chalkduster")
        lifeLabel.text = "♥️♥️♥️"
        lifeLabel.fontColor = UIColor.red
        lifeLabel.position = CGPoint(x: self.view.frame.width - 50, y: 5)
        scene.addChild(lifeLabel)
        
        backButton = SKSpriteNode(imageNamed: "pause.png")
        backButton.size = CGSize(width: 60, height: 60)
        backButton.position = CGPoint(x: backButton.size.width / 2, y: backButton.size.height / 2)
        backButton.name = "Back"
        scene.addChild(backButton)
        
        restartButton = SKLabelNode(fontNamed: "Chalkduster")
        restartButton.text = "Restart"
        restartButton.fontSize = 40
        restartButton.fontColor = UIColor.red
        restartButton.position = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        restartButton.isHidden = true
        restartButton.name = "Restart"
        scene.addChild(restartButton)
        
        let frame = self.view.frame
        
        minimap = []
        for (x, _) in level.data.enumerated() {
            var nodes: [SKSpriteNode] = []
            for (z, _) in level.data[x].enumerated() {
                let node = SKSpriteNode(color: UIColor.magenta, size: CGSize(width: 5, height: 5))
                let posX = frame.width - CGFloat(level.data[x].count * 5) + CGFloat(z * 5) + 2.5
                let posZ = frame.height - CGFloat(level.data.count * 5) + CGFloat(x * 5) + 2.5
                node.position = CGPoint(x: posX, y: posZ)
                nodes.append(node)
                scene.addChild(node)
            }
            minimap.append(nodes)
        }
        
        return scene
    }
    
    func updateMinimap() {
        for (x, _) in level.data.enumerated() {
            for (z, data) in level.data[x].enumerated() {
                let node = minimap[x][z]
                switch data {
                case .blank:
                    node.color = UIColor.black.withAlphaComponent(0.6)
                case .point:
                    node.color = UIColor.blue.withAlphaComponent(0.6)
                case .wall:
                    node.color = UIColor.gray.withAlphaComponent(0.6)
                }
            }
        }

        for monster in monsters {
            let x: Int = Int(monster.position.x / 5)
            let z: Int = Int(monster.position.z / 5)
            minimap[x][z].color = UIColor.red.withAlphaComponent(0.6)
        }
        
        let x: Int = Int(player.position.x / 5)
        let z: Int = Int(player.position.z / 5)
        minimap[x][z].color = UIColor.yellow.withAlphaComponent(0.6)
    }
    
    func restart() {
        viewDidLoad()
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
            return .landscapeLeft
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
