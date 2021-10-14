//
//  DGISpecial.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import SpriteKit

protocol DGISpecial {
    func specialDirect(_ num: Int)
}

class DGIGuessNos: SKEffectNode, UITextFieldDelegate, DGISpecial {
    
    let answer: [Int]
    let maxlines: Int
    let headerspace: CGFloat
    let grid: [CGFloat]
    var views: [SKEffectNode] = []
    let textfield: UITextField
    var linecount: Int = 0
    var active: Bool
    var solvespot: DGIJSONGrid?
    var solved = false
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding guessnos is not supported")
    }
    
    init(name: String, values: [CGFloat], active: Bool, solve: DGIJSONGrid?) {
        var answer: [Int] = Array(0...9)
        answer.shuffle()
        self.answer = Array(answer.prefix(Int(values[0])))
        maxlines = Int(values[1])
        headerspace = values[2]
        grid = [values[3], values[4]]
        textfield = UITextField()
        self.active = active
        solvespot = solve
        super.init()
        
        self.name = name
        shouldEnableEffects = true
        shouldRasterize = true
        
        textfield.borderStyle = .roundedRect
        textfield.keyboardType = .numberPad
        //textfield.enablesReturnKeyAutomatically = true
        //textfield.returnKeyType = .go
        textfield.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textfield.clearButtonMode = .whileEditing
        textfield.textColor = .black
        textfield.backgroundColor = .white
        textfield.placeholder = "CODE"
        textfield.delegate = self
    }
    
    func generate(_ viewlist: [DGIJSONSpecialLoc]) {
        let images = viewlist[0].guessnos!
        let warpFrom = [
            vector_float2(0.0, 0.0),
            vector_float2(0.0, 1.0),
            vector_float2(1.0, 0.0),
            vector_float2(1.0, 1.0)
        ]
        var first = true
        for viewData in viewlist {
            let warpTo = [
                vector_float2(0.0, 0.0),
                vector_float2(Float((viewData.pos[2] - viewData.pos[0])/Config.bounds.width), Float((viewData.pos[3] - viewData.pos[1])/Config.bounds.height)),
                vector_float2(Float((viewData.pos[4] - viewData.pos[0])/Config.bounds.width), Float((viewData.pos[5] - viewData.pos[1])/Config.bounds.height)),
                vector_float2(Float((viewData.pos[6] - viewData.pos[0])/Config.bounds.width), Float((viewData.pos[7] - viewData.pos[1])/Config.bounds.height))
            ]
            let viewNode = first ? self : SKEffectNode()
            viewNode.zPosition = 1
            viewNode.position = CGPoint(x: viewData.pos[0] * Config.scale, y: viewData.pos[1] * Config.scale)
            if !active { viewNode.isHidden = true }
            let header = SKSpriteNode(imageNamed: images.header)
            header.name = "Header"
            header.position = CGPoint(x: Config.bounds.width / 2 * Config.scale, y: Config.bounds.height * Config.scale)
            header.anchorPoint = CGPoint(x:0.5, y:1)
            if !active { header.isHidden = true }
            viewNode.addChild(header)
            
            let test = SKSpriteNode(imageNamed: "sym39")
            test.name = "Dummy"
            test.position = CGPoint(x: 0, y: 0)
            test.anchorPoint = CGPoint(x: 0, y: 0)
            test.isHidden = true
            viewNode.addChild(test)
            
            initLines(images, currNode: viewNode)
            if active { start() }
            
            viewNode.warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1, sourcePositions: warpFrom, destinationPositions: warpTo)
            if !first { views.append(viewNode) }
            first = false
        }
    }
    
    func start(save: Bool = true) {
        active = true
        var initialTry = answer
        initialTry.shuffle()
        initialTry.removeLast(answer.count - 2)
        var wrongs = Array(Set(answer).symmetricDifference(Set(0...9))).shuffled()
        wrongs.removeLast(12 - 2 * answer.count) //TEMPORARY - GENERALIZE
        initialTry += wrongs
        initialTry.shuffle()
        for viewNode in [self]+views {
            viewNode.isHidden = false
            viewNode.childNode(withName: "Header")?.isHidden = false
            drawLine(initialTry, currNode: viewNode)
        }
        if save {
            GameSave.autosave.addSpecial(special: name!, state: 1)
            GameSave.autosave.save()
        }
    }
    
    func initLines(_ images: DGIJSONGuessNos, currNode: SKEffectNode) {
        for lineno in 0..<maxlines {
            let ypos = Config.bounds.height - (grid[1] * CGFloat(lineno + 1)) - headerspace
            for i in 0..<answer.count {
                let digitNode = DGIRoomCycle(imagesNamed: images.numbers)
                digitNode.name = (currNode.name ?? "") + "_D_\(lineno+1)_\(i+1)"
                let xpos = Config.bounds.width / 2 - (grid[0] * (CGFloat(answer.count - i) + 0.5))
                digitNode.position = CGPoint(x: xpos * Config.scale, y: ypos * Config.scale)
                digitNode.anchorPoint = CGPoint(x:0, y:0)
                digitNode.isHidden = true
                currNode.addChild(digitNode)
                
                let buttonNode = DGIRoomCycle(imagesNamed: images.lights)
                buttonNode.name = (currNode.name ?? "") + "_B_\(lineno+1)_\(i+1)"
                let xpos2 = Config.bounds.width / 2 + (grid[0] * (CGFloat(i) + 0.5))
                buttonNode.position = CGPoint(x: xpos2 * Config.scale, y: ypos * Config.scale)
                buttonNode.anchorPoint = CGPoint(x:0, y:0)
                buttonNode.isHidden = true
                currNode.addChild(buttonNode)
            }
        }
    }
    
    func drawLine(_ currTry: [Int], currNode: SKEffectNode) {
        var lightvals = checkTry(currTry)
        linecount += 1
        if linecount > maxlines {
            linecount = maxlines
            for lineno in 1..<linecount {
                for i in 0..<answer.count {
                    let thisDigitNode = childNode(withName: (currNode.name ?? "") + "_D_\(lineno)_\(i+1)") as! DGIRoomCycle
                    let nextDigitNode = childNode(withName: (currNode.name ?? "") + "_D_\(lineno+1)_\(i+1)") as! DGIRoomCycle
                    thisDigitNode.set(to: nextDigitNode.count)
                    let thisButtonNode = childNode(withName: (currNode.name ?? "") + "_B_\(lineno)_\(i+1)") as! DGIRoomCycle
                    let nextButtonNode = childNode(withName: (currNode.name ?? "") + "_B_\(lineno+1)_\(i+1)") as! DGIRoomCycle
                    thisButtonNode.set(to: nextButtonNode.count)
                }
            }
        }
        for i in 0..<answer.count {
            let digitNode = childNode(withName: (currNode.name ?? "") + "_D_\(linecount)_\(i+1)") as! DGIRoomCycle
            digitNode.set(to: currTry[i])
            digitNode.isHidden = false
            let buttonNode = childNode(withName: (currNode.name ?? "") + "_B_\(linecount)_\(i+1)") as! DGIRoomCycle
            if lightvals.0 == 0 {
                if lightvals.1 == 0 {
                    buttonNode.set(to: 2)
                } else {
                    buttonNode.set(to: 1)
                    lightvals.1 -= 1
                }
            } else {
                buttonNode.set(to: 0)
                lightvals.0 -= 1
            }
            buttonNode.isHidden = false
        }
    }
    
    func showInput(_ view: UIView) {
        (parent?.parent as? DGIRoom)?.disableGestures() //TODO: DISABLE ALL OTHER INPUT
        textfield.frame = CGRect(origin: .zero, size: CGSize(width: view.frame.width / 8, height: view.frame.height / 20))
        textfield.center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        textfield.textAlignment = .center
        view.addSubview(textfield)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) -> Bool {
        if textField.text?.count != answer.count { return false }
        let currTry = Array(textField.text ?? "").map{ $0.wholeNumberValue ?? 0 }
        if currTry.count != answer.count { return false }
        drawLine(currTry, currNode: self)
        for node in views { drawLine(currTry, currNode: node )}
        textField.removeFromSuperview()
        textField.text = ""
        textField.resignFirstResponder()
        if checkSolve(currTry) {
            solve()
        } else { (parent?.parent as? DGIRoom)?.enableGestures() }
        return true
    }
    
    func specialDirect(_ num: Int) {
        switch num {
        case 1:
            start()
        default:
            return
        }
    }
    
    func checkTry(_ current: [Int]) -> (Int, Int) {
        var result = (0, 0)
        if current.count != answer.count { return result }
        for i in 0..<answer.count {
            if answer[i] == current[i] {
                result.0 += 1
            }
        }
        result.1 = Set(answer).intersection(Set(current)).count - result.0
        return result
    }
    
    func checkSolve(_ currTry: [Int]) -> Bool {
        let check = checkTry(currTry)
        return check == (answer.count, 0) ? true : false
    }
    
    func solve() {
        active = false
        for child in children {
            if child.name != "Dummy" { child.run(SKAction.sequence([SKAction.hide(),SKAction.wait(forDuration: 0.5),SKAction.unhide(),SKAction.wait(forDuration: 0.5),SKAction.hide(),SKAction.wait(forDuration: 0.5),SKAction.unhide(),SKAction.wait(forDuration: 0.5), SKAction.hide()])) }
        }
        if let spot = solvespot {
            run(SKAction.sequence([SKAction.wait(forDuration: 2),SKAction.run{(self.parent?.parent as? DGIRoom)?.runSpot(spot); (self.parent?.parent as? DGIRoom)?.enableGestures()},SKAction.hide()]))
            
        }
        GameSave.autosave.addSpecial(special: name!, state: 0)
        GameSave.autosave.save()
    }
    
}

class DGIRotateNode: SKSpriteNode, DGISpecial {
    
    var child: DGISpecial? { return children.first(where: { $0 is DGISpecial }) as? DGISpecial }
    var childsub: DGIRoomSub? { return children[0] as? DGIRoomSub }
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding rotatenodes is not supported")
    }
    
    init() {
        super.init(texture: nil, color: .white, size: CGSize())
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    func specialDirect(_ num: Int) {
        child?.specialDirect(num)
    }
}

class DGIWarpNode: SKEffectNode, DGISpecial {
    
    var child: DGISpecial? { return children.first(where: { $0 is DGISpecial }) as? DGISpecial }
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding warpnodes is not supported")
    }
    
    override init() {
        super.init()
        shouldEnableEffects = true
        shouldRasterize = true
    }
    
    func warp(sourcePositions: [vector_float2], destinationPositions: [vector_float2]) {
        warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1, sourcePositions: sourcePositions, destinationPositions: destinationPositions)
    }
    
    func specialDirect(_ num: Int) {
        child?.specialDirect(num)
    }
}

class DGISlideBox: SKSpriteNode, DGISpecial {
    
    var active: Bool
    let box: SKTexture
    let ball: SKTexture
    let divider: SKTexture
    let arrow: SKTexture
    let grid: Int
    var rotation = Next<String>(["U", "R", "D", "L"])
    let rect: CGRect
    var views: [SKSpriteNode] = []
    var locations: (start: (Int, Int), finish: (Int, Int), position: (Int, Int), divX: [(Int, Int, Bool)], divY: [(Int, Int, Bool)]) = ((0,0),(0,0),(0,0),[],[])
    let solvespot: DGIJSONGrid?
    var solved = false
    var leftArrow: SKSpriteNode? { return parent?.parent?.childNode(withName: name! + "_SlideArrowL") as? SKSpriteNode }
    var rightArrow: SKSpriteNode? { return parent?.parent?.childNode(withName: name! + "_SlideArrowR") as? SKSpriteNode }
    var boxNode: SKSpriteNode? { return parent?.parent?.childNode(withName: name! + "_Box") as? SKSpriteNode}
    var ballNode: SKSpriteNode? { return childNode(withName: name! + "_Ball") as? SKSpriteNode}
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding slideboxes is not supported")
    }
    
    init(name: String, imageNamed: String, active: Bool, rect: CGRect, slidedata: DGIJSONSlideBox, solve: DGIJSONGrid?) {
        self.active = active
        self.box = SKTexture(imageNamed: imageNamed)
        self.ball = SKTexture(imageNamed: slidedata.images[0])
        self.divider = SKTexture(imageNamed: slidedata.images[1])
        self.arrow = SKTexture(imageNamed: slidedata.images[2])
        self.grid = slidedata.size
        self.rect = rect
        self.locations.start = (slidedata.locations[0][0][0], slidedata.locations[0][0][1])
        self.locations.position = self.locations.start
        self.locations.finish = (slidedata.locations[0][1][0], slidedata.locations[0][1][1])
        for divX in slidedata.locations[1] { locations.divX.append((divX[0], divX[1], divX.count == 3 ? (divX[2] == 1 ? true : false) : true)) }
        for divY in slidedata.locations[2] { locations.divY.append((divY[0], divY[1], divY.count == 3 ? (divY[2] == 1 ? true : false) : true)) }
        self.solvespot = solve
        super.init(texture: nil, color: .white, size: CGSize())
        
        self.name = name
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    func generate(_ viewlist: [DGIJSONSpecialLoc]) {
        let warpFrom = [
            vector_float2(0.0, 0.0),
            vector_float2(0.0, 1.0),
            vector_float2(1.0, 0.0),
            vector_float2(1.0, 1.0)
        ]
        var first = true
        let firstWarp = parent as! DGIWarpNode
        for viewData in viewlist {
            let warpTo = [
                vector_float2(0, 0),
                vector_float2(Float((viewData.pos[2] - viewData.pos[0])/Config.bounds.height), Float((viewData.pos[3] - viewData.pos[1])/Config.bounds.height)),
                vector_float2(Float((viewData.pos[4] - viewData.pos[0])/Config.bounds.height), Float((viewData.pos[5] - viewData.pos[1])/Config.bounds.height)),
                vector_float2(Float((viewData.pos[6] - viewData.pos[0])/Config.bounds.height), Float((viewData.pos[7] - viewData.pos[1])/Config.bounds.height))
            ]
            let viewNode = first ? self : SKSpriteNode()
            let warpNode = first ? firstWarp : DGIWarpNode()
            if !first { viewNode.zPosition = 1.5 }
            
            //viewNode.position = CGPoint(x: -100, y: 0)
            viewNode.position = CGPoint(x: -1 * (viewData.pos[4] - viewData.pos[2]) / 2, y: -1 * (viewData.pos[3] - viewData.pos[1]) / 2)
            //viewNode.position = CGPoint(x: (viewData.pos[0]) * Config.scale - Config.bounds.width / 2, y: (viewData.pos[1]) * Config.scale - Config.bounds.height / 2)
            
            for (count, divX) in locations.divX.enumerated() {
                if divX.2 {
                    let divNode = SKSpriteNode(texture: divider)
                    divNode.name = viewData.name + "_DivX\(count)"
                    divNode.anchorPoint = CGPoint(x: 0, y: 0.5)
                    divNode.position = CGPoint(x: Config.bounds.height * (CGFloat(divX.0)) / CGFloat(grid), y: Config.bounds.height * (CGFloat(divX.1)) / CGFloat(grid))
                    viewNode.addChild(divNode)
                }
            }
            for (count, divY) in locations.divY.enumerated() {
                if divY.2 {
                    let divNode = SKSpriteNode(texture: divider)
                    divNode.name = viewData.name + "_DivY\(count)"
                    divNode.anchorPoint = CGPoint(x: 0, y: 0.5)
                    divNode.zRotation = CGFloat.pi / 2
                    divNode.position = CGPoint(x: Config.bounds.height * (CGFloat(divY.0)) / CGFloat(grid), y: Config.bounds.height * (CGFloat(divY.1)) / CGFloat(grid))
                    viewNode.addChild(divNode)
                }
            }
            
            let balldummy = SKSpriteNode(texture: ball)
            balldummy.anchorPoint = CGPoint(x: 0, y: 0)
            balldummy.position = CGPoint(x: 0, y: 0)
            balldummy.isHidden = true
            viewNode.addChild(balldummy)
            
            if first {
                class arrowNode: SKSpriteNode {
                    required init?(coder decoder: NSCoder) { fatalError() }
                    init (_ name: String, right: Bool, texture: SKTexture) {
                        super.init(texture: texture, color: .white, size: texture.size())
                        self.name = name
                        if right { xScale = -1 }
                        anchorPoint = CGPoint(x: 0, y: 0)
                        position = CGPoint(x: right ? Config.bounds.width : 0, y: 0 )
                        zPosition = 2
                        alpha = 0
                    }
                }
                let arrowL = arrowNode(name! + "_SlideArrowL", right: false, texture: arrow)
                let arrowR = arrowNode(name! + "_SlideArrowR", right: true, texture: arrow)
                parent?.parent?.addChild(arrowL)
                parent?.parent?.addChild(arrowR)
            }
            warpNode.warp(sourcePositions: warpFrom, destinationPositions: warpTo)
            if let parentName = viewData.parent {
                viewNode.name = viewData.name
                warpNode.addChild(viewNode)
                warpNode.zPosition = 2
                warpNode.position = CGPoint(x: ((viewData.pos[0] + viewData.pos[4]) / 2)  * Config.scale, y: ((viewData.pos[1] + viewData.pos[3]) / 2)  * Config.scale)
                parent?.parent?.parent?.childNode(withName: parentName)?.addChild(warpNode)
                views.append(viewNode)
            }
            first = false
        }
        if active { start() }
    }
    
    func showArrows() {
        leftArrow?.run(SKAction.fadeIn(withDuration: 0.7))
        rightArrow?.run(SKAction.fadeIn(withDuration: 0.7))
    }
    
    func hideArrows() {
        leftArrow?.alpha = 0
        rightArrow?.alpha = 0
    }
    
    func start(save: Bool = true) {
        active = true
        for viewNode in (views + [self]) {
            let newBall = SKSpriteNode(texture: ball)
            newBall.name = viewNode.name! + "_Ball"
            newBall.position = CGPoint(x: Config.bounds.height * (CGFloat(locations.start.0)) / CGFloat(grid), y: Config.bounds.height * (CGFloat(locations.start.1)) / CGFloat(grid))
            newBall.anchorPoint = CGPoint(x: 0, y: 0)
            locations.position = locations.start
            viewNode.addChild(newBall)
        }
        fall()
        if save {
            GameSave.autosave.addSpecial(special: name!, state: 1)
            GameSave.autosave.save()
        }
    }
    
    func rotate(_ direction: Bool) {
        //NEEDS SWALLOWS TOUCHES AND OTHER VIEWS
        boxNode?.run(SKAction.rotate(byAngle: (direction ? -1 : 1) * CGFloat.pi / 2, duration: 0.7))
        parent?.run(SKAction.sequence([SKAction.rotate(byAngle: (direction ? -1 : 1) * CGFloat.pi / 2, duration: 0.7),SKAction.run{ [weak self] in self?.fall()}]))
        //parent?.run(SKAction.rotate(byAngle: (direction ? -1 : 1) * CGFloat.pi / 2, duration: 0.7))
        //run(SKAction.sequence([SKAction.wait(forDuration: 0.7),SKAction.run{ [weak self] in self?.fall()}]))
        for viewNode in views {
            viewNode.parent?.zRotation = viewNode.parent!.zRotation + (direction ? -1 : 1) * CGFloat.pi / 2
        }
        if direction { rotation.increment() } else { rotation.decrement() }
    }
    
    func fall() {
        switch rotation.now {
        case "U":
            if locations.divX.contains(where: {$0.0 == locations.position.0 && $0.1 == locations.position.1}) {
                //RELEASE CONTROL
            } else {
                var topos = 0
                for divX in locations.divX {
                    if divX.0 == locations.position.0 {
                        if divX.1 > topos && divX.1 < locations.position.1 { topos = divX.1 }
                    }
                }
                let delay = Double(locations.position.1 - topos) * 0.2
                ballNode?.run(SKAction.move(by: CGVector(dx:0, dy: Config.bounds.height * CGFloat(topos - locations.position.1) / CGFloat(grid)), duration: delay))
                for view in views {
                    if let viewBall = view.childNode(withName: view.name! + "_Ball") {
                        viewBall.position = CGPoint(x: viewBall.position.x, y: viewBall.position.y + Config.bounds.height * CGFloat(topos - locations.position.1) / CGFloat(grid))
                    }
                }
                locations.position.1 = topos
                if checkSolve() { solve(delay) }
            }
        case "L":
            if locations.divY.contains(where: {$0.0 == locations.position.0 && $0.1 == locations.position.1}) {
                //RELEASE CONTROL
            } else {
                var topos = 0
                for divY in locations.divY {
                    if divY.1 == locations.position.1 {
                        if divY.0 > topos && divY.0 < locations.position.0 { topos = divY.0 }
                    }
                }
                let delay = Double(locations.position.0 - topos) * 0.2
                ballNode?.run(SKAction.move(by: CGVector(dx: Config.bounds.height * CGFloat(topos - locations.position.0) / CGFloat(grid), dy: 0), duration: delay))
                for view in views {
                    if let viewBall = view.childNode(withName: view.name! + "_Ball") {
                        viewBall.position = CGPoint(x: viewBall.position.x + Config.bounds.height * CGFloat(topos - locations.position.0) / CGFloat(grid), y: viewBall.position.y)
                    }
                }
                locations.position.0 = topos
                if checkSolve() { solve(delay) }
            }
        case "D":
            if locations.divX.contains(where: {$0.0 == locations.position.0 && $0.1 == locations.position.1 + 1}) {
                //RELEASE CONTROL
            } else {
                var topos = grid - 1
                for divX in locations.divX {
                    if divX.0 == locations.position.0 {
                        if divX.1 - 1 < topos && divX.1 - 1 > locations.position.1 { topos = divX.1 - 1 }
                    }
                }
                let delay = Double(topos - locations.position.1) * 0.2
                ballNode?.run(SKAction.move(by: CGVector(dx:0, dy: Config.bounds.height * CGFloat(topos - locations.position.1) / CGFloat(grid)), duration: delay))
                for view in views {
                    if let viewBall = view.childNode(withName: view.name! + "_Ball") {
                        viewBall.position = CGPoint(x: viewBall.position.x, y: viewBall.position.y + Config.bounds.height * CGFloat(topos - locations.position.1) / CGFloat(grid))
                    }
                }
                locations.position.1 = topos
                if checkSolve() { solve(delay) }
            }
        case "R":
            if locations.divY.contains(where: {$0.0 == locations.position.0 + 1 && $0.1 == locations.position.1}) {
                //RELEASE CONTROL
            } else {
                var topos = grid - 1
                for divY in locations.divY {
                    if divY.1 == locations.position.1 {
                        if divY.0 - 1 < topos && divY.0 - 1 > locations.position.0 { topos = divY.0 - 1 }
                    }
                }
                let delay = Double(topos - locations.position.0) * 0.2
                ballNode?.run(SKAction.move(by: CGVector(dx: Config.bounds.height * CGFloat(topos - locations.position.0) / CGFloat(grid), dy: 0), duration: delay))
                for view in views {
                    if let viewBall = view.childNode(withName: view.name! + "_Ball") {
                        viewBall.position = CGPoint(x: viewBall.position.x + Config.bounds.height * CGFloat(topos - locations.position.0) / CGFloat(grid), y: viewBall.position.y)
                    }
                }
                locations.position.0 = topos
                if checkSolve() { solve(delay) }
            }
        default: return
        }
    }
    
    func checkSolve() -> Bool {
        if locations.position == locations.finish { active = false; return true }
        return false
    }
    
    func solve(_ after: Double) {
        GameSave.autosave.addSpecial(special: name!, state: 0)
        if let spot = solvespot {
            run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.run{ [weak self] in (self?.parent?.parent?.parent as? DGIRoom)?.runSpot(spot, savealways: true); self?.hideArrows()}]))
        } else {
            hideArrows()
            GameSave.autosave.save()
        }
    }
    
    func specialDirect(_ num: Int) {
        switch num {
        case 0: if active { rotate(true) }
        case 1: if active { rotate(false) }
        case 2: if active { showArrows() }
        case 3: if active { hideArrows() }
        case 4: active = true; showArrows(); start()
        case 5: active = true
        default: return
        }
    }
    
}

class DGIScramble: SKEffectNode, DGISpecial {
    
    let texture: SKTexture
    let grid: (Int, Int)
    let rect: CGRect
    var views: [SKEffectNode] = []
    var positions: [(Int, Int)] = []
    var selected: (Int, Int)? = nil
    let solvespot: DGIJSONGrid?
    var solved = false
    var hides: [CGFloat] = []
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding scrambles is not supported")
    }
    
    init(name: String, imageNamed: String, grid: (Int, Int), rect: CGRect, solve: DGIJSONGrid?, hides: [CGFloat]) {
        self.texture = SKTexture(imageNamed: imageNamed)
        self.grid = grid
        self.rect = rect
        self.solvespot = solve
        self.hides = hides
        super.init()
        
        self.name = name
        shouldEnableEffects = true
        shouldRasterize = true
        
    }
    
    func generate(_ scramble: [DGIJSONSpecialLoc]) {
        for row in 0..<grid.0 { for col in 0..<grid.1 { positions.append((row, col)) } }
        if !solved { positions = positions.shuffled() }
        let warpFrom = [
            vector_float2(0.0, 0.0),
            vector_float2(0.0, 1.0),
            vector_float2(1.0, 0.0),
            vector_float2(1.0, 1.0)
        ]
        var first = true
        for scrambleData in scramble {
            let warpTo = [
                vector_float2(0.0, 0.0),
                vector_float2(Float((scrambleData.pos[2] - scrambleData.pos[0])/texture.size().width), Float((scrambleData.pos[3] - scrambleData.pos[1])/texture.size().height)),
                vector_float2(Float((scrambleData.pos[4] - scrambleData.pos[0])/texture.size().width), Float((scrambleData.pos[5] - scrambleData.pos[1])/texture.size().height)),
                vector_float2(Float((scrambleData.pos[6] - scrambleData.pos[0])/texture.size().width), Float((scrambleData.pos[7] - scrambleData.pos[1])/texture.size().height))
            ]
            let scrambleNode = first ? self : SKEffectNode()
            scrambleNode.zPosition = 1
            scrambleNode.position = CGPoint(x: scrambleData.pos[0] * Config.scale, y: scrambleData.pos[1] * Config.scale)
            for row in 0..<grid.0 {
                for col in 0..<grid.1 {
                    let sub = SKSpriteNode(texture: SKTexture(rect: CGRect(x: CGFloat(col)/CGFloat(grid.1), y: CGFloat(row)/CGFloat(grid.0), width: 1/CGFloat(grid.1), height: 1/CGFloat(grid.0)), in: texture))
                    sub.name = scrambleData.name + "_\(row)_\(col)"
                    sub.anchorPoint = CGPoint(x: 0, y: 0)
                    let rawVal = positions.firstIndex(where: {$0 == (row, col)})!
                    let newpos = (Int(Double(rawVal)/Double(grid.1)), rawVal % grid.1)
                    sub.position = CGPoint(x: CGFloat(newpos.1) * texture.size().width / CGFloat(grid.1), y: CGFloat(newpos.0) * texture.size().height / CGFloat(grid.0))
                    sub.zPosition = 0.01
                    for index in 0..<hides.count/2 {
                        if row == Int(hides[index*2]), col == Int(hides[index*2 + 1]) {
                            sub.isHidden = true
                        }
                    }
                    scrambleNode.addChild(sub)
                }
            }
            scrambleNode.warpGeometry = SKWarpGeometryGrid(columns: 1, rows: 1, sourcePositions: warpFrom, destinationPositions: warpTo)
            if let parentName = scrambleData.parent {
                scrambleNode.name = scrambleData.name
                parent?.parent?.childNode(withName: parentName)?.addChild(scrambleNode)
                views.append(scrambleNode)
            }
            first = false
        }
    }
    
    func select(at pos: CGPoint) {
        if let selected = self.selected {
            let newselected = (Int(pos.y * CGFloat(grid.0) / rect.height), Int(pos.x * CGFloat(grid.1) / rect.width))
            self.selected = nil
            let move1 = positions[selected.0*(grid.0+1)+selected.1]
            let move2 = positions[newselected.0*(grid.0+1)+newselected.1]
            let holdpos = childNode(withName: "\(name!)_\(move1.0)_\(move1.1)")!.position
            (childNode(withName: "\(name!)_\(move1.0)_\(move1.1)") as? SKSpriteNode)?.clearTint()
            childNode(withName: "\(name!)_\(move1.0)_\(move1.1)")?.position = childNode(withName: "\(name!)_\(move2.0)_\(move2.1)")!.position
            childNode(withName: "\(name!)_\(move2.0)_\(move2.1)")?.position = holdpos
            for view in views {
                let holdpos = view.childNode(withName: "\(view.name!)_\(move1.0)_\(move1.1)")!.position
                view.childNode(withName: "\(view.name!)_\(move1.0)_\(move1.1)")?.position = view.childNode(withName: "\(view.name!)_\(move2.0)_\(move2.1)")!.position
                view.childNode(withName: "\(view.name!)_\(move2.0)_\(move2.1)")?.position = holdpos
            }
            positions[selected.0*(grid.0+1)+selected.1] = move2
            positions[newselected.0*(grid.0+1)+newselected.1] = move1
            if checkSolve() { solve() }
        } else {
            let setselected = (Int(pos.y * CGFloat(grid.0) / rect.height), Int(pos.x * CGFloat(grid.1) / rect.width))
            selected = setselected
            let set = positions[setselected.0*(grid.0+1)+setselected.1]
            (childNode(withName: "\(name!)_\(set.0)_\(set.1)") as! SKSpriteNode).addTint()
        }
    }
    
    func checkSolve() -> Bool {
        var count = 0
        for row in 0..<grid.0 {
            for col in 0..<grid.1 {
                if positions[count] != (row, col) { return false }
                count += 1
            }
        }
        solved = true
        return true
    }
    
    func solve() {
        GameSave.autosave.addSpecial(special: name!, state: 1)
        if let spot = solvespot { (parent?.parent as? DGIRoom)?.runSpot(spot) }
        else { GameSave.autosave.save() }
        
    }
    
    func specialDirect(_ num: Int) {
        
    }
    
}

class DGIGearNode: SKNode {
    
    let data: DGIJSONGearBox
    let driveteeth: Int
    var pegs: [Point:Bool] = [:]
    var gears: [DGIGear] = []
    var solved = false
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding gearboxes is not supported")
    }
    
    init(_ data: DGIJSONGearBox) {
        self.data = data
        driveteeth = data.geartypes.first(where: { $0.name == data.gears[0].type })!.teeth
        super.init()
        name = self.data.name
        self.zPosition = -1
        for (index, peg) in data.pegs.enumerated() {
            pegs[Point(x: peg[0], y: peg[1])] = index < data.pegs.count - (data.pegextra ?? 0) ? true : false
        }
    }
    
    override func addChild(_ node: SKNode) {
        if let gear = node as? DGIGear {
            gears.append(gear)
        }
        super.addChild(node)
    }
    
    func jumble() {
        for (index, gear) in gears.enumerated() {
            if !gear.fixed {
                let firstgears = gears[0..<index]
                gear.position = CGPoint(x: data.pos[0] + CGFloat(Double(arc4random_uniform(UInt32(data.pos[2])))), y: data.pos[1] + CGFloat(Double(arc4random_uniform(UInt32(data.pos[3])))))
                while (firstgears.allSatisfy( {!$0.overlaps(with: gear)} )) {
                    gear.position = CGPoint(x: data.pos[0] + CGFloat(Double(arc4random_uniform(UInt32(data.pos[2])))), y: data.pos[1] + CGFloat(Double(arc4random_uniform(UInt32(data.pos[3])))))
                }
            }
        }
    }
    
    func solve() {
        solved = true
        GameSave.autosave.gearsolves.append((parent?.name)!)
        if let solve = data.solve {
            if let solveaction = (parent as? DGIRoomNode)?.gridSelected(name: solve)?.spot { ((parent as? DGIRoomNode)?.parent as? DGIRoom)?.runSpot(solveaction) }
        }
    }
}

class DGIGear: DGIRoomSub {
    
    static var count = 0
    let wiggle: CGFloat = 38 * Config.scale
    let type: DGIJSONGearType
    var pegon: Bool
    var running: Int
    weak var driving: DGIGear? = nil
    let fixed: Bool
    var startPos: CGPoint
    var toPos: CGPoint
    var gearbox: DGIGearNode {
        get { return (parent as? DGIGearNode)! }
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding gears is not supported")
    }
    
    init(type: DGIJSONGearType, gear: DGIJSONGear, gearbox: DGIGearNode) {
        let image = SKTexture(imageNamed: type.image)
        self.type = type
        running = gear.running ?? 0
        startPos = CGPoint(x: gear.pos[0], y: gear.pos[1])
        toPos = CGPoint(x: gear.pos[0], y: gear.pos[1])
        fixed = gear.fixed ?? false
        pegon = running != 0 || gear.fixed ?? false || gearbox.pegs.contains{ CGPoint(x: gear.pos[0], y: gear.pos[1]) == CGPoint($0.key)}
        super.init(texture: image, color: UIColor(), size: (image.size()))
        if let name = gear.name { self.name = name }
        else { self.name = gearbox.data.name + "Gear_\(DGIGear.count)"; DGIGear.count += 1 }
        texturename = type.image
        position = CGPoint(x: gear.pos[0], y: gear.pos[1])
        zPosition = 1
        if running != 0 {
            run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double(running) * Double.pi * Double(gearbox.driveteeth) / Double(type.teeth)), duration: gearbox.data.speed)))
            
        }
    }
    
    func startRunning(after: Double = 0) {
        run(SKAction.sequence([SKAction.wait(forDuration: after), SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double(running) * Double.pi * Double(gearbox.driveteeth) / Double(type.teeth)), duration: gearbox.data.speed))]))
        if !gearbox.solved {
            for gear in gearbox.gears.filter({ $0.locks(with: self) && $0.pegon && $0.running == 0 }) {
                gear.running = running * -1
                gear.startRunning()
                driving = gear
                if gear == gearbox.gears[gearbox.gears.count - 1] { gearbox.solve() }
            }
        }
    }
    
    func stopRunning() {
        removeAllActions()
        if let driving = driving { driving.stopRunning() }
        if pegon {
            gearbox.pegs[Point(startPos)] = false
            pegon = false
        }
    }
    
    func drop(at pos: CGPoint) {
        if gearbox.gears.filter({ $0.name != name }).contains(where: { overlaps(with: $0) }) || !(CGRect(x: gearbox.data.pos[0], y: gearbox.data.pos[1], width: gearbox.data.pos[2], height: gearbox.data.pos[3]).contains(pos)) {
            toPos = startPos
            run(SKAction.move(to: startPos, duration: 0.2))
        } else if let newpeg = gearbox.pegs.filter({ !$0.value && pos.distance(to: CGPoint($0.key)) < type.radius}).min(by: { peg1, peg2 in pos.distance(to: CGPoint(peg1.key)) < pos.distance(to: CGPoint(peg2.key)) }) {
            run(SKAction.move(to: CGPoint(newpeg.key), duration: 0.2))
            gearbox.pegs[newpeg.key] = true
            startPos = CGPoint(newpeg.key)
            toPos = CGPoint(newpeg.key)
            pegon = true
            if let drivegear = gearbox.gears.first(where: {$0.locks(with: self, to: true) && $0.running != 0}) {
                running = -1 * drivegear.running
                startRunning(after: 0.2)
                if let drivenext = gearbox.gears.first(where: {$0.locks(with: self, to: true) && $0.running == 0}) {
                    drivenext.running = -1 * running
                    drivenext.startRunning(after: 0.2)
                    driving = drivenext
                }
            }
        } else {
            startPos = pos
            toPos = pos
        }
    }
    
    func locks(with gear2: DGIGear, to: Bool = false) -> Bool {
        if to { return position.distance(to: gear2.toPos) < (gear2.type.radius + type.radius) && !overlaps(with: gear2, to: to) }
        else { return position.distance(to: gear2.position) < (gear2.type.radius + type.radius) && !overlaps(with: gear2, to: to) }
    }
    
    func overlaps(with gear2: DGIGear, to: Bool = false) -> Bool {
        if to { return position.distance(to: gear2.toPos) < (gear2.type.radius + type.radius - wiggle) }
        else { return position.distance(to: gear2.position) < (gear2.type.radius + type.radius - wiggle)}
    }
}

class DGICounter: SKLabelNode {
    
    var count: Double = 0.0
    var max: Double?
    var precision: Int = 1
    
    required init?(coder decoder: NSCoder) {
        fatalError("Encoding counters is not supported")
    }
    
    override init() {
        super.init()
    }
    
    override init(fontNamed: String?) {
        super.init(fontNamed: fontNamed)
    }
    
    convenience init(name: String, fontNamed: String?, size: CGFloat, initialVal: Double) {
        self.init(fontNamed: fontNamed)
        self.name = name
        fontSize = size
        count = initialVal
        setLabel()
        zPosition = 1.5
        numberOfLines = 1
    }
    
    func setLabel() {
        text = String(format: "%.\(precision)f", count)
    }
    
    func increment(by add: Double, speed: Double = 0.4, divisor: Int = 10) {
        if let max = self.max {
            if count == max, add >= 0 { return }
            if count + add > max {
                let newadd = max - count
                let increment = [SKAction.run{ [weak self, newadd] in self?.count += newadd / Double(divisor) }, SKAction.run{ [weak self, newadd] in self?.text = String(format: "%.\(self?.precision ?? 1)f", Swift.max(self?.count ?? 0 + newadd / Double(divisor), 0))},SKAction.wait(forDuration: speed / Double(divisor))]
                run(SKAction.sequence([SKAction.run{ [weak self] in (self?.parent?.parent as! DGIRoom).view?.isUserInteractionEnabled = false }] + Array(repeating: increment, count: divisor).flatMap{ $0 } + [SKAction.run{ [weak self] in (self?.parent?.parent as! DGIRoom).view?.isUserInteractionEnabled = true }]))
                return
            }
        }
        let increment = [SKAction.run{ [weak self, add] in self?.count += add / Double(divisor) }, SKAction.run{ [weak self, add] in self?.text = String(format: "%.\(self?.precision ?? 1)f", Swift.max(self?.count ?? 0 + add / Double(divisor), 0))},SKAction.wait(forDuration: speed / Double(divisor))]
        run(SKAction.sequence([SKAction.run{ [weak self] in (self?.parent?.parent as! DGIRoom).view?.isUserInteractionEnabled = false }] + Array(repeating: increment, count: divisor).flatMap{ $0 } + [SKAction.run{ [weak self] in (self?.parent?.parent as! DGIRoom).view?.isUserInteractionEnabled = true }]))
    }
    
    func increment(to total: Double, speed: Double = 0.4, divisor: Int = 10) {
        increment(by: total - count, speed: speed, divisor: divisor)
    }
}
