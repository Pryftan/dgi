//
//  DGITutorial.swift
//  DGI: Engine
//
//  Created by William Frank on 6/11/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit

class DGITutorial: SKNode {
    
    var typechecks: Set<DGITutorialType> = []
    var isRunning = false
    let font = "Courier"
    
    enum DGITutorialType {
        case swipeMove, tapZoom, invObj, swipeBack, dragObj, menuObj
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init() {
        super.init()
        
    }
    
    class arrowNode: SKSpriteNode {
        
        enum arrowOrient {
            case up, down, left, right, upperleft, upperright, lowerleft, lowerright
        }
        required init?(coder decoder: NSCoder) {
            super.init(coder: decoder)
        }
        override init(texture: SKTexture?, color: UIColor, size: CGSize) {
            super.init(texture: texture, color: color, size: size)
        }
        convenience init(_ point: arrowOrient, inner: CGFloat = 100 * Config.scale) {
            let color = UIColor()
            let texture = SKTexture(imageNamed: "arrow")
            let size = texture.size()
            self.init(texture: texture, color: color, size: size)
            anchorPoint = CGPoint(x: 1, y: 0.5)
            setScale(0.4)
            zPosition = 4
            alpha = 0
            switch point {
            case .up:
                zRotation = CGFloat.pi / 2
            case .left:
                zRotation = CGFloat.pi
            case .down:
                zRotation = 3 * CGFloat.pi / 2
                xScale = 0.8
                run(SKAction.fadeAlpha(to: 0.5, duration: 1))
            case .upperleft:
                zRotation = 7 * CGFloat.pi / 4
                run(SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.move(by: CGVector(dx: inner, dy: -1 * inner), duration: 1), SKAction.fadeOut(withDuration: 0.3), SKAction.move(by: CGVector(dx: -1 * inner, dy: inner), duration: 0), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
            case .upperright:
                zRotation = 5 * CGFloat.pi / 4
                run(SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.move(by: CGVector(dx: -1 * inner, dy: -1 * inner), duration: 1), SKAction.fadeOut(withDuration: 0.3), SKAction.move(by: CGVector(dx: inner, dy: inner), duration: 0), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
            case .lowerleft:
                zRotation = CGFloat.pi / 4
                run(SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.move(by: CGVector(dx: inner, dy: inner), duration: 1), SKAction.fadeOut(withDuration: 0.3), SKAction.move(by: CGVector(dx: -1 * inner, dy: -1 * inner), duration: 0), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
            case .lowerright:
                zRotation = 3 * CGFloat.pi / 4
                run(SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.move(by: CGVector(dx: -1 * inner, dy: inner), duration: 1), SKAction.fadeOut(withDuration: 0.3), SKAction.move(by: CGVector(dx: inner, dy: -1 * inner), duration: 0), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
            default:
                zRotation = 0
            }
        }
    }
    
    func nextStep(hasLeft: Bool = false, zoomGrid: DGIJSONGrid? = nil, hasBack: Bool = false, objGrid: DGIJSONGrid? = nil, dragSub: DGIRoomSub? = nil) {
        if !isRunning { return }
        if typechecks.count == 6 { isRunning = true; clearScreen(); return }
        if !typechecks.contains(.swipeMove), hasLeft {
            swipeMove()
        } else if !typechecks.contains(.tapZoom), let grid = zoomGrid {
            tapZoom(grid)
        } else if !typechecks.contains(.invObj), let grid = objGrid {
            invObj(grid)
        } else if !typechecks.contains(.swipeBack), hasBack {
            swipeBack()
        } else if !typechecks.contains(.dragObj), let sub = dragSub {
            dragObj(sub)
        } else if !typechecks.contains(.menuObj) {
            menuObj()
        } else {
            clearScreen()
        }
    }
    
    func swipeMove() {
        clearScreen()
        let swipeText = SKLabelNode(text: "Swipe to move")
        swipeText.fontSize = CGFloat(Config.subtitle.text * 2)
        swipeText.fontName = font
        swipeText.position = CGPoint(x: Config.bounds.width / 2, y : 800)
        swipeText.zPosition = 4
        swipeText.alpha = 0
        swipeText.color = .cyan
        addChild(swipeText)
        swipeText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let swipeArrow = SKSpriteNode(imageNamed: "arrowswipe")
        swipeArrow.name = "SwipeArrow"
        swipeArrow.alpha = 0
        swipeArrow.zPosition = 3
        swipeArrow.position = CGPoint(x: 960, y: 700)
        swipeArrow.setScale(0.7)
        addChild(swipeArrow)
        swipeArrow.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let finger = SKSpriteNode(imageNamed: "finger")
        finger.name = "Finger"
        finger.alpha = 0
        finger.zPosition = 3
        finger.anchorPoint = CGPoint(x: 0, y: 0)
        finger.position = CGPoint(x: 900, y: 50)
        finger.setScale(0.5)
        finger.zRotation = 0.4
        addChild(finger)
        finger.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.6, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.group([SKAction.rotate(byAngle: -0.4, duration: 1), SKAction.move(by: CGVector(dx: 150, dy: 0), duration: 1)]), SKAction.fadeOut(withDuration: 0.3), SKAction.group([SKAction.rotate(byAngle: 0.4, duration: 0), SKAction.move(by: CGVector(dx: -150, dy: 0), duration: 0)]), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
    }
    
    func tapZoom(_ grid: DGIJSONGrid) {
        clearScreen()
        let zoomText = SKLabelNode(text: "Tap to zoom on interesting objects")
        zoomText.fontSize = CGFloat(Config.subtitle.text * 2)
        zoomText.fontName = font
        zoomText.position = CGPoint(x: Config.bounds.width / 2, y : 800)
        zoomText.zPosition = 4
        zoomText.alpha = 0
        zoomText.color = .cyan
        addChild(zoomText)
        zoomText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        if let pos = grid.pos {
            let arrow1 = arrowNode(.upperleft)
            arrow1.position = CGPoint(x: pos[0] + 0.1 * pos[2], y: pos[1] + pos[3] - 0.1 * pos[3])
            addChild(arrow1)
            let arrow2 = arrowNode(.upperright)
            arrow2.position = CGPoint(x: pos[0] + pos[2] - 0.1 * pos[2], y: pos[1] + pos[3] - 0.1 * pos[3])
            addChild(arrow2)
            let arrow3 = arrowNode(.lowerleft)
            arrow3.position = CGPoint(x: pos[0] + 0.1 * pos[2], y: pos[1] + 0.1 * pos[3])
            addChild(arrow3)
            let arrow4 = arrowNode(.lowerright)
            arrow4.position = CGPoint(x: pos[0] + pos[2] - 0.1 * pos[2], y: pos[1] + 0.1 * pos[3])
            addChild(arrow4)
        }
    }
    
    func swipeBack() {
        clearScreen()
        let swipeText = SKLabelNode(text: "Swipe down to zoom out")
        swipeText.fontSize = CGFloat(Config.subtitle.text * 2)
        swipeText.fontName = font
        swipeText.position = CGPoint(x: Config.bounds.width / 2, y : 800)
        swipeText.zPosition = 4
        swipeText.alpha = 0
        swipeText.color = .cyan
        addChild(swipeText)
        swipeText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let arrow = arrowNode(.down)
        arrow.position = CGPoint(x: 960, y: 300)
        addChild(arrow)
        let finger = SKSpriteNode(imageNamed: "finger")
        finger.name = "Finger"
        finger.alpha = 0
        finger.zPosition = 3
        finger.anchorPoint = CGPoint(x: 0, y: 0)
        finger.position = CGPoint(x: 1200, y: 50)
        finger.setScale(0.5)
        finger.zRotation = 0.4
        addChild(finger)
        finger.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.6, duration: 1), SKAction.repeatForever(SKAction.sequence([SKAction.group([SKAction.rotate(byAngle: 0.2, duration: 1), SKAction.move(by: CGVector(dx: 50, dy: -200), duration: 1)]), SKAction.fadeOut(withDuration: 0.3), SKAction.group([SKAction.rotate(byAngle: -0.2, duration: 0), SKAction.move(by: CGVector(dx: -50, dy: 200), duration: 0)]), SKAction.fadeAlpha(by: 0.6, duration: 0.3)]))]))
    }
    
    func invObj(_ grid: DGIJSONGrid) {
        clearScreen()
        let objText = SKLabelNode(text: "Some objects can be picked up")
        objText.fontSize = CGFloat(Config.subtitle.text * 2)
        objText.fontName = font
        objText.position = CGPoint(x: Config.bounds.width / 2, y : 800)
        objText.zPosition = 4
        objText.alpha = 0
        objText.color = .cyan
        addChild(objText)
        objText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        if let pos = grid.pos {
            let arrow1 = arrowNode(.upperleft)
            arrow1.position = CGPoint(x: pos[0] + 0.1 * pos[2], y: pos[1] + pos[3] - 0.1 * pos[3])
            addChild(arrow1)
            let arrow2 = arrowNode(.upperright)
            arrow2.position = CGPoint(x: pos[0] + pos[2] - 0.1 * pos[2], y: pos[1] + pos[3] - 0.1 * pos[3])
            addChild(arrow2)
            let arrow3 = arrowNode(.lowerleft)
            arrow3.position = CGPoint(x: pos[0] + 0.1 * pos[2], y: pos[1] + 0.1 * pos[3])
            addChild(arrow3)
            let arrow4 = arrowNode(.lowerright)
            arrow4.position = CGPoint(x: pos[0] + pos[2] - 0.1 * pos[2], y: pos[1] + 0.1 * pos[3])
            addChild(arrow4)
        }
    }
    
    func dragObj(_ sub: DGIRoomSub) {
        clearScreen()
        if sub.texture == nil { sub.loadTexture() }
        let dragText = SKLabelNode(text: "Hold and drag")
        dragText.fontSize = CGFloat(Config.subtitle.text * 2)
        dragText.fontName = font
        dragText.position = CGPoint(x: Config.bounds.width / 2, y : 800)
        dragText.zPosition = 4
        dragText.alpha = 0
        dragText.color = .cyan
        addChild(dragText)
        dragText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let arrow = arrowNode(.upperright)
        arrow.position = CGPoint(x: sub.frame.midX + 100 * Config.scale, y: sub.frame.midY + 100 * Config.scale)
        addChild(arrow)
        
        
        sub.addOutline()
    }
    
    func menuObj() {
        clearScreen()
        typechecks.insert(.menuObj)
        let menuArrow = arrowNode(.lowerright, inner: 25 * Config.scale)
        let (menux, menuy) = ((parent as? DGIRoom)?.menubar.position.x ?? 0, (parent as? DGIRoom)?.menubar.position.y ?? 0)
        menuArrow.setScale(0.2)
        menuArrow.position = CGPoint(x: menux + 100 * Config.scale, y: menuy - 100 * Config.scale)
        addChild(menuArrow)
        let menuText = SKLabelNode(text: "Access options")
        menuText.fontSize = Config.subtitle.text
        menuText.fontName = font
        menuText.zPosition = 4
        menuText.alpha = 0
        menuText.color = .cyan
        menuText.horizontalAlignmentMode = .left
        menuText.verticalAlignmentMode = .top
        menuText.position = CGPoint(x: menuArrow.frame.maxX, y: menuArrow.frame.minY)
        addChild(menuText)
        menuText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let avatarArrow = arrowNode(.lowerleft, inner: 25 * Config.scale)
        let (avatarx, avatary) = (parent?.childNode(withName: "Avatar")?.frame.minX ?? 0, parent?.childNode(withName: "Avatar")?.frame.minY ?? 0)
        avatarArrow.setScale(0.2)
        avatarArrow.position = CGPoint(x: avatarx - 100 * Config.scale, y: avatary - 100 * Config.scale)
        addChild(avatarArrow)
        let avatarText = SKLabelNode(text: "Discuss with computer")
        avatarText.fontSize = Config.subtitle.text
        avatarText.fontName = font
        avatarText.zPosition = 4
        avatarText.alpha = 0
        avatarText.color = .cyan
        avatarText.horizontalAlignmentMode = .center
        avatarText.verticalAlignmentMode = .top
        avatarText.position = CGPoint(x: avatarArrow.frame.minX, y: avatarArrow.frame.minY)
        addChild(avatarText)
        avatarText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        let invArrow = arrowNode(.upperright, inner: 25 * Config.scale)
        let (invx, invy) = ((parent as? DGIRoom)?.inventory.frame.maxX ?? 0, (parent as? DGIRoom)?.inventory.frame.maxY ?? 0)
        invArrow.setScale(0.2)
        invArrow.position = CGPoint(x: invx + 100 * Config.scale, y: invy + 100 * Config.scale)
        addChild(invArrow)
        let invText = SKLabelNode(text: "Open inventory")
        invText.fontSize = Config.subtitle.text
        invText.fontName = font
        invText.zPosition = 4
        invText.alpha = 0
        invText.color = .cyan
        invText.horizontalAlignmentMode = .center
        invText.verticalAlignmentMode = .bottom
        invText.position = CGPoint(x: invArrow.frame.maxX, y: invArrow.frame.maxY)
        addChild(invText)
        invText.run(SKAction.fadeAlpha(to: 0.5, duration: 1))
        
    }
    
    func clearScreen() {
        for child in children {
            child.run(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.removeFromParent()]))
        }
    }
    
    func restart() {
        isRunning = true
        typechecks = []
    }
    
}
