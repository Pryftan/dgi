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
    var moveonaction: String? = nil
    var backaction: String? = nil
    var ontime = DispatchTime.now()
    var grid: [DGIJSONGrid] = []
    var wait: [DGIJSONMove] = []
    var sequence: [String] = []
    var sequencelength = 0
    var sequencedraw: DGIJSONSequenceDraw? = nil
    weak var selected: DGIRoomSub? = nil
    var zoomGrid: DGIJSONGrid? { return grid.first(where: { $0.active ?? true && $0.zoom != nil } ) }
    var objGrid: DGIJSONGrid? { return grid.first(where: { $0.active ?? true && $0.object != nil } ) }
    var dragSub: DGIRoomSub? {
        if let dragReturn = children.first(where: {($0 as? DGIRoomSub)?.draggable ?? false}) as? DGIRoomSub {
            return dragReturn
        } else if let dragReturn = children.first(where: {($0 as? DGIRotateNode)?.childsub?.draggable ?? false}) as? DGIRoomSub {
            return dragReturn
        }
        return nil
    }
    var blurs: [SKEffectNode] = []
    var gearbox: DGIGearNode? = nil
    var special: DGISpecialType? = nil
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding rooms is not supported")
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, name: String, grid: [DGIJSONGrid]? = []) {
        self.init()
        texturename = imageNamed
        self.name = name
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
    
    func moveOn() {
        ontime = DispatchTime.now()
        for blur in blurs {
            if let blurSub = blur.children[0] as? DGIRoomSub, let fill = (blur.children[0] as? DGIRoomSub)?.contents {
                if blurSub.texture == nil { blurSub.loadTexture() }
                if fill == "0" { blur.filter = nil
                } else if blur.isHidden == false { blur.filter = CIFilter(name:"CIGaussianBlur",parameters: ["inputRadius": CGFloat(Double(fill)!)]) }
            }
        }
        if let moveonaction = self.moveonaction {
            (parent as? DGIRoom)?.runSpot(gridSelected(name: moveonaction)!.spot)
        }
        if let special = self.special {
            if special == .slidebox {
                (children.first(where: {$0 is DGISpecial}) as? DGISpecial)?.specialDirect(2)
            }
        }
    }
    
    func moveOff() {
        (parent as? DGIRoom)?.cutSpeech()
        for blur in blurs { blur.filter = nil }
        if let backaction = self.backaction {
            (parent as? DGIRoom)?.runSpot(gridSelected(name: backaction)!.spot)
        }
        if let special = self.special {
            if special == .slidebox {
                (children.first(where: {$0 is DGISpecial}) as? DGISpecial)?.specialDirect(3)
            }
        }
    }
}

class DGIRoomSub: SKSpriteNode {
    
    var texturename: String = ""
    var displayname: String = ""
    var initalpha: CGFloat = 1
    var setcolor: UIColor = UIColor.white
    var contents: String = ""
    var draggable = false
    var dragbed: Int = 0
    var draginf: DGIJSONDrags?
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding subs is not supported")
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
    
    convenience init(texture: SKTexture) {
        self.init(texture: texture, color: UIColor.white, size: texture.size())
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
        if texturename != "black" {
            texture = SKTexture(imageNamed: texturename)
            size = texture!.size()
            //super.run(SKAction.setTexture(SKTexture(imageNamed: texturename), resize: true))
            color = setcolor
            alpha = initalpha
        }
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

class DGIRoomCycle: DGIRoomSub {
    //USED?
    var texturenames: [String] = []
    var count: Int = 0
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding subs is not supported")
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    init(imagesNamed: [String]) {
        self.init()
        self.texturenames = imagesNamed
        texturename = imagesNamed[0]
    }
    
    func increment() {
        count = count + 1 >= texturenames.count ? 0 : count + 1
        texturename = texturenames[count]
        loadTexture() //NECESSARY?
    }
    
    func set(to new: Int) {
        if new < texturenames.count {
            count = new
            texturename = texturenames[count]
            loadTexture()
        }
    }
}
