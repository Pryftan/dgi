//
//  GameInvObj.swift
//  GameTest1
//
//  Created by William Frank on 8/29/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

class GameInvObj: SKSpriteNode {
    
    private var scale: CGFloat?
    private var animations: [GameJSONAnimation]?
    private var collects: [GameInvObj]?
    private var iscollected: Bool = false
    private var subs: [GameJSONInvSub]?
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, name: String, scale: CGFloat)
    {
        
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.name = name
        self.scale = scale
    }

    convenience init(imageNamed: String, name: String, scale: CGFloat, animations: [GameJSONAnimation]?, displayname: String?, subs: [GameJSONInvSub]?)
    {
        
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.name = name
        self.scale = scale
        self.animations = animations
        self.subs = subs
        userData = NSMutableDictionary()
        if let displayname = displayname
        {
            userData?.setValue(displayname, forKeyPath: "displayname")
        }
        if let subs = self.subs {
            for sub in subs {
                let newsub = SKSpriteNode(imageNamed: sub.image)
                if let relZ = sub.relZ { newsub.zPosition = zPosition + relZ }
                if let visible = sub.visible { if !visible { newsub.isHidden = true }}
                addChild(newsub)
            }
        }
    }
    
    func getScale() -> CGFloat
    {
        if let scale = self.scale
        {
            return scale
        }
        return 0
    }
    
    func getAnimation(animNamed: String) -> GameJSONAnimation?
    {
        if let animations = self.animations
        {
            for animation in animations
            {
                if animation.name == animNamed
                {
                    return animation
                }
            }
        }
        return nil
    }
    
    func getCollects() -> [GameInvObj]?
    {
        return collects
    }
    
    func setCollects(collects: [GameInvObj])
    {
        self.collects = collects
    }
    
    func isCollected() -> Bool
    {
        return iscollected
    }
    
    func setCollected(collected: Bool)
    {
        iscollected = collected
    }
    
    func getSubs() -> [GameJSONInvSub]?
    {
        return subs
    }
}
