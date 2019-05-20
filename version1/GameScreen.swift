//
//  GameScreen.swift
//  GameTest1
//
//  Created by William Frank on 8/28/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

class GameScreen: SKSpriteNode {
    
    var config: GameJSONConfig
    private weak var left: GameScreen?
    private weak var right: GameScreen?
    private weak var back: GameScreen?
    private var backactionname: String?
    private var backaction: GameSpot?
    private var grid: [GameSpot]?
    private var sequence: [String] = []
    private var sequencelength: Int?
    private var selected: SKSpriteNode?
    
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
    }
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder)
    {
        super.encode(with: coder)
        if let left = self.left { coder.encode(left.name, forKey: "left") }
        if let right = self.right { coder.encode(right.name, forKey: "right") }
        if let back = self.back { coder.encode(back.name, forKey: "back") }
    }
    
    func setLeft(left: GameScreen)
    {
        self.left = left
    }
    
    func setRight(right: GameScreen)
    {
        self.right = right
    }
    
    func setBack(back: GameScreen)
    {
        self.back = back
    }
    
    func setGrid(grid: [GameSpot])
    {
        self.grid = grid
    }
    
    func setSequenceLength(set: Int)
    {
        self.sequencelength = set
    }
    
    func getSelected() -> SKSpriteNode?
    {
        return selected
    }
    
    func setSelected(selected: SKSpriteNode)
    {
        clearSelected()
        self.selected = selected
        selected.addSelect()
        for child in selected.children
        {
            if child is SKSpriteNode { (child as! SKSpriteNode).addSelect(label: false) }
        }
    }
    
    func clearSelected()
    {
        if let selected = self.selected
        {
            selected.removeSelect()
            for child in selected.children
            {
                if child is SKSpriteNode { (child as! SKSpriteNode).removeSelect() }
            }
        }
        self.selected = nil
    }
    
    func pushSequence(push: String)
    {
        if let sequencelength = self.sequencelength
        {
            sequence.append(push)
            if sequence.count > sequencelength
            {
                sequence.removeFirst()
            }
        }
    }
    
    func clearSequence()
    {
        sequence = []
    }
    
    func getLeft() -> GameScreen?
    {
        if let left = self.left
        {
            return left
        }
        else
        {
            return nil
        }
    }
    
    func getRight() -> GameScreen?
    {
        if let right = self.right
        {
            return right
        }
        else
        {
            return nil
        }
    }
    
    func getBack() -> GameScreen?
    {
        if let back = self.back
        {
            return back
        }
        else
        {
            return nil
        }
    }
    
    func getBackActionName() -> String?
    {
        return backactionname
    }
    
    func setBackActionName(backactionname: String)
    {
        self.backactionname = backactionname
    }
    
    func getBackAction() -> GameSpot?
    {
        return backaction
    }
    
    func setBackAction(backaction: GameSpot)
    {
        self.backaction = backaction
    }
    
    func getGrid() -> [GameSpot]?
    {
        return grid
    }
    
    func getSequence() -> [String]
    {
        return sequence
    }
    
    func gridSelected(pos: CGPoint) -> GameSpot?
    {
        if let grid = self.grid
        {
            for spot in grid
            {
                if let loc = spot.getSpot()
                {
                    if loc.contains(pos) && spot.getActive()
                    {
                        return spot
                        
                    }
                }
            }
        }
        return nil
    }
}

