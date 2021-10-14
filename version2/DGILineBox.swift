//
//  DGILineBox.swift
//  DGI: Engine
//
//  Created by William Frank on 4/22/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import SpriteKit

class DGILineBox: SKShapeNode {
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    init(name: String, at pos: lineBoxPosition) {
        super.init()
        self.path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: Config.bounds.width, height: Config.dialogue.rows * (Config.dialogue.text + Config.dialogue.space + 1)), cornerWidth: Config.bounds.width * 0.02, cornerHeight: Config.bounds.width * 0.02, transform: nil)
        self.name = name
        self.fillColor = UIColor.black
        self.alpha = 0.35
        self.zPosition = 3
        switch pos {
        case .top:
            self.position = CGPoint(x: 0, y: Config.bounds.height - ((Config.dialogue.rows * (Config.dialogue.text + Config.dialogue.space + 1))))
        case .bottom:
            self.position = CGPoint(x: 0, y: 0)
        }
        self.isHidden = true
    }
    
}

class DGISpeechBox: DGILineBox {
    
    let text = SKLabelNode(fontNamed: "Arial")
    var lines: [SKAction] = []
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(name: String, at pos: lineBoxPosition) {
        super.init(name: name, at: pos)
        text.name = "Text"
        text.fontSize = Config.dialogue.text
        text.color = .white
        text.horizontalAlignmentMode = .left
        text.verticalAlignmentMode = .top
        text.position = CGPoint(x: Config.dialogue.space, y: frame.height - Config.dialogue.space)
        text.lineBreakMode = .byWordWrapping
        text.preferredMaxLayoutWidth = frame.width - 2 * Config.dialogue.space
        text.numberOfLines = 0
        //if pos == .top { text.preferredMaxLayoutWidth = frame.maxX - (Config.avatar.space * 2 + avatar.size.width) }
        text.text = "Test line here is the test line! Here is more test line content that is the very best test lines that have ever been tested by lines!"
        addChild(text)
    }
    
    func runLines(jsonlines: [DGIJSONLine], name: String, branch: [DGIJSONBranch]? = nil, action: DGIJSONGrid? = nil, exit: Bool = false) {
        lines = []
        for jsonline in jsonlines {
            var lineaction: [SKAction] = []
            if !(jsonline.skippable ?? true) { lineaction.append(SKAction.run{
                (self.parent as? DGIScreen)?.setTouches(false)
                //(self.parent as? DGIVoid)?.preloadTextures()
            }) }
            if jsonline.character == name {
                lineaction.append(SKAction.run{ [weak self, jsonline] in self?.text.text = jsonline.line; self?.lines.remove(at: 0) })
                if jsonline.line != "" { lineaction.append(SKAction.unhide()) }
            } else { lineaction += [SKAction.hide(), SKAction.run{ [weak self] in self?.lines.remove(at: 0) }] }
            lineaction.append(SKAction.wait(forDuration: jsonline.duration))
            if jsonline.character == name { lineaction.append(SKAction.hide()) }
            if !(jsonline.skippable ?? true) { lineaction.append(SKAction.run{ (self.parent as? DGIScreen)?.setTouches(true) }) }
            lines.append(SKAction.sequence(lineaction))
        }
        lines.append(SKAction.hide())
        if name == "Player" {
            if let branch = branch {
                if let action = action {
                    lines.append(SKAction.run{ [weak self] in
                        (self?.parent as? DGIScreen)?.choicebox?.runBranch(branch)
                        (self?.parent as? DGIRoom)?.runSpot(action)
                    })
                } else if exit {
                    lines.append(SKAction.run{ [weak self] in
                        (self?.parent as? DGIScreen)?.closeDialogue() })
                } else {
                    lines.append(SKAction.run{ [weak self] in
                        (self?.parent as? DGIScreen)?.choicebox?.runBranch(branch)
                    })
                }
            } else {
                if let action = action {
                    lines.append(SKAction.run{ [weak self] in
                        (self?.parent as? DGIScreen)?.closeDialogue()
                        (self?.parent as? DGIRoom)?.runSpot(action)
                    })
                } else {
                    lines.append(SKAction.run{ [weak self] in
                        (self?.parent as? DGIScreen)?.closeDialogue() })
                }
            }
        }
        run(SKAction.sequence(lines))
    }
    
    func skipLine() {
        removeAllActions()
        run(SKAction.sequence(lines))
    }
}

class DGIChoiceBox: DGILineBox {
    
    var scroll = 0
    var dialno = 0
    var lineno = 0
    var maxcount = 0
    var currbranch: [DGIJSONBranch]? = nil
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(name: String, at pos: lineBoxPosition) {
        super.init(name: name, at: pos)
        for val in (0..<10) {
            let line = SKLabelNode(fontNamed: "Arial")
            line.name = "Line \(val+1)"
            line.text = "Line \(val+1)"
            line.fontSize = Config.dialogue.text
            line.color = .white
            line.horizontalAlignmentMode = .left
            line.verticalAlignmentMode = .top
            line.position = CGPoint(x: Config.dialogue.space, y: (Config.dialogue.text + Config.dialogue.space) * (Config.dialogue.rows - CGFloat(val)) - Config.dialogue.space)
            if val > Int(Config.dialogue.rows) { line.isHidden = true }
            addChild(line)
        }
    }
    
    func selectLine(at pos: CGPoint) {
        if frame.contains(pos) {
            let selectNum = max((Int(Config.dialogue.rows - 1) - Int((pos.y + Config.dialogue.space / 2)/(Config.dialogue.space + Config.dialogue.text))), 0)
            var realCount = -1
            //for branch in ((parent as? DGIRoom)?.dialogues[dialno].branch ?? []) {
            for (index, branch) in (currbranch ?? []).enumerated() {
                if branch.active ?? true { realCount += 1 }
                if realCount == selectNum {
                    if let lines = branch.lines {
                        isHidden = true
                        var action = branch.action?[0]
                        var exitbool = false
                        if let dialtype = (parent as? DGIScreen)?.dialogues[dialno].type {
                            if dialtype == "max2" {
                                maxcount += 1
                                if maxcount == 2 { exitbool = true; maxcount = 0 }
                            }
                        }
                        if let exittype = branch.exittype {
                            if action == nil { action = (parent as? DGIRoom)?.dialogues[dialno].sharedexit?.first(where: {$0.name == exittype}) }
                            exitbool = true
                        }
                        if let type = branch.type {
                            switch type {
                            case .remove:
                                currbranch?.remove(at: index)
                                (parent as? DGIScreen)?.playerbox?.runLines(jsonlines: lines, name: "Player", branch: currbranch, action: action, exit: exitbool)
                            case .cont:
                                (parent as? DGIScreen)?.playerbox?.runLines(jsonlines: lines, name: "Player", branch: branch.branch, action: action, exit: exitbool)
                            }
                        } else {
                            (parent as? DGIScreen)?.playerbox?.runLines(jsonlines: lines, name: "Player", branch: branch.branch, action: action, exit: exitbool)
                        }
                        (parent as? DGIScreen)?.avatarbox?.runLines(jsonlines: lines, name: "Avatar")
                    } else if let exittype = branch.exittype {
                        if let action = branch.action?[0] { (parent as? DGIRoom)?.runSpot(action) }
                        else if let action = (parent as? DGIRoom)?.dialogues[dialno].sharedexit?.first(where: {$0.name == exittype}) { (parent as? DGIRoom)?.runSpot(action) }
                        (parent as? DGIScreen)?.closeDialogue()
                    } else if let nextbranch = branch.branch {
                        if let action = branch.action?[0] {
                            (parent as? DGIRoom)?.runSpot(action)
                            runBranch(nextbranch)
                        } else { runBranch(nextbranch) }
                    } else if let type = branch.type {
                        switch type {
                        case .remove:
                            currbranch?.remove(at: index)
                            (parent as? DGIScreen)?.closeDialogue()
                        case .cont:
                            (parent as? DGIScreen)?.closeDialogue()
                        }
                    }
                    return
                }
            }
        }
    }
    
    func runBranch(_ branch: [DGIJSONBranch]) {
        lineno = branch.count(where: {$0.active ?? true} )
        currbranch = branch
        var realCount = branch.firstIndex(where: {$0.active ?? true})!
        for val in (0..<10) {
            if val < lineno {
                (childNode(withName: "Line \(val+1)") as! SKLabelNode).text = branch[realCount].text
                realCount = branch[(realCount+1)...].firstIndex(where: {$0.active ?? true}) ?? -1
            } else { (childNode(withName: "Line \(val+1)") as! SKLabelNode).text = "" }
        }
        isHidden = false
    }
}

enum lineBoxPosition {
    case top, bottom
}
