//
//  DGIRoom.swift
//  DGI: Engine
//
//  Created by William Frank on 4/17/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit
import AVFoundation

class DGIRoom: DGIScreen {
    
    weak var thisnode: DGIRoomNode!
    var states: [DGIParsedState] = []
    let subtitle = SKLabelNode.init()
    let inventory = DGIInventory()
    var invsounds: Next<String>!
    var flags = [String : Bool]()
    var globanims: [DGIJSONAnimation]?
    weak var viewnode: DGIRoomNode!
    weak var dragging: DGIRoomSub!
    var dragspot: CGPoint?
    weak var downsub: DGIRoomSub!
    var downloc: CGRect!
    var downtime = DispatchTime.now()
    let tutorial = DGITutorial()
    var sharedactions: [DGIJSONGrid] = []
    var clocks: [[DGIRoomSub]] = [[],[]]
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(from json: String) {
        super.init(from: json)
        
        addChild(tutorial)
        
        inventory.setScale(Config.inv.scale)
        inventory.position = CGPoint(x: Config.inv.space + (Config.inv.unit / 2), y: Config.inv.space + (Config.inv.unit / 2))
        inventory.zPosition = 2
        addChild(inventory)
        childNode(withName: "Avatar")?.alpha = 0.8
        
        subtitle.fontSize = CGFloat(Config.subtitle.text)
        subtitle.fontName = "Arial"
        subtitle.position = CGPoint(x: frame.midX, y: Config.subtitle.y)
        subtitle.zPosition = 4
        subtitle.verticalAlignmentMode = .center
        subtitle.isHidden = true
        addChild(subtitle)
        
        
        /*let testbox = SKShapeNode(rect: CGRect(x: -60, y: -60, width: 120, height: 120), cornerRadius: 15)
        testbox.position = CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2)
        testbox.zPosition = 3
        testbox.fillColor = .black
        addChild(testbox)
        let effectNode = SKEffectNode()
        effectNode.shouldRasterize = true
        effectNode.addChild(SKSpriteNode(texture: view?.texture(from: testbox)))
        addChild(effectNode)
        effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius":60])*/
        
        loadAutoSave()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if GameSave.autosave.tutorial == "" {
            tutorial.restart()
            tutorial.nextStep(hasLeft: true, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            GameSave.autosave.setTutorial(true)
            GameSave.autosave.save()
        }
    }
    
    override func disableGestures(except names: [String] = []) {
        tutorial.clearScreen()
        super.disableGestures(except: names)
    }
    
    override func touchDown(atPoint pos: CGPoint) {
        if let spot = thisnode.gridSelected(at: pos) {
            if let loc = thisnode.grid[spot.index].down, let pos = thisnode.grid[spot.index].pos {
                if let gp = loc.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: loc.parent)?.childNode(withName: loc.name) as? DGIRoomSub
                    {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                        sub.alpha = sub.initalpha
                        downsub = sub
                        downloc = CGRect(x: pos[0], y: pos[1], width: pos[2], height: pos[3])
                    } /*else if let sub = childNode(withName: gp)?.childNode(withName: downloc.parent)?.childNode(withName: show.name) {
                        sub.isHidden = false
                    }*/
                } else {
                    if let sub = childNode(withName: loc.parent)?.childNode(withName: loc.name) as? DGIRoomSub
                    {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                        sub.alpha = sub.initalpha
                        downsub = sub
                        downloc = CGRect(x: pos[0], y: pos[1], width: pos[2], height: pos[3])
                        downtime = DispatchTime.now()
                    } /*else if let sub = childNode(withName: show.parent)?.childNode(withName: show.name) {
                        sub.isHidden = false
                    }*/
                }
                disableGestures()
                return
            }
        }
        let nodelist = nodes(at: pos)
        for node in nodelist {
            if let gear = node as? DGIGear {
                if !gear.fixed && !((node.parent as? DGIGearNode)?.solved ?? false) {
                    gear.stopRunning()
                    dragging = node as? DGIRoomSub
                    disableGestures()
                    return
                }
            } else if node is DGIRoomSub {
                if (node as? DGIRoomSub)?.draggable ?? false {
                    dragging = node as? DGIRoomSub
                    if dragging.draginf!.dragrot ?? 0 > 0 {
                        dragspot = pos
                    } else {
                        dragspot = CGPoint(x: pos.x - dragging.position.x, y: pos.y - dragging.position.y)
                    }
                    disableGestures()
                    return
                }
            }
        }
    }
    
    override func touchMoved(toPoint pos: CGPoint) {
        if dragging != nil, let draginf = dragging.draginf {
            if draginf.dragtype == .dragX || draginf.dragtype == .free {
                if dragging.anchorPoint == CGPoint(x: 0, y: 0) {
                    if let dragrect = draginf.dragrect {
                        dragging.position = CGPoint(x: min(max(pos.x - dragging.size.width / 2, dragrect[0]), dragrect[0] + dragrect[2] - dragging.size.width), y: min(max(pos.y - dragging.size.height / 2, dragrect[1]), dragrect[1] + dragrect[3] - dragging.size.height))
                    } else {
                        dragging.position = CGPoint(x: pos.x - dragging.size.width / 2, y: pos.y - dragging.size.height / 2)
                    }
                } else if dragging.anchorPoint == CGPoint(x: 0.5, y: 0.5)  {
                    if let dragrect = draginf.dragrect {
                        dragging.position = CGPoint(x: min(max(pos.x, dragrect[0] + dragging.size.width / 2), dragrect[0] + dragrect[2] - dragging.size.width / 2), y: min(max(pos.y, dragrect[1] + dragging.size.height / 2), dragrect[1] + dragrect[3] - dragging.size.height / 2))
                    } else {
                        dragging.position = CGPoint(x: pos.x, y: pos.y)
                    }
                }
            } else if draginf.dragtype == .dragY {
                if dragging.anchorPoint == CGPoint(x: 0, y: 1) {
                    dragging.position = CGPoint(x: dragging.position.x, y: min(max(pos.y - (dragspot?.y ?? 0),0),CGFloat(dragging.dragbed) ))
                }
            } else if dragging is DGIGear {
                dragging.position = CGPoint(x: pos.x, y: pos.y)
            } else if draginf.dragtype == .rotate {
                dragging.zRotation = -1 * atan2(pos.x - dragging.position.x, pos.y - dragging.position.y)
            }
        }
        if downsub != nil {
            if !downloc.contains(pos) {
                downsub.isHidden = true
                downsub = nil
                downloc = nil
                enableGestures()
            }
        }
    }
    
    override func touchUp(atPoint pos : CGPoint) {
        thisnode.ontime = DispatchTime.now()
        if dragging != nil {
            if let gear = dragging as? DGIGear { gear.drop(at: pos) }
            else if let draginf = dragging.draginf {
                if let dragbedsall = draginf.dragbeds { //CHECK
                    let dragbeds = dragbedsall[1]
                    if dragging.anchorPoint == CGPoint(x: 0, y: 0) {
                        dragging.position = CGPoint(x: pos.x - dragging.size.width / 2, y: pos.y - dragging.size.height / 2)
                    } else if draginf.dragtype == .dragY {
                        dragging.position = CGPoint(x: dragging.position.x, y: min(max(pos.y - (dragspot?.y ?? 0),0),CGFloat(dragging.dragbed) ))
                    } else {
                        dragging.zRotation = -1 * atan2(pos.x - dragging.position.x, pos.y - dragging.position.y)
                        //dragging.zRotation += pos.distance(toPoint: dragging.position) / (CGFloat.pi * 200)
                    }
                    dragging.dragbed = (-1*((dragging.zRotation - (CGFloat.pi / CGFloat(dragbeds))).remainder(dividingBy: 2 * CGFloat.pi)) / (2 * CGFloat.pi / CGFloat(dragbeds))).mod(dragbeds)
                    dragging.run(SKAction.rotate(toAngle: -2 * CGFloat.pi * CGFloat(dragging.dragbed) / CGFloat(dragbeds), duration: 0.3, shortestUnitArc: true))
                    for cycle in draginf.dragcycle ?? [] {
                        if let parentNode = childNode(withName: cycle.parent) {
                            for sub in cycle.subs { parentNode.childNode(withName: sub.sub)?.isHidden = true }
                            if let newNode = parentNode.childNode(withName: cycle.subs[dragging.dragbed].sub) as? DGIRoomSub {
                                if newNode.texture == nil { newNode.loadTexture() }
                                newNode.isHidden = false
                            }
                            
                            //add saving dragcycles
                            //if spotsave { GameSave.autosave.addCycle(name: spot.name, parent: cycle.parent, val: spot.cyclecounter) }
                            //save = true
                        }
                    }
                } else if let dragrot = draginf.dragrot {
                    if let initspot = dragspot {
                        if initspot.distance(to: pos) < 1 {
                            dragging.run(SKAction.rotate(byAngle: -1.0 * dragrot * CGFloat.pi, duration: 0.1))
                        }
                    }
                }
                if let dragaction = draginf.dragaction {
                    runSpot((thisnode.gridSelected(name: dragaction)?.spot)!)
                }
            }
            enableGestures()
            tutorial.typechecks.insert(.dragObj)
            tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            dragging = nil
            return
        }
        if downsub != nil {
            downsub.isHidden = true
            downsub = nil
            enableGestures()
            if let spot = thisnode.gridSelected(at: downloc.origin) {
                if let downvals = spot.spot.down?.values {
                    let timeElapsed = Double(DispatchTime.now().uptimeNanoseconds - downtime.uptimeNanoseconds) / 1_000_000_000
                    for value in downvals {
                        if value.name.hasPrefix("<") {
                            if timeElapsed < Double(value.name.dropFirst())! {
                                runSpot(value)
                            }
                        } else if value.name.hasPrefix(">") {
                            if timeElapsed > Double(value.name.dropFirst())! {
                                runSpot(value)
                            }
                        }
                    }
                } else {
                    runSpot(thisnode.grid[spot.index])
                    return
                }
            }
            downloc = nil
        }
        if gestures.allSatisfy( {$0.value.state == .possible || $0.value.state == .failed} ) {
            if camera?.xScale != 1 {
                if let spot = thisnode.gridSelected(at: pos)?.spot {
                    if let _ = spot.phonezoom {
                        
                    } else {
                        camera?.run(SKAction.group([SKAction.move(to: CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2), duration: 0.6), SKAction.scale(to: 1, duration: 0.6)]))
                    }
                } else {
                    camera?.run(SKAction.group([SKAction.move(to: CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2), duration: 0.6), SKAction.scale(to: 1, duration: 0.6)]))
                }
            }
            if menubar.contains(pos) {
                removeAction(forKey: "MenuBarClose")
                menubar.openBar()
                run(SKAction.sequence([SKAction.wait(forDuration:4), SKAction.run{ self.menubar.closeBar() }]), withKey: "MenuBarClose")
                let menuoption = menubar.touchUp(pos: pos)
                if menuoption == 1 {
                    for music in self.music { music.run(SKAction.pause()) }
                    menu?.returnScene = self
                    menu?.toggleSettings(false)
                    view?.presentScene(menu!, transition: .fade(withDuration: 0.2))
                } else if menuoption == 2 {
                    for music in self.music { music.run(SKAction.pause()) }
                    menu?.returnScene = self
                    menu?.toggleSettings(true)
                    view?.presentScene(menu!, transition: .fade(withDuration: 0.2))
                } else if menuoption == 3 {
                    tutorial.restart()
                    tutorial.nextStep(hasLeft: thisnode.back == nil && thisnode.moves["leftname"] != "", zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back != nil, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
                }
                return
            }
            if !choicebox.isHidden {
                choicebox.selectLine(at: pos)
                return
            }
            if !playerbox.isHidden || !avatarbox.isHidden {
                playerbox.skipLine()
                avatarbox.skipLine()
                return
            }
            if pos.x > Config.bounds.width - Config.avatarspace - (childNode(withName: "Avatar")?.frame.width ?? 0), pos.y > Config.bounds.height - Config.avatarspace - (childNode(withName: "Avatar")?.frame.height ?? 0) {
                tutorial.clearScreen()
                runDialogue(name: "Avatar")
                return
            }
            if pos.y < 2 * Config.inv.space + Config.inv.unit {
                if pos.x < 2 * Config.inv.space + Config.inv.unit {
                    inventory.openInv()
                    return
                } else if inventory.zRotation < CGFloat(-86 * Double.pi/180), pos.x < Config.inv.space + (Config.inv.space + Config.inv.unit) * CGFloat(inventory.currentinv.count + 1) {
                    inventory.openInv()
                    inventory.selectInv(at: pos.x)
                    return
                }
            }
            if viewnode != nil {
                if viewnode.frame.contains(pos) {
                    if let spot = viewnode.gridSelected(at: pos) {
                        runSpot(viewnode.grid[spot.index])
                    }
                } else {
                    viewnode.isHidden = true
                    viewnode = nil
                    enableGestures()
                }
            } else if let spot = thisnode.gridSelected(at: pos) {
                runSpot(thisnode.grid[spot.index])
            } else {
                for node in nodes(at: pos) {
                    if let gnode = node as? DGIGuessNos, let view = self.view {
                        if gnode.active {
                            gnode.showInput(view)
                            gnode.textfield.becomeFirstResponder()
                        }
                    }
                    if let snode = node as? DGIScramble {
                        let pos2 = convert(pos, to: snode)
                        if snode.rect.contains(pos2), !snode.solved { snode.select(at: pos2) }
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
    
    @objc override func moveLeft() {
        if thisnode.moves["leftname"] != "" && thisnode.left == nil {
            thisnode.left = childNode(withName: thisnode.moves["leftname"]!) as? DGIRoomNode
        }
        if let left = thisnode.left {
            //disables zoom swipes
            //if left.texture == nil { return }
            thisnode.clearSelected()
            thisnode.moveOff()
            left.run(SKAction.sequence([SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0.15)]))
            thisnode.run(SKAction.sequence([SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0)]))
            thisnode = left
            thisnode.moveOn()
            tutorial.typechecks.insert(.swipeMove)
            tutorial.nextStep(hasLeft: true, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
        }
    }
    
    @objc override func moveRight() {
        if thisnode.moves["rightname"] != "" && thisnode.right == nil {
            thisnode.right = childNode(withName: thisnode.moves["rightname"]!) as? DGIRoomNode
        }
        if let right = thisnode.right {
            //disables zoom swipes
            //if right.texture == nil { return }
            thisnode.clearSelected()
            thisnode.moveOff()
            right.run(SKAction.sequence([SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0.15)]))
            thisnode.run(SKAction.sequence([SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0)]))
            thisnode = right
            thisnode.moveOn()
            tutorial.typechecks.insert(.swipeMove)
            tutorial.nextStep(hasLeft: true, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
        }
    }
    
    @objc override func scrollUp() {
        if !(childNode(withName: "ChoiceBox")?.isHidden ?? true) {
            super.scrollUp()
        } else if viewnode != nil {
            viewnode.isHidden = true
            viewnode = nil
            cutSpeech()
            enableGestures()
        } else {
            if thisnode.moves["backname"] != "" && thisnode.back == nil {
                thisnode.back = childNode(withName: thisnode.moves["backname"]!) as? DGIRoomNode
            }
            if let back = thisnode.back {
                if back.texture == nil { back.loadTexture() }
                thisnode.moveOff()
                thisnode.clearSelected()
                thisnode.isHidden = true
                thisnode = back
                thisnode.isHidden = false
                thisnode.moveOn()
                tutorial.typechecks.insert(.swipeBack)
                tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
                
            }
        }
    }
    
    @objc override func scrollDown() {
        super.scrollDown()
    }
    
    func runSpeech(_ spot: DGIJSONGrid) {
        speechloop: for count in 0..<spot.speech!.count {
            if let frequency = spot.speech![(count+spot.speechcounter!) % spot.speech!.count].frequency {
                if Double.random(in: 0..<1) < frequency {
                    subtitle.removeAllActions()
                    subtitle.removeAllChildren()
                    subtitle.position = CGPoint(x: frame.midX, y: Config.subtitle.y)
                    subtitle.text = spot.speech![(count + spot.speechcounter!) % spot.speech!.count].line
                    
                    if let offset = spot.speech![(count+spot.speechcounter!) % spot.speech!.count].offset {
                        subtitle.run(SKAction.sequence([SKAction.unhide(), SKAction.move(by: CGVector(dx: 0, dy: offset), duration: 0),SKAction.wait(forDuration: Config.textspeed),SKAction.move(by: CGVector(dx: 0, dy: -1 * offset), duration: 0), SKAction.hide()]))
                    } else { subtitle.run(SKAction.sequence([SKAction.unhide(), SKAction.wait(forDuration: Config.textspeed), SKAction.hide()])) }
                    spot.speechcounter = (spot.speechcounter! + count + 1) % spot.speech!.count
                    break speechloop
                }
            } else {
                subtitle.removeAllActions()
                subtitle.removeAllChildren()
                subtitle.position = CGPoint(x: frame.midX, y: Config.subtitle.y)
                subtitle.text = spot.speech![(count + spot.speechcounter!) % spot.speech!.count].line
                if let boxalpha = spot.speech![(count+spot.speechcounter!) % spot.speech!.count].boxalpha {
                    let subbox = SKShapeNode(rectOf: CGSize(width: subtitle.frame.width + 2 * Config.subtitle.text, height: 2 * Config.subtitle.text))
                    subbox.fillColor = .black
                    subbox.strokeColor = .black
                    subbox.alpha = boxalpha
                    subbox.zPosition = -0.5
                    subtitle.addChild(subbox)
                }
                if let offset = spot.speech![(count+spot.speechcounter!) % spot.speech!.count].offset {
                    subtitle.run(SKAction.sequence([SKAction.unhide(), SKAction.move(by: CGVector(dx: 0, dy: offset), duration: 0),SKAction.wait(forDuration: Config.textspeed),SKAction.move(by: CGVector(dx: 0, dy: -1 * offset), duration: 0), SKAction.hide()]))
                } else { subtitle.run(SKAction.sequence([SKAction.unhide(), SKAction.wait(forDuration: Config.textspeed), SKAction.hide()])) }
                spot.speechcounter = (spot.speechcounter! + count + 1) % spot.speech!.count
                break speechloop
            }
        }
    }
    
    func cutSpeech() {
        if !subtitle.isHidden {
            subtitle.removeAllActions()
            subtitle.run(SKAction.sequence([SKAction.wait(forDuration: 0.1), SKAction.hide()]))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (inventory.zRotation == 0) {
            inventory.selected = nil
        }
        if thisnode.wait.count > 0 {
            //CURRENTLY ONLY IMPLEMENTED FOR ONE WAIT
            let timeElapsed = Double(DispatchTime.now().uptimeNanoseconds - thisnode.ontime.uptimeNanoseconds) / 1_000_000_000
            for waitspot in thisnode.wait {
                if timeElapsed > Double(waitspot.pos[0]) {
                    let spotid = (childNode(withName: waitspot.parent) as? DGIRoomNode)?.gridSelected(name: waitspot.name)
                    if let spot = spotid?.spot {
                        if spot.active ?? true { runSpot(spot) }
                    }
                    thisnode.ontime = DispatchTime.now()
                }
            }
        }
        for (index, state) in states.enumerated().reversed() {
            if state.action.active ?? true {
                var satisfied: Bool = true
                if let screen = state.sequencescreen, let sequence = state.sequence {
                    if state.type == .wrong {
                        satisfied = false
                        for (index, line) in screen.sequence.enumerated() {
                            if index < sequence.count { if sequence[sequence.index(sequence.startIndex, offsetBy: index)] != line[line.index(line.startIndex, offsetBy: 0)] { satisfied = true } }
                        }
                        if satisfied {
                            screen.sequence = []
                        }
                    } else {
                        var alltogether: String = ""
                        for line in screen.sequence { alltogether += line }
                        if alltogether != sequence { satisfied = false }
                    }
                }
                if let visibles = state.visibles {
                    for visible in visibles {
                        if let sub = visible.sub {
                            if sub.isHidden == visible.vis { satisfied = false }
                            if let color = visible.color { if !(sub.color == color) { satisfied = false} }
                        } else if let name = visible.name, let parent = visible.parent {
                            if let sub = (childNode(withName: parent)?.children.filter{ $0.name == name })?.last as? SKSpriteNode {
                                if sub.isHidden == visible.vis { satisfied = false }
                                if let color = visible.color {
                                    if !(sub.color.equals(other: color)) {
                                        satisfied = false} }
                            } else { if visible.vis == true { satisfied = false } }
                        }
                    }
                }
                if let cycles = state.cycles {
                    for cycle in cycles {
                        if cycle.screen.grid[cycle.index].cyclecounter != cycle.val { satisfied = false }
                    }
                }
                if let flags = state.flags {
                    for flag in flags {
                        if self.flags[flag.name] ?? false != flag.value { satisfied = false }
                    }
                }
                if let containers = state.containers {
                    for container in containers {
                        if let sub = container.sub {
                            if container.values.count == 1 {
                                if let total = Int(container.values[0]) {
                                    if sub.contents.intParse().reduce(0, +) != total { satisfied = false }
                                } else if container.values[0].starts(with: ">") {
                                    if sub.contents.intParse().reduce(0, +) <= Int(String(container.values[0].dropFirst()))! { satisfied = false }
                                } else if container.values[0] != sub.contents { satisfied = false }
                            } else if !container.values.contains(sub.contents) { satisfied = false }
                        } else if let label = container.label {
                            if !container.values.contains(label.text ?? "") { satisfied = false }
                        }
                    }
                }
                if satisfied {
                    if state.action.active ?? true {
                        if let _ = state.action.animate {
                            state.action.active = false
                        }
                        runSpot(state.action, cutspeech: false)
                    }
                    if state.type == .once {
                        states.remove(at: index)
                        GameSave.autosave.addState(name: state.name)
                        GameSave.autosave.save()
                    }
                } else if let flag = state.action.flag {
                    flags[flag] = false
                }
            }
        }
        for hour in clocks[0] {
            hour.zRotation = -2 * CGFloat.pi * (CGFloat(Calendar.current.component(.hour, from: Date())) / 12 + CGFloat(Calendar.current.component(.minute, from: Date())) / 720)
        }
        for minute in clocks[1] {
            minute.zRotation = -2 * CGFloat.pi * CGFloat(Calendar.current.component(.minute, from: Date())) / 60
        }
    }
    
    func runDialogue(name: String = "") {
        if let index = dialogues.firstIndex(where: {$0.name == name}) {
            disableGestures(except: ["scrollUp", "scrollDown"])
            if let lines = dialogues[index].lines {
                (childNode(withName: "PlayerBox") as! DGISpeechBox).runLines(jsonlines: lines, name: "Player", branch: dialogues[index].branch)
                (childNode(withName: "AvatarBox") as! DGISpeechBox).runLines(jsonlines: lines, name: "Avatar", branch: dialogues[index].branch)
                (childNode(withName: "ChoiceBox") as! DGIChoiceBox).dialno = index
            } else if let branch = dialogues[index].branch {
                (childNode(withName: "ChoiceBox") as! DGIChoiceBox).dialno = index
                (childNode(withName: "ChoiceBox") as! DGIChoiceBox).runBranch(branch)
            }
            inventory.run(SKAction.fadeOut(withDuration: 0.5))
            menubar.run(SKAction.fadeOut(withDuration: 0.5))
            if (inventory.zRotation > 0) {
                inventory.closeInv()
            }
        }
    }
    
    override func closeDialogue() {
        choicebox.isHidden = true
        inventory.run(SKAction.fadeIn(withDuration: 0.5))
        menubar.run(SKAction.fadeIn(withDuration: 0.5))
        enableGestures()
    }
    
    override func loadJSON() {
        do {
            let jsonData = try JSONDecoder().decode(DGIJSONRoom.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: json, ofType: "json")!)))
            invsounds = Next<String>(jsonData.invsounds)
            if let musics = jsonData.music {
                for (index, music) in musics.enumerated() {
                    let musicNode = SKAudioNode(fileNamed: music)
                    musicNode.name = music
                    musicNode.autoplayLooped = true
                    if index > 0 { musicNode.run(SKAction.changeVolume(to: 0, duration: 0)) }
                    addChild(musicNode)
                    self.music.append(musicNode)
                }
            }
            /*if let musicname = jsonData.music {
                let musicNode = SKAudioNode(fileNamed: musicname)
                musicNode.name = "Music"
                musicNode.autoplayLooped = true
                addChild(musicNode)
            }*/
            for screenData in jsonData.screens {
                let start = (jsonData.start == screenData.name) ? true : false
                let screen = DGIRoomNode(imageNamed: screenData.image, name: screenData.name, grid: screenData.grid)
                if let left = screenData.left { screen.moves["leftname"] = left }
                if let right = screenData.right { screen.moves["rightname"] = right }
                if let back = screenData.back { screen.moves["backname"] = back }
                if let wait = screenData.wait { screen.wait = wait }
                if let backaction = screenData.backaction { screen.backaction = backaction }
                if let moveonaction = screenData.onaction { screen.moveonaction = moveonaction }
                if let sequence = screenData.sequence { screen.sequencelength = sequence }
                if let sequencedraw = screenData.sequencedraw { screen.sequencedraw = sequencedraw }
                addChild(screen)
                if let subs = screenData.subs {
                    var currZ: CGFloat = 0.01
                    subloop: for subData in subs {
                        if let special = DGISpecialType(rawValue: subData.image) {
                            if special != .counter { screen.special = special }
                            if special == .counter, let counter = subData.special {
                                let counterNode = DGICounter(name: subData.name, fontNamed: counter[0].counter?.font ?? "Courier New", size: Config.dialogue.text * (counter[0].counter?.size ?? 1), initialVal: Double(subData.sub[0]))
                                if subData.sub.count > 1 { counterNode.max = Double(subData.sub[1]) }
                                if subData.sub.count > 2 { counterNode.precision = Int(subData.sub[2]); counterNode.setLabel() }
                                //FUTURE: ALLOW COUNTER COLOR CONTROL THROUGH SPECIAL
                                counterNode.fontColor = UIColor(hex: counter[0].counter?.color ?? "#FFFFFF")
                                counterNode.horizontalAlignmentMode = .center
                                counterNode.verticalAlignmentMode = .bottom
                                counterNode.alpha = counter[0].counter?.alpha ?? 1
                                counterNode.position = CGPoint(x: counter[0].pos[0] * Config.scale, y: counter[0].pos[1] * Config.scale)
                                screen.addChild(counterNode)
                            }
                            if special == .scramble, let scramble = subData.special {
                                let scrambleNode = DGIScramble(name: scramble[0].name, imageNamed: scramble[0].scramble!.image, grid: (Int(subData.sub[0]), Int(subData.sub[1])), rect: CGRect(x: 0, y: 0, width: max(scramble[0].pos[4], scramble[0].pos[6])-min(scramble[0].pos[0], scramble[0].pos[2]), height: max(scramble[0].pos[3], scramble[0].pos[7])-min(scramble[0].pos[1], scramble[0].pos[5])), solve: subData.solve, hides: Array(subData.sub[2..<subData.sub.count]))
                                screen.addChild(scrambleNode)
                                if GameSave.autosave.specials[scramble[0].name] == 1 { scrambleNode.solved = true }
                                scrambleNode.generate(scramble)
                            }
                            if special == .slidebox, let slidedata = subData.special {
                                guard let boxdata = slidedata[0].slidebox else {
                                    fatalError("Slidebox defined without data")
                                }
                                let boxNode = SKSpriteNode(imageNamed: subData.image, name: slidedata[0].name + "_Box")
                                boxNode.zPosition = 1
                                boxNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                                boxNode.position = CGPoint(x: (subData.sub[0] + (subData.sub[2] / 2))  * Config.scale, y: (subData.sub[1] + (subData.sub[3] / 2)) * Config.scale)
                                screen.addChild(boxNode)
                                let slideRect = CGRect(x: 0, y: 0, width: max(slidedata[0].pos[4], slidedata[0].pos[6])-min(slidedata[0].pos[0], slidedata[0].pos[2]), height: max(slidedata[0].pos[3], slidedata[0].pos[7])-min(slidedata[0].pos[1], slidedata[0].pos[5]))
                                let slideNode = DGISlideBox(name: slidedata[0].name, imageNamed: subData.image, active: slidedata[0].active ?? true, rect: slideRect, slidedata: boxdata, solve: subData.solve)
                                /*let rotateNode = DGIRotateNode()
                                rotateNode.position = CGPoint(x: ((slidedata[0].pos[0] + slidedata[0].pos[4]) / 2)  * Config.scale, y: ((slidedata[0].pos[1] + slidedata[0].pos[3]) / 2)  * Config.scale)
                                rotateNode.addChild(slideNode)
                                screen.addChild(rotateNode)*/
                                let warpNode = DGIWarpNode()
                                warpNode.zPosition = 2
                                //warpNode.anchorPoint = CGPoint(x: 0, y: 0)
                                //warpNode.position = CGPoint(x: slidedata[0].pos[0], y: slidedata[0].pos[1])
                                warpNode.position = CGPoint(x: ((slidedata[0].pos[0] + slidedata[0].pos[4]) / 2)  * Config.scale, y: ((slidedata[0].pos[1] + slidedata[0].pos[3]) / 2)  * Config.scale)
                                warpNode.addChild(slideNode)
                                screen.addChild(warpNode)
                                slideNode.generate(slidedata)
                                if GameSave.autosave.specials[slidedata[0].name] == 1 { slideNode.start(save: false) }
                            }
                            if special == .guessnos, let guessData = subData.special {
                                let guessNode = DGIGuessNos(name: guessData[0].name, values: subData.sub, active: guessData[0].active ?? true, solve: subData.solve)
                                screen.addChild(guessNode)
                                guessNode.generate(guessData)
                                if GameSave.autosave.specials[guessData[0].name] == 1 { guessNode.start() }
                            }
                            continue subloop
                        }
                        if subData.image == "label", let labelData = subData.label {
                            let labelNode = SKLabelNode(fontNamed: labelData.font ?? "Arial")
                            labelNode.name = subData.name
                            labelNode.fontSize = Config.dialogue.text * (labelData.size ?? 1)
                            labelNode.text = labelData.text
                            labelNode.fontColor = UIColor(hex: labelData.color ?? "#FFFFFF")
                            labelNode.alpha = labelData.alpha ?? 1
                            labelNode.position = CGPoint(x: subData.sub[0] * Config.scale, y: subData.sub[1] * Config.scale)
                            if let rotate = subData.rotate { labelNode.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                            labelNode.numberOfLines = 1
                            labelNode.zPosition = 1.5
                            labelNode.horizontalAlignmentMode = labelData.align == "center" ? .center : .left
                            labelNode.verticalAlignmentMode = .bottom
                            labelNode.isHidden = !(subData.visible ?? true)
                            screen.addChild(labelNode)
                            if let frames = subData.frames {
                                //COPIED FROM SUB FRAMES - ???
                                var actionGroup: [SKAction] = []
                                for frame in frames {
                                    if frame.frame == "rotateby" {
                                        actionGroup.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi)/180, duration: frame.duration))
                                    } else if frame.frame == "moveby" {
                                        actionGroup.append(SKAction.move(by: CGVector(dx: frame.pos![0], dy: frame.pos![0]), duration: frame.duration))
                                    }
                                }
                                labelNode.run(SKAction.repeatForever(SKAction.sequence(actionGroup)), withKey: "Animate")
                                if let running = subData.running {
                                    if !running { labelNode.action(forKey: "Animate")!.speed = 0 }
                                }
                            }
                            continue subloop
                        }
                        let sub = DGIRoomSub(imageNamed: subData.image, name: subData.name, position: CGPoint(x: subData.sub[0] * Config.scale, y: subData.sub[1] * Config.scale))
                        if let anchor = subData.anchor {
                            sub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                            sub.position = CGPoint(x: (subData.sub[0] + (subData.sub[2] * anchor[0]))  * Config.scale, y: (subData.sub[1] + (subData.sub[3] * anchor[1])) * Config.scale)
                        }
                        if let preload = subData.preload { if preload { sub.loadTexture() }}
                        if let contains = subData.contains { sub.contents = contains }
                        if let drags = subData.drags {
                            sub.draggable = true
                            sub.draginf = drags
                            if let dragbeds = drags.dragbeds {
                                sub.dragbed = dragbeds[0]
                                /*if dragbeds.count > 1 {
                                    sub.dragbeds = dragbeds[1]
                                }*/
                                if dragbeds[0] > 0 && drags.dragtype == .rotate { sub.zRotation = -2 * CGFloat.pi * CGFloat(dragbeds[0]) / CGFloat(dragbeds[1]) }
                            }
                            if let _ = drags.dragrot {
                                sub.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                                sub.position = CGPoint(x: (subData.sub[0] + (subData.sub[2] * 0.5))  * Config.scale, y: (subData.sub[1] + (subData.sub[3] * 0.5)) * Config.scale)
                            }
                            /*if let dragrect = drags.dragrect {
                                sub.dragrect = dragrect
                            }
                            sub.dragtype = drags.dragtype
                            if let dragcycle = drags.dragcycle { sub.dragcycle = dragcycle }
                            if let dragaction = drags.dragaction { sub.dragaction = dragaction }*/
                        }
                        sub.displayname = subData.displayname ?? subData.name
                        if let visible = subData.visible { sub.isHidden = !visible }
                        if let setZ = subData.setZ { sub.zPosition = setZ }
                        else { sub.zPosition = currZ; currZ += 0.01 }
                        if let alpha = subData.alpha { sub.alpha = CGFloat(alpha); sub.initalpha = CGFloat(alpha) }
                        if let rotate = subData.rotate { if !sub.draggable { sub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}}
                        if let clockcheck = subData.clock { if let clock = DGIClockType(rawValue: clockcheck) {
                            if clock == .hour { clocks[0].append(sub) }
                            else { clocks[1].append(sub) }
                        } }
                        if let blur = subData.blur {
                            let effectNode = SKEffectNode()
                            effectNode.name = subData.name
                            sub.name = subData.name + "Blur"
                            effectNode.addChild(sub)
                            sub.loadTexture()
                            sub.isHidden = false
                            effectNode.isHidden = !(subData.visible ?? true)
                            //effectNode.filter = CIFilter(name:"CIGaussianBlur",parameters: ["inputRadius": blur])
                            effectNode.shouldRasterize = true
                            effectNode.shouldEnableEffects = true
                            //effectNode.position = CGPoint(x: 0, y: 0)
                            sub.contents = "\(blur)"
                            screen.blurs.append(effectNode)
                            screen.addChild(effectNode)
                        } else if let rotate = subData.rotate { if sub.draggable {
                            let rotateNode = DGIRotateNode()
                            rotateNode.name = subData.name
                            let anchor = subData.anchor ?? [0, 0]
                            rotateNode.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                            rotateNode.position = CGPoint(x: (subData.sub[0] + (subData.sub[2] * anchor[0]))  * Config.scale, y: (subData.sub[1] + (subData.sub[3] * anchor[1])) * Config.scale)
                            rotateNode.zRotation = -1 * rotate * CGFloat(Double.pi)/180
                            rotateNode.isHidden = !(subData.visible ?? true)
                            sub.isHidden = false
                            sub.zRotation = 0
                            sub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                            sub.position = CGPoint(x: 0, y: 0)
                            sub.loadTexture()
                            rotateNode.addChild(sub)
                            screen.addChild(rotateNode)
                        } } else { screen.addChild(sub) }
                        if let subsubs = subData.subsubs {
                            for subsub in subsubs {
                                let currsubsub = DGIRoomSub(imageNamed: subsub.image, name: subsub.name, position: CGPoint(x: (subsub.sub[0] - subData.sub[0]) * Config.scale, y: (subsub.sub[1] - subData.sub[1]) * Config.scale))
                                if let anchor = subsub.anchor {
                                    currsubsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                                } else { currsubsub.anchorPoint = CGPoint(x:0, y:0) }
                                if let setZ = subsub.setZ { currsubsub.zPosition = setZ }
                                else { currsubsub.zPosition = CGFloat(currZ) }
                                currZ += 0.001
                                if let subvis = subsub.visible { currsubsub.isHidden = !subvis }
                                if let subalpha = subsub.alpha { currsubsub.alpha = CGFloat(subalpha); currsubsub.initalpha = CGFloat(subalpha)}
                                if let subrotate = subsub.rotate { currsubsub.zRotation = -1 * subrotate * CGFloat(Double.pi)/180}
                                sub.addChild(currsubsub)
                            }
                        }
                        //MOVE TO DGIROOMSUB? - MAKE ANIM FRAMES LOAD ON NEED?
                        if var frames = subData.frames {
                            sub.loadTexture()
                            if subData.type == "action" {
                                var actionGroup: [SKAction] = []
                                for frame in frames {
                                    var useduration = frame.duration
                                    //OFFSET UNTESTED
                                    if let offset = frame.offset {
                                        useduration += Double(arc4random_uniform(UInt32(offset*2))) - offset
                                        useduration = max(0, useduration)
                                    }
                                    if frame.frame == "rotateby" {
                                        actionGroup.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi)/180, duration: useduration))
                                    } else if frame.frame == "moveby" {
                                        actionGroup.append(SKAction.move(by: CGVector(dx: frame.pos![0], dy: frame.pos![1]), duration: useduration))
                                    } else if frame.frame == "show" {
                                        actionGroup.append(SKAction.unhide())
                                        actionGroup.append(SKAction.wait(forDuration: useduration))
                                    } else if frame.frame == "hide" {
                                        actionGroup.append(SKAction.hide())
                                        actionGroup.append(SKAction.wait(forDuration: useduration))
                                    }
                                }
                                sub.run(SKAction.repeatForever(SKAction.sequence(actionGroup)), withKey: "Animate")
                                if let running = subData.running {
                                    if !running { sub.action(forKey: "Animate")!.speed = 0 }
                                }
                            } else {
                                var framenames: [String] = [subData.image]
                                for frame in frames { framenames.append(frame.frame) }
                                if let type = subData.type {
                                    if type == "reverse" {
                                        frames = frames.reversed()
                                        for i in frames.indices.dropFirst() { framenames.append(frames[i].frame) }
                                    }
                                }
                                var framelist: [SKTexture] = [SKTexture(imageNamed: subData.image)]
                                for frame in framenames { framelist.append(SKTexture(imageNamed: frame)) }
                                if let type = subData.type {
                                    if type == "once" {
                                        sub.run(SKAction.animate(with: framelist, timePerFrame: 0.05), withKey: "Animate")
                                        sub.action(forKey: "Animate")!.speed = 0
                                    } else {
                                        sub.run(SKAction.repeatForever(SKAction.animate(with: framelist, timePerFrame: 0.05)), withKey: "Animate")
                                    }
                                } else {
                                    sub.run(SKAction.repeatForever(SKAction.animate(with: framelist, timePerFrame: 0.05)), withKey: "Animate")
                                }
                                if let running = subData.running {
                                    if !running { sub.action(forKey: "Animate")!.speed = 0 }
                                }
                            }
                        }
                    }
                }
                for spot in screen.grid { parseSpot(spot) }
                if let gearbox = screenData.gearbox {
                    let gearNode = DGIGearNode(gearbox)
                    screen.gearbox = gearNode
                    screen.addChild(gearNode)
                    for (index, peg) in gearbox.pegs.enumerated() {
                        let pegNode = DGIRoomSub(imageNamed: gearbox.pegimage, name: gearbox.name + "_Peg\(index)", position: CGPoint(x: peg[0], y: peg[1]))
                        pegNode.loadTexture()
                        pegNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                        gearNode.addChild(pegNode)
                    }
                    for gear in gearbox.gears {
                        gearNode.addChild(DGIGear(type: gearbox.geartypes.first(where: { $0.name == gear.type })!, gear: gear, gearbox: gearNode))
                    }
                    if let front = gearbox.front {
                        let frontNode = DGIRoomSub(imageNamed: front, name: gearbox.name + "_front", position: CGPoint(x: 0, y: 0))
                        frontNode.zPosition = 2
                        screen.addChild(frontNode)
                    }
                }
                if start { thisnode = screen; screen.loadTexture(); screen.isHidden = false }
                //else if index <= 8 { screen.loadTexture() }
            }
            if let sharedactions = jsonData.sharedactions {
                self.sharedactions = sharedactions
                for sharedaction in sharedactions {
                    parseSpot(sharedaction)
                }
            }
            //TODO: CLEANUP INVOBJ INITS
            for objectData in jsonData.objects {
                let object = DGIInventoryObject(imageNamed: objectData.image, name: objectData.name, displayname: objectData.displayname, scale: objectData.scale, animations: objectData.animations, subs: objectData.subs, collects: objectData.collects)
                inventory.masterinv.append(object)
                addChild(object)
            }
            if let debugitems = jsonData.debugitems {
                for debugitem in debugitems {
                    inventory.currentinv.append(inventory.masterinv.first(where: { $0.name == debugitem })!)
                    //GameSave.autosave.addInv(object: debugitem)
                }
            }
            globanims = jsonData.globanims
            for globanim in globanims ?? [] {
                for frame in globanim.frames {
                    if var flag = frame.flag {
                        if flag.last != "*" {
                            if flag.first == "!" { flag.removeFirst() }
                            flags[flag] = false
                        }
                    }
                }
            }
            let rawstates = jsonData.states ?? []
            for state in rawstates { self.states.append(parseState(from: state)) }
            if let setdialogues = jsonData.dialogues {
                dialogues = setdialogues
                for dialogue in setdialogues {
                    if let branch = dialogue.branch { parseBranch(branch) }
                }
            }
        } catch let error {
            print(error)
            print("Error parsing JSON.")
        }
        
    }
    
    func parseSpot(_ spot: DGIJSONGrid) {
        if spot.cyclecounter == nil { spot.cyclecounter = 0 }
        if let viewname = spot.view {
            parseView(view: viewname, name: spot.name, grid: spot.subgrid, subs: spot.subsubs)
        }
        if let flagactions = spot.flagactions {
            for flagaction in flagactions {
                parseSpot(flagaction)
            }
        }
        if let contents = spot.contents {
            for content in contents {
                for value in content.values {
                    parseSpot(value)
                }
            }
        }
        if let sequenceactions = spot.sequenceactions {
            for sequenceaction in sequenceactions {
                parseSpot(sequenceaction)
            }
        }
        if let selects = spot.selects {
            for select in selects {
                parseSpot(select)
            }
        }
    }
    
    func parseBranch(_ currbranch: [DGIJSONBranch]) {
        for branch in currbranch {
            if let action = branch.action?[0] {
                parseSpot(action)
            }
            if let nextbranch = branch.branch {
                parseBranch(nextbranch)
            }
        }
    }
    
    func parseView(view: String, name: String, grid: [DGIJSONGrid]?, subs: [DGIJSONSub]?) {
        let viewsub = DGIRoomNode(imageNamed: view, name: name, grid: grid)
        let viewsize = UIImage(named: view)?.size ?? CGSize(width: 0, height: 0)
        viewsub.anchorPoint = CGPoint(x:0.5, y:0.5)
        viewsub.position = CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2)
        viewsub.isHidden = true
        viewsub.zPosition = 2
        addChild(viewsub)
        if let sublist = subs {
            var currZ : Double = 0.01
            for sub in sublist {
                if sub.image == "label", let labelData = sub.label {
                    //COPY FROM ROOM - MAKE FUNCTION
                    let labelNode = SKLabelNode(fontNamed: labelData.font ?? "Arial")
                    labelNode.name = sub.name
                    labelNode.fontSize = Config.dialogue.text * (labelData.size ?? 1)
                    labelNode.text = labelData.text
                    labelNode.fontColor = UIColor(hex: labelData.color ?? "#FFFFFF")
                    labelNode.alpha = labelData.alpha ?? 1
                    labelNode.position = CGPoint(x: sub.sub[0] * Config.scale, y: sub.sub[1] * Config.scale)
                    if let rotate = sub.rotate { labelNode.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                    labelNode.numberOfLines = 1
                    labelNode.zPosition = 1.5
                    if let align = labelData.align {
                        if align == "center" { labelNode.horizontalAlignmentMode = .center }
                    } else { labelNode.horizontalAlignmentMode = .left }
                    labelNode.verticalAlignmentMode = .bottom
                    labelNode.isHidden = !(sub.visible ?? true)
                    viewsub.addChild(labelNode)
                } else {
                    //let currsub = DGIRoomSub(imageNamed: sub.image, name: sub.name, position: CGPoint(x: sub.sub[0] * Config.scale, y: sub.sub[1] * Config.scale))
                    let currsub = DGIRoomSub(imageNamed: sub.image, name: sub.name, position: CGPoint(x: (sub.sub[0] - viewsize.width / 2) * Config.scale, y: (sub.sub[1] - viewsize.height / 2) * Config.scale))
                    if let anchor = sub.anchor {
                        currsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                    } else { currsub.anchorPoint = CGPoint(x:0, y:0) }
                    currsub.zPosition = CGFloat(currZ)
                    currZ += 0.01
                    if let vis = sub.visible { currsub.isHidden = !vis }
                    if let alpha = sub.alpha { currsub.alpha = CGFloat(alpha)}
                    if let rotate = sub.rotate { currsub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                    viewsub.addChild(currsub)
                }
            }
        }
        if let subgrid = grid {
            for grid in subgrid {
                parseSpot(grid)
            }
        }
    }
    
    func parseState(from spot: DGIJSONGrid) -> DGIParsedState {
        var setscreen: DGIRoomNode?
        if let screen = spot.screen { setscreen = childNode(withName: screen) as? DGIRoomNode }
        var setvisibles: [(sub: DGIRoomSub?, vis: Bool, name: String?, parent: String?, color: UIColor?)]?
        if let visibles = spot.visibles {
            var visiblelist: [(sub: DGIRoomSub?, vis: Bool, name: String?, parent: String?, color: UIColor?)] = []
            for visible in visibles {
                if let gp = visible.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: visible.parent)?.childNode(withName: visible.name) as? DGIRoomSub {
                        if let color = visible.color { visiblelist.append((sub, visible.visible, visible.name, visible.parent,UIColor(hex: color))) }
                        else { visiblelist.append((sub, visible.visible, visible.name, visible.parent, nil)) }
                    }
                } else {
                    if let sub = childNode(withName: visible.parent)?.childNode(withName: visible.name) as? DGIRoomSub {
                        if let color = visible.color { visiblelist.append((sub, visible.visible, visible.name, visible.parent, UIColor(hex: color))) }
                        else { visiblelist.append((sub, visible.visible, visible.name, visible.parent, nil)) }
                    } else {
                        if let color = visible.color { visiblelist.append((nil, visible.visible, visible.name, visible.parent, UIColor(hex: color))) }
                        else { visiblelist.append((nil, visible.visible, visible.name, visible.parent, nil)) }
                    }
                }
            }
            setvisibles = visiblelist
        }
        var setcycles: [(screen: DGIRoomNode, index: Int, val: Int)]?
        if let cycles = spot.cycles {
            var cyclelist: [(screen: DGIRoomNode, index: Int, val: Int)] = []
            for cycle in cycles {
                if let gp = cycle.grandparent {
                    if let screen = childNode(withName: gp)?.childNode(withName: cycle.parent) as? DGIRoomNode {
                        //check this - when can subs have cycles?
                        cyclelist.append((screen, screen.gridSelected(name: cycle.name)!.index, cycle.cycle))
                    }
                } else {
                    if let screen = childNode(withName: cycle.parent) as? DGIRoomNode {
                        cyclelist.append((screen, screen.gridSelected(name: cycle.name)!.index, cycle.cycle))
                    }
                }
            }
            setcycles = cyclelist
        }
        var setcontainers: [(sub: DGIRoomSub?, label: SKLabelNode?, values: [String])]?
        if let containers = spot.containers {
            var containerlist: [(sub: DGIRoomSub?, label: SKLabelNode?, values: [String])] = []
            for container in containers {
                if let gp = container.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: container.parent)?.childNode(withName: container.name) as? DGIRoomSub {
                        containerlist.append((sub, nil, container.values))
                    } else if let label = childNode(withName: gp)?.childNode(withName: container.parent)?.childNode(withName: container.name) as? SKLabelNode {
                        containerlist.append((nil, label, container.values))
                    }
                } else {
                    if let sub = childNode(withName: container.parent)?.childNode(withName: container.name) as? DGIRoomSub {
                        containerlist.append((sub, nil, container.values))
                    } else if let label = childNode(withName: container.parent)?.childNode(withName: container.name) as? SKLabelNode {
                        containerlist.append((nil, label, container.values))
                    }
                }
            }
            setcontainers = containerlist
        }
        return DGIParsedState(name: spot.name, type: spot.type!, sequencescreen: setscreen, sequence: spot.match, visibles: setvisibles, cycles: setcycles, flags: spot.flags, containers: setcontainers, saves: spot.saves ?? true, action: spot)
    }
    
    override func loadAutoSave() {
        //GameSave.autosave.printString()
        for object in GameSave.autosave.inventory {
            for obj in inventory.masterinv {
                if obj.name == object {
                    inventory.currentinv.append(obj)
                    obj.position = CGPoint(x: inventory.center, y: inventory.center)
                    obj.setScale(0)
                    for collectobj in obj.collects {
                        if let addto = inventory.currentinv.firstIndex(where: { $0.name == collectobj }) {
                            obj.isCollected = addto
                        }
                    }
                }
            }
        }
        for color in GameSave.autosave.color {
            if color.value[1].hasPrefix("#") {
                if color.value[0] == "None" {
                    (childNode(withName: color.key) as? DGIRoomNode)?.colorBlendFactor = 1
                    (childNode(withName: color.key) as? DGIRoomNode)?.setcolor = UIColor(hex: color.value[1])
                } else {
                    (childNode(withName: color.value[0])?.childNode(withName: color.key) as? DGIRoomSub)?.colorBlendFactor = 1
                    (childNode(withName: color.value[0])?.childNode(withName: color.key) as? DGIRoomSub)?.setcolor = UIColor(hex: color.value[1])
                    if color.value.count == 3 {
                        (childNode(withName: color.value[0])?.childNode(withName: color.key) as? DGIRoomSub)?.initalpha = CGFloat(Double(color.value[2])!)
                    }
                }
            } else {
                (childNode(withName: color.value[1])?.childNode(withName: color.value[0])?.childNode(withName: color.key) as? DGIRoomSub)?.setcolor = UIColor(hex: color.value[2])
                if color.value.count == 4 {
                    (childNode(withName: color.value[1])?.childNode(withName: color.value[0])?.childNode(withName: color.key) as? DGIRoomSub)?.initalpha = CGFloat(Double(color.value[3])!)
                }
            }
        }
        for (name, value) in GameSave.autosave.cyclevals {
            let parent = (childNode(withName: GameSave.autosave.cyclelocs[name]!) as? DGIRoomNode)
            let grid = parent?.gridSelected(name: name)?.spot
            grid?.cyclecounter = value
            for cycle in grid?.cycle ?? [] {
                childNode(withName: cycle.parent)?.childNode(withName: cycle.subs[0].sub)?.isHidden = true
                childNode(withName: cycle.parent)?.childNode(withName: cycle.subs[value].sub)?.isHidden = false
            }
        }
        for show in GameSave.autosave.shows {
            if show.value.count == 2 {
                childNode(withName: show.value[1])?.childNode(withName: show.value[0])?.childNode(withName: show.key)?.isHidden = false
            }
            else {
                //print("Show" + show[0])
                if let parent = childNode(withName: show.value[0]) as? DGIRoomSub {
                    if let name = parent.childNode(withName: show.key) {
                        name.isHidden = false
                        if parent.texture != nil, let nameSub = name as? DGIRoomSub { nameSub.loadTexture() }
                        else if let nameSub = name as? DGIRotateNode { nameSub.childsub?.loadTexture() }
                    }
                }
            }
            
        }
        for hide in GameSave.autosave.hides {
            if hide.value.count == 2 {
                childNode(withName: hide.value[1])?.childNode(withName: hide.value[0])?.childNode(withName: hide.key)?.isHidden = true
            }
            else {
                //print("Hide" + hide[0])
                childNode(withName: hide.value[0])?.childNode(withName: hide.key)?.isHidden = true
                childNode(withName: hide.value[0])?.childNode(withName: hide.key)?.removeAllActions()
            }
        }
        for (name, parent) in GameSave.autosave.toggles
        {
            if parent == "State" {
                for state in states {
                    if state.name == name {
                        state.action.active = !(state.action.active ?? true)
                    }
                }
            } else if parent == "StateRemove" {
                for (index, state) in states.enumerated().reversed() {
                    if state.name == name { states.remove(at: index) }
                }
            } else {
                (childNode(withName: parent) as! DGIRoomNode).toggleGrid(withName: name)
            }
        }
        for (name, value) in GameSave.autosave.flags {
            flags[name] = value
        }
        for screen in GameSave.autosave.sequences {
            (childNode(withName: screen.key) as? DGIRoomNode)?.sequence = screen.value
        }
        var vals: [Int] = []
        for (i, state) in states.enumerated() {
            if GameSave.autosave.states.contains(state.name) {
                vals.append(i)
            }
        }
        for i in vals.reversed() { states.remove(at: i) }
        for choice in GameSave.autosave.choices {
            changeBranch(name: choice[0], parent: choice.count == 4 ? choice[3] : nil, branches: &dialogues[(dialogues.firstIndex(where: {$0.name == choice[1]}))!].branch!, type: DGIChoiceType(rawValue: choice[2])!)
            
        }
        for displayname in GameSave.autosave.displaynames {
            inventory.masterinv.first(where: { $0.name == displayname.key })?.displayname = displayname.value
        }
        for gearsolve in GameSave.autosave.gearsolves {
            if let gearbox = (childNode(withName: gearsolve) as? DGIRoomNode)?.gearbox {
                gearbox.solved = true
                var direction = -1 * gearbox.gears[0].running
                for gear in gearbox.gears {
                    if gear.running == 0 {
                        gear.running = direction
                        gear.startRunning()
                        direction *= -1
                    }
                }
            }
        }
        //MOVE ELSEWHERE?
        for child in children {
            if let gearbox = (child as? DGIRoomNode)?.gearbox {
                if !gearbox.solved { gearbox.jumble() }
            }
        }
    }
}
