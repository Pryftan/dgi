//
//  Gear.swift
//  Retrograde
//
//  Created by William Frank on 9/12/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

class Gearbox: GameScreen
{
    var front: SKSpriteNode?
    var flag: String?
    var solve: GameSpot?
    var clearsolve: Bool = false
    var gearspeed: Double?
    var gears: [Gear] = []
    let pegimage: SKTexture
    var pegextra: Int?
    var pegs: [(point: CGPoint, on: Bool)] = []
    
    required init?(coder decoder: NSCoder)
    {
        pegimage = SKTexture(imageNamed: "peg")
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        pegimage = SKTexture(imageNamed: "peg")
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, config: GameJSONConfig)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.config = config
    }
    
    func loadJSONGearbox(jsonData: GameJSONGearbox)
    {
        
        self.name = jsonData.name
        if let frontname: String = jsonData.front
        {
            front = SKSpriteNode(imageNamed: frontname)
            front!.name = jsonData.name + "_front"
            front!.anchorPoint = CGPoint(x: 0, y: 0)
            front!.position = CGPoint(x: 0, y: 0)
            front!.zPosition = 2
            addChild(front!)
        }
        if let flagname: String = jsonData.flag
        {
            flag = flagname
        }
        if let jsonsolve: [GameJSONGrid] = jsonData.solve
        {
            solve = (self.parent as! GameScene).loadJSONSpot(currgrid: jsonsolve[0])
        }
        if let clearsolvecheck: Bool = jsonData.clearsolve
        {
            clearsolve = clearsolvecheck
        }
        gearspeed = jsonData.speed
        for gear in jsonData.gears
        {
            var currtype: GameJSONGearType? = nil
            for type in jsonData.geartypes
            {
                if gear.type == type.name
                {
                    currtype = type
                    break
                }
            }
            if let type = currtype
            {
                let newgear = Gear(imageNamed: type.image, config: config, teeth: type.teeth, radius: type.radius)
                newgear.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                newgear.position = CGPoint(x: gear.posX * config.scale, y: gear.posY * config.scale)
                newgear.zPosition = 1
                if let name = gear.name
                {
                    newgear.name = name
                }
                else
                {
                    newgear.name = type.name
                }
                addChild(newgear)
                gears.append(newgear)
            } else
            {
                print("Error loading gear")
            }
            
        }
        if let pegextracheck: Int = jsonData.pegextra
        {
            pegextra = pegextracheck
        }
        for peg in jsonData.pegs
        {
            pegs.append((point: CGPoint(x: peg.posX * config.scale, y: peg.posY * config.scale),on: false))
            let newpeg = SKSpriteNode(texture: pegimage)
            newpeg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            newpeg.position = CGPoint(x: peg.posX * config.scale, y: peg.posY * config.scale)
            newpeg.zPosition = 1
            addChild(newpeg)
        }
    }
 
}

class Gear: SKSpriteNode, Draggable
{
    var config: GameJSONConfig
    var teeth: Int
    var radius: CGFloat
    var pegon: CGPoint?
    var dragging: Bool = false
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        self.teeth = 0
        self.radius = 0
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        self.teeth = 0
        self.radius = 0
        config = GameJSONConfig()
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, config: GameJSONConfig, teeth: Int, radius: CGFloat)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.config = config
        self.teeth = teeth
        self.radius = radius
    }
    
    func selectAction(pos: CGPoint)
    {
        dragging = true
        self.setScale(1.1)
        if let pegon = self.pegon
        {
            for var peg in (parent as! Gearbox).pegs
            {
                if pegon == peg.point { peg.on = false }
            }
        }
    }
    
    func dropAction(pos: CGPoint)
    {
        dragging = false
        self.setScale(1)
        var pegto: (point: CGPoint, on: Bool)?
        for peg in (parent as! Gearbox).pegs
        {
            if pos.distance(toPoint: peg.point) < radius * config.scale
            {
                if let pegtocheck = pegto
                {
                    if pos.distance(toPoint: peg.point) < pos.distance(toPoint: pegtocheck.point)
                    {
                        if !peg.on { pegto = peg }
                    }
                } else
                {
                    if !peg.on { pegto = peg }
                }
            }
        }
        if let pegtocheck = pegto
        {
            run(SKAction.move(to: pegtocheck.point, duration: 0.2))
            pegto!.on = true
            pegon = pegtocheck.point
        }
    }
}

protocol Draggable{
    var dragging: Bool { get set }
    func selectAction(pos: CGPoint)
    func dropAction(pos: CGPoint)
}
