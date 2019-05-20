//
//  GameScene.swift
//  GameTest1
//
//  Created by William Frank on 8/27/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: GameCommon {
    
    private weak var thisscreen : GameScreen?
    private var menubar: MenuBar?
    private var subtitle: SKLabelNode?
    private var invbox: SKSpriteNode?
    private var invout: Bool = false
    private var invsounds: [AVAudioPlayer] = []
    private var invcount: Int = 0
    private var masterinv: [GameInvObj] = []
    private var currentinv: [GameInvObj] = []
    private var collected: Int = 0
    private var selected: GameInvObj?
    private var inView: Bool = false
    private var arcadename: String?
    private weak var thisview: GameScreen?
    private var dragobj: Draggable?
    private var states: [GameParsedState] = []
    private var flickers: [GameParsedFlicker] = []
    private var globanims: [GameJSONAnimation] = []
    private var flags: [String: Bool] = [:]
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
    }
    
    override init(config: GameJSONConfig, jsonfile: String, menu: GameMenu)
    {
        super.init(config: config, jsonfile: jsonfile, menu: menu)
        
        menubar = MenuBar.init(imageNamed: "config", config: config)
        addChild(menubar!)
        
        self.subtitle = SKLabelNode.init(text: "Test location")
        subtitle?.fontSize = CGFloat(config.subtitletext * config.scale)
        subtitle?.fontName = "Arial"
        subtitle?.position = CGPoint(x: config.basewidth / 2, y: config.subtitley * config.scale)
        subtitle?.zPosition = 3
        subtitle?.isHidden = true
        addChild(subtitle!)
        
        invbox = SKSpriteNode.init(imageNamed: "invbox")
        invbox?.setScale(CGFloat(config.invscale))
        invbox?.position = CGPoint(x: (config.invspace + (config.invunit * config.scale / 2)) * config.invscale, y: (config.invspace * config.scale + (config.invunit * config.scale / 2)) * config.invscale)
        invbox?.zPosition = 2
        addChild(invbox!)
    }
    
    override func didMove(to view: SKView) {
        
        super.didMove(to: view)
        childNode(withName: "Avatar")?.alpha = 0.8
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if thisscreen is Gearbox
        {
            for gear in (thisscreen as! Gearbox).gears
            {
                if gear.contains(pos)
                {
                    dragobj = gear as Draggable
                    dragobj!.selectAction(pos: pos)
                    disableGestures()
                }
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let dragobj = self.dragobj
        {
            if dragobj.dragging {
                (dragobj as? SKNode)?.position = pos
            }
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let dragobj = self.dragobj
        {
            if dragobj.dragging
            {
                dragobj.dropAction(pos: pos)
                enableGestures()
            }
        }
        if cam!.xScale != 1
        {
            if let spot: GameSpot = thisscreen!.gridSelected(pos: pos)
            {
                if let _ = spot.getPhoneZoom()
                {
                    
                } else
                {
                    cam!.run(SKAction.group([SKAction.move(to: CGPoint(x: config.basewidth / 2, y: config.baseheight / 2), duration: 0.6), SKAction.scale(to: 1, duration: 0.6)]))
                }
            } else
            {
                cam!.run(SKAction.group([SKAction.move(to: CGPoint(x: config.basewidth / 2, y: config.baseheight / 2), duration: 0.6), SKAction.scale(to: 1, duration: 0.6)]))
            }
        }
        if thisscreen?.name == arcadename && arcadename != nil
        {
            (thisscreen as! GameArcade).touchUp(pos: pos)
            return
        }
        if menubar!.contains(pos)
        {
            removeAction(forKey: "MenuBarClose")
            menubar!.openBar()
            run(SKAction.sequence([SKAction.wait(forDuration:4), SKAction.run{ self.menubar!.closeBar() }]), withKey: "MenuBarClose")
            if menubar!.touchUp(pos: pos) == 1
            {
                print("title selected")
                music?.stop()
                view?.presentScene(menu)
            }
            return
        }
        if inView
        {
            if let viewnode = thisview
            {
                if pos.y < (2 * config.invspace * config.scale + config.invunit * config.scale) * config.invscale
                {
                    if pos.x < (2 * config.invspace * config.scale + config.invunit * config.scale) * config.invscale
                    {
                        openInv()
                        return
                    } else if invbox!.zRotation < CGFloat(-86 * Double.pi/180)
                    {
                        openInv()
                        selectInv(pos: pos)
                    }
                } else if viewnode.frame.contains(pos)
                {
                    if let spot: GameSpot = viewnode.gridSelected(pos: pos)
                    {
                        runGameSpot(spot: spot)
                    }
                } else {
                    viewnode.isHidden = true
                    inView = false
                    enableGestures()
                }
            }
            return
        }
        if (leftSwipe.state == UIGestureRecognizer.State.possible || leftSwipe.state == UIGestureRecognizer.State.failed) && (rightSwipe.state == UIGestureRecognizer.State.possible || rightSwipe.state == UIGestureRecognizer.State.failed) && (downSwipe.state == UIGestureRecognizer.State.possible || downSwipe.state == UIGestureRecognizer.State.failed) && (upSwipe.state == UIGestureRecognizer.State.possible || upSwipe.state == UIGestureRecognizer.State.failed)
        {
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
                    }
                    return
                }
            }
            if let dialoguebox = childNode(withName: "DialogueBox")
            {
                if !dialoguebox.isHidden
                {
                    if dialoguebox.frame.contains(pos)
                    {
                        let select: Int = Int(config.dialoguerows) - 1 - Int((pos.y / (config.dialoguetext * config.scale + config.dialoguespace * config.scale))) + scrollVal
                        if var branches = currdialogue.getBranch()
                        {
                            if (select > branches.count || select < 0) { return }
                            var realcount: Int = 0
                            var currbranch: GameDialogue = branches[0]
                            for count in (0...select)
                            {
                                if realcount < branches.count { while branches[realcount].getActive() != 1 { realcount += 1 } }
                                if realcount >= branches.count { return }
                                if count == select { currbranch = branches[realcount] }
                                realcount += 1
                            }
                            scrollVal = 0
                            for (index, line) in dialoguebox.children.enumerated()
                            {
                                if index < Int(config.dialoguerows) {
                                    line.isHidden = false
                                    line.alpha = 1
                                }
                                else { line.isHidden = true }
                                var ypos = (config.dialoguetext + config.dialoguespace)  * config.scale * (config.dialoguerows - CGFloat(index))
                                ypos -= dialoguebox.frame.maxY / 2 + config.dialoguespace * config.scale
                                line.position = CGPoint(x: -1 * dialoguebox.frame.maxX / 2 + config.dialoguespace * config.scale, y: ypos)
                            }
                            if let action = currbranch.getAction()
                            {
                                runGameSpot(spot: action)
                            }
                            if let exitaction = currbranch.getExitAction()
                            {
                                dialoguebox.isHidden = true
                                runGameSpot(spot: exitaction)
                                invbox?.run(SKAction.fadeIn(withDuration: 0.5))
                                menubar?.run(SKAction.fadeIn(withDuration: 0.5))
                                leftSwipe.isEnabled = true
                                rightSwipe.isEnabled = true
                            } else
                            {
                                runDialogue(dialogue: currbranch)
                            }
                        }
                    }
                    return
                }
            }
            if let avatarimg = childNode(withName: "Avatar")
            {
                if pos.x > (config.basewidth - avatarimg.frame.width - config.avatarspace * config.scale) && pos.y > (config.baseheight - avatarimg.frame.height - config.avatarspace * config.scale)
                {
                    for branch in dialogue
                    {
                        if branch.getName() == "Avatar"
                        {
                            invbox?.run(SKAction.fadeOut(withDuration: 0.5))
                            menubar?.run(SKAction.fadeOut(withDuration: 0.5))
                            if (invout)
                            {
                                invout = false
                                let center: CGFloat = (config.invspace * config.scale + (config.invunit * config.scale / 2)) * config.invscale
                                let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
                                for object in currentinv
                                {
                                    object.run(hideobj, withKey: "HideObj")
                                    object.removeSelect()
                                }
                            }
                            runDialogue(dialogue: branch)
                        }
                    }
                    return
                }
            }
            if pos.y < (2 * config.invspace * config.scale + config.invunit * config.scale) * config.invscale
            {
                if pos.x < (2 * config.invspace * config.scale + config.invunit * config.scale) * config.invscale
                {
                    openInv()
                    return
                } else if invbox!.zRotation < CGFloat(-86 * Double.pi/180)
                {
                    openInv()
                    selectInv(pos: pos)
                }
            }
            if thisscreen == nil { return }
            if let spot: GameSpot = thisscreen!.gridSelected(pos: pos)
            {
                runGameSpot(spot: spot)
            }
        }
    }
    
    @objc override func moveLeft()
    {
        if let left : GameScreen = thisscreen?.getLeft()
        {
            thisscreen?.clearSelected()
            left.run(SKAction.sequence([SKAction.moveBy(x: -1 * config.basewidth, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: config.basewidth, y: 0, duration: 0.15)]))
            thisscreen?.run(SKAction.sequence([SKAction.moveBy(x: config.basewidth, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: -1 * config.basewidth, y: 0, duration: 0)]))
            thisscreen = left
            return
        }
    }
    
    @objc override func moveRight()
    {
        if let right : GameScreen = thisscreen?.getRight()
        {
            thisscreen?.clearSelected()
            right.run(SKAction.sequence([SKAction.moveBy(x: config.basewidth, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: -1 * config.basewidth, y: 0, duration: 0.15)]))
            thisscreen?.run(SKAction.sequence([SKAction.moveBy(x: -1 * config.basewidth, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: config.basewidth, y: 0, duration: 0)]))
            thisscreen = right
            return
        }
    }
    
    @objc override func scrollDown()
    {
        if let dialoguebox = childNode(withName: "DialogueBox")
        {
            if !dialoguebox.isHidden && (scrollVal + Int(config.dialoguerows)) < currdialogue.getBranch()!.count
            {
                scrollVal += 1
                for (index, line) in dialoguebox.children.enumerated()
                {
                    if index < scrollVal
                    {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: (config.dialoguetext + config.dialoguespace) * config.scale, duration: 0.1), SKAction.fadeOut(withDuration: 0.1), SKAction.hide()]))
                    } else {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: (config.dialoguetext + config.dialoguespace) * config.scale, duration: 0.1), SKAction.unhide(), SKAction.fadeIn(withDuration: 0.1)]))
                    }
                    
                }
            }
        }
    }
    
    @objc override func scrollUp()
    {
        if let dialoguebox = childNode(withName: "DialogueBox")
        {
            if !dialoguebox.isHidden && scrollVal > 0
            {
                scrollVal -= 1
                for (index, line) in dialoguebox.children.enumerated()
                {
                    if index < scrollVal
                    {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: -1 * (config.dialoguetext + config.dialoguespace) * config.scale, duration: 0.1), SKAction.fadeOut(withDuration: 0.1), SKAction.hide()]))
                    } else {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: -1 * (config.dialoguetext + config.dialoguespace) * config.scale, duration: 0.1), SKAction.unhide(), SKAction.fadeIn(withDuration: 0.1)]))
                    }
                    
                }
            } else if dialoguebox.isHidden
            {
                if inView
                {
                    if let viewnode = thisview
                    {
                        viewnode.isHidden = true
                        inView = false
                        enableGestures()
                    }
                    return
                } else if let back : GameScreen = thisscreen?.getBack()
                {
                    if let backaction: GameSpot = thisscreen?.getBackAction()
                    {
                        runGameSpot(spot: backaction)
                    }
                    thisscreen?.clearSelected()
                    back.isHidden = false
                    thisscreen?.isHidden = true
                    thisscreen = back
                    return
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
        if (invbox?.zRotation == 0)
        {
            selected = nil
        }
        for (index, state) in states.enumerated().reversed()
        {
            if state.action!.getActive()
            {
                var satisfied: Bool = true
                if let screen: GameScreen = state.sequencescreen, let sequence: String = state.sequence
                {
                    if state.type == "wrong" {
                        satisfied = false
                        for (index, line) in screen.getSequence().enumerated() {
                            if index < sequence.count { if sequence[sequence.index(sequence.startIndex, offsetBy: index)] != line[line.index(line.startIndex, offsetBy: 0)] { satisfied = true } }
                        }
                        if satisfied {
                            screen.clearSequence()
                        }
                    }
                    else {
                        var alltogether: String = ""
                        for line in screen.getSequence() { alltogether += line }
                        if alltogether != sequence { satisfied = false }
                    }
                }
                if let visibles: [(sub: SKSpriteNode, vis: Bool)] = state.visibles {
                    for visible in visibles
                    {
                        if visible.sub.isHidden == visible.vis { satisfied = false }
                    }
                }
                if let cycles: [(spot: GameSpot, val: Int)] = state.cycles {
                    for cycle in cycles
                    {
                        if cycle.spot.getCycleCounter() != cycle.val { satisfied = false }
                    }
                }
                if let flags: [GameJSONFlagState] = state.flags
                {
                    for flag in flags
                    {
                        if self.flags[flag.name] != flag.value { satisfied = false }
                    }
                }
                if satisfied
                {
                    if let spot: GameSpot = state.action { if spot.getActive()
                    {
                        if let _ = spot.getAnimate()
                        {
                            spot.setActive(active: false)
                        }
                        runGameSpot(spot: spot)
                            
                    } }
                    if state.type == "once"
                    {
                        states.remove(at: index)
                        GameSave.autosave.addState(name: state.name)
                        GameSave.autosave.save()
                    }
                }
                else
                {
                    if let spot: GameSpot = state.action
                    {
                        if let flag: String = spot.getFlag()
                        {
                            flags[flag] = false
                        }
                    }
                }
            }
        }
        for flicker in flickers
        {
            let random = Int(arc4random_uniform(UInt32(flicker.frequency * 60)))
            if random == 50
            {
                for sub in flicker.subs
                {
                    if flicker.type == "ifvisible" && !sub.isHidden {
                        sub.removeAllActions()
                        sub.run(SKAction.sequence([SKAction.hide(), SKAction.wait(forDuration: 0.2), SKAction.unhide(), SKAction.wait(forDuration: 0.4), SKAction.hide(), SKAction.wait(forDuration: 0.7), SKAction.unhide()]))
                    }
                }
            }
        }
    }
    
    func runDialogue(dialogue: GameDialogue)
    {
        currdialogue = dialogue
        leftSwipe.isEnabled = false
        rightSwipe.isEnabled = false
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
            var realcount: Int = 0
            for val in (0..<10)
            {
                let dialogueline: SKLabelNode = dialoguebox.childNode(withName: "Line \(val+1)") as! SKLabelNode
                dialogueline.text = ""
                breaklabel: if realcount < branch.count
                {
                    while branch[realcount].getActive() != 1 {
                        realcount += 1
                        if realcount >= branch.count { break breaklabel }
                    }
                    dialogueline.text = branch[realcount].getText()
                } else
                {
                    dialogueline.text = ""
                }
                if val > Int(config.dialoguerows) { dialogueline.isHidden = true }
                realcount += 1
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
                    avatarlines.append(SKAction.run{ [weak avatarbox, linetext] in (avatarbox?.childNode(withName: "AvatarText") as! SKLabelNode).text = linetext
                        
                    })
                    avatarlines.append(SKAction.unhide())
                    avatarlines.append(SKAction.wait(forDuration: line.duration))
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
                    playerlines.append(SKAction.run{ [weak playerbox, linetext] in (playerbox?.childNode(withName: "PlayerText") as! SKLabelNode).text = linetext})
                    playerlines.append(SKAction.unhide())
                    playerlines.append(SKAction.wait(forDuration: line.duration))
                    avatarlines.append(SKAction.hide())
                    avatarlines.append(SKAction.wait(forDuration: line.duration))
                    avatarlines.append(SKAction.run{
                        self.playerlines.removeFirst(3)
                        self.avatarlines.removeFirst(3)
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
                playerlines.append(SKAction.run{ [invbox, menubar] in
                    invbox?.run(SKAction.fadeIn(withDuration: 0.5))
                    menubar?.run(SKAction.fadeIn(withDuration: 0.5))
                    self.leftSwipe.isEnabled = true
                    self.rightSwipe.isEnabled = true
                })
            }
            avatarbox.run(SKAction.sequence(avatarlines), withKey: "AvatarLines")
            playerbox.run(SKAction.sequence(playerlines), withKey: "PlayerLines")
        }
        
    }
    
    func openInv()
    {
        invout = true
        invbox?.removeAllActions()
        invbox?.run(SKAction.sequence([SKAction.rotate(toAngle: CGFloat(-87*Double.pi/180), duration: 0.7),SKAction.wait(forDuration: 4),SKAction.rotate(toAngle: 0, duration: 0.5)]))
        let center: CGFloat = (config.invspace + (config.invunit / 2)) * config.invscale * config.scale
        let block: CGFloat = (config.invspace + config.invunit) * config.invscale * config.scale
        var realindex: Int = 0
        for (index, object) in currentinv.enumerated()
        {
            object.removeAllActions()
            realindex += 1
            var movepos: CGFloat = block * CGFloat(realindex) + center
            
            if let collects: [GameInvObj] = object.getCollects()
            {
                for object2 in collects
                {
                    for index2 in (0..<index)
                    {
                        if currentinv[index2] == object2
                        {
                            movepos = block * CGFloat(index2 + 1) + center
                            realindex += -1
                        }
                        //break - look up swift break context
                    }
                }
            }
            
            let showobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: movepos, y: center), duration: 0.5), SKAction.scale(to: object.getScale() * config.invscale, duration: 0.5)])
            let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.run{ [weak object] in object?.removeSelect()}, SKAction.scale(to: 0, duration: 0.5)])
            let clearselect: SKAction = SKAction.run({
                for object in self.currentinv
                {
                    object.removeSelect()
                }
            })
            object.run(SKAction.sequence([SKAction.unhide(), showobj, SKAction.wait(forDuration: 4), hideobj, clearselect]), withKey: "ShowObj")
        }
    }
    
    func selectInv(pos: CGPoint)
    {
        let block: CGFloat = (config.invspace * config.scale + config.invunit * config.scale) * config.invscale
        var objindex: Int = Int(pos.x / block) - 1
        if objindex < currentinv.count - collected
        {
            for (index, object) in currentinv.enumerated()
            {
                object.removeSelect()
                if (object.isCollected() && objindex >= index) { objindex += 1 }
            }
            currentinv[objindex].addSelect()
            selected = currentinv[objindex]
            if let collects: [GameInvObj] = currentinv[objindex].getCollects()
            {
                for object in currentinv
                {
                    if collects.contains(object)
                    {
                        object.addSelect()
                    }
                }
            }
            return
        }
    }
    
    func closeInv()
    {
        let center: CGFloat = (config.invspace + (config.invunit / 2)) * config.invscale * config.scale
        let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
        //let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.colorize(with: UIColor.white, colorBlendFactor: 1, duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
        let clearselect: SKAction = SKAction.run({
            for object in self.currentinv
            {
                object.removeSelect()
            }
        })
        for object in currentinv {
            object.removeAllActions()
            object.run(SKAction.sequence([hideobj, clearselect]), withKey: "HideObj")
        }
    }
    
    func runAnimation(animation: GameJSONAnimation, delay: Double = 0) -> Double
    {
        var last: SKSpriteNode?
        var lasttype: String = ""
        var lastparent: String?
        var lastgrandparent: String?
        var delay: Double = delay
        var actionGroup: [SKAction] = []
        if let freeze = animation.freeze { self.view?.isUserInteractionEnabled = !freeze }
        else { self.view?.isUserInteractionEnabled = false }
        var oldthis: String?
        if animation.frames[animation.frames.count - 1].frame == "releaseto"
        {
            oldthis = thisscreen!.name
            thisscreen = childNode(withName: animation.frames[animation.frames.count - 1].name!) as? GameScreen
        }
        for frame in animation.frames
        {
            var pauses: Bool = true
            var useframe: GameJSONFrame = frame
            if var flag = frame.flag
            {
                if flag.first == "!"
                {
                    flag.removeFirst()
                    run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{self.flags[flag] = false}]))
                } else { run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{self.flags[flag] = true}])) }
            }
            if let flagframes = frame.flagframes
            {
                for flagframe in flagframes
                {
                    if var flagname = flagframe.flag
                    {
                        if flagname.first == "!"
                        {
                            flagname.removeFirst()
                            if let checkflag: Bool = flags[flagname]
                            {
                                if !checkflag { useframe = flagframe }
                            }
                        } else
                        {
                            if let checkflag: Bool = flags[flagname]
                            {
                                if checkflag { useframe = flagframe }
                            }
                        }
                    }
                    
                }
            }
            if let pausecheck = useframe.pauses
            {
                pauses = pausecheck
            }
            if let name = useframe.name, let parent = useframe.parent
            {
                if let last = last
                {
                    if lasttype == "temp" { actionGroup.append(SKAction.removeFromParent()) }
                    last.run(SKAction.sequence(actionGroup))
                    actionGroup.removeAll()
                    actionGroup.append(SKAction.wait(forDuration: delay))
                }
                if parent == "None"
                {
                    last = childNode(withName: name) as? SKSpriteNode
                    lastparent = nil
                    lastgrandparent = nil
                    lasttype = "permscreen"
                } else
                {
                    if let grandparent = useframe.grandparent
                    {
                        last = childNode(withName: grandparent)?.childNode(withName: parent)?.childNode(withName: name) as? SKSpriteNode
                        lastgrandparent = grandparent
                    } else
                    {
                        last = childNode(withName: parent)?.childNode(withName: name) as? SKSpriteNode
                        lastgrandparent = nil
                    }
                    lastparent = parent
                    lasttype = "permsub"
                }
            }
            if useframe.frame == "zoom"
            {
                if let pos = frame.pos {
                    cam!.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.move(to: CGPoint(x: pos[0] * config.scale, y: pos[1] * config.scale), duration: frame.duration), SKAction.scale(to: pos[2], duration: frame.duration)])]))
                }
            }
            else if useframe.frame == "show"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.unhide())
                if lasttype == "permscreen"
                {
                    if let last = last
                    {
                        if let lastname = oldthis { childNode(withName: lastname)?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.hide()]))}
                        actionGroup.append(SKAction.run({
                           last.zPosition = 1
                        }))
                        actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                        if (last != thisscreen!) { actionGroup.append(SKAction.hide()) }
                        actionGroup.append(SKAction.run({
                            last.zPosition = 0
                        }))
                        pauses = false
                    }
                }
                else
                {
                    if lasttype == "permsub" { if let last = last { GameSave.autosave.addShow(name: last.name!, parent: lastparent!, grandparent: lastgrandparent) } }
                    actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                }
                
            }
            else if useframe.frame == "hide"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.hide())
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                if lasttype == "permsub" { if let last = last { GameSave.autosave.addHide(name: last.name!, parent: lastparent!, grandparent: lastgrandparent) } }
            }
            else if useframe.frame == "moveto"
            {
                if let posX: CGFloat = useframe.posX, let posY: CGFloat = useframe.posY
                {
                    actionGroup.append(SKAction.move(to: CGPoint(x: posX * config.scale, y: posY * config.scale), duration: useframe.duration))
                } else if let pos: [CGFloat] = useframe.pos
                {
                    actionGroup.append(SKAction.move(to: CGPoint(x: pos[0] * config.scale, y: pos[1] * config.scale), duration: useframe.duration))
                }
            } else if useframe.frame == "moveby"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                if let posX: CGFloat = useframe.posX, let posY: CGFloat = useframe.posY
                {
                    actionGroup.append(SKAction.move(by: CGVector(dx: posX * config.scale, dy: posY * config.scale), duration: useframe.duration))
                } else if let pos: [CGFloat] = useframe.pos
                {
                    actionGroup.append(SKAction.move(by: CGVector(dx: pos[0] * config.scale, dy: pos[1] * config.scale), duration: useframe.duration))
                }
            } else if useframe.frame == "cfmoveby"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                if let posX: CGFloat = useframe.posX, let posY: CGFloat = useframe.posY, let subs: [String] = useframe.subs
                {
                    actionGroup.append(SKAction.group([SKAction.run{last?.childNode(withName: subs[0])?.run(SKAction.fadeOut(withDuration: useframe.duration))},SKAction.move(by: CGVector(dx: posX * config.scale, dy: posY * config.scale), duration: useframe.duration),SKAction.run{last?.childNode(withName: subs[1])?.run(SKAction.fadeIn(withDuration: useframe.duration))}]))
                } else if let pos: [CGFloat] = useframe.pos, let subs: [String] = useframe.subs
                {
                    actionGroup.append(SKAction.group([SKAction.run{last?.childNode(withName: subs[0])?.run(SKAction.fadeOut(withDuration: useframe.duration))},SKAction.move(by: CGVector(dx: pos[0] * config.scale, dy: pos[1] * config.scale), duration: useframe.duration),SKAction.run{last?.childNode(withName: subs[1])?.run(SKAction.fadeIn(withDuration: useframe.duration))}]))
                }
            } else if useframe.frame == "rotateby"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                if let posX: CGFloat = useframe.posX
                {
                    actionGroup.append(SKAction.rotate(byAngle: -1 * posX * CGFloat(Double.pi)/180, duration: useframe.duration))
                } else if let pos: [CGFloat] = useframe.pos
                {
                    actionGroup.append(SKAction.rotate(byAngle: -1 * pos[0] * CGFloat(Double.pi)/180, duration: useframe.duration))
                }
            } else if useframe.frame == "fadein"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                last?.alpha = 0
                //actionGroup.append(SKAction.fadeOut(withDuration: 0))
                if lasttype == "permsub" { if let last = last { GameSave.autosave.addShow(name: last.name!, parent: lastparent!, grandparent: lastgrandparent) } }
                actionGroup.append(SKAction.unhide())
                actionGroup.append(SKAction.fadeIn(withDuration: useframe.duration))
            } else if useframe.frame == "fadeout"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                if lasttype == "permsub" { if let last = last { GameSave.autosave.addHide(name: last.name!, parent: lastparent!, grandparent: lastgrandparent) } }
                actionGroup.append(SKAction.fadeOut(withDuration: useframe.duration))
            } else if useframe.frame == "fliph"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.group([SKAction.scaleX(to: last!.xScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: last!.size.width * last!.xScale, dy: 0), duration: useframe.duration)]))
                
            } else if useframe.frame == "flipv"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.group([SKAction.scaleY(to: last!.yScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: 0, dy: last!.size.height * last!.yScale), duration: useframe.duration)]))
            } else if useframe.frame == "runanim"
            {
                if let last = last { actionGroup.append(SKAction.run({ last.action(forKey: "Animate")?.speed = 1 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "stopanim"
            {
                if let last = last { actionGroup.append(SKAction.run({ last.action(forKey: "Animate")?.speed = 0 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "releaseto"
            {
                /*if let last = last { actionGroup.append(SKAction.sequence([SKAction.unhide(), SKAction.run({
                    self.thisscreen!.isHidden = true
                    self.thisscreen = last as? GameScreen
                })])) }*/
            } else if useframe.frame == "wait"
            {
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else
            {
                let newframe = SKSpriteNode(imageNamed: useframe.frame)
                if let last = last
                {
                    if lasttype == "temp" { actionGroup.append(SKAction.removeFromParent()) }
                    last.run(SKAction.sequence(actionGroup))
                    actionGroup.removeAll()
                }
                lasttype = "temp"
                if let posX: CGFloat = useframe.posX, let posY: CGFloat = useframe.posY
                {
                    newframe.position = CGPoint(x: posX * config.scale, y: posY * config.scale)
                } else if let pos: [CGFloat] = useframe.pos
                {
                    newframe.position = CGPoint(x: pos[0] * config.scale, y: pos[1] * config.scale)
                }
                newframe.anchorPoint = CGPoint(x: 0, y: 0)
                newframe.zPosition = 4
                newframe.isHidden = true
                //if inView { thisview?.addChild(newframe) }
                thisscreen?.addChild(newframe)
                actionGroup.append(SKAction.wait(forDuration: delay))
                actionGroup.append(SKAction.unhide())
                if let sound = useframe.sound
                {
                    actionGroup.append(SKAction.run({
                        do {
                            self.soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                            self.soundEffect?.play()
                        } catch
                        {
                            print("sound \(sound) not found")
                        }
                    }))
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                last = newframe
            }
            if pauses { delay += useframe.duration }
        }
        if let last = last
        {
            actionGroup.append(SKAction.run{
                self.view?.isUserInteractionEnabled = true
                GameSave.autosave.save()
            })
            if lasttype == "temp" { actionGroup.append(SKAction.removeFromParent()) }
            last.run(SKAction.sequence(actionGroup))
        }
        return delay
    }
    
    func runGameSpot(spot: GameSpot, animateskip: Bool = false)
    {
        if let flagactions: [GameSpot] = spot.getFlagActions()
        {
            for flagaction in flagactions
            {
                var flagname = flagaction.getName()
                if flagname.first == "&"
                {
                    flagname.removeFirst()
                    if flagname.first == "!"
                    {
                        flagname.removeFirst()
                        if let flagval = flags[flagname]
                        {
                            if !flagval {
                                runGameSpot(spot: flagaction)
                            }
                        }
                    } else
                    {
                        if let flagval = flags[flagname]
                        {
                            if flagval {
                                runGameSpot(spot: flagaction)
                            }
                        }
                    }
                } else if flagname.first == "!"
                {
                    flagname.removeFirst()
                    if let flagval = flags[flagname]
                    {
                        if !flagval
                        {
                            runGameSpot(spot: flagaction)
                            return
                        }
                    }
                } else
                {
                    if let flagval = flags[flagname], flagval
                    {
                        runGameSpot(spot: flagaction)
                        return
                    }
                }
            }
        }
        if let sequenceactions: [GameSpot] = spot.getSequenceActions()
        {
            for sequenceaction in sequenceactions
            {
                var alltogether: String = ""
                for line in thisscreen!.getSequence() { alltogether += line }
                if alltogether == sequenceaction.getName()
                {
                    runGameSpot(spot: sequenceaction)
                    return
                }
            }
        }
        if let currselect: String = selected?.name
        {
            if let select: GameSpot = spot.getSelect(select: currselect)
            {
                runGameSpot(spot: select)
                return
            }
            else
            {
                if let collects: [GameInvObj] = selected?.getCollects()
                {
                    for collect in collects
                    {
                        if let select: GameSpot = spot.getSelect(select: collect.name!)
                        {
                            runGameSpot(spot: select)
                            return
                        }
                    }
                }
            }
        }
        else if let currselect: SKSpriteNode = thisscreen!.getSelected()
        {
            if let select: GameSpot = spot.getSelect(select: currselect.name!)
            {
                runGameSpot(spot: select)
                thisscreen!.clearSelected()
                return
            }
        }
        if let animate: GameJSONAnimation = spot.getAnimate()
        {
            if !animateskip
            {
                let delay: Double = runAnimation(animation: animate)
                run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{ self.runGameSpot(spot: spot, animateskip: true)}]))
                return
            }
        }
        var save: Bool = false
        if var flag: String = spot.getFlag()
        {
            if flag.first == "!"
            {
                flag.removeFirst()
                if flag.last == "*"
                {
                    flag.removeLast()
                    for currflag in flags
                    {
                        if currflag.key.hasPrefix(flag)
                        {
                            flags[currflag.key] = false
                            if spot.getSaves() { GameSave.autosave.setFlag(name: currflag.key, value: false) }
                        }
                    }
                }
                else
                {
                    flags[flag] = false
                    if spot.getSaves() { GameSave.autosave.setFlag(name: flag, value: false) }
                }
            } else
            {
                if flag.last == "*"
                {
                    flag.removeLast()
                    for currflag in flags
                    {
                        if currflag.key.hasPrefix(flag)
                        {
                            flags[currflag.key] = true
                            if spot.getSaves() { GameSave.autosave.setFlag(name: currflag.key, value: true) }
                        }
                    }
                }
                else
                {
                    flags[flag] = true
                    if spot.getSaves() { GameSave.autosave.setFlag(name: flag, value: true) }
                }
            }
            save = true
        }
        if let random: GameSpot = spot.getRandom()
        {
            runGameSpot(spot: random)
        }
        if let selectable: SKSpriteNode = spot.getSelectable()
        {
            thisscreen!.setSelected(selected: selectable)
        }
        if let sound: AVAudioPlayer = spot.getSound()
        {
            sound.play()
        }
        if let zoom: GameScreen = spot.getZoom()
        {
            if let thisscreen: GameScreen = self.thisscreen
            {
                zoom.setBack(back: thisscreen)
            }
            thisscreen?.isHidden = true
            thisscreen = zoom
            thisscreen?.isHidden = false
            thisscreen?.removeAllActions()
        }
        if let phonezoom: GameJSONPhoneZoom = spot.getPhoneZoom()
        {
            cam!.run(SKAction.group([SKAction.move(to: CGPoint(x: phonezoom.posX * config.scale, y: phonezoom.posY * config.scale), duration: 0.7), SKAction.scale(to: 0.5, duration: 0.7)]))
        }
        if let view: GameScreen = spot.getView()
        {
            view.isHidden = false
            inView = true
            thisview = view
            leftSwipe.isEnabled = false
            rightSwipe.isEnabled = false
            upSwipe.isEnabled = false
        }
        if let removes: GameInvObj = spot.getRemoves()
        {
            var found: Int = -1
            for (index, object) in currentinv.enumerated()
            {
                if found > -1 && invbox!.zRotation != 0
                {
                    let block: CGFloat = (config.invspace + config.invunit) * config.invscale * config.scale
                    if !object.isCollected() {
                        object.run(SKAction.moveBy(x: -1 * block, y: 0, duration: 0.5), withKey: "BumpObj")
                        if let collects = object.getCollects()
                        {
                            for collect in collects { collect.run(SKAction.moveBy(x: -1 * block, y: 0, duration: 0.5), withKey: "BumpObj") }
                        }
                    }
                }
                if object == removes
                {
                    found = index
                }
            }
            if removes == selected { selected = nil }
            if found > -1
            {
                currentinv.remove(at: found)
                if spot.getSaves() { GameSave.autosave.removeInv(object: removes.name!) }
                if let collects: [GameInvObj] = removes.getCollects()
                {
                    for (index, object) in currentinv.enumerated().reversed()
                    {
                        for objcollect in collects
                        {
                            if object.name == objcollect.name
                            {
                                currentinv.remove(at: index)
                                if spot.getSaves() { GameSave.autosave.removeInv(object: object.name!) }
                                collected += -1
                            }
                        }
                    }
                }
                if invbox!.zRotation != 0
                {
                    let center: CGFloat = (config.invspace + (config.invunit / 2)) * config.invscale * config.scale
                    let hideobj: SKAction = SKAction.group([SKAction.moveBy(x: 0, y: -1 * center, duration: 0.5), SKAction.scale(to: 0, duration: 0.5), SKAction.hide(), SKAction.scale(to: 1, duration: 0)])
                    removes.run(SKAction.sequence([hideobj, SKAction.removeFromParent(), SKAction.unhide()]), withKey: "RemoveObj")
                    if let collects: [GameInvObj] = removes.getCollects()
                    {
                        for objcollect in collects
                        {
                            objcollect.run(SKAction.sequence([hideobj, SKAction.removeFromParent()]), withKey: "RemoveObj")
                        }
                    }
                }
            }
        }
        if let object: GameInvObj = spot.getObject()
        {
            openInv()
            addChild(object)
            object.isHidden = false
            object.scale(to: CGSize(width: object.texture!.size().width, height: object.texture!.size().height))
            object.position = CGPoint(x: config.basewidth/2, y: config.baseheight/2)
            object.zPosition = 2
            object.zRotation = CGFloat(Double.pi/15)
            let center: CGFloat = (config.invspace + (config.invunit / 2)) * config.invscale * config.scale
            let block: CGFloat = (config.invspace + config.invunit) * config.invscale * config.scale
            var movepos: CGFloat = block * CGFloat(currentinv.count - collected + 1) + center
            if let collects: [GameInvObj] = object.getCollects()
            {
                for collect in collects
                {
                    for (index, colobject) in currentinv.enumerated()
                    {
                        if collect.name == colobject.name
                        {
                            movepos = block * CGFloat(index + 1) + center
                            object.setCollected(collected: true)
                            collected += 1
                        }
                    }
                }
            }
            invsounds[invcount].play()
            invcount = (invcount + 1) % invsounds.count
            let showobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: movepos, y: center), duration: 0.5), SKAction.scale(to:object.getScale() * config.invscale, duration: 0.5)])
            let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
            object.run(SKAction.sequence([SKAction.rotate(toAngle: 0, duration: 0.5), showobj, SKAction.wait(forDuration: 3.5), hideobj]), withKey: "AddObj")
            currentinv.append(object)
            if spot.getSaves() { GameSave.autosave.addInv(object: object.name!) }
            save = true
        }
        if let invdisplay: [String] = spot.getInvDisplay()
        {
            for index in 0..<(invdisplay.count / 2)
            {
                for invobj in masterinv
                {
                    if invobj.name == invdisplay[index * 2]
                    {
                        invobj.changeDisplayName(newname: invdisplay[index * 2 + 1])
                    }
                }
            }
        }
        if let sequence: String = spot.getSequence()
        {
            if sequence == "clear"
            {
                thisscreen?.clearSequence()
            }
            else
            {
                thisscreen?.pushSequence(push: sequence)
            }
        }
        if let line: String = spot.getSpeechLine()
        {
            subtitle?.text = line
            subtitle?.isHidden = false
            subtitle?.removeAllActions()
            subtitle?.run(SKAction.sequence([SKAction.wait(forDuration: TimeInterval(config.textspeed)), SKAction.hide()]))
        }
        if let dialogue: GameDialogue = spot.getDialogue()
        {
            invbox?.run(SKAction.fadeOut(withDuration: 0.5))
            menubar?.run(SKAction.fadeOut(withDuration: 0.5))
            if (invout)
            {
                invout = false
                let center: CGFloat = (config.invspace + (config.invunit / 2)) * config.invscale * config.scale
                let hideobj: SKAction = SKAction.group([SKAction.move(to: CGPoint(x: center, y: center), duration: 0.5), SKAction.scale(to: 0, duration: 0.5)])
                for object in currentinv
                {
                    object.removeAllActions()
                    object.removeSelect()
                    object.run(hideobj, withKey: "HideObj")
                }
            }
            runDialogue(dialogue: dialogue)
        }
        if spot.hasCycle()
        {
            spot.incrementCycle()
            if spot.getSaves() { GameSave.autosave.addCycle(name: spot.getName(), parent: thisscreen!.name!, val: spot.getCycleCounter()!) }
        }
        if let cyclerev = spot.getCycleRev()
        {
            cyclerev.decrementCycle()
        }
        if let cycleifs = spot.getCycleIfs()
        {
            for cycleif in cycleifs
            {
                for value in cycleif.values
                {
                    if cycleif.cycle.getCycleCounter() == value.getValue()
                    {
                        runGameSpot(spot: value)
                    }
                }
            }
        }
        if let choices = spot.getChoices(), let choicenames = spot.getChoiceNames()
        {
            for choice in choices
            {
                if let line = choice.line
                {
                    if choice.act == "enable" { choice.choice.setLineActive(line: line, active: true) }
                    if choice.act == "disable" { choice.choice.setLineActive(line: line, active: false) }
                } else {
                    if choice.act == "enable" && choice.choice.getActive() != 2
                    {
                        choice.choice.setActive(active: 1)
                    } else if choice.act == "disable" && choice.choice.getActive() != 2
                    {
                        choice.choice.setActive(active: 0)
                    } else if choice.act == "remove"
                    {
                        choice.choice.setActive(active: 2)
                    }
                }
            }
            for choicename in choicenames {
                if spot.getSaves() { GameSave.autosave.addChoice(name: choicename.name, dialogue: choicename.dialogue, type: choicename.act, parent: choicename.parent) } }
        }
        if let draws: [GameJSONDraw] = spot.getDraws()
        {
            for draw in draws
            {
                let drawimage = SKSpriteNode(imageNamed: draw.draw)
                drawimage.anchorPoint = CGPoint(x:0, y:0)
                let offset = CGFloat(Double(arc4random_uniform(UInt32(draw.maxoff))) - Double(draw.maxoff) / 2)
                if let pos = draw.pos
                {
                    drawimage.position = CGPoint(x: (pos[0] + offset) * config.scale, y: (pos[1] + offset) * config.scale)
                } else if let posX = draw.posX, let posY = draw.posY
                {
                    drawimage.position = CGPoint(x: (posX + offset) * config.scale, y: (posY + offset) * config.scale)
                }
                drawimage.zPosition = 1
                drawimage.name = "Draw_" + draw.name
                childNode(withName: draw.parent)?.addChild(drawimage)
            }
        }
        if let drawclear: [GameScreen] = spot.getDrawClear()
        {
            for screen in drawclear
            {
                screen.enumerateChildNodes(withName: "Draw_*"){
                    (node, stop) in
                    node.removeFromParent()
                }
            }
        }
        if let shows: [SKSpriteNode] = spot.getShows()
        {
            for sub in shows
            {
                sub.isHidden = false
            }
            for showloc in spot.getShowLocs()!
            {
                if spot.getSaves() { GameSave.autosave.addShow(name: showloc.name, parent: showloc.parent, grandparent: showloc.grandparent) }
            }
            save = true
        }
        if let hides: [SKSpriteNode] = spot.getHides()
        {
            for sub in hides
            {
                sub.isHidden = true
            }
            for hideloc in spot.getHideLocs()!
            {
                if spot.getSaves() { GameSave.autosave.addHide(name: hideloc.name, parent: hideloc.parent, grandparent: hideloc.grandparent) }
            }
            save = true
        }
        if let toggles: [GameSpot] = spot.getToggles()
        {
            for togglespot in toggles
            {
                togglespot.toggle()
            }
            for toggleloc in spot.getToggleLocs()!
            {
                if spot.getSaves() { GameSave.autosave.addToggle(name: toggleloc.name, parent: toggleloc.parent) }
            }
            save = true
        }
        if spot.getTransition() { runNextScene() }
        if save, spot.getSaves() { GameSave.autosave.save() }
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
        guard let jsonData = try? JSONDecoder().decode(GameJSONPart.self, from: data) else
        {
            print("Error parsing JSON")
            return
        }
        for sound in jsonData.invsounds
        {
            do {
                let soundloaded: AVAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
                invsounds.append(soundloaded)
            } catch
            {
                print("sound \(sound) not found")
            }
        }
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
        for object in jsonData.objects
        {
            masterinv.append(GameInvObj.init(imageNamed: object.image, name: object.name, scale: object.scale, animations: object.animations, displayname: object.displayname, subs: object.subs))
            if let animations = object.animations
            {
                for animation in animations
                {
                    for frame in animation.frames
                    {
                        if let flag = frame.flag
                        {
                            flags[flag] = false
                        }
                    }
                }
            }
        }
        for object in jsonData.objects
        {
            if let collects = object.collects
            {
                var collectlist: [GameInvObj] = []
                var currobj: GameInvObj?
                for invobject in masterinv
                {
                    if invobject.name == object.name { currobj = invobject }
                    for collectobj in collects
                    {
                        if collectobj == invobject.name
                        {
                            collectlist.append(invobject)
                        }
                    }
                }
                currobj?.setCollects(collects: collectlist)
            }
        }
        for screen in jsonData.screens
        {
            var currscreen = GameScreen(imageNamed: screen.image, config: config)
            if let _ = screen.arcade
            {
                currscreen = GameArcade(imageNamed: screen.image, config: config, playarea: CGRect(x: 614 * config.scale, y: 164 * config.scale, width: 740 * config.scale, height: 710 * config.scale), callback: self)
                arcadename = screen.name
            }
            if screen.image.hasSuffix("gearbox") || screen.name.hasSuffix("GearZoom")
            {
                currscreen = Gearbox(imageNamed: screen.image, config: config)
            }
            currscreen.name = screen.name
            currscreen.anchorPoint = CGPoint(x:0, y:0)
            if jsonData.start != currscreen.name { currscreen.isHidden = true }
            else { thisscreen = currscreen }
            
            if let sublist = screen.subs
            {
                var currZ : Double = 0.1
                for sub in sublist
                {
                    let currsub = SKSpriteNode(imageNamed: sub.image)
                    currsub.name = sub.name
                    currsub.userData = NSMutableDictionary()
                    if let displayname = sub.displayname
                    {
                        currsub.userData?.setValue(displayname, forKeyPath: "displayname")
                    }
                    if let anchor: [CGFloat] = sub.anchor
                    {
                        currsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                        currsub.position = CGPoint(x: (sub.sub[0] + (sub.sub[2] * anchor[0]))  * config.scale, y: (sub.sub[1] + (sub.sub[3] * anchor[1])) * config.scale)
                    } else
                    {
                        currsub.anchorPoint = CGPoint(x:0, y:0)
                        currsub.position = CGPoint(x: sub.sub[0] * config.scale, y: sub.sub[1] * config.scale)
                    }
                    if let setZ = sub.setZ { currsub.zPosition = setZ }
                    else { currsub.zPosition = CGFloat(currZ) }
                    currZ += 0.01
                    if let vis = sub.visible { currsub.isHidden = !vis }
                    if let opacity = sub.opacity { currsub.alpha = CGFloat(opacity)}
                    if let rotate = sub.rotate { currsub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                    if var frames = sub.frames
                    {
                        if sub.type == "action" {
                            var actionGroup: [SKAction] = []
                            for frame in frames {
                                if frame.frame == "rotateby" {
                                    actionGroup.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi)/180, duration: frame.duration))
                                }
                            }
                            currsub.run(SKAction.repeatForever(SKAction.sequence(actionGroup)), withKey: "Animate")
                            if let running = sub.running {
                                if !running { currsub.action(forKey: "Animate")!.speed = 0 }
                            }
                        } else {
                            var framenames: [String] = [sub.image]
                            for frame in frames { framenames.append(frame.frame) }
                            if let type = sub.type
                            {
                                if type == "reverse" {
                                    frames = frames.reversed()
                                    for i in frames.indices.dropFirst() { framenames.append(frames[i].frame) }
                                }
                            }
                            var framelist: [SKTexture] = [SKTexture(imageNamed: sub.image)]
                            for frame in framenames { framelist.append(SKTexture(imageNamed: frame)) }
                            if let type = sub.type
                            {
                                if type == "once"
                                {
                                    currsub.run(SKAction.animate(with: framelist, timePerFrame: 0.05), withKey: "Animate")
                                    currsub.action(forKey: "Animate")!.speed = 0
                                } else
                                {
                                    currsub.run(SKAction.repeatForever(SKAction.animate(with: framelist, timePerFrame: 0.05)), withKey: "Animate")
                                }
                            } else
                            {
                                currsub.run(SKAction.repeatForever(SKAction.animate(with: framelist, timePerFrame: 0.05)), withKey: "Animate")
                            }
                            if let running = sub.running {
                                if !running { currsub.action(forKey: "Animate")!.speed = 0 }
                            }
                        }
                    }
                    if let subsubs = sub.subsubs
                    {
                        for subsub in subsubs
                        {
                            let currsubsub = SKSpriteNode(imageNamed: subsub.image)
                            currsubsub.name = subsub.name
                            if let anchor:[CGFloat] = subsub.anchor
                            {
                                currsubsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                            } else { currsubsub.anchorPoint = CGPoint(x:0, y:0) }
                            currsubsub.position = CGPoint(x: (subsub.sub[0] - sub.sub[0]) * config.scale, y: (subsub.sub[1] - sub.sub[1]) * config.scale)
                            if let setZ = subsub.setZ { currsubsub.zPosition = setZ }
                            else { currsubsub.zPosition = CGFloat(currZ) }
                            currZ += 0.01
                            if let subvis = subsub.visible { currsubsub.isHidden = !subvis }
                            if let subopacity = subsub.opacity { currsubsub.alpha = CGFloat(subopacity)}
                            if let subrotate = subsub.rotate { currsubsub.zRotation = -1 * subrotate * CGFloat(Double.pi)/180}
                            currsub.addChild(currsubsub)
                        }
                    }
                    currscreen.addChild(currsub)
                }
            }
            
            addChild(currscreen)
        }
        for screen in jsonData.screens
        {
            if let addscreen : GameScreen = childNode(withName: screen.name) as? GameScreen
            {
                if let currleft = screen.left
                {
                    if childNode(withName: currleft) != nil
                    {
                        addscreen.setLeft(left: childNode(withName: currleft) as! GameScreen)
                    }
                }
                if let currright = screen.right
                {
                    if (childNode(withName: currright) != nil)
                    {
                        addscreen.setRight(right: childNode(withName: currright) as! GameScreen)
                    }
                }
                if let currback = screen.back
                {
                    if (childNode(withName: currback) != nil)
                    {
                        addscreen.setBack(back: childNode(withName: currback) as! GameScreen)
                    }
                }
                if let currsequence = screen.sequence
                {
                    addscreen.setSequenceLength(set: currsequence)
                }
                if let grid = screen.grid
                {
                    var assigngrid: [GameSpot] = []
                    for currgrid in grid
                    {
                        assigngrid.append(loadJSONSpot(currgrid: currgrid))
                    }
                    addscreen.setGrid(grid: assigngrid)
                }
                if let currbackaction = screen.backaction
                {
                    addscreen.setBackActionName(backactionname: currbackaction)
                }
            }
        }
        if let jsonanims = jsonData.globanims
        {
            for globanim in jsonanims
            {
                globanims.append(globanim)
            }
        }
        for (index, globanim) in globanims.enumerated()
        {
            for frame in globanim.frames
            {
                if let flag = frame.flag
                {
                    flags[flag] = false
                }
                if let chain = frame.chain
                {
                    for chainsearch in globanims
                    {
                        if chain == chainsearch.name
                        {
                            globanims[index].frames.append(contentsOf: chainsearch.frames)
                        }
                    }
                }
            }
        }
        if let dialogues = jsonData.dialogues
        {
            for dialogue in dialogues
            {
                loadJSONDialogue(dialogue: dialogue)
            }
        }
        for screen in jsonData.screens
        {
            if let addscreen : GameScreen = (childNode(withName: screen.name) as? GameScreen)
            {
                if let grid = addscreen.getGrid()
                {
                    for currgrid in grid
                    {
                        linkSpotRefs(currgrid: currgrid)
                        if let currview = currgrid.getView()
                        {
                            if let currsubgrid = currview.getGrid()
                            {
                                for grid in currsubgrid {
                                    linkSpotRefs(currgrid: grid)
                                }
                            }
                        }
                        if let currcyclerevname = currgrid.getCycleRevName()
                        {
                            for currgrid2 in grid
                            {
                                if currgrid2.getName() == currcyclerevname
                                {
                                    currgrid.setCycleRev(cyclerev: currgrid2)
                                }
                            }
                        }
                        if let currcycleifs = currgrid.getCycleIfNames()
                        {
                            var parsedcycleifs: [(cycle: GameSpot, values: [GameSpot])] = []
                            for currcycleif in currcycleifs
                            {
                                if let searchgrid = (childNode(withName: currcycleif.cycle.parent) as! GameScreen).getGrid()
                                {
                                    for grid in searchgrid
                                    {
                                        if grid.getName() == currcycleif.cycle.name
                                        {
                                            parsedcycleifs.append((cycle: grid, values: currcycleif.values))
                                        }
                                    }
                                }
                                for value in currcycleif.values
                                {
                                    linkSpotRefs(currgrid: value)
                                }
                            }
                            currgrid.setCycleIfs(cycleifs: parsedcycleifs)
                        }
                    }
                }
                if let backaction = addscreen.getBackActionName(), let fullgrid = addscreen.getGrid()
                {
                    for grid in fullgrid
                    {
                        if grid.getName() == backaction
                        {
                            addscreen.setBackAction(backaction: grid)
                        }
                    }
                }
            }
        }
        for currdialogue in dialogue
        {
            linkbranch(start: currdialogue)
        }
        if let states: [GameJSONState] = jsonData.states { parseStates(jsonstates: states) }
        for state in states { linkSpotRefs(currgrid: state.action!) }
        if let flickers: [GameJSONFlicker] = jsonData.flickers
        {
            for flicker in flickers
            {
                var sublist: [SKSpriteNode] = []
                for sub in flicker.subs
                {
                    if let grandparent = sub.grandparent
                    {
                        sublist.append(childNode(withName: grandparent)?.childNode(withName: sub.parent)?.childNode(withName: sub.name) as! SKSpriteNode)
                    } else
                    {
                        sublist.append(childNode(withName: sub.parent)?.childNode(withName: sub.name) as! SKSpriteNode)
                    }
                }
                self.flickers.append(GameParsedFlicker(name: flicker.name, type: flicker.type, frequency: flicker.frequency, subs: sublist))
            }
        }
        if let gearboxes = jsonData.gearboxes
        {
            for currgearbox in gearboxes
            {
                (childNode(withName: currgearbox.name) as! Gearbox).loadJSONGearbox(jsonData: currgearbox)
            }
        }
        loadingPercent = 100
    }
    
    func parseStates(jsonstates: [GameJSONState])
    {
        for jsonstate in jsonstates
        {
            var visiblelist: [(sub: SKSpriteNode, vis: Bool)] = []
            if let visibles: [GameJSONVisible] = jsonstate.visibles
            {
                for sub in visibles
                {
                    if let grandparent = sub.grandparent
                    {
                        visiblelist.append((sub: childNode(withName: grandparent)?.childNode(withName: sub.parent)?.childNode(withName:sub.name) as! SKSpriteNode, vis: sub.visible))
                    } else
                    {
                        visiblelist.append((sub: childNode(withName: sub.parent)?.childNode(withName:sub.name) as! SKSpriteNode, vis: sub.visible))
                    }
                }
            }
            var cyclelist: [(spot: GameSpot, val: Int)] = []
            if let cycle: [GameJSONCycleState] = jsonstate.cycles
            {
                for spot in cycle
                {
                    if let grid = (childNode(withName: spot.parent) as! GameScreen).getGrid()
                    {
                        for currgrid in grid
                        {
                            if currgrid.getName() == spot.name
                            {
                                cyclelist.append((spot: currgrid, val: spot.cycle))
                            }
                        }
                    }
                }
            }
            var sequencescreen: GameScreen? = nil
            var sequence: String?
            if let screen: String = jsonstate.screen, let match: String = jsonstate.match
            {
                sequencescreen = (childNode(withName: screen) as! GameScreen)
                sequence = match
            }
            let animate: String? = jsonstate.animate
            if let flag = jsonstate.flag { flags[flag] = false }
            let spot = GameJSONGrid(name: jsonstate.name, pos: nil, posX: nil, posY: nil, width: nil, height: nil, active: jsonstate.active, saves: jsonstate.saves, value: nil, flag: jsonstate.flag, flagactions: nil, sequenceactions: nil, randoms: nil, sound: nil, zoom: nil, phonezoom: nil, view: nil, subgrid: nil, subsubs: nil, object: jsonstate.object, removes: jsonstate.removes, animate: animate, selectable: nil, selects: nil, invdisplay: nil, sequence: jsonstate.sequence, speech: nil, dialogue: nil, cycle: nil, cyclerev: nil, cycleif: nil, choices: jsonstate.choices, draws: nil, drawclear: nil, shows: jsonstate.shows, hides: jsonstate.hides, toggles: jsonstate.toggles, transition: jsonstate.transition)
            let setaction: GameSpot = loadJSONSpot(currgrid: spot)
            states.append(GameParsedState(name: jsonstate.name, type: jsonstate.type, sequencescreen: sequencescreen, sequence: sequence, visibles: visiblelist, cycles: cyclelist, flags: jsonstate.flags, action: setaction))
        }
    }
    
    func linkSpotRefs(currgrid: GameSpot)
    {
        if let curranimatename = currgrid.getAnimateName()
        {
            var animateset = false
            for object in masterinv
            {
                if let animate: GameJSONAnimation = object.getAnimation(animNamed: curranimatename)
                {
                    currgrid.setAnimate(animate: animate)
                    animateset = true
                }
            }
            if !animateset
            {
                for animate in globanims
                {
                    if animate.name == curranimatename
                    {
                        currgrid.setAnimate(animate: animate)
                        animateset = true
                    }
                }
            }
        }
        if let currcyclelocs = currgrid.getCycleLocs()
        {
            var assigncycles: [[SKSpriteNode?]] = []
            for currcycleloc in currcyclelocs
            {
                var assigncycle: [SKSpriteNode?] = []
                for sub in currcycleloc.subs
                {
                    if sub.sub == "None"
                    {
                        assigncycle.append(nil)
                    } else
                    {
                        assigncycle.append((childNode(withName: currcycleloc.parent)?.childNode(withName: sub.sub) as! SKSpriteNode))
                    }
                }
                assigncycles.append(assigncycle)
            }
            currgrid.setCycle(cycle: assigncycles)
        }
        if let currtogglelocs = currgrid.getToggleLocs()
        {
            var assigntoggles: [GameSpot] = []
            for toggleloc in currtogglelocs
            {
                if toggleloc.parent == "State"
                {
                    for state in states
                    {
                        if state.name == toggleloc.name
                        {
                            assigntoggles.append(state.action!)
                        }
                    }
                }
                else
                {
                    if let searchgrid: [GameSpot] = (childNode(withName: toggleloc.parent) as! GameScreen).getGrid()
                    {
                        for findgrid in searchgrid
                        {
                            if findgrid.getName() == toggleloc.name
                            {
                                assigntoggles.append(findgrid)
                            }
                        }
                    }
                }
            }
            currgrid.setToggles(toggles: assigntoggles)
        }
        if let currdialogue = currgrid.getDialogueName()
        {
            for parsed in dialogue
            {
                if currdialogue == parsed.getName()
                {
                    currgrid.setDialogue(dialogue: parsed)
                }
            }
        }
        if let choicenames = currgrid.getChoiceNames()
        {
            var choices: [(choice: GameDialogue, act: String, line: String?)] = []
            for choicename in choicenames
            {
                for currdialogue in dialogue
                {
                    if currdialogue.getName() == choicename.dialogue
                    {
                        if let parent = choicename.parent
                        {
                            if let choiceparent = findChoice(start: currdialogue, name: parent)
                            {
                                choices.append((choice: choiceparent, act: choicename.act, line: choicename.name))
                            }
                        } else
                        {
                            if let choiceparent = findChoice(start: currdialogue, name: choicename.name)
                            {
                                choices.append((choice: choiceparent, act: choicename.act, line: nil))
                            }
                        }
                    }
                }
            }
            currgrid.setChoices(choices: choices)
        }
        if let flagactions = currgrid.getFlagActions() {
            for flagaction in flagactions { linkSpotRefs(currgrid: flagaction) }
        }
        if let sequenceactions = currgrid.getSequenceActions() {
            for sequenceaction in sequenceactions { linkSpotRefs(currgrid: sequenceaction) }
        }
        if let selects = currgrid.getSelects() {
            for select in selects { linkSpotRefs(currgrid: select) }
        }
        if let randoms = currgrid.getRandoms() {
            for random in randoms { linkSpotRefs(currgrid: random) }
        }
    }
    
    func linkbranch(start: GameDialogue)
    {
        if let action = start.getAction()
        {
            linkSpotRefs(currgrid: action)
        }
        if let fullbranch = start.getBranch()
        {
            for branch in fullbranch
            {
                linkbranch(start: branch)
            }
        }
    }
    
    func findChoice(start: GameDialogue, name: String) -> GameDialogue?
    {
        if let branch = start.getBranch()
        {
            for dialogue in branch
            {
                if dialogue.getName() == name
                {
                    return dialogue
                }
                else if let result = findChoice(start: dialogue, name: name)
                { return result }
            }
        }
        return nil
    }
    
    func loadJSONSpot(currgrid: GameJSONGrid) -> GameSpot
    {
        let newgrid = GameSpot(name: currgrid.name)
        if let pos: [CGFloat] = currgrid.pos
        {
            newgrid.setSpot(spot: CGRect(x: pos[0] * config.scale, y: pos[1] * config.scale, width: pos[2] * config.scale, height: pos[3] * config.scale))
        }
        else if let posX: CGFloat = currgrid.posX, let posY: CGFloat = currgrid.posY, let width = currgrid.width, let height = currgrid.height
        {
            newgrid.setSpot(spot: CGRect(x: posX * config.scale, y: posY * config.scale, width: width * config.scale, height: height * config.scale))
        }
        if let curractive = currgrid.active { newgrid.setActive(active: curractive) }
        if let currsaves = currgrid.saves { newgrid.setSaves(saves: currsaves) }
        if let currvalue = currgrid.value { newgrid.setValue(value: currvalue) }
        if var currflag = currgrid.flag
        {
            newgrid.setFlag(flag: currflag)
            if currflag.first == "!"
            {
                currflag.removeFirst()
            }
            flags[currflag] = false
        }
        if let currflagactions = currgrid.flagactions
        {
            var flagactionlist: [GameSpot] = []
            for flagaction in currflagactions
            {
                flagactionlist.append(loadJSONSpot(currgrid: flagaction))
            }
            newgrid.setFlagActions(flagactions: flagactionlist)
        }
        if let currsequenceactions = currgrid.sequenceactions
        {
            var sequenceactionlist: [GameSpot] = []
            for sequenceaction in currsequenceactions
            {
                sequenceactionlist.append(loadJSONSpot(currgrid: sequenceaction))
            }
            newgrid.setSequenceActions(sequenceactions: sequenceactionlist)
        }
        if let currrandoms = currgrid.randoms
        {
            var randomlist: [GameSpot] = []
            for random in currrandoms
            {
                randomlist.append(loadJSONSpot(currgrid: random))
            }
            newgrid.setRandoms(randoms: randomlist)
        }
        if let currsound = currgrid.sound
        {
            do {
                let sound: AVAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: currsound + ".mp3", ofType: nil)!))
                newgrid.setSound(sound: sound)
            } catch
            {
                print("sound \(currsound) not found")
            }
        }
        if let currzoom = currgrid.zoom
        {
            newgrid.setZoom(zoom: (childNode(withName: currzoom) as! GameScreen))
        }
        if let currphonezoom = currgrid.phonezoom
        {
            newgrid.setPhoneZoom(phonezoom: currphonezoom[0])
        }
        if let currview = currgrid.view
        {
            let currscreen = GameScreen(imageNamed: currview)
            currscreen.name = currgrid.name
            currscreen.anchorPoint = CGPoint(x:0.5, y:0.5)
            currscreen.position = CGPoint(x: config.basewidth / 2, y: config.baseheight / 2)
            currscreen.isHidden = true
            currscreen.zPosition = 1
            addChild(currscreen)
            if let sublist = currgrid.subsubs
            {
                var currZ : Double = 1.1
                for sub in sublist
                {
                    let currsub = SKSpriteNode(imageNamed: sub.image)
                    currsub.name = sub.name
                    if let anchor:[CGFloat] = sub.anchor
                    {
                        currsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                    } else { currsub.anchorPoint = CGPoint(x:0, y:0) }
                    currsub.position = CGPoint(x: sub.sub[0] * config.scale - currscreen.size.width / 2, y: sub.sub[1] * config.scale - currscreen.size.height / 2)
                    currsub.zPosition = CGFloat(currZ)
                    currZ += 0.01
                    if let vis = sub.visible { currsub.isHidden = !vis }
                    if let opacity = sub.opacity { currsub.alpha = CGFloat(opacity)}
                    if let rotate = sub.rotate { currsub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                    currscreen.addChild(currsub)
                }
            }
            if let subgrid = currgrid.subgrid
            {
                var gridlist: [GameSpot] = []
                for grid in subgrid
                {
                    gridlist.append(loadJSONSpot(currgrid: grid))
                }
                currscreen.setGrid(grid: gridlist)
            }
            newgrid.setView(view: currscreen)
        }
        if let currobject = currgrid.object
        {
            for object in masterinv
            {
                if object.name == currobject
                {
                    newgrid.setObject(object: object)
                }
            }
        }
        if let currremoves = currgrid.removes
        {
            for object in masterinv
            {
                if object.name == currremoves
                {
                    newgrid.setRemoves(removes: object)
                }
            }
        }
        if let curranimate = currgrid.animate
        {
            newgrid.setAnimateName(animatename: curranimate)
        }
        if let currselectable: String = currgrid.selectable
        {
            newgrid.setSelectable(selectable: childNode(withName: ".//" + currselectable) as! SKSpriteNode)
        }
        if let currselects: [GameJSONGrid] = currgrid.selects
        {
            var selectlist: [GameSpot] = []
            for select in currselects
            {
                selectlist.append(loadJSONSpot(currgrid: select))
            }
            newgrid.setSelects(selects: selectlist)
        }
        if let currinvdisplay = currgrid.invdisplay
        {
            newgrid.setInvDisplay(invdisplay: currinvdisplay)
        }
        if let currsequence = currgrid.sequence
        {
            newgrid.setSequence(sequence: currsequence)
        }
        if let currspeech = currgrid.speech
        {
            newgrid.setSpeech(speech: currspeech)
        }
        if let currdialogue = currgrid.dialogue
        {
            newgrid.setDialogueName(dialoguename: currdialogue)
            /*for eachdialogue in dialogue
            {
                if eachdialogue.getName() == currdialogue
                {
                    newgrid.setDialogue(dialogue: eachdialogue)
                }
            }*/
        }
        if let currcycle = currgrid.cycle
        {
            newgrid.setCycleLocs(cyclelocs: currcycle)
        }
        if let currcyclerev = currgrid.cyclerev
        {
            newgrid.setCycleRevName(cyclerevname: currcyclerev)
        }
        if let currcycleifs = currgrid.cycleif
        {
            var cycleiflist: [(GameJSONLoc, [GameSpot])] = []
            for currcycleif in currcycleifs
            {
                let jsonloc: GameJSONLoc = GameJSONLoc(name: currcycleif.name, parent: currcycleif.parent, grandparent: nil)
                var valuelist: [GameSpot] = []
                for value in currcycleif.values
                {
                    valuelist.append(loadJSONSpot(currgrid: value))
                }
                cycleiflist.append((jsonloc, valuelist))
            }
            newgrid.setCycleIfNames(cycleifnames: cycleiflist)
        }
        if let currchoices = currgrid.choices
        {
            var choicenames: [(name: String, dialogue: String, act: String, parent: String?)] = []
            for choice in currchoices
            {
                choicenames.append((name: choice.name, dialogue: choice.dialogue, act: choice.type, parent: choice.parent))
            }
            newgrid.setChoiceNames(choicenames: choicenames)
        }
        if let currdraws = currgrid.draws
        {
            newgrid.setDraws(draws: currdraws)
        }
        if let currdrawclear = currgrid.drawclear
        {
            var drawclearlist: [GameScreen] = []
            for drawclear in currdrawclear
            {
                drawclearlist.append(childNode(withName: drawclear) as! GameScreen)
            }
            newgrid.setDrawClear(drawclear: drawclearlist)
        }
        if let currshows = currgrid.shows
        {
            var assignshows: [SKSpriteNode] = []
            var assignshowlocs: [GameJSONLoc] = []
            for show in currshows
            {
                assignshowlocs.append(show)
                if let grandparent = show.grandparent
                {
                    assignshows.append(childNode(withName: grandparent)?.childNode(withName: show.parent)?.childNode(withName: show.name) as! SKSpriteNode)
                } else
                {
                    assignshows.append(childNode(withName: show.parent)?.childNode(withName: show.name) as! SKSpriteNode)
                }
            }
            newgrid.setShowLocs(showlocs: assignshowlocs)
            newgrid.setShows(shows: assignshows)
        }
        if let currhides = currgrid.hides
        {
            var assignhides: [SKSpriteNode] = []
            var assignhidelocs: [GameJSONLoc] = []
            for hide in currhides
            {
                assignhidelocs.append(hide)
                if let grandparent = hide.grandparent
                {
                    assignhides.append(childNode(withName: grandparent)?.childNode(withName: hide.parent)?.childNode(withName: hide.name) as! SKSpriteNode)
                } else
                {
                    assignhides.append(childNode(withName: hide.parent)?.childNode(withName: hide.name) as! SKSpriteNode)
                }
            }
            newgrid.setHideLocs(hidelocs: assignhidelocs)
            newgrid.setHides(hides: assignhides)
        }
        if let currtoggles = currgrid.toggles
        {
            newgrid.setToggleLocs(togglelocs: currtoggles)
        }
        if let currtransition = currgrid.transition
        {
            if currtransition { newgrid.setTransition(transition: true) }
        }
        
        return newgrid
    }
    
    func loadJSONDialogue(dialogue: GameJSONDialogue)
    {
        let currdialogue = GameDialogue(name: dialogue.name)
        if let lines: [GameJSONLine] = dialogue.lines
        {
            currdialogue.setLines(lines: lines)
        }
        var exits: [GameSpot] = []
        if let sharedexit: [GameJSONGrid] = dialogue.sharedexit
        {
            for exit in sharedexit
            {
                exits.append(loadJSONSpot(currgrid: exit))
            }
        }
        if let branch: [GameJSONBranch] = dialogue.branch
        {
            var branchlist: [GameDialogue] = []
            for currbranch in branch
            {
                branchlist.append(loadJSONBranch(branch: currbranch, exitactions: exits))
                
            }
            currdialogue.setBranch(branch: branchlist)
        }
        for exit in exits { linkSpotRefs(currgrid: exit) }
        self.dialogue.append(currdialogue)
    }
    
    func loadJSONBranch(branch: GameJSONBranch, exitactions: [GameSpot]) -> GameDialogue
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
        if let exittype = branch.exittype
        {
            for spot in exitactions
            {
                if spot.getName() == exittype
                {
                    currbranch.setExitAction(exitaction: spot)
                }
            }
        }
        if let lines = branch.lines
        {
            currbranch.setLines(lines: lines)
        }
        if let branch = branch.branch
        {
            var branchlist: [GameDialogue] = []
            for currbranch in branch
            {
                branchlist.append(loadJSONBranch(branch: currbranch, exitactions: exitactions))
            }
            currbranch.setBranch(branch: branchlist)
        }
        if let action = branch.action
        {
            let parsedaction = loadJSONSpot(currgrid: action[0])
            currbranch.setAction(action: parsedaction)
            /*linkSpotRefs(currgrid: parsedaction)
            if let parsedview = parsedaction.getView()
            {
                if let parsedsubgrid = parsedview.getGrid()
                {
                    for grid in parsedsubgrid
                    {
                        linkSpotRefs(currgrid: grid)
                    }
                }
            }*/
        }
        
        return currbranch
    }
    
    override func loadAutoSave()
    {
        var hold: GameSave  = GameSave.autosave
        for object: String in GameSave.autosave.inventory
        {
            for obj: GameInvObj in masterinv
            {
                if obj.name == object
                {
                    currentinv.append(obj)
                    obj.position = CGPoint(x: (config.invspace + (config.invunit / 2)) * config.invscale * config.scale, y: (config.invspace + (config.invunit / 2)) * config.invscale * config.scale)
                    obj.scale(to: CGSize(width: 0, height: 0))
                    obj.zPosition = 2
                    addChild(obj)
                }
            }
        }
        for show in GameSave.autosave.shows
        {
            if show.count == 3
            {
                childNode(withName: show[2])?.childNode(withName: show[1])?.childNode(withName: show[0])?.isHidden = false
            }
            else
            {
                childNode(withName: show[1])?.childNode(withName: show[0])?.isHidden = false
            }
            
        }
        for hide in GameSave.autosave.hides
        {
            if hide.count == 3
            {
                childNode(withName: hide[2])?.childNode(withName: hide[1])?.childNode(withName: hide[0])?.isHidden = true
            }
            else
            {
                childNode(withName: hide[1])?.childNode(withName: hide[0])?.isHidden = true
            }
        }
        for (name, parent) in GameSave.autosave.toggles
        {
            if parent == "State" {
                for state in states {
                    if state.name == name {
                        state.action?.toggle()
                    }
                }
            } else {
                for grid in (childNode(withName: parent) as! GameScreen).getGrid()!
                {
                    if grid.getName() == name
                    {
                        grid.toggle()
                    }
                }
            }
        }
        for (name, value) in GameSave.autosave.flags
        {
            flags[name] = value
        }
        for (name, value) in GameSave.autosave.cyclevals
        {
            for grid in (childNode(withName: GameSave.autosave.cyclelocs[name]!) as! GameScreen).getGrid()!
            {
                if grid.getName() == name
                {
                    grid.setCycleCounter(count: value)
                }
            }
        }
        var vals: [Int] = []
        for (i, state) in states.enumerated()
        {
            if GameSave.autosave.states.contains(state.name)
            {
                vals.append(i)
            }
        }
        for i in vals.reversed() { states.remove(at: i) }
        for choice in GameSave.autosave.choices
        {
            for currdialogue in dialogue
            {
                if currdialogue.getName() == choice[1]
                {
                    if choice.count == 4
                    {
                        if let choiceparent = findChoice(start: currdialogue, name: choice[3])
                        {
                            if choice[2] == "enable"
                            {
                                choiceparent.setLineActive(line: choice[0], active: true)
                            } else if choice[2] == "disable"
                            {
                                choiceparent.setLineActive(line: choice[0], active: false)
                            }
                        }
                    } else
                    {
                        if let choiceparent = findChoice(start: currdialogue, name: choice[0])
                        {
                            if choice[2] == "enable" && choiceparent.getActive() != 2
                            {
                                choiceparent.setActive(active: 1)
                            } else if choice[2] == "disable" && choiceparent.getActive() != 2
                            {
                                choiceparent.setActive(active: 0)
                            } else if choice[2] == "remove"
                            {
                                choiceparent.setActive(active: 2)
                            }
                        }
                    }
                }
            }
        }
    }
}
