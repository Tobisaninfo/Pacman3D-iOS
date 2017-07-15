//
//  Level.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 19.06.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import Foundation
import SceneKit

class Level {
    
    enum TileType {
        case wall
        case blank
        case point
    }
    
    private (set) var data: [[TileType]]
    
    init(named: String) {
        if let path = Bundle.main.path(forResource: named, ofType: "plv") {
            if let aStreamReader = StreamReader(path: path, delimiter: "\n") {
                defer {
                    aStreamReader.close()
                }
                
                var tempLines: [[TileType]] = []
                while let line = aStreamReader.nextLine() {
                    var tempLine: [TileType] = []
                    for index in line.characters.indices {
                        let c = line[index]
                        if c == "w" {
                            tempLine.append(TileType.point)
                        } else if c == "s" {
                            tempLine.append(TileType.wall)
                        }
                    }
                    tempLines.append(tempLine)
                }
                self.data = tempLines
                return
            }
        }
        data = [[]]
    }
    
    func createLevelEnviroment(scene: SCNScene) {
        for (x, line) in data.enumerated() {
            for (z, block) in line.enumerated() {
                if block == .wall {
                    addBlock(toScene: scene, at: (x, z))
                } else if block == .point {
                    addPointObject(toScene: scene, at: (x, z))
                }
            }
        }
    }
    
    func collectPoint(position: (x: Int, z: Int)) -> Bool {
        if data[position.x][position.z] == .point {
            data[position.x][position.z] = .blank
            
            return true
        }
        return false
    }
    
    private func addBlock(toScene scene: SCNScene, at point: (x: Int, z: Int)) {
        let box = SCNBox(width: 5, height: 2, length: 5, chamferRadius: 0)
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(x: Float(point.x * 5), y: 1, z: Float(point.z * 5))
        node.name = "\(point.x) \(point.z)"
        scene.rootNode.addChildNode(node)
    }
    
    private func addPointObject(toScene scene: SCNScene, at point: (x: Int, z: Int)) {
        let shere = SCNSphere(radius: 0.5)
        shere.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode(geometry: shere)
        node.name = "Score.\(point.x).\(point.z)"
        node.position = SCNVector3(x: Float(point.x * 5), y: 1, z:Float(point.z * 5))
        scene.rootNode.addChildNode(node)
    }
    
    func nextFreeSpace() -> (x: Int, z: Int) {
        while true {
            let x = Int(arc4random_uniform(UInt32(data.count)))
            let z = Int(arc4random_uniform(UInt32(data[x].count)))
            
            if data[x][z] != .wall {
                return (x, z)
            }
        }
    }
}
