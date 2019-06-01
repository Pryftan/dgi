//
//  DGIExtensions.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import SpriteKit

extension CGPoint {
    func distance(toPoint p: CGPoint) -> CGFloat {
        return sqrt(pow(x-p.x,2) + pow(y-p.y,2))
    }
}

extension Collection {
    //shouldn't be needed in Swift 5
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }
}

extension SKSpriteNode {
    
    convenience init(imageNamed: String, name: String) {
        self.init(imageNamed: imageNamed)
        self.name = name
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
    }
    
    convenience init(imageNamed: String, name: String, position: CGPoint) {
        self.init(imageNamed: imageNamed)
        self.name = name
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
        self.position = position
    }
    
}

struct Next<T> {
    private var data = [T]()
    private var counter = 0
    var next: T {
        mutating get {
            let curr = counter
            counter = (counter + 1) % data.count
            return data[curr]
        }
    }
    
    init(_ data: [T]) {
        self.data = data
    }
    
    mutating func add(_ element: T) {
        data.append(element)
    }
}
