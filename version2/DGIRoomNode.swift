//
//  DGIRoomNode.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import SpriteKit

class DGIRoomNode: DGIRoomSub {
    
    var moves = ["leftname": "", "rightname": "", "backname": ""]
    weak var left: DGIRoomNode?
    weak var right: DGIRoomNode?
    weak var back: DGIRoomNode?
    var backaction: String? = nil
    var grid: [DGIJSONGrid] = []
    var sequence: [String] = []
    var sequencelength = 0
    weak var selected: DGIRoomSub? = nil
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String) {
        self.init()
        texturename = imageNamed
    }
    
    convenience init(imageNamed: String, name: String, grid: [DGIJSONGrid]? = []) {
        self.init()
        self.name = name
        texturename = imageNamed
        self.isHidden = true
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
        if let setgrid = grid {
            for spot in setgrid {
                if spot.active == nil { spot.active = true }
                self.grid.append(spot)
            }
        }
    }
    
    override func loadTexture() {
        super.loadTexture()
        for case let child as DGIRoomSub in children {
            if child.isHidden == false { child.loadTexture() }
        }
    }
    
    func gridSelected(at pos: CGPoint) -> (index: Int, spot: DGIJSONGrid)? {
        for (index, spot) in grid.enumerated() {
            if let spotpos = spot.pos {
                if CGRect(x: spotpos[0], y: spotpos[1], width: spotpos[2], height: spotpos[3]).contains(pos) {
                    let active = spot.active ?? true
                    if active { return (index, spot) }
                }
            }
        }
        return nil
    }
    
    func gridSelected(name: String) -> (index: Int, spot: DGIJSONGrid)? {
        for (index, spot) in grid.enumerated() {
            if spot.name == name { return (index, spot) }
        }
        return nil
    }
    
    func setSelected(name: String) {
        if selected != nil { clearSelected() }
        selected = (childNode(withName: name) as? DGIRoomSub)
        selected?.addSelect()
    }
    
    func clearSelected() {
        selected?.removeSelect()
        selected = nil
    }
    
    func toggleGrid(withName: String) {
        for (index, spot) in grid.enumerated() {
            if spot.name == withName {
                grid[index].active = !(grid[index].active ?? true)
            }
        }
    }
}

class DGIRoomSub: SKSpriteNode {
    
    var texturename: String = ""
    var displayname: String = ""
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String) {
        /*if loadnow {
            let color = UIColor()
            let texture = SKTexture(imageNamed: imageNamed)
            let size = texture.size()
            self.init(texture: texture, color: color, size: size)
        } else {
            self.init()
        }*/
        self.init()
        texturename = imageNamed
    }
    
    override func addChild(_ node: SKNode) {
        if let sub = node as? DGIRoomSub, texture != nil {
            sub.loadTexture()
        }
        super.addChild(node)
    }
    
    override func run(_ action: SKAction) {
        if texture == nil {
            super.run(SKAction.sequence([SKAction.run{ self.loadTexture() }, action]))
        } else { super.run(action)}
    }
    
    func loadTexture() {
        super.run(SKAction.setTexture(SKTexture(imageNamed: texturename), resize: true))
        for case let child as DGIRoomSub in children {
            if child.isHidden == false { child.loadTexture() }
        }
    }
    
    func addSelect(radius: Float = 50, label: Bool = true) {
        color = UIColor.red
        colorBlendFactor = 1
        /*let effectNode = SKEffectNode()
         effectNode.name = "Glow"
         effectNode.shouldRasterize = true
         effectNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
         addChild(effectNode)
         effectNode.addChild(SKSpriteNode(texture: texture))
         effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])*/
        if label {
            let labelNode = SKLabelNode()
            labelNode.name = "Label"
            labelNode.fontSize = 28 / self.xScale
            labelNode.fontName = "Palatino"
            labelNode.text = displayname
            labelNode.zPosition = self.zPosition + 0.1
            labelNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            addChild(labelNode)
        }
    }
    
    func removeSelect() {
        color = UIColor.white
        //childNode(withName: "Glow")?.removeFromParent()
        childNode(withName: "Label")?.removeFromParent()
    }
}
