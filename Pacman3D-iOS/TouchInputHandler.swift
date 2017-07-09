//
//  InputHandler.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 09.07.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

import SceneKit

class TouchInputHandler: UIGestureRecognizer {
    
    var isTouchDown: Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.isTouchDown = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.isTouchDown = false
    }
}
