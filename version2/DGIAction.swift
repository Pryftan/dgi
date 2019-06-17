//
//  DGIAction.swift
//  DGI: Engine
//
//  Created by William Frank on 4/19/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit

extension DGIRoom {
    
    func runAnimation(_ animation: DGIJSONAnimation, delay: Double = 0) -> Double {
        var last: (ref: DGIRoomSub, type: DGIFrameType, parent: String?, grandparent: String?)?
        var delay = delay
        var actionGroup: [SKAction] = []
        if let freeze = animation.freeze { self.view?.isUserInteractionEnabled = !freeze }
        else { self.view?.isUserInteractionEnabled = false }
        var oldthis: String?
        if animation.frames[animation.frames.count - 1].frame == "releaseto" {
            oldthis = thisnode.name
            thisnode = childNode(withName: animation.frames[animation.frames.count - 1].name!) as? DGIRoomNode
        }
        for frame in animation.frames {
            var pauses = true
            var useframe = frame
            if var flag = frame.flag {
                if flag.first == "!" {
                    flag.removeFirst()
                    run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{self.flags[flag] = false}]))
                } else { run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{self.flags[flag] = true}])) }
            }
            if let flagframes = frame.flagframes {
                for flagframe in flagframes {
                    if var flagname = flagframe.flag {
                        if flagname.first == "!" {
                            flagname.removeFirst()
                            if let checkflag = flags[flagname] {
                                if !checkflag { useframe = flagframe }
                            }
                        } else {
                            if let checkflag = flags[flagname] {
                                if checkflag { useframe = flagframe }
                            }
                        }
                    }
                }
            }
            if let pausecheck = useframe.pauses {
                pauses = pausecheck
            }
            if let name = useframe.name, let parent = useframe.parent {
                if let last = last {
                    if last.type == .temp { actionGroup.append(SKAction.removeFromParent()) }
                    //else if last.ref.texture == nil { last.ref.loadTexture() }
                    last.ref.run(SKAction.sequence(actionGroup))
                    actionGroup.removeAll()
                    actionGroup.append(SKAction.wait(forDuration: delay))
                }
                if parent == "None" {
                    last = (childNode(withName: name) as! DGIRoomSub, .permscreen, nil, nil)
                } else {
                    if let grandparent = useframe.grandparent {
                        last = (childNode(withName: grandparent)?.childNode(withName: parent)?.childNode(withName: name) as! DGIRoomSub, .permsub, parent, grandparent)
                    } else {
                        last = (childNode(withName: parent)?.childNode(withName: name) as! DGIRoomSub, .permsub, parent, nil)
                    }
                }
            }
            if let sound = useframe.sound {
                actionGroup.append(SKAction.run{ [weak self] in self?.playSound(sound) })
            }
            if useframe.frame == "zoom" {
                camera?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.move(to: CGPoint(x: frame.pos![0] * Config.scale, y: frame.pos![1] * Config.scale), duration: frame.duration), SKAction.scale(to: frame.pos![2], duration: frame.duration)])]))
            }
            else if useframe.frame == "show" {
                actionGroup.append(SKAction.unhide())
                if let last = last {
                    if last.type == .permscreen {
                        if let lastname = oldthis { childNode(withName: lastname)?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.hide()]))}
                        actionGroup.append(SKAction.run({ last.ref.zPosition = 1 }))
                        actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                        if (last.ref != thisnode) { actionGroup.append(SKAction.hide()) }
                        actionGroup.append(SKAction.run({ last.ref.zPosition = 0 }))
                        pauses = false
                    } else if last.type == .permsub {
                        GameSave.autosave.addShow(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent)
                    }
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                
            }
            else if useframe.frame == "hide" {
                actionGroup.append(SKAction.hide())
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                if let last = last { if last.type == .permsub { GameSave.autosave.addHide(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) } }
            }
            else if useframe.frame == "moveto" {
                actionGroup.append(SKAction.move(to: CGPoint(x: useframe.pos![0] * Config.scale, y: useframe.pos![1] * Config.scale), duration: useframe.duration))
            } else if useframe.frame == "moveby" {
                actionGroup.append(SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration))
            } else if useframe.frame == "cfmoveby" {
                if let subs = useframe.subs { actionGroup.append(SKAction.group([SKAction.run{last?.ref.childNode(withName: subs[0])?.run(SKAction.fadeOut(withDuration: useframe.duration))},SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration),SKAction.run{last?.ref.childNode(withName: subs[1])?.run(SKAction.fadeIn(withDuration: useframe.duration))}])) }
            } else if useframe.frame == "rotateto" {
                actionGroup.append(SKAction.rotate(toAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180, duration: useframe.duration, shortestUnitArc: true))
            } else if useframe.frame == "rotateby" {
                actionGroup.append(SKAction.rotate(byAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180, duration: useframe.duration))
            } else if useframe.frame == "fadein" {
                actionGroup.append(SKAction.unhide())
                actionGroup.append(SKAction.fadeIn(withDuration: useframe.duration))
                if let last = last {
                    last.ref.alpha = 0
                    //actionGroup.append(SKAction.fadeOut(withDuration: 0))
                    if last.type == .permsub { GameSave.autosave.addShow(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) }
                }
            } else if useframe.frame == "fadeout" {
                if let last = last { if last.type == .permsub  { GameSave.autosave.addHide(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) } }
                actionGroup.append(SKAction.fadeOut(withDuration: useframe.duration))
            } else if useframe.frame == "fliph" {
                if let last = last { actionGroup.append(SKAction.group([SKAction.scaleX(to: last.ref.xScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: last.ref.size.width * last.ref.xScale, dy: 0), duration: useframe.duration)])) }
            } else if useframe.frame == "flipv" {
                if let last = last { actionGroup.append(SKAction.group([SKAction.scaleY(to: last.ref.yScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: 0, dy: last.ref.size.height * last.ref.yScale), duration: useframe.duration)])) }
            } else if useframe.frame == "runanim" {
                if let last = last { actionGroup.append(SKAction.run({ last.ref.action(forKey: "Animate")?.speed = 1 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "stopanim" {
                if let last = last { actionGroup.append(SKAction.run({ last.ref.action(forKey: "Animate")?.speed = 0 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "releaseto" {
                /*if let last = last { actionGroup.append(SKAction.sequence([SKAction.unhide(), SKAction.run({
                 self.thisscreen!.isHidden = true
                 self.thisscreen = last as? GameScreen
                 })])) }*/
            } else if useframe.frame == "wait" {
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else {
                let newframe = DGIRoomSub(imageNamed: useframe.frame)
                if let last = last {
                    if last.type == .temp { actionGroup.append(SKAction.removeFromParent()) }
                    last.ref.run(SKAction.sequence(actionGroup))
                    last.ref.zPosition = 2
                    actionGroup.removeAll()
                }
                newframe.position = CGPoint(x: useframe.pos![0] * Config.scale, y: useframe.pos![1] * Config.scale)
                newframe.anchorPoint = CGPoint(x: 0, y: 0)
                newframe.zPosition = 2
                newframe.isHidden = true
                actionGroup.insert(SKAction.run{ newframe.zPosition = 2 }, at: 0)
                //if inView { thisview?.addChild(newframe) }
                thisnode.addChild(newframe)
                actionGroup.append(SKAction.wait(forDuration: delay))
                actionGroup.append(SKAction.unhide())
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                last = (newframe, .temp, nil, nil)
            }
            if pauses { delay += useframe.duration }
        }
        if let last = last {
            actionGroup.append(SKAction.run{
                self.view?.isUserInteractionEnabled = true
                GameSave.autosave.save()
            })
            if last.type == .temp { actionGroup.append(SKAction.removeFromParent()) }
            last.ref.run(SKAction.sequence(actionGroup))
        }
        return delay
    }
    
    func runSpot(_ spot: DGIJSONGrid, animate: Bool = true, after: Double = 0) {
        var delay: Double = after
        if let flagactions = spot.flagactions {
            for flagaction in flagactions {
                var flagname = flagaction.name
                if flagname.first == "&" {
                    flagname.removeFirst()
                    if flagname.first == "!" {
                        flagname.removeFirst()
                        if !(flags[flagname] ?? false) { runSpot(flagaction) }
                    } else {
                        if flags[flagname] ?? false { runSpot(flagaction) }
                    }
                } else if flagname.first == "!" {
                    flagname.removeFirst()
                    if !(flags[flagname] ?? false) {
                        runSpot(flagaction)
                        return
                    }
                } else {
                    if flags[flagname] ?? false {
                        runSpot(flagaction)
                        return
                    }
                }
            }
        }
        if let sequenceactions = spot.sequenceactions {
            for sequenceaction in sequenceactions {
                var alltogether = ""
                for line in thisnode.sequence { alltogether += line }
                if alltogether == sequenceaction.name {
                    runSpot(sequenceaction)
                    return
                }
            }
        }
        if let currselect = inventory.selected {
            if let selects = spot.selects {
                for select in selects {
                    if currselect.name == select.name {
                        runSpot(select)
                        return
                    }
                }
                for select in selects {
                    for collect in currselect.collects {
                        if inventory.currentinv.first(where: {$0.name == collect}) != nil {
                            if currselect.name == collect {
                                runSpot(select)
                                return
                            }
                        }
                    }
                }
            }
        } else if let currselect = thisnode.selected {
            if let selects = spot.selects {
                for select in selects {
                    if currselect.name == select.name {
                        runSpot(select)
                        thisnode.clearSelected()
                        return
                    }
                }
            }
        }
        if let animname = spot.animate, animate {
            if var animation = ((globanims ?? []) + (inventory.selected?.animations ?? [])).first(where: {$0.name == animname}) {
                if let chain = animation.frames.last?.chain {
                    if let chainanim = ((globanims ?? []) + (inventory.selected?.animations ?? [])).first(where: {$0.name == chain}) {
                        animation.frames += chainanim.frames
                    }
                }
                delay += runAnimation(animation)
                run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{ [spot] in self.runSpot(spot, animate: false)}]))
                return
            }
        }
        var save = false
        let spotsave = spot.saves ?? true
        if var flag = spot.flag {
            if flag.first == "!" {
                flag.removeFirst()
                if flag.last == "*" {
                    flag.removeLast()
                    for currflag in flags {
                        if currflag.key.hasPrefix(flag) {
                            flags[currflag.key] = false
                            if spotsave { GameSave.autosave.setFlag(name: currflag.key, value: false) }
                        }
                    }
                } else {
                    flags[flag] = false
                    if spotsave { GameSave.autosave.setFlag(name: flag, value: false) }
                }
            } else {
                if flag.last == "*" {
                    flag.removeLast()
                    for currflag in flags {
                        if currflag.key.hasPrefix(flag) {
                            flags[currflag.key] = true
                            if spotsave { GameSave.autosave.setFlag(name: currflag.key, value: true) }
                        }
                    }
                } else {
                    //flags.updateValue(true, forKey: flag)
                    flags[flag] = true
                    if spotsave { GameSave.autosave.setFlag(name: flag, value: true) }
                }
            }
            save = true
        }
        if let randoms = spot.randoms {
            runSpot(randoms[Int.random(in: 0..<randoms.count)])
        }
        if let selectable = spot.selectable { thisnode.setSelected(name: selectable) }
        if let sound = spot.sound { playSound(sound) }
        if let zoom = spot.zoom {
            if let newnode = childNode(withName: zoom) as? DGIRoomNode {
                thisnode.clearSelected()
                if newnode.texture == nil { newnode.loadTexture() }
                newnode.back = thisnode
                thisnode.isHidden = true
                thisnode = newnode
                thisnode.isHidden = false
                tutorial.typechecks.insert(.tapZoom)
                tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            }
        }
        if let phonezoom = spot.phonezoom {
            //untested
            camera?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.move(to: CGPoint(x: phonezoom[0] * Config.scale, y: phonezoom[1] * Config.scale), duration: 0.7), SKAction.scale(to: 0.5, duration: 0.7)])]))
        }
        if spot.view != nil {
            viewnode = childNode(withName: spot.name) as? DGIRoomNode
            if viewnode.texture == nil { viewnode.loadTexture() }
            disableGestures(except: ["downSwipe"])
            viewnode.isHidden = false
        }
        if let removename = spot.removes {
            inventory.removeObj(objectname: removename, after: delay)
            save = true
        }
        if let objectname = spot.object {
            playSound(invsounds.next)
            inventory.addObj(objectname: objectname, after: delay)
            tutorial.typechecks.insert(.invObj)
            tutorial.nextStep(hasLeft: thisnode.left != nil, zoomGrid: thisnode.zoomGrid, hasBack: thisnode.back == nil ? false : true, objGrid: thisnode.objGrid, dragSub: thisnode.dragSub)
            let spotsave = spot.saves ?? true
            if spotsave { GameSave.autosave.addInv(object: objectname) }
            save = true
        }
        if let invdisplay = spot.invdisplay {
            for index in 0..<(invdisplay.count / 2) {
                for invobj in inventory.masterinv {
                    if invobj.name == invdisplay[index * 2] {
                        invobj.displayname = invdisplay[index * 2 + 1]
                        if invobj.color == .red {
                            invobj.removeSelect()
                            invobj.addSelect()
                        }
                        //CHECK IF THE ABOVE CAUSES ISSUES FOR OBJECTS NOT IN CURRENTINV
                    }
                }
            }
        }
        if let sequence = spot.sequence {
            if sequence == "clear" {
                thisnode.sequence = []
            } else {
                thisnode.sequence.append(sequence)
                if thisnode.sequence.count > thisnode.sequencelength { thisnode.sequence.removeFirst() }
            }
        }
        if let speech = spot.speech {
            if spot.speechcounter == nil { spot.speechcounter = 0 }
            subtitle.removeAllActions()
            subtitle.text = speech[spot.speechcounter!].line
            subtitle.run(SKAction.sequence([SKAction.unhide(), SKAction.wait(forDuration: Config.textspeed), SKAction.hide()]))
            spot.speechcounter = (spot.speechcounter! + 1) % speech.count
        }
        if let dialoguename = spot.dialogue {
            tutorial.clearScreen()
            runDialogue(name: dialoguename)
        }
        if let cycles = spot.cycle {
            for cycle in cycles {
                if let parentNode = childNode(withName: cycle.parent) {
                    parentNode.childNode(withName: cycle.subs[spot.cyclecounter].sub)?.isHidden = true
                    if let newNode = parentNode.childNode(withName: cycle.subs[(spot.cyclecounter + 1) % cycles[0].subs.count].sub) as? DGIRoomSub {
                        if newNode.texture == nil { newNode.loadTexture() }
                        newNode.isHidden = false
                    }
                }
            }
            spot.cyclecounter = (spot.cyclecounter + 1) % cycles[0].subs.count
            if spotsave { GameSave.autosave.addCycle(name: spot.name, parent: thisnode.name!, val: spot.cyclecounter) }
            save = true
        }
        if let cycleifs = spot.cycleif {
            cycleloop: for cycleif in cycleifs {
                /*var cycleval = -1
                if let cyclenode = childNode(withName: cycleif.parent) as? DGIRoomNode { if let index = cyclenode.gridSelected(name: cycleif.name)?.index {
                    cycleval = cyclenode.grid[index].cyclecounter ?? -1
                } }*/
                //CURRENTLY IMPLEMENTED ONLY FOR ACTIVE SPOT - MAY NEED TO CHANGE
                if let dragNode = childNode(withName: cycleif.parent)?.childNode(withName: cycleif.name) {
                    for value in cycleif.values {
                        if value.value == (dragNode as? DGIRoomSub)?.dragbed {
                            runSpot(value)
                        }
                    }
                    break cycleloop
                }
                if cycleif.name == spot.name { for action in cycleif.values {
                    if let value = action.value {
                        if spot.cyclecounter == value { let _ = runSpot(action) }
                    }
                } }
            }
        }
        
        if let choices = spot.choices {
            for choice in choices {
                changeBranch(name: choice.name, parent: choice.parent, branches: &dialogues[(dialogues.firstIndex(where: {$0.name == choice.dialogue}))!].branch!, type: choice.type)
                if spotsave { GameSave.autosave.addChoice(name: choice.name, dialogue: choice.dialogue, type: choice.type.rawValue, parent: choice.parent) }
                save = true
            }
        }
        if let draws = spot.draws {
            for draw in draws {
                let drawimage = SKSpriteNode(imageNamed: draw.draw, name: "Draw_" + draw.name)
                drawimage.anchorPoint = CGPoint(x:0, y:0)
                let offset = CGFloat(Double(arc4random_uniform(UInt32(draw.maxoff))) - Double(draw.maxoff) / 2)
                drawimage.position = CGPoint(x: (draw.pos[0] + offset) * Config.scale, y: (draw.pos[1] + offset) * Config.scale)
                drawimage.zPosition = 1
                childNode(withName: draw.parent)?.addChild(drawimage)
            }
        }
        if let drawclear = spot.drawclear {
            for name in drawclear {
                childNode(withName: name)?.enumerateChildNodes(withName: "Draw_*"){
                    (node, stop) in
                    node.removeFromParent()
                }
            }
        }
        if let shows = spot.shows {
            for show in shows {
                if let gp = show.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: show.parent)?.childNode(withName: show.name) as? DGIRoomSub
                    {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                    }
                } else {
                    if let sub = childNode(withName: show.parent)?.childNode(withName: show.name) as? DGIRoomSub
                    {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                    }
                }
                if spotsave { GameSave.autosave.addShow(name: show.name, parent: show.parent, grandparent: show.grandparent) }
                save = true
            }
        }
        if let hides = spot.hides {
            for hide in hides {
                if let gp = hide.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: hide.parent)?.childNode(withName: hide.name) as? DGIRoomSub
                    {
                        sub.isHidden = true
                    }
                } else {
                    if let sub = childNode(withName: hide.parent)?.childNode(withName: hide.name) as? DGIRoomSub
                    {
                        sub.isHidden = true
                    }
                }
                if spotsave { GameSave.autosave.addHide(name: hide.name, parent: hide.parent, grandparent: hide.grandparent) }
                save = true
            }
        }
        if let toggles = spot.toggles {
            for toggle in toggles {
                if toggle.parent == "State" {
                    for (index, spot) in states.enumerated() {
                        if spot.name == toggle.name {
                            states[index].action.active = !(states[index].action.active ?? true)
                        }
                    }
                }
                (childNode(withName: toggle.parent) as? DGIRoomNode)?.toggleGrid(withName: toggle.name)
                if spotsave { GameSave.autosave.addToggle(name: toggle.name, parent: toggle.parent) }
            }
        }
        if let _ = spot.transition { view?.transitionScene() }
        if save, spotsave { GameSave.autosave.save() }
    }
    
    func changeBranch(name: String, parent: String? = nil, branches: inout [DGIJSONBranch], type: DGIChoiceType) {
        for (index, branch) in branches.enumerated() {
            if let parent = parent {
                if branch.name == parent {
                    switch type {
                    case .enable:
                        branch.lines![branch.lines!.firstIndex(where: {$0.name == name})!].active = true
                    case .disable:
                        branch.lines![branch.lines!.firstIndex(where: {$0.name == name})!].active = false
                    case .remove:
                        print("Remove run on line.")
                        return
                    }
                    return
                }
            } else {
                if branch.name == name {
                    switch type {
                    case .enable:
                        branch.active = true
                    case .disable:
                        branch.active = false
                    case .remove:
                        branches.remove(at: index)
                    }
                    return
                }
            }
            if let _ = branch.branch {
                changeBranch(name: name, branches: &branch.branch!, type: type)
            }
        }
    }
}
