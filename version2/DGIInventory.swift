//
//  DGIInventory.swift
//  DGI: Engine
//
//  Created by William Frank on 4/19/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit

class DGIInventory: SKSpriteNode {
    
    var masterinv: [DGIInventoryObject] = []
    var currentinv: [DGIInventoryObject] = []
    weak var selected: DGIInventoryObject?
    
    let center: CGFloat = (Config.inv.space + (Config.inv.unit / 2))
    let block: CGFloat = (Config.inv.space + Config.inv.unit)
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let color = UIColor()
        let texture = SKTexture(imageNamed: "invbox")
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setScale(Config.inv.scale)
        position = CGPoint(x: Config.inv.space, y: Config.inv.space)
        zPosition = 3
    }
    
    func addObj(objectname: String, after: Double = 0) {
        if let object = masterinv.first(where: { $0.name == objectname }) {
            //add find by displayname
            openInv()
            currentinv.append(object)
            object.removeAllActions()
            object.isHidden = false
            object.scale(to: CGSize(width: object.texture!.size().width, height: object.texture!.size().height))
            object.position = CGPoint(x: parent!.frame.midX, y: parent!.frame.midY)
            object.zPosition = 2
            object.zRotation = CGFloat(Double.pi/15)
            let collected = currentinv.filter({ $0.isCollected > -1 }).count
            var movepos: CGFloat = block * CGFloat(currentinv.count - collected) + center
            for collectobj in object.collects {
                if let addto = currentinv.firstIndex(where: { $0.name == collectobj }) {
                    movepos = block * CGFloat(addto + 1) + center
                    object.isCollected = addto
                }
            }
            let showobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: movepos, y: center), duration: 0.5), SKAction.scale(to:object.holdscale * Config.inv.scale, duration: 0.5)])
            let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
            object.run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.unhide(), SKAction.rotate(toAngle: 0, duration: 0.5), showobj, SKAction.wait(forDuration: 3.5), hideobj]), withKey: "AddObj")
        }
        
    }
    
    func removeObj(objectname: String, after: Double = 0) {
        var found: Int = -1
        for (index, object) in currentinv.enumerated() {
            if found > -1 && zRotation != 0 {
                if object.isCollected == -1 {
                    object.run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.moveBy(x: -1 * block, y: 0, duration: 0.5)]), withKey: "BumpObj")
                    for collect in object.collects {
                        if let collectobj = currentinv.first(where: {$0.name == collect}) { collectobj.run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.moveBy(x: -1 * block, y: 0, duration: 0.5)]), withKey: "BumpObj") }
                    }
                }
            }
            if object.name == objectname { found = index }
        }
        if found > -1 {
            let removeref = currentinv[found]
            removeref.removeAllActions()
            if removeref == selected {
                removeref.removeSelect()
                selected = nil
            }
            if zRotation != 0 {
                let hideobj: SKAction = SKAction.group([SKAction.moveBy(x: 0, y: -1 * center, duration: 0.5), SKAction.scale(to: 0, duration: 0.5), SKAction.hide(), SKAction.scale(to: 1, duration: 0)])
                removeref.run(SKAction.sequence([SKAction.wait(forDuration: after), hideobj]), withKey: "RemoveObj")
                for collect in removeref.collects {
                    if let collectobj = currentinv.first(where: {$0.name == collect}) {
                        collectobj.run(SKAction.sequence([SKAction.wait(forDuration: after), hideobj]), withKey: "RemoveObj")
                    }
                }
            }
            currentinv.remove(at: found)
            GameSave.autosave.removeInv(object: objectname)
            for collect in removeref.collects {
                if let collectIndex = currentinv.firstIndex(where: {$0.name == collect}) {
                    currentinv.remove(at: collectIndex)
                    GameSave.autosave.removeInv(object: collect)
                }
            }
        }
    }
    
    func openInv(after: Double = 0) {
        removeAllActions()
        run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.rotate(toAngle: CGFloat(-87*Double.pi/180), duration: 0.7),SKAction.wait(forDuration: 4),SKAction.rotate(toAngle: 0, duration: 0.5)]))
        var realIndex = 0
        for object in currentinv {
            object.removeAllActions()
            realIndex += object.isCollected > -1 ? 0 : 1
            let movepos: CGFloat = block * CGFloat(object.isCollected > -1 ?object.isCollected + 1 : realIndex) + center
            let showobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: movepos, y: center), duration: 0.5), SKAction.scale(to:object.holdscale * Config.inv.scale, duration: 0.5)])
            let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.run{ [weak object] in object?.removeSelect()}, SKAction.scale(to: 0, duration: 0.5)])
            object.run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.unhide(), showobj, SKAction.wait(forDuration: 4), hideobj]), withKey: "ShowObj")
        }
    }
    
    func selectInv(at pos: CGFloat) {
        var objindex: Int = Int(pos / block) - 1
        let collected = currentinv.filter({ $0.isCollected > -1 }).count
        if objindex < currentinv.count - collected {
            for (index, object) in currentinv.enumerated() {
                object.removeSelect()
                if (object.isCollected > -1 && objindex >= index) { objindex += 1 }
            }
            selected = currentinv[objindex]
            currentinv[objindex].addSelect()
            for collect in currentinv[objindex].collects {
                //add find by display name
                if let collectobj = currentinv.first(where: {$0.name == collect}) {
                    collectobj.addSelect(label: false)
                }
            }
        }
    }
    
    func closeInv() {
        let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
        for object in currentinv {
            object.removeAllActions()
            object.removeSelect()
            object.run(hideobj, withKey: "HideObj")
        }
    }
}

class DGIInventoryObject: DGIRoomSub {
    
    var holdscale: CGFloat = 1
    var animations: [DGIJSONAnimation] = []
    var collects: [String] = []
    var isCollected = -1
    var subs: [DGIJSONInvSub] = []
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, name: String, displayname: String?, scale: CGFloat, animations: [DGIJSONAnimation]?, subs: [DGIJSONInvSub]?, collects: [String]?) {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.name = name
        self.isHidden = true
        self.zPosition = 3
        if let displayname = displayname {
            self.displayname = displayname
        } else { self.displayname = name }
        self.holdscale = scale
        self.animations = animations ?? []
        self.subs = subs ?? []
        self.collects = collects ?? []
    }
}
