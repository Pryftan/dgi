//
//  GameArcade.swift
//  GameTest1
//
//  Created by William Frank on 9/3/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

class GameArcade: GameScreen
{
    private var callback: GameScene?
    private var holes: [Hole] = []
    private var playarea: CGRect
    private var menu: SKSpriteNode
    private var menualt: SKSpriteNode?
    private var gameover: SKSpriteNode
    private var gameoveralt: SKSpriteNode?
    private var win: SKSpriteNode?
    private var scale: CGFloat = 0.388
    private let monstertypes: [String] = ["croc", "mole", "mouse", "tentacle", "spider"]
    private let monsterpoints: [Int] = [50, 60, 20, 70, 30]
    private var monsterframes: [[SKTexture]] = [[]]
    private var totalpoints = 0
    private var hammer: SKSpriteNode = SKSpriteNode(imageNamed: "hammer")
    private let frametime: Double = 0.3
    private let gametime: TimeInterval = 30
    private var winaction: GameSpot?
    private var mode: Int = 0
    
    required init?(coder decoder: NSCoder)
    {
        playarea = CGRect()
        menu = SKSpriteNode()
        gameover = SKSpriteNode()
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        playarea = CGRect()
        menu = SKSpriteNode()
        gameover = SKSpriteNode()
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String, config: GameJSONConfig, playarea: CGRect, callback: GameScene)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.config = config
        self.playarea = playarea
        self.callback = callback
        self.menu = SKSpriteNode(imageNamed: "menu1")
        self.gameover = SKSpriteNode(imageNamed: "winall")
        whackInit()
    }
    
    func whackInit()
    {
        self.menualt = SKSpriteNode(imageNamed: "menu2")
        self.gameoveralt = SKSpriteNode(imageNamed: "losemole")
        self.win = SKSpriteNode(imageNamed: "winmole")
        for type in monstertypes
        {
            let monsterAtlas = SKTextureAtlas(named: type)
            var currframes: [SKTexture] = []
            for i in 1...4 {
                let monsterFrame = "\(type)\(i)"
                currframes.append(monsterAtlas.textureNamed(monsterFrame))
            }
            monsterframes.append(currframes)
        }
        monsterframes.removeFirst()
        for i in (0..<5) {
            for j in (0..<5)
            {
                let newhole = Hole(monsterframes: monsterframes, frametime: frametime, gametime: gametime)
                holes.append(newhole)
                newhole.isHidden = true
                newhole.anchorPoint = CGPoint(x: 0, y: 0)
                newhole.setScale(scale)
                newhole.position = CGPoint(x: playarea.minX + CGFloat(j) * newhole.size.width, y: playarea.minY + CGFloat(i) * newhole.size.height)
                newhole.zPosition = 1
                addChild(newhole)
            }
        }
        hammer.isHidden = true
        hammer.anchorPoint = CGPoint(x: 0, y: 0)
        hammer.setScale(scale)
        hammer.zPosition = 1.01
        addChild(hammer)
        menu.position = CGPoint(x: 588 * config.scale, y: 170 * config.scale)
        menu.anchorPoint = CGPoint(x: 0, y: 0)
        menu.zPosition = 1
        menu.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.hide(), SKAction.wait(forDuration: 0.3), SKAction.unhide()])))
        if let menualt = self.menualt
        {
            menualt.position = CGPoint(x: 588 * config.scale, y: 170 * config.scale)
            menualt.anchorPoint = CGPoint(x: 0, y: 0)
            menualt.zPosition = 1
            menualt.isHidden = true
            menualt.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.unhide(), SKAction.wait(forDuration: 0.5), SKAction.hide(), SKAction.wait(forDuration: 0.7)])))
            addChild(menualt)
        }
        gameover.position = CGPoint(x: 588 * config.scale, y: 170 * config.scale)
        gameover.anchorPoint = CGPoint(x: 0, y: 0)
        gameover.zPosition = 1
        gameover.isHidden = true
        if let gameoveralt = self.gameoveralt
        {
            gameoveralt.position = CGPoint(x: 588 * config.scale, y: 170 * config.scale)
            gameoveralt.anchorPoint = CGPoint(x: 0, y: 0)
            gameoveralt.zPosition = 1
            gameoveralt.isHidden = true
            addChild(gameoveralt)
        }
        if let win = self.win
        {
            win.position = CGPoint(x: 588 * config.scale, y: 170 * config.scale)
            win.anchorPoint = CGPoint(x: 0, y: 0)
            win.zPosition = 1
            win.isHidden = true
            addChild(win)
        }
        addChild(menu)
        addChild(gameover)
    }
    
    func touchUp(pos : CGPoint)
    {
        let playrect: CGRect = CGRect(x: 760 * config.scale, y: 314 * config.scale, width: 250 * config.scale, height: 128 * config.scale)
        let quitrect: CGRect = CGRect(x: 770 * config.scale, y: 198 * config.scale, width: 374 * config.scale, height: 116 * config.scale)
        switch mode {
        case 0:
            if playrect.contains(pos)
            {
                startPlay()
                mode = 1
            } else if quitrect.contains(pos)
            {
                if let callback: GameScene = self.callback
                {
                    callback.scrollUp()
                }
            }
        case 1:
            print("\(Int((pos.x - playarea.minX)/holes[0].size.width)), \(Int((pos.y - playarea.minY)/holes[0].size.height))")
            let holeclicked = holes[Int((pos.x - playarea.minX)/holes[0].size.width) + Int((pos.y - playarea.minY)/holes[0].size.height) * 5]
            if holeclicked.monsterup
            {
                hammer.removeAllActions()
                hammer.position = holeclicked.position
                hammer.run(SKAction.sequence([SKAction.unhide(), SKAction.wait(forDuration: frametime), SKAction.hide()]))
                holeclicked.removeAllActions()
                holeclicked.monsterup = false
                holeclicked.run(SKAction.animate(with: [monsterframes[holeclicked.monsternum][3], holeclicked.hole], timePerFrame: frametime))
                holeclicked.run(SKAction.run{ holeclicked.spawn(forDuration: self.gametime - holeclicked.currtime)})
                totalpoints += monsterpoints[holeclicked.monsternum]
            }
        default:
            return
        }
        
    }
    
    func startPlay(forDuration: TimeInterval = 30)
    {
        if let callback: GameScene = self.callback
        {
            callback.disableGestures()
        }
        menu.removeAllActions()
        menualt?.removeAllActions()
        menu.isHidden = true
        menualt?.isHidden = true
        for i in (0..<25) {
            holes[i].isHidden = false
            holes[i].spawn(forDuration: gametime)
        }
        run(SKAction.sequence([SKAction.wait(forDuration: forDuration), SKAction.run{ self.endPlay() }]))
    }
    
    func endPlay()
    {
        mode = 2
        if let callback: GameScene = self.callback
        {
            callback.enableGestures()
        }
        for i in (0..<25) {
            holes[i].isHidden = true
            holes[i].texture = holes[i].hole
            holes[i].removeAllActions()
        }
        print(totalpoints)
        var won: Bool = false
        var wonspot: GameSpot?
        if let grid = self.getGrid()
        {
            for spot in grid
            {
                if spot.getName() == "Win\(totalpoints)"
                {
                    won = true
                    wonspot = spot
                }
            }
        }
        if won
        {
            if let win = self.win
            {
                callback?.view?.isUserInteractionEnabled = false
                win.isHidden = false
                win.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.hide(), SKAction.wait(forDuration: 0.3), SKAction.unhide()])))
                run(SKAction.sequence([SKAction.wait(forDuration: 5),SKAction.run{
                    self.win?.removeAllActions()
                    self.win?.isHidden = true
                    self.menu.isHidden = false
                    self.menualt?.isHidden = false
                    self.menu.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.hide(), SKAction.wait(forDuration: 0.3), SKAction.unhide()])))
                    self.menualt?.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.unhide(), SKAction.wait(forDuration: 0.5), SKAction.hide(), SKAction.wait(forDuration: 0.7)])))
                    self.mode = 0
                    self.callback?.view?.isUserInteractionEnabled = true
                    self.callback?.runGameSpot(spot: wonspot!)
                }]))
            }
        } else
        {
            totalpoints = 0
            gameover.isHidden = false
            gameover.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.hide(), SKAction.wait(forDuration: 0.3), SKAction.unhide()])))
            gameoveralt?.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.unhide(), SKAction.wait(forDuration: 0.5), SKAction.hide(), SKAction.wait(forDuration: 0.7)])))
            run(SKAction.sequence([SKAction.wait(forDuration: 5),SKAction.run{
                self.gameover.removeAllActions()
                self.gameoveralt?.removeAllActions()
                self.gameover.isHidden = true
                self.gameoveralt?.isHidden = true
                self.menu.isHidden = false
                self.menualt?.isHidden = false
                self.menu.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.hide(), SKAction.wait(forDuration: 0.3), SKAction.unhide()])))
                self.menualt?.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.unhide(), SKAction.wait(forDuration: 0.5), SKAction.hide(), SKAction.wait(forDuration: 0.7)])))
                self.mode = 0
            }]))
        }
    }
    
}

class Hole: SKSpriteNode
{
    private var monsterframes: [[SKTexture]] = [[]]
    var hole: SKTexture
    var monsterup: Bool = false
    var monsternum: Int = 0
    var currtime: TimeInterval = 0
    private var frametime: TimeInterval
    private var gametime: TimeInterval
    
    required init?(coder decoder: NSCoder)
    {
        hole = SKTexture(imageNamed: "hole")
        frametime = 0.3
        gametime = 30
        super.init(coder: decoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize)
    {
        hole = SKTexture(imageNamed: "hole")
        frametime = 0.3
        gametime = 30
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        hole = texture
    }
    
    convenience init(monsterframes: [[SKTexture]], frametime: TimeInterval, gametime: TimeInterval)
    {
        self.init(imageNamed: "hole")
        self.monsterframes = monsterframes
        self.frametime = frametime
        self.gametime = gametime
    }
    
    func spawn(forDuration: TimeInterval)
    {
        let maxspace: Double = forDuration
        var totaltime: Double = 0
        var sequence: [SKAction] = []
        while totaltime < forDuration
        {
            let monnum: Int = Int(arc4random_uniform(UInt32(4)))
            let frames: [SKTexture] = monsterframes[monnum]
            let delay: Double = Double(arc4random_uniform(UInt32(maxspace*1000))/1000)
            let showduration: Double = Double((arc4random_uniform(UInt32(5000))+1000)/1000)
            let trueduration: Double = Double(Int(showduration / (2 * frametime))) * frametime
            
            sequence.append(SKAction.wait(forDuration: delay))
            sequence.append(SKAction.animate(with: [frames[0]], timePerFrame: frametime))
            sequence.append(SKAction.run{ self.monsterup = true; self.monsternum = monnum; self.currtime = totaltime})
            sequence.append(SKAction.repeat(SKAction.animate(with: [frames[1], frames[2]], timePerFrame: frametime), count: Int(showduration / (2 * frametime))))
            sequence.append(SKAction.run{ self.monsterup = false })
            sequence.append(SKAction.animate(with: [frames[0], hole], timePerFrame: frametime))
            totaltime += delay + 2 * trueduration + 2 * frametime
        }
        run(SKAction.sequence(sequence), withKey: "Spawn")
    }
}
