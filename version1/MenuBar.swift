//
//  MenuBar.swift
//  DGI: Soldier
//
//  Created by William Frank on 2/3/19.
//  Copyright © 2019 William Frank. All rights reserved.
//

import SpriteKit

class MenuBar: SKSpriteNode
{
    var config: GameJSONConfig
    var titleScreen = SKLabelNode(fontNamed: "Arial")
    var manualSave = SKLabelNode(fontNamed: "Arial")
    var settings = SKLabelNode(fontNamed: "Arial")
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        config = GameJSONConfig()
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, config: GameJSONConfig)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.config = config
        self.name = "MenuBar"
        self.setScale(config.invscale * 0.75)
        self.zRotation = CGFloat(Double.pi)
        //self.position = CGPoint(x: 30, y: 400)
        self.zPosition = 4
        self.position = CGPoint(x: config.invspace + size.width / 2, y: config.baseheight - (config.invspace * 0.5 + size.height))
        
        titleScreen.text = "Title Screen"
        titleScreen.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        titleScreen.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        titleScreen.fontName = "Palatino"
        titleScreen.fontSize = config.dialoguetext * config.scale * 0.75
        titleScreen.position = CGPoint(x: size.width, y: 0)
        addChild(titleScreen)
    }
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        super.init(coder: decoder)
    }
    
    func touchUp(pos: CGPoint) -> Int
    {
        if titleScreen.frame.contains(convert(pos, from: parent!))
        {
            return 1
        }
        return 0
    }
    
    func openBar()
    {
        run(SKAction.rotate(toAngle: 0, duration: 1))
        //titleScreen.run(SKAction.move(to: CGPoint(x: size.width + config.invspace, y: config.invspace), duration: 1))
    }
    
    func closeBar()
    {
        run(SKAction.rotate(toAngle: CGFloat(Double.pi), duration: 1))
        //titleScreen.run(SKAction.move(by: CGVector(dx: 0, dy: 2 * config.invspace), duration: 1))
    }
    
}
