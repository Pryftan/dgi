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

extension CGFloat {
    func mod(_ by: Int) -> Int {
        let r = Int(self >= 0 ? self : self + CGFloat(by)) % by
        return r
    }
}

extension Collection {
    //shouldn't be needed in a future Swift version
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
    
    func addOutline() {
        let outline = SKSpriteNode(texture: texture)
        outline.color = .yellow
        outline.zPosition = zPosition - 0.1
        outline.setScale(1.2)
        addChild(outline)
    }
    
}

struct Next<T: Equatable> {
    private var data = [T]()
    private var counter = 0
    var next: T {
        mutating get {
            let curr = counter
            counter = (counter + 1) % data.count
            return data[curr]
        }
    }
    var now: T {
        get { return data[counter] }
    }
    var peek: T {
        get { return data[(counter + 1) % data.count] }
    }
    
    init(_ data: [T]) {
        self.data = data
    }
    
    mutating func set(_ element: T) {
        counter = 0
        while data[counter] != element { counter += 1; if counter > data.count { break } }
    }
    
    mutating func add(_ element: T) {
        data.append(element)
    }
    
    mutating func reset() {
        counter = 0
    }
    
    mutating func increment() {
        counter = (counter + 1) % data.count
    }
    
    mutating func setData(_ data: [T]) {
        self.data = data
    }
}
