//
//  MotionInput.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 09.07.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import Foundation
import CoreMotion
import SceneKit

class MotionInput {
    
    private let gameScene: GameViewController
    private var isRotating = false
    
    init(gameScene: GameViewController) {
        self.gameScene = gameScene
    }
    
    func handleMotionInput(data: CMAccelerometerData?, error: Error?) -> Swift.Void {
        let rotate = data!.acceleration.y
        //print(rotate)
        let pacman = gameScene.scene.rootNode.childNode(withName: "Pacman", recursively: true)!
        let direction: Float = rotate < 0 ? 1.0 : -1.0
        if abs(rotate) > 0.3 {
            if !self.isRotating {
                let action = SCNAction.rotateBy(x: 0, y: CGFloat(direction * Float.pi * 0.5), z: 0, duration: 0.25)
                pacman.runAction(action, completionHandler: nil)
                self.isRotating = true
                
                var directionVal = gameScene.player.direction.rawValue - Int(direction)
                if directionVal == 5 {
                    directionVal = 1
                }
                if directionVal == 0 {
                    directionVal = 4
                }
                gameScene.player.direction = Direction(rawValue: directionVal)!
            }
        } else {
            self.isRotating = false
        }

    }
}
