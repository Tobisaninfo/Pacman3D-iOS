//
//  InputHandler.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 09.07.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import SpriteKit

import SceneKit

class TouchInputHandler: UIGestureRecognizer {
    
    var isTouchDown: Bool = false
    
    var gameController: GameViewController!
    var scene: SKScene!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        let touch = touches.first!
        let viewTouchLocation = touch.location(in: gameController.view)
        let sceneTouchPoint = scene.convertPoint(fromView: viewTouchLocation)
        let touchedNode = scene.atPoint(sceneTouchPoint)
        
        if touchedNode.name == "Back" {
            gameController.scene.isPaused = !gameController.scene.isPaused
            
            return
        } else if touchedNode.name == "Restart" {
            gameController.restart()
        }
        
        self.isTouchDown = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.isTouchDown = false
    }
}
