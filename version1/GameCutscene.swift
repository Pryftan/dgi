//
//  GameScene.swift
//  GameTest1
//
//  Created by William Frank on 8/27/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameCutscene: GameCommon {
    
    private var maxcount: Int = 0
    private var delay: Double = 0
    private var finale: Bool = false
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
    }
    
    override init(config: GameJSONConfig, jsonfile: String, menu: GameMenu)
    {
        super.init(config: config, jsonfile: jsonfile, menu: menu)
        currdialogue = dialogue[0]
    }
    
    override func didMove(to view: SKView) {
        
        super.didMove(to: view)
        childNode(withName: "Avatar")?.run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.fadeAlpha(to: 0.8, duration: 1), SKAction.run{ self.runDialogue(dialogue: self.currdialogue) }]))
    }
    
    @objc override func scrollDown()
    {
        
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if finale {
            let node: SKNode = self.atPoint(pos)
            if node == childNode(withName: "Remember")
            {
                childNode(withName: "Finale2")?.run(SKAction.fadeOut(withDuration: 1.5))
                childNode(withName: "Remember")?.run(SKAction.fadeOut(withDuration: 1.5))
                childNode(withName: "Forget")?.run(SKAction.fadeOut(withDuration: 1.5))
                GameSave.autosave.setFinale(choice: "Remember")
            } else if node == childNode(withName: "Forget")
            {
                childNode(withName: "Finale2")?.run(SKAction.fadeOut(withDuration: 1.5))
                childNode(withName: "Remember")?.run(SKAction.fadeOut(withDuration: 1.5))
                childNode(withName: "Forget")?.run(SKAction.fadeOut(withDuration: 1.5))
                GameSave.autosave.setFinale(choice: "Forget")
            }
            return
        }
        if let playerbox = childNode(withName: "PlayerBox"), let avatarbox = childNode(withName: "AvatarBox")
        {
            if playerbox.hasActions()
            {
                if (playerlines.count > 4 && avatarlines.count > 3)
                {
                    playerbox.removeAllActions()
                    avatarbox.removeAllActions()
                    playerlines.removeFirst(3)
                    avatarlines.removeFirst(3)
                    playerbox.run(SKAction.sequence(playerlines))
                    avatarbox.run(SKAction.sequence(avatarlines))
                    self.view?.isUserInteractionEnabled = true
                }
            }
        }
        if let dialoguebox = childNode(withName: "DialogueBox")
        {
            if (!dialoguebox.isHidden && dialoguebox.frame.contains(pos))
            {
                let select: Int = Int(config.dialoguerows) - 1 - Int((pos.y / (config.dialoguetext * config.scale + config.dialoguespace * config.scale)))
                if (select > Int(config.dialoguerows) || select < 0) { return }
                //print(select)
                if var branches = currdialogue.getBranch()
                {
                    if select >= branches.count { return }
                    let currbranch: GameDialogue = branches[select]
                    if let type = currbranch.getType()
                    {
                        if type == "Remove" {
                            if let toptype = currdialogue.getType()
                            {
                                if toptype.hasPrefix("Max")
                                {
                                    maxcount += 1
                                    if maxcount == Int(String(toptype.last!)) {
                                        maxcount = 0
                                        if var lines: [GameJSONLine] = currbranch.getLines()
                                        {
                                            dialoguecount += 1
                                            if dialoguecount < dialogue.count {
                                                currdialogue = dialogue[dialoguecount]
                                                if let currlines = currdialogue.getLines() { lines.append(contentsOf: currlines) }
                                                runLines(lines: lines, tobranch: currdialogue.getBranch())
                                                return
                                            } else
                                            {
                                                runLines(lines: lines, tobranch: nil)
                                                return
                                            }
                                        }
                                    }
                                }
                            }
                            branches.remove(at: select)
                            currdialogue.setBranch(branch: branches)
                        }
                        if (type == "Continue") {
                            dialoguecount += 1
                            if dialoguecount < dialogue.count {
                                currdialogue = dialogue[dialoguecount]
                                runDialogue(dialogue: currdialogue)
                            } else
                            {
                                if let lines: [GameJSONLine] = currbranch.getLines()
                                {
                                    runLines(lines: lines)
                                }
                                else
                                {
                                    runNextScene()
                                }
                            }
                        }
                        else if let lines: [GameJSONLine] = currbranch.getLines()
                        {
                            runLines(lines: lines, tobranch: branches)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    func runDialogue(dialogue: GameDialogue)
    {
        if let lines: [GameJSONLine] = dialogue.getLines()
        {
            if let branch: [GameDialogue] = dialogue.getBranch()
            {
                runLines(lines: lines, tobranch: branch)
            }
            else
            {
                runLines(lines: lines)
            }
            
        } else
        {
            if let branch: [GameDialogue] = dialogue.getBranch()
            {
                runBranch(branch: branch)
            }
        }
    }
    
    func runBranch(branch: [GameDialogue])
    {
        if let dialoguebox = childNode(withName: "DialogueBox")
        {
            dialoguebox.isHidden = false
            for val in (0..<10)
            {
                let dialogueline: SKLabelNode = dialoguebox.childNode(withName: "Line \(val+1)") as! SKLabelNode
                if val < branch.count
                {
                    dialogueline.text = branch[val].getText()
                } else
                {
                    dialogueline.text = ""
                }
                if val > Int(config.dialoguerows) { dialogueline.isHidden = true }
            }
        }
    }
    
    func runLines(lines: [GameJSONLine], tobranch: [GameDialogue]? = nil)
    {
        if let dialoguebox: SKNode = childNode(withName: "DialogueBox")
        {
            dialoguebox.isHidden = true
        }
        if let avatarbox: SKNode = childNode(withName: "AvatarBox"), let playerbox: SKNode = childNode(withName: "PlayerBox")
        {
            avatarlines = []
            playerlines = []
            for line in lines
            {
                if let active = line.active
                {
                    if !active { continue }
                }
                if line.character == "Avatar"
                {
                    let linetext: String = line.line
                    if linetext == ""
                    {
                        avatarlines.append(SKAction.hide())
                        avatarlines.append(SKAction.hide())
                    }
                    else
                    {
                        avatarlines.append(SKAction.run{ [weak avatarbox, linetext] in (avatarbox?.childNode(withName: "AvatarText") as! SKLabelNode).text = linetext
                            
                        })
                        avatarlines.append(SKAction.unhide())
                    }
                    if let skippable = line.skippable, !skippable
                    {
                        avatarlines.append(SKAction.sequence([SKAction.run{ self.view?.isUserInteractionEnabled = false }, SKAction.wait(forDuration: line.duration), SKAction.run{ self.view?.isUserInteractionEnabled = true }]))
                    } else
                    {
                        avatarlines.append(SKAction.wait(forDuration: line.duration))
                    }
                    
                    playerlines.append(SKAction.hide())
                    playerlines.append(SKAction.wait(forDuration: line.duration))
                    playerlines.append(SKAction.run{
                        self.avatarlines.removeFirst(3)
                        self.playerlines.removeFirst(3)
                    })
                }
                if line.character == "Player"
                {
                    let linetext: String = line.line
                    if linetext == ""
                    {
                        playerlines.append(SKAction.hide())
                        playerlines.append(SKAction.hide())
                    }
                    else
                    {
                        playerlines.append(SKAction.run{ [weak playerbox, linetext] in (playerbox?.childNode(withName: "PlayerText") as! SKLabelNode).text = linetext})
                        playerlines.append(SKAction.unhide())
                    }
                    if let skippable = line.skippable, !skippable
                    {
                        playerlines.append(SKAction.sequence([SKAction.run{ self.view?.isUserInteractionEnabled = false }, SKAction.wait(forDuration: line.duration), SKAction.run{ self.view?.isUserInteractionEnabled = true }]))
                    } else
                    {
                        playerlines.append(SKAction.wait(forDuration: line.duration))
                    }
                    avatarlines.append(SKAction.hide())
                    avatarlines.append(SKAction.wait(forDuration: line.duration))
                    avatarlines.append(SKAction.run{
                        self.playerlines.removeFirst(3)
                        self.avatarlines.removeFirst(3)
                    })
                }
                if line.character == "Image"
                {
                    let showImage: [SKAction] = [
                        SKAction.fadeIn(withDuration: 0.7),
                        SKAction.wait(forDuration: line.duration - 1.4),
                        SKAction.fadeOut(withDuration: 0.7)
                    ]
                    avatarlines.append(SKAction.hide())
                    avatarlines.append(SKAction.wait(forDuration: line.duration))
                    avatarlines.append(SKAction.run{
                        self.playerlines.removeFirst(3)
                        self.avatarlines.removeFirst(3)
                    })
                    playerlines.append(SKAction.hide())
                    playerlines.append(SKAction.hide())
                    playerlines.append(SKAction.run{
                        self.childNode(withName: line.line)?.run(SKAction.sequence(showImage))
                    })
                }
            }
            avatarlines.append(SKAction.hide())
            playerlines.append(SKAction.hide())
            if let branch: [GameDialogue] = tobranch
            {
                playerlines.append(SKAction.run{
                    self.runBranch(branch: branch)
                })
            } else
            {
                if currdialogue.getName() == "Finale"
                {
                    playerlines.append(SKAction.run{
                        self.runFinale()
                    })
                } else {
                    playerlines.append(SKAction.run{
                        super.runNextScene()
                    })
                }
            }
            avatarbox.run(SKAction.sequence(avatarlines), withKey: "AvatarLines")
            playerbox.run(SKAction.sequence(playerlines), withKey: "PlayerLines")
        }
        
    }
    
    override func loadJSON(withName: String)
    {
        guard let url = Bundle.main.url(forResource: withName, withExtension: "json") else {
            print("Error finding JSON")
            return
        }
        guard let data = try? Data(contentsOf: url) else
        {
            print("Error loading JSON")
            return
        }
        guard let jsonData = try? JSONDecoder().decode(GameJSONCutscene.self, from: data) else
        {
            print("Error parsing JSON")
            return
        }
        if let delay  = jsonData.delay { self.delay = delay }
        if let music = jsonData.music
        {
            do
            {
                self.music = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: music + ".mp3", ofType: nil)!))
                self.music!.numberOfLoops = -1
            } catch {
                print("Music Error")
            }
        }
        if let images: [GameJSONSub] = jsonData.images
        {
            var currZ:CGFloat = 0.1
            for image in images
            {
                let addimage = SKSpriteNode(imageNamed: image.image)
                addimage.name = image.name
                if let anchor:[CGFloat] = image.anchor
                {
                    addimage.anchorPoint = CGPoint(x:anchor[0], y:anchor[1]) 
                } else { addimage.anchorPoint = CGPoint(x:0, y:0) }
                addimage.position = CGPoint(x: image.sub[0] * config.scale, y: image.sub[1] * config.scale)
                addimage.zPosition = currZ
                currZ += 0.01
                if let vis = image.visible { addimage.isHidden = !vis }
                if let opacity = image.opacity { addimage.alpha = CGFloat(opacity)}
                if let rotate = image.rotate { addimage.zRotation = -1 * rotate * CGFloat(Double.pi)/180 }
                if let frames = image.frames
                {
                    var actions: [SKAction] = []
                    for frame in frames
                    {
                        if frame.frame == "rotateby"
                        {
                            actions.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi/180), duration: frame.duration))
                        }
                        else if frame.frame == "opacityto"
                        {
                            actions.append(SKAction.fadeAlpha(to: frame.pos![0], duration: frame.duration))
                        }
                    }
                    addimage.run(SKAction.repeatForever(SKAction.sequence(actions)))
                }
                addChild(addimage)
            }
        }
        for dialogue in jsonData.dialogue
        {
            loadJSONDialogue(dialogue: dialogue)
        }
    }
    
    func loadJSONDialogue(dialogue: GameJSONDialogue)
    {
        let currdialogue = GameDialogue(name: dialogue.name)
        if let type: String = dialogue.type
        {
            currdialogue.setType(type: type)
        }
        if let lines: [GameJSONLine] = dialogue.lines
        {
            currdialogue.setLines(lines: lines)
        }
        //var exits: [GameSpot] = []
        //if let sharedexit: [GameJSONGrid]
        //{
        //    for exit in sharedexit
        //    {
        //        exits.append(loadJSONAction(exit))
        //    }
        //}
        if let branch: [GameJSONBranch] = dialogue.branch
        {
            var branchlist: [GameDialogue] = []
            for currbranch in branch
            {
                //branchlist.append(loadJSONBranch(branch: currbranch, exitactions: exits))
                branchlist.append(loadJSONBranch(branch: currbranch))
                
            }
            currdialogue.setBranch(branch: branchlist)
        }
        self.dialogue.append(currdialogue)
    }
    
    //func loadJSONBranch(branch: GameJSONBranch, exitactions: [GameSpot]) -> GameDialogue
    func loadJSONBranch(branch: GameJSONBranch) -> GameDialogue
    {
        let currbranch = GameDialogue(name: branch.name)
        if let text = branch.text
        {
            currbranch.setText(text: text)
        }
        if let type = branch.type
        {
            currbranch.setType(type: type)
        }
        if let active = branch.active
        {
            if active { currbranch.setActive(active: 1) }
            else if !active { currbranch.setActive(active: 0) }
        }
        //if let exittype = branch.exittype
        //{
        //    for spot in exitactions
        //    {
        //        if spot.getName() == exittype
        //        {
        //            currbranch.setExitAction(exitaction: spot)
        //        }
        //    }
        //}
        if let lines = branch.lines
        {
            currbranch.setLines(lines: lines)
        }
        if let branch = branch.branch
        {
            var branchlist: [GameDialogue] = []
            for currbranch in branch
            {
                //branchlist.append(loadJSONBranch(branch: currbranch, exitactions: exitactions))
                branchlist.append(loadJSONBranch(branch: currbranch))
            }
            currbranch.setBranch(branch: branchlist)
        }
        //if let action = branch.action
        //{
        //    currbranch.setAction(action: loadJSONSpot(currgrid: action))
        //}
        
        return currbranch
    }
    
    func runFinale()
    {
        finale = true
        let finale1 = SKSpriteNode(imageNamed: "finale1")
        let finale2 = SKSpriteNode(imageNamed: "finale2")
        let remember = SKSpriteNode(imageNamed: "remember")
        let forget = SKSpriteNode(imageNamed: "forget")
        finale1.name = "Finale1"
        finale2.name = "Finale2"
        remember.name = "Remember"
        forget.name = "Forget"
        finale1.anchorPoint = CGPoint(x: 0, y: 0)
        finale2.anchorPoint = CGPoint(x: 0, y: 0)
        remember.anchorPoint = CGPoint(x: 0, y: 0)
        forget.anchorPoint = CGPoint(x: 0, y: 0)
        finale1.position = CGPoint(x: 518 * config.scale, y: 730 * config.scale)
        finale2.position = CGPoint(x: 600 * config.scale, y: 585 * config.scale)
        remember.position = CGPoint(x: 167 * config.scale, y: 264 * config.scale)
        forget.position = CGPoint(x: 1125 * config.scale, y: 273 * config.scale)
        finale1.alpha = 0
        finale2.alpha = 0
        remember.alpha = 0
        forget.alpha = 0
        addChild(finale1)
        addChild(finale2)
        addChild(remember)
        addChild(forget)
        finale1.run(SKAction.sequence([SKAction.wait(forDuration: 2), SKAction.fadeIn(withDuration: 1)]))
        finale2.run(SKAction.sequence([SKAction.wait(forDuration: 4), SKAction.fadeIn(withDuration: 1)]))
        remember.run(SKAction.sequence([SKAction.wait(forDuration: 5), SKAction.fadeIn(withDuration: 1)]))
        forget.run(SKAction.sequence([SKAction.run{ self.view?.isUserInteractionEnabled = false },SKAction.wait(forDuration: 6), SKAction.fadeIn(withDuration: 1), SKAction.run{ self.view?.isUserInteractionEnabled = true }]))
    }
}
