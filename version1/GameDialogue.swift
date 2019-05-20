//
//  GameDialogue.swift
//  GameTest1
//
//  Created by William Frank on 9/1/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

class GameDialogue
{
    private let name: String
    private var text: String?
    private var type: String?
    private var active: Int = 1
    private var exitaction: GameSpot?
    private var lines: [GameJSONLine]?
    private var branch: [GameDialogue]?
    private var action: GameSpot?
    
    init(name:String = "")
    {
        self.name = name
    }
    
    func getName() -> String
    {
        return name
    }
    
    func getText() -> String?
    {
        return text
    }
    
    func setText(text: String)
    {
        self.text = text
    }
    
    func getType() -> String?
    {
        return type
    }
    
    func setType(type: String)
    {
        self.type = type
    }
    
    func getActive() -> Int
    {
        return active
    }
    
    func setActive(active: Int)
    {
        self.active = active
    }
    
    func getExitAction() -> GameSpot?
    {
        return exitaction
    }
    
    func setExitAction(exitaction: GameSpot)
    {
        self.exitaction = exitaction
    }
    
    func getLines() -> [GameJSONLine]?
    {
        return lines
    }
    
    func setLines(lines: [GameJSONLine])
    {
        self.lines = lines
    }
    
    func setLineActive(line: String, active: Bool)
    {
        for (index, jsonline) in lines!.enumerated()
        {
            if jsonline.name == line
            {
                lines?[index].active = active
            }
        }
    }
    
    func getBranch() -> [GameDialogue]?
    {
        return branch
    }
    
    func setBranch(branch: [GameDialogue])
    {
        self.branch = branch
    }
    
    func getAction() -> GameSpot?
    {
        return action
    }
    
    func setAction(action: GameSpot)
    {
        self.action = action
    }
    
}
