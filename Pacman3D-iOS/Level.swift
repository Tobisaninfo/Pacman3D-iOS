//
//  Level.swift
//  Pacman3D-iOS
//
//  Created by Tobias on 19.06.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import Foundation

class Level {
    
    enum TileType {
        case wall
        case blank
    }
    
    let data: [[TileType]]
    
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
                            tempLine.append(TileType.blank)
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
}
