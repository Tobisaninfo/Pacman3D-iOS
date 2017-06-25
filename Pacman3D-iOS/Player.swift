//
//  Player.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 19.06.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import Foundation

class Player {
    enum Direction: Int {
        case north = 1
        case east
        case south
        case west
    }
    
    var points: Int = 0
    var life: Int = 3
}
