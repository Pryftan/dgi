//
//  Extensions.swift
//  Retrograde
//
//  Created by William Frank on 9/13/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

extension CGPoint
{
    func distance(toPoint p: CGPoint) -> CGFloat
    {
        return sqrt(pow(x-p.x,2) + pow(y-p.y,2))
    }
}

extension SKSpriteNode
{
    func addSelect(radius: Float = 50, label: Bool = true)
    {
        color = UIColor.red
        colorBlendFactor = 1
        let effectNode = SKEffectNode()
        effectNode.name = "Glow"
        effectNode.shouldRasterize = true
        effectNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        addChild(effectNode)
        effectNode.addChild(SKSpriteNode(texture: texture))
        effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])
        if label {
            let labelNode = SKLabelNode()
            labelNode.name = "Label"
            labelNode.fontSize = 14 / self.xScale
            labelNode.fontName = "Palatino"
            if let displayname: String = userData?.value(forKey: "displayname") as? String
            {
                labelNode.text = displayname
            } else { labelNode.text = name }
            labelNode.zPosition = self.zPosition + 0.1
            labelNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            addChild(labelNode)
        }
    }
    
    func removeSelect()
    {
        color = UIColor.white
        childNode(withName: "Glow")?.removeFromParent()
        childNode(withName: "Label")?.removeFromParent()
    }
    
    func changeDisplayName(newname: String)
    {
        userData?.setValue(newname, forKeyPath: "displayname")
        if let label: SKLabelNode = childNode(withName: "Label") as? SKLabelNode
        {
            label.text = newname
        }
    }
}
