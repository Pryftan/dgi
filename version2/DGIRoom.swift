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
    let tutorial = DGITutorial()
    
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
    
    override func touchDown(atPoint pos: CGPoint) {
        let nodelist = nodes(at: pos)
        for node in nodelist {
            if node is DGIRoomSub {
                if (node as? DGIRoomSub)?.draggable ?? false {
                    dragging = node as? DGIRoomSub
                    disableGestures()
                    return
                }
            }
        }
        
    }
    
    override func touchMoved(toPoint pos: CGPoint) {
        if dragging != nil {
            if dragging.anchorPoint == CGPoint(x: 0, y: 0) {
                dragging.position = CGPoint(x: pos.x - dragging.size.width / 2, y: pos.y - dragging.size.height / 2)
            } else {
                dragging.zRotation = -1 * atan2(pos.x - dragging.position.x, pos.y - dragging.position.y)
                //dragging.zRotation += pos.distance(toPoint: dragging.position) / (CGFloat.pi * 200)
            }
        }
    }
    
    override func touchUp(atPoint pos : CGPoint) {
        if dragging != nil {
            if dragging.dragbeds > 0 {
                if dragging.anchorPoint == CGPoint(x: 0, y: 0) {
                    dragging.position = CGPoint(x: pos.x - dragging.size.width / 2, y: pos.y - dragging.size.height / 2)
                } else {
                    dragging.zRotation = -1 * atan2(pos.x - dragging.position.x, pos.y - dragging.position.y)
                    //dragging.zRotation += pos.distance(toPoint: dragging.position) / (CGFloat.pi * 200)
                }
                dragging.dragbed = (-1*((dragging.zRotation - (CGFloat.pi / CGFloat(dragging.dragbeds))).remainder(dividingBy: 2 * CGFloat.pi)) / (2 * CGFloat.pi / CGFloat(dragging.dragbeds))).mod(dragging.dragbeds)
                dragging.run(SKAction.rotate(toAngle: -2 * CGFloat.pi * CGFloat(dragging.dragbed) / CGFloat(dragging.dragbeds), duration: 0.3, shortestUnitArc: true))
                for cycle in dragging.dragcycle {
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
                enableGestures()
            }
            if dragging.dragaction != "" {
                runSpot((thisnode.gridSelected(name: dragging.dragaction)?.spot)!)
            }
            tutorial.typechecks.insert(.dragObj)
            tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            dragging = nil
            return
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
                    music?.run(SKAction.pause())
                    menu?.returnScene = self
                    menu?.toggleSettings(false)
                    view?.presentScene(menu)
                } else if menuoption == 2 {
                    music?.run(SKAction.pause())
                    menu?.returnScene = self
                    menu?.toggleSettings(true)
                    view?.presentScene(menu)
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
            left.run(SKAction.sequence([SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0.15)]))
            thisnode.run(SKAction.sequence([SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0)]))
            thisnode = left
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
            right.run(SKAction.sequence([SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0.15)]))
            thisnode.run(SKAction.sequence([SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0.15), SKAction.hide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0)]))
            thisnode = right
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
            enableGestures()
        } else {
            if thisnode.moves["backname"] != "" && thisnode.back == nil {
                thisnode.back = childNode(withName: thisnode.moves["backname"]!) as? DGIRoomNode
            }
            if let backaction = thisnode.backaction {
                if let spot = thisnode.gridSelected(name: backaction)?.spot {
                    runSpot(spot)
                }
            }
            if let back = thisnode.back {
                if back.texture == nil { back.loadTexture() }
                thisnode.clearSelected()
                thisnode.isHidden = true
                thisnode = back
                thisnode.isHidden = false
                tutorial.typechecks.insert(.swipeBack)
                tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            }
        }
    }
    
    @objc override func scrollDown() {
        super.scrollDown()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (inventory.zRotation == 0) {
            inventory.selected = nil
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
                    }
                    else {
                        var alltogether: String = ""
                        for line in screen.sequence { alltogether += line }
                        if alltogether != sequence { satisfied = false }
                    }
                }
                if let visibles = state.visibles {
                    for visible in visibles {
                        if visible.sub.isHidden == visible.vis { satisfied = false }
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
                if satisfied {
                    if state.action.active ?? true {
                        if let _ = state.action.animate {
                            states[index].action.active = false
                        }
                        runSpot(states[index].action)
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
        inventory.run(SKAction.fadeIn(withDuration: 0.5))
        menubar.run(SKAction.fadeIn(withDuration: 0.5))
        enableGestures()
    }
    
    override func loadJSON() {
        do {
            let jsonData = try JSONDecoder().decode(DGIJSONRoom.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: json, ofType: "json")!)))
            invsounds = Next<String>(jsonData.invsounds)
            if let musicname = jsonData.music {
                let musicNode = SKAudioNode(fileNamed: musicname)
                musicNode.name = "Music"
                musicNode.autoplayLooped = true
                addChild(musicNode)
            }
            for screenData in jsonData.screens {
                let start = (jsonData.start == screenData.name) ? true : false
                let screen = DGIRoomNode(imageNamed: screenData.image, name: screenData.name, grid: screenData.grid)
                if let left = screenData.left { screen.moves["leftname"] = left }
                if let right = screenData.right { screen.moves["rightname"] = right }
                if let back = screenData.back { screen.moves["backname"] = back }
                if let backaction = screenData.backaction { screen.backaction = backaction }
                if let sequence = screenData.sequence { screen.sequencelength = sequence }
                addChild(screen)
                if let subs = screenData.subs {
                    var currZ: CGFloat = 0.01
                    for subData in subs {
                        let sub = DGIRoomSub(imageNamed: subData.image, name: subData.name, position: CGPoint(x: subData.sub[0] * Config.scale, y: subData.sub[1] * Config.scale))
                        if let anchor = subData.anchor {
                            sub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                            sub.position = CGPoint(x: (subData.sub[0] + (subData.sub[2] * anchor[0]))  * Config.scale, y: (subData.sub[1] + (subData.sub[3] * anchor[1])) * Config.scale)
                        }
                        if let draggable = subData.draggable {
                            sub.draggable = draggable;
                            sub.dragbeds = subData.dragbeds?[1] ?? 0
                            sub.dragbed = subData.dragbeds?[0] ?? 0
                            if sub.dragbed > 0 { sub.zRotation = -2 * CGFloat.pi * CGFloat(sub.dragbed) / CGFloat(sub.dragbeds) }
                        }
                        if let dragcycle = subData.dragcycle { sub.dragcycle = dragcycle }
                        if let dragaction = subData.dragaction { sub.dragaction = dragaction }
                        sub.displayname = subData.displayname ?? subData.name
                        if let visible = subData.visible { sub.isHidden = !visible }
                        if let setZ = subData.setZ { sub.zPosition = setZ }
                        else { sub.zPosition = currZ; currZ += 0.01 }
                        if let opacity = subData.opacity { sub.alpha = CGFloat(opacity)}
                        if let rotate = subData.rotate { sub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                        screen.addChild(sub)
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
                                if let subopacity = subsub.opacity { currsubsub.alpha = CGFloat(subopacity)}
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
                                    if frame.frame == "rotateby" {
                                        actionGroup.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi)/180, duration: frame.duration))
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
                if start { thisnode = screen; screen.loadTexture(); screen.isHidden = false }
                //else if index <= 8 { screen.loadTexture() }
            }
            //TODO: CLEANUP INVOBJ INITS
            for objectData in jsonData.objects {
                let object = DGIInventoryObject(imageNamed: objectData.image, name: objectData.name, displayname: objectData.displayname, scale: objectData.scale, animations: objectData.animations, subs: objectData.subs, collects: objectData.collects)
                inventory.masterinv.append(object)
                addChild(object)
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
            if let setdialogues = jsonData.dialogues { dialogues = setdialogues }
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
    
    func parseView(view: String, name: String, grid: [DGIJSONGrid]?, subs: [DGIJSONSub]?) {
        let viewsub = DGIRoomNode(imageNamed: view, name: name, grid: grid)
        let viewsize = UIImage(named: view)?.size ?? CGSize(width: 0, height: 0)
        viewsub.anchorPoint = CGPoint(x:0.5, y:0.5)
        viewsub.position = CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2)
        viewsub.isHidden = true
        viewsub.zPosition = 1
        addChild(viewsub)
        if let sublist = subs {
            var currZ : Double = 1.1
            for sub in sublist {
                //let currsub = DGIRoomSub(imageNamed: sub.image, name: sub.name, position: CGPoint(x: sub.sub[0] * Config.scale, y: sub.sub[1] * Config.scale))
                let currsub = DGIRoomSub(imageNamed: sub.image, name: sub.name, position: CGPoint(x: (sub.sub[0] - viewsize.width / 2) * Config.scale, y: (sub.sub[1] - viewsize.height / 2) * Config.scale))
                if let anchor = sub.anchor {
                    currsub.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                } else { currsub.anchorPoint = CGPoint(x:0, y:0) }
                currsub.zPosition = CGFloat(currZ)
                currZ += 0.01
                if let vis = sub.visible { currsub.isHidden = !vis }
                if let opacity = sub.opacity { currsub.alpha = CGFloat(opacity)}
                if let rotate = sub.rotate { currsub.zRotation = -1 * rotate * CGFloat(Double.pi)/180}
                viewsub.addChild(currsub)
            }
        }
    }
    
    func parseState(from spot: DGIJSONGrid) -> DGIParsedState {
        var setscreen: DGIRoomNode?
        if let screen = spot.screen { setscreen = childNode(withName: screen) as? DGIRoomNode }
        var setvisibles: [(sub: DGIRoomSub, vis: Bool)]?
        if let visibles = spot.visibles {
            var visiblelist: [(sub: DGIRoomSub, vis: Bool)] = []
            for visible in visibles {
                if let gp = visible.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: visible.parent)?.childNode(withName: visible.name) as? DGIRoomSub {
                        visiblelist.append((sub, visible.visible))
                    }
                } else {
                    if let sub = childNode(withName: visible.parent)?.childNode(withName: visible.name) as? DGIRoomSub {
                        visiblelist.append((sub, visible.visible))
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
        return DGIParsedState(name: spot.name, type: spot.type!, sequencescreen: setscreen, sequence: spot.match, visibles: setvisibles, cycles: setcycles, flags: spot.flags, action: spot)
    }
    
    override func loadAutoSave() {
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
        for show in GameSave.autosave.shows {
            if show.count == 3 {
                childNode(withName: show[2])?.childNode(withName: show[1])?.childNode(withName: show[0])?.isHidden = false
            }
            else {
                if let parent = childNode(withName: show[1]) as? DGIRoomNode {
                    if let name = parent.childNode(withName: show[0]) as? DGIRoomSub {
                        name.isHidden = false
                        if parent.texture != nil { name.loadTexture() }
                    }
                }
            }
            
        }
        for hide in GameSave.autosave.hides {
            if hide.count == 3 {
                childNode(withName: hide[2])?.childNode(withName: hide[1])?.childNode(withName: hide[0])?.isHidden = true
            }
            else {
                childNode(withName: hide[1])?.childNode(withName: hide[0])?.isHidden = true
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
            } else {
                (childNode(withName: parent) as! DGIRoomNode).toggleGrid(withName: name)
            }
        }
        for (name, value) in GameSave.autosave.flags {
            flags[name] = value
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
    }
}
