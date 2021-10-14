//
//  DGIAction.swift
//  DGI: Engine
//
//  Created by William Frank on 4/19/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit

extension DGIRoom {
    
    func runAnimation(_ animation: DGIJSONAnimation, delay: Double = 0, offset: [CGFloat] = [0, 0]) -> Double {
        var last: (ref: SKNode, type: DGIFrameType, parent: String?, grandparent: String?)?
        var delay = delay
        var actionGroup: [SKAction] = []
        if let freeze = animation.freeze { self.view?.isUserInteractionEnabled = !freeze }
        else { self.view?.isUserInteractionEnabled = false; tutorial.clearScreen() }
        var release: String?
        var oldthis: String?
        var currthis = thisnode as SKNode
        if animation.frames[animation.frames.count - 1].frame == "releaseto" {
            release = animation.frames[animation.frames.count - 1].name
            oldthis = thisnode.name
            //thisnode = childNode(withName: animation.frames[animation.frames.count - 1].name!) as? DGIRoomNode
        }
        var currZ: CGFloat = 1
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
                    //else if last.type == .permscreen && last.ref.name != release { actionGroup.append(SKAction.hide()) }
                    //else if last.ref.texture == nil { last.ref.loadTexture() }
                    last.ref.run(SKAction.sequence(actionGroup))
                    actionGroup.removeAll()
                    actionGroup.append(SKAction.wait(forDuration: delay))
                }
                if parent == "None" {
                    last = (childNode(withName: name)!, .permscreen, nil, nil)
                } else {
                    if let grandparent = useframe.grandparent {
                        last = ((childNode(withName: grandparent)?.childNode(withName: parent)?.childNode(withName: name))!, .permsub, parent, grandparent)
                    } else {
                        last = ((childNode(withName: parent)?.childNode(withName: name))!, .permsub, parent, nil)
                    }
                }
            }
            if let sound = useframe.sound {
                actionGroup.append(SKAction.run{ [weak self] in self?.playSound(sound) })
            }
            if useframe.frame == "zoom" {
                camera?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.move(to: CGPoint(x: frame.pos![0] * Config.scale, y: frame.pos![1] * Config.scale), duration: frame.duration), SKAction.scale(to: frame.pos![2], duration: frame.duration)])]))
            } else if useframe.frame == "show" {
                actionGroup.append(SKAction.unhide())
                if let last = last {
                    if last.type == .permscreen {
                        if let lastname = oldthis { childNode(withName: lastname)?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.hide()]))}
                        actionGroup.append(SKAction.run({ last.ref.zPosition = 1 }))
                        actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                        currthis = last.ref
                        if last.ref != thisnode, last.ref.name != release { actionGroup.append(SKAction.hide()) }
                        actionGroup.append(SKAction.run({ last.ref.zPosition = 0 }))
                        pauses = false
                    } else if last.type == .permsub {
                        GameSave.autosave.addShow(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent)
                    }
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                
            } else if useframe.frame == "hide" {
                actionGroup.append(SKAction.hide())
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                if let last = last { if last.type == .permsub { GameSave.autosave.addHide(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) } }
            } else if useframe.frame == "moveto" {
                actionGroup.append(SKAction.move(to: CGPoint(x: useframe.pos![0] * Config.scale, y: useframe.pos![1] * Config.scale), duration: useframe.duration))
            } else if useframe.frame == "moveby" {
                actionGroup.append(SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration))
            } else if useframe.frame == "movebtxy" {
                actionGroup.append(SKAction.group([SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: 0), duration: useframe.duration),SKAction.move(to: CGPoint(x: last?.ref.position.x ?? 0, y: useframe.pos![1] * Config.scale), duration: useframe.duration)]))
            } else if useframe.frame == "fadeinmoveby" {
                last?.ref.alpha = 0
                actionGroup.append(SKAction.group([SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration), SKAction.fadeIn(withDuration: useframe.duration)]))
            } else if useframe.frame == "fadeoutmoveby" {
                actionGroup.append(SKAction.group([SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration), SKAction.fadeOut(withDuration: useframe.duration)]))
            } else if useframe.frame == "cfmoveby" {
                if let subs = useframe.subs { actionGroup.append(SKAction.group([SKAction.run{last?.ref.childNode(withName: subs[0])?.run(SKAction.fadeOut(withDuration: useframe.duration))},SKAction.move(by: CGVector(dx: useframe.pos![0] * Config.scale, dy: useframe.pos![1] * Config.scale), duration: useframe.duration),SKAction.run{last?.ref.childNode(withName: subs[1])?.run(SKAction.fadeIn(withDuration: useframe.duration))}])) }
            } else if useframe.frame == "rotateto" {
                actionGroup.append(SKAction.rotate(toAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180, duration: useframe.duration, shortestUnitArc: true))
            } else if useframe.frame == "rotateby" {
                actionGroup.append(SKAction.rotate(byAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180, duration: useframe.duration))
            } else if useframe.frame == "spinto" {
                last?.ref.removeAllActions()
                let rate = Int(useframe.pos![2])
                for num in 1...rate {
                    let exp = useframe.pos![0] > useframe.pos![1] ? num : rate - num + 1
                    actionGroup.append(SKAction.rotate(byAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180 - ((useframe.pos![1] - useframe.pos![0]) * CGFloat(Double.pi)/180)*CGFloat(exp)/CGFloat(rate), duration: useframe.duration / Double(rate)))
                }
                if useframe.pos![0] != 0 { actionGroup.append(SKAction.repeatForever(SKAction.rotate(byAngle: -1 * useframe.pos![0] * CGFloat(Double.pi)/180, duration: useframe.duration / Double(rate)))) }
            } else if useframe.frame == "fadein" {
                actionGroup.append(SKAction.unhide())
                //if useframe.reset ?? true { actionGroup.append(SKAction.unhide()) }
                if let last = last {
                    if last.ref.isHidden { actionGroup.append(SKAction.fadeOut(withDuration: 0)) }
                    //if last.ref.isHidden { last.ref.alpha = 0 }
                    //actionGroup.append(SKAction.fadeOut(withDuration: 0))
                    if last.type == .permsub { GameSave.autosave.addShow(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) }
                }
                actionGroup.append(SKAction.fadeIn(withDuration: useframe.duration))
            } else if useframe.frame == "fadeto" {
                actionGroup.append(SKAction.unhide())
                //if useframe.reset ?? true { actionGroup.append(SKAction.unhide()) }
                actionGroup.append(SKAction.fadeAlpha(to: useframe.pos![0], duration: useframe.duration))
                if let last = last {
                  if last.ref.isHidden { last.ref.alpha = 0 }
                  //actionGroup.append(SKAction.fadeOut(withDuration: 0))
                  if last.type == .permsub { GameSave.autosave.addShow(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) }
                }
            } else if useframe.frame == "fadeout" {
                if let last = last { if last.type == .permsub  { GameSave.autosave.addHide(name: last.ref.name!, parent: last.parent!, grandparent: last.grandparent) } }
                actionGroup.append(SKAction.fadeOut(withDuration: useframe.duration))
            } else if useframe.frame == "fliph" {
                if let last = last { actionGroup.append(SKAction.group([SKAction.scaleX(to: last.ref.xScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: (last.ref as! SKSpriteNode).size.width * last.ref.xScale, dy: 0), duration: useframe.duration)])) }
            } else if useframe.frame == "flipv" {
                if let last = last { actionGroup.append(SKAction.group([SKAction.scaleY(to: last.ref.yScale * -1, duration: useframe.duration), SKAction.move(by: CGVector(dx: 0, dy: (last.ref as! SKSpriteNode).size.height * last.ref.yScale), duration: useframe.duration)])) }
            } else if useframe.frame == "runanim" {
                if let last = last { actionGroup.append(SKAction.run({ last.ref.action(forKey: "Animate")?.speed = 1 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "stopanim" {
                if let last = last { actionGroup.append(SKAction.run({ last.ref.action(forKey: "Animate")?.speed = 0 })) }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "left" {
                if let last = last {
                    if last.type == .permscreen {
                        if let lastname = oldthis {
                            childNode(withName: lastname)?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: useframe.duration), SKAction.hide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0)]))
                        }
                        actionGroup.append(SKAction.sequence([SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: useframe.duration)]))
                        if last.ref != thisnode, last.ref.name != release { actionGroup.append(SKAction.hide()) }
                    }
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "right" {
                if let last = last {
                    if last.type == .permscreen {
                        if let lastname = oldthis {
                            childNode(withName: lastname)?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: useframe.duration), SKAction.hide(), SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0)]))
                        }
                        actionGroup.append(SKAction.sequence([SKAction.moveBy(x: Config.bounds.width, y: 0, duration: 0), SKAction.unhide(), SKAction.moveBy(x: -1 * Config.bounds.width, y: 0, duration: useframe.duration)]))
                        if last.ref != thisnode, last.ref.name != release { actionGroup.append(SKAction.hide()) }
                    }
                }
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else if useframe.frame == "releaseto" {
                if let last = last {
                    actionGroup.append(SKAction.sequence([SKAction.unhide(), SKAction.run({
                 self.thisnode.isHidden = true
                 self.thisnode = last.ref as? DGIRoomNode
                 self.thisnode.isHidden = false
                 })]))
                    actionGroup.append(SKAction.unhide())
                }
            } else if useframe.frame == "sharedaction" {
                if let action = sharedactions.first(where: {$0.name == useframe.name}) {
                    actionGroup.append(SKAction.wait(forDuration: useframe.duration))
                    actionGroup.append(SKAction.run{[weak self, action] in self?.runSpot(action, cutspeech: false)})
                }
            } else if useframe.frame == "wait" {
                actionGroup.append(SKAction.wait(forDuration: useframe.duration))
            } else {
                let newframe = DGIRoomSub(imageNamed: useframe.frame)
                if let last = last {
                    if last.type == .temp {
                        actionGroup.append(SKAction.removeFromParent())
                        if last.ref is DGIRoomSub { (last.ref as! DGIRoomSub).loadTexture() }
                    }
                    last.ref.run(SKAction.sequence(actionGroup))
                    actionGroup.removeAll()
                }
                newframe.loadTexture()
                newframe.position = CGPoint(x: (useframe.pos![0] + offset[0]) * Config.scale, y: (useframe.pos![1] + offset[1]) * Config.scale)
                newframe.anchorPoint = CGPoint(x: 0, y: 0)
                newframe.zPosition = currZ
                currZ += 0.1
                newframe.isHidden = true
                //actionGroup.insert(SKAction.run{ newframe.zPosition = 2 }, at: 0)
                //if inView { thisview?.addChild(newframe) }
                currthis.addChild(newframe)
                actionGroup.append(SKAction.wait(forDuration: delay))
                actionGroup.append(SKAction.unhide())
                if let color = useframe.color { actionGroup.append(SKAction.colorize(with: UIColor(hex: color), colorBlendFactor: useframe.colorblend ?? 1, duration: 0)) }
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
            if last.type == .temp {
                actionGroup.append(SKAction.removeFromParent())
                if last.ref is DGIRoomSub { (last.ref as! DGIRoomSub).loadTexture() }
            }
            last.ref.run(SKAction.sequence(actionGroup))
        }
        return delay
    }
    
    func runSpot(_ spot: DGIJSONGrid, animate: Bool = true, after: Double = 0, cutspeech: Bool = true, skipand: Bool = false, savealways: Bool = false) {
        var delay: Double = after
        var delayspots: [DGIJSONGrid] = []
        if let flagactions = spot.flagactions {
            var last = ""
            for flagaction in flagactions {
                var flagname = flagaction.name
                if flagname.first == "&", !skipand {
                    flagname.removeFirst()
                    if flagname.first == "!" {
                        flagname.removeFirst()
                        if !(flags[flagname] ?? false), flagname != last {
                            if let _ = spot.animate, animate { delayspots.append(flagaction) }
                            else { runSpot(flagaction) }
                            last = flagname
                        }
                    } else {
                        if flags[flagname] ?? false, flagname != last {
                            if let _ = spot.animate, animate { delayspots.append(flagaction) }
                            else { runSpot(flagaction) }
                            last = flagname
                        }
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
        if let contents = spot.contents {
            for content in contents {
                if let gp = content.grandparent {
                    if let spot = content.values.first(where: {$0.name == (childNode(withName: gp)?.childNode(withName: content.parent)?.childNode(withName: content.name) as? DGIRoomSub)?.contents}) { runSpot(spot) }
                } else {
                    if let _ = Int(content.values[0].name) {
                        if let currcontents = (childNode(withName: content.parent)?.childNode(withName: content.name) as? DGIRoomSub)?.contents {
                            if let _ = Int(currcontents) {
                                if let spot = content.values.first(where: {$0.name == currcontents}) { runSpot(spot)}
                            } else {
                                if let spot = content.values.first(where: {Int($0.name) == currcontents.intParse().reduce(0,+)}) { runSpot(spot) }
                            }
                        }
                    } else if let _ = Int(content.values[0].name.dropFirst()) {
                        if content.values[0].name.first == ">" {
                            if let currcontents = (childNode(withName: content.parent)?.childNode(withName: content.name) as? DGIRoomSub)?.contents {
                                if let currint = Int(currcontents) {
                                    if let spot = content.values.first(where: {Int(String($0.name.dropFirst()))! < currint}) { runSpot(spot)}
                                } else {
                                    if let spot = content.values.first(where: {Int(String($0.name.dropFirst()))! < currcontents.intParse().reduce(0,+)}) { runSpot(spot) }
                                }
                            }
                        }
                    } else if let spot = content.values.first(where: {$0.name == (childNode(withName: content.parent)?.childNode(withName: content.name) as? DGIRoomSub)?.contents}) { runSpot(spot) }
                }
            }
        }
        if let currselect = inventory.selected {
            if let selects = spot.selects {
                for select in selects {
                    if currselect.name == select.name || currselect.displayname == select.name {
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
                if let offset = spot.animoffset { delay += runAnimation(animation, offset: offset) }
                else { delay += runAnimation(animation) }
                if delayspots.count == 0 { run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{ [spot] in self.runSpot(spot, animate: false)}])) }
                else { run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.run{ [spot, delayspots] in for delayspot in delayspots { self.runSpot(delayspot, animate: false)}; self.runSpot(spot, animate: false, skipand: true)}])) }
                return
            }
        }
        if let sharedaction = spot.sharedaction {
            if let action = sharedactions.first(where: {$0.name == sharedaction}) {
                runSpot(action)
            }
        }
        var save = savealways
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
        if let setflags = spot.setflags {
            for setflag in setflags {
                flags[setflag.name] = setflag.value
            }
        }
        if let randoms = spot.randoms {
            for random in randoms {
                runSpot(random[Int.random(in: 0..<random.count)])
            }
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
                newnode.moveOn()
            }
        }
        if let phonezoom = spot.phonezoom {
            //untested
            //camera?.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.move(to: CGPoint(x: phonezoom[0] * Config.scale, y: phonezoom[1] * Config.scale), duration: 0.7), SKAction.scale(to: 0.5, duration: 0.7)])]))
        }
        if let swipe = spot.swipe {
            switch swipe {
            case "left":
                moveLeft()
            case "right":
                moveRight()
            case "up":
                scrollDown()
            case "down":
                scrollUp()
            default:
                return
            }
        }
        if spot.view != nil {
            if viewnode != nil { viewnode.isHidden = true }
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
                        if spotsave { GameSave.autosave.addDisplayName(object: invdisplay[index * 2], newname: invdisplay[index * 2 + 1]) }
                        save = true
                    }
                }
            }
        }
        if let special = spot.special, let _ = thisnode.special {
            (thisnode.children.first(where: { $0 is DGISpecial }) as? DGISpecial)?.specialDirect(special)
        }
        if let colors  = spot.color {
            for color in colors {
                var colorFind: SKNode?
                if color.parent == "None" { colorFind = childNode(withName: color.name) as? DGIRoomNode }
                else if let gp = color.grandparent {
                    colorFind = childNode(withName: gp)?.childNode(withName: color.parent)?.childNode(withName: color.name)
                } else {
                    colorFind = childNode(withName: color.parent)?.childNode(withName: color.name)
                    if colorFind is SKEffectNode { colorFind = childNode(withName: color.parent)?.childNode(withName: color.name)?.childNode(withName: color.name + "Blur") as? DGIRoomSub }
                }
                if let colorNode = colorFind as? DGIRoomSub {
                    colorNode.loadTexture()
                    colorNode.color = UIColor(hex: color.color ?? "+000000", from: colorNode.color)
                    colorNode.colorBlendFactor = 1
                    if let alpha = color.alpha {
                        colorNode.alpha = alpha
                        colorNode.initalpha = alpha
                        if spotsave { GameSave.autosave.addColor(name: color.name, parent: color.parent, grandparent: color.grandparent, hex: colorNode.color.toHexString(), alpha: String(format: "%f", Double(alpha))) }
                        save = true
                    } else {
                        if spotsave { GameSave.autosave.addColor(name: color.name, parent: color.parent, grandparent: color.grandparent, hex: colorNode.color.toHexString(), alpha: nil) }
                        save = true
                    }
                } else if let colorNode = colorFind as? SKLabelNode {
                    colorNode.fontColor = UIColor(hex: color.color ?? "+000000", from: colorNode.color)
                    colorNode.colorBlendFactor = 1
                    if let alpha = color.alpha {
                        colorNode.alpha = alpha
                        if spotsave { GameSave.autosave.addColor(name: color.name, parent: color.parent, grandparent: color.grandparent, hex: (colorNode.fontColor?.toHexString())!, alpha: String(format: "%f", Double(alpha))) }
                        save = true
                    } else {
                        if spotsave { GameSave.autosave.addColor(name: color.name, parent: color.parent, grandparent: color.grandparent, hex: (colorNode.fontColor?.toHexString())!, alpha: nil) }
                        save = true
                    }
                }
            }
        }
        if let sequence = spot.sequence {
            if sequence == "clear" {
                thisnode.sequence = []
                if let sequencedraw = thisnode.sequencedraw {
                    for position in sequencedraw.positions {
                        for sub in position.subs {
                            thisnode.childNode(withName: sub)?.isHidden = true
                        }
                    }
                }
                if spotsave { GameSave.autosave.addSequence(name: thisnode.name!, sequence: []) }
                save = true
            } else {
                thisnode.sequence.append(sequence)
                if thisnode.sequence.count > thisnode.sequencelength { thisnode.sequence.removeFirst() }
                let fillsequence = thisnode.sequence.merge(length: thisnode.sequencelength)
                if let sequencedraw = thisnode.sequencedraw {
                    for (index, position) in sequencedraw.positions.enumerated() {
                        var searchnum = -1
                        if fillsequence[index] != " " {
                            searchnum = sequencedraw.characters.firstIndex(of: String(fillsequence[index]))!
                        }
                        for (index, sub) in position.subs.enumerated() {
                            if index == searchnum {
                                if let showsub = thisnode.childNode(withName: sub) as? DGIRoomSub {
                                    showsub.isHidden = false
                                    if showsub.texture == nil { showsub.loadTexture() }
                                }
                            } else { thisnode.childNode(withName: sub)?.isHidden = true }
                        }
                    }
                }
                if spotsave { GameSave.autosave.addSequence(name: thisnode.name!, sequence: thisnode.sequence) }
                save = true
            }
        }
        if let container = spot.container {
            for currcontain in container {
                if let fill = currcontain.fill {
                    if let gp = currcontain.grandparent {
                        (childNode(withName: gp)?.childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGIRoomSub)?.contents = fill
                    } else {
                        if let counter = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGICounter {
                            counter.increment(to: Double(fill)!)
                        } else if let label = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? SKLabelNode {
                            label.text = fill
                        } else if let _ = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? SKEffectNode {
                            /*if fill == "0" { effectNode.filter = nil
                            } else { effectNode.filter = CIFilter(name:"CIGaussianBlur",parameters: ["inputRadius": CGFloat(Double(fill)!)]) }*/
                            ((childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name)?.childNode(withName: currcontain.name + "Blur")) as? DGIRoomSub)?.contents = fill
                        } else { (childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGIRoomSub)?.contents = fill }
                    }
                } else if let add = currcontain.add {
                    if let gp = currcontain.grandparent {
                        (childNode(withName: gp)?.childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGIRoomSub)?.contents += add
                    } else {
                         if let counter = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGICounter {
                            counter.increment(by: Double(add)!)
                         } else if let label = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? SKLabelNode {
                            label.text = (label.text ?? "") + add
                         } else { (childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as? DGIRoomSub)?.contents += add }
                    }
                } else if let addfrom = currcontain.addfrom {
                    let fromref = childNode(withName: addfrom.parent)?.childNode(withName: addfrom.name) as! DGIRoomSub
                    let subref = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as! DGIRoomSub
                    if subref.contents == "" {
                        subref.contents = zip([Int](repeating: 0, count: fromref.contents.intParse().count).map{String($0)}, fromref.contents.stringParse()).map(+).joined()
                    }
                    var addint = fromref.contents.intParse()
                    let totaladded = (subref.contents.intParse()+addint).reduce(0, +)
                    let totalmax = Int(currcontain.addmax ?? "") ?? totaladded
                    if totaladded - totalmax > 0 {
                        let multiplier = Double(totalmax - subref.contents.intParse().reduce(0, +)) / Double(addint.reduce(0, +))
                        addint = addint.map{Int(Double($0) * multiplier)}
                    }
                    let newtocontents = zip(addint,subref.contents.intParse()).map(+)
                    let newfromcontents = zip(fromref.contents.intParse(), zip(newtocontents,subref.contents.intParse()).map(-)).map(-)
                    subref.contents = zip(newtocontents.map{String($0)},subref.contents.stringParse()).map(+).joined()
                    fromref.contents = zip(newfromcontents.map{String($0)},subref.contents.stringParse()).map(+).joined()
                    print(subref.contents)
                    print(fromref.contents)
                } else if let addpiece = currcontain.addpiece {
                    var addint = addpiece.intParse()
                    let subref = childNode(withName: currcontain.parent)?.childNode(withName: currcontain.name) as! DGIRoomSub
                    if subref.contents == "" {
                        subref.contents = zip([Int](repeating: 0, count: addpiece.intParse().count).map{String($0)}, addpiece.stringParse()).map(+).joined()
                    }
                    let totaladded = (subref.contents.intParse()+addint).reduce(0, +)
                    let totalmax = Int(currcontain.addmax ?? "") ?? totaladded
                    if totaladded - totalmax > 0 {
                        let multiplier = Double(totalmax - subref.contents.intParse().reduce(0, +)) / Double(addint.reduce(0, +))
                        addint = addint.map{Int(Double($0) * multiplier)}
                    }
                    let newtocontents = zip(addint,subref.contents.intParse()).map(+)
                    subref.contents = zip(newtocontents.map{String($0)},subref.contents.stringParse()).map(+).joined()
                    print(subref.contents)
                }
            }
        }
        if cutspeech { cutSpeech() }
        if spot.speech != nil {
            if spot.speechcounter == nil { spot.speechcounter = 0 }
            runSpeech(spot)
        }
        if let dialoguename = spot.dialogue {
            tutorial.clearScreen()
            runDialogue(name: dialoguename)
        }
        if let musics = spot.music {
            for music in musics {
                childNode(withName: music.name)?.run(SKAction.changeVolume(to: music.on ? Config.volume.music : 0, duration: music.fade ?? 1))
            }
        }
        if let cycles = spot.cycle {
            for cycle in cycles {
                if let parentNode = childNode(withName: cycle.parent) {
                    if let label = cycle.subs[(spot.cyclecounter + 1) % cycles[0].subs.count].label {
                        (parentNode.childNode(withName: cycle.subs[(spot.cyclecounter + 1) % cycles[0].subs.count].sub) as? SKLabelNode)?.text = label
                    } else {
                        parentNode.childNode(withName: cycle.subs[spot.cyclecounter].sub)?.isHidden = true
                        if let newNode = parentNode.childNode(withName: cycle.subs[(spot.cyclecounter + 1) % cycles[0].subs.count].sub) as? DGIRoomSub {
                            if newNode.texture == nil { newNode.loadTexture() }
                            newNode.isHidden = false
                        }
                    }
                }
            }
            spot.cyclecounter = (spot.cyclecounter + 1) % cycles[0].subs.count
            if spotsave { GameSave.autosave.addCycle(name: spot.name, parent: thisnode.name!, val: spot.cyclecounter) }
            save = true
        }
        if let cyclerev = spot.cyclerev {
            if let cycles = thisnode.gridSelected(name: cyclerev)?.spot.cycle, let revspot = thisnode.gridSelected(name: cyclerev)?.spot {
                let newval = revspot.cyclecounter == 0 ? cycles[0].subs.count - 1 : revspot.cyclecounter - 1
                for cycle in cycles {
                    if let parentNode = childNode(withName: cycle.parent) {
                        parentNode.childNode(withName: cycle.subs[revspot.cyclecounter].sub)?.isHidden = true
                        if let newNode = parentNode.childNode(withName: cycle.subs[newval].sub) as? DGIRoomSub {
                            if newNode.texture == nil { newNode.loadTexture() }
                            newNode.isHidden = false
                        }
                    }
                }
                revspot.cyclecounter = newval
                if spotsave { GameSave.autosave.addCycle(name: revspot.name, parent: thisnode.name!, val: revspot.cyclecounter) }
                save = true
            }
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
                drawimage.colorBlendFactor = 1
                drawimage.color = UIColor(hex: (spot.drawcolor ?? "#FFFFFF"))
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
        if let drawchanges  = spot.drawchange {
            for drawchange in drawchanges {
                (childNode(withName: drawchange.parent) as? DGIRoomNode)?.gridSelected(name: drawchange.name)?.spot.drawcolor = drawchange.color
            }
        }
        if let shows = spot.shows {
            for show in shows {
                if let gp = show.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: show.parent)?.childNode(withName: show.name) as? DGIRoomSub {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                        sub.alpha = sub.initalpha
                    } else if let sub = childNode(withName: gp)?.childNode(withName: show.parent)?.childNode(withName: show.name) {
                        sub.isHidden = false
                    }
                } else {
                    if let sub = childNode(withName: show.parent)?.childNode(withName: show.name) as? DGIRoomSub {
                        if sub.texture == nil { sub.loadTexture() }
                        sub.isHidden = false
                        sub.alpha = sub.initalpha
                    } else if let sub = childNode(withName: show.parent)?.childNode(withName: show.name) as? DGIRotateNode {
                        if sub.childsub?.texture == nil { sub.childsub?.loadTexture() }
                        sub.isHidden = false
                    } else if let sub = childNode(withName: show.parent)?.childNode(withName: show.name) {
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
                    if let sub = childNode(withName: gp)?.childNode(withName: hide.parent)?.childNode(withName: hide.name) {
                        sub.isHidden = true
                    }
                } else {
                    if let sub = childNode(withName: hide.parent)?.childNode(withName: hide.name) {
                        sub.isHidden = true
                        if let subRef = sub as? DGIRotateNode {
                            subRef.childsub?.position = CGPoint(x: 0 , y: 0)
                        }
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
                } else if toggle.parent == "StateRemove" {
                    stateloop: for (index, spot) in states.enumerated().reversed() {
                        if spot.name == toggle.name {
                            states.remove(at: index)
                            break stateloop
                        }
                    }
                }
                (childNode(withName: toggle.parent) as? DGIRoomNode)?.toggleGrid(withName: toggle.name)
                if spotsave { GameSave.autosave.addToggle(name: toggle.name, parent: toggle.parent) }
            }
        }
        if let moves = spot.moves {
            for move in moves {
                if let gp = move.grandparent {
                    if let sub = childNode(withName: gp)?.childNode(withName: move.parent)?.childNode(withName: move.name) {
                        sub.position = CGPoint(x: move.pos[0], y: move.pos[1])
                    }
                } else {
                    if let sub = childNode(withName: move.parent)?.childNode(withName: move.name) {
                        sub.position = CGPoint(x: move.pos[0], y: move.pos[1])
                    }
                }
            }
        }
        if let sharedafter = spot.sharedafter {
            if let action = sharedactions.first(where: {$0.name == sharedafter}) {
                runSpot(action)
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
