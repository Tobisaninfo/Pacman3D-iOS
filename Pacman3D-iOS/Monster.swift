//
//  Monster.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 05.07.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import Foundation
import SceneKit

class Monster {
    
    private var position: SCNVector3
    private var direction: Direction = .north
    
    private let level: Level
    private let scene: SCNScene
    private var node: SCNNode?
    
    init(position: SCNVector3, level: Level, scene: SCNScene) {
        self.position = position
        self.scene = scene
        self.level = level
    }
    
    func addToScene(rootScene: SCNScene) {
        let scene = SCNScene(named: "art.scnassets/Monster.dae")
        if let node = scene?.rootNode.childNodes.first {
            self.node = node
            node.position = position
            node.name = "Monster"
            
            node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
            node.physicsBody?.categoryBitMask = GameViewController.monsterCollision
            node.physicsBody?.contactTestBitMask = GameViewController.pacmanCollision
            node.physicsBody?.isAffectedByGravity = false
            
            rootScene.rootNode.addChildNode(node)
        }
    }
    
    private var lastRotationPoint: (x: Int, z: Int) = (0, 0)
    
    func move() {
        if let node = node {
            let x: Int = Int(position.x / 5)
            let z: Int = Int(position.z / 5)
            
            if !(lastRotationPoint.x == x && lastRotationPoint.z == z) {
                var directions = findFreeSpaces()
                
                if directions.count > 1 {
                    if self.direction == .north {
                        directions.remove(object: .south)
                    } else if self.direction == .east {
                        directions.remove(object: .west)
                    } else if self.direction == .south {
                        directions.remove(object: .north)
                    } else if self.direction == .west {
                        directions.remove(object: .east)
                    }
                }
                
                let direction = directions[Int(arc4random_uniform(UInt32(directions.count)))]
                self.direction = direction
            }
            
            if direction == .north {
                position = SCNVector3(x: node.position.x + 0.15, y: node.position.y, z: Float(z * 5))
            } else if direction == .east {
                position = SCNVector3(x: Float(x * 5), y: node.position.y, z: node.position.z + 0.15)
            } else if direction == .south {
                position = SCNVector3(x: node.position.x - 0.15, y: node.position.y, z: Float(z * 5))
            } else if direction == .west {
                position = SCNVector3(x: Float(x * 5), y: node.position.y, z: node.position.z - 0.15)
            }
            node.position = position
        }
    }
    
    private func findFreeSpaces() -> [Direction] {
        var directions: [Direction] = []
        
        let x: Int = Int(position.x / 5)
        let z: Int = Int(position.z / 5)
        
        lastRotationPoint = (x, z)
        
        if level.data[x - 1][z] == .blank {
            directions.append(.south)
        }
        if level.data[x][z - 1] == .blank {
            directions.append(.west)
        }
        if level.data[x + 1][z] == .blank {
            directions.append(.north)
        }
        if level.data[x][z + 1] == .blank {
            directions.append(.east)
        }
        
        return directions
    }
}
