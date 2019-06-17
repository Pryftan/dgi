//
//  DGIMenu.swift
//  DGI: Engine
//
//  Created by William Frank on 6/1/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit
import AVFoundation

class DGIMenu: SKScene {
    
    let json: String!
    var main: [String] = []
    var settings: [String] = []
    var music: SKAudioNode? {
        get { return childNode(withName: "Music") as? SKAudioNode }
    }
    weak var dragging: DGISlider!
    weak var returnScene: DGIScreen?
    
    required init?(coder decoder: NSCoder) {
        json = ""
        super.init(coder: decoder)
    }
    
    override init(size: CGSize) {
        json = ""
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
    }
    
    init(from json: String) {
        self.json = json
        super.init(size: Config.bounds)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
        if let particles = SKEmitterNode(fileNamed: "MenuParticle") {
            particles.position = CGPoint(x: Config.bounds.width / 2, y: Config.bounds.height / 2)
            addChild(particles)
        }
        loadJSON()
        /*newGame.text = "New Game"
        newGame.fontSize = Config.dialogue.text
        newGame.position = CGPoint(x: size.width / 2, y: size.height / 2 + 0.2 * Config.bounds.height)
        addChild(newGame)
        contGame.text = "Continue"
        contGame.fontSize = Config.dialogue.text
        contGame.position = CGPoint(x: size.width / 2, y: size.height / 2 - 0.2 * Config.bounds.height)
        addChild(contGame)
        if let url = Bundle.main.url(forResource: "music_menu", withExtension: "mp3") {
            music = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        }*/
    }
    
    override func didMove(to view: SKView) {
        music?.run(SKAction.group([SKAction.play(), SKAction.changeVolume(to: Config.volume.music, duration: 0)]))
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if dragging != nil {
            if pos.x > dragging.bar.frame.minX && pos.x < dragging.bar.frame.maxX {
                dragging.position = CGPoint(x: pos.x, y: dragging.position.y)
            } else if pos.x < dragging.bar.frame.minX {
                dragging.position = CGPoint(x: dragging.bar.frame.minX, y: dragging.position.y)
            } else if pos.x > dragging.bar.frame.maxX {
                dragging.position = CGPoint(x: dragging.bar.frame.maxX, y: dragging.position.y)
            }
            if dragging.name! == "musicball" {
                Config.volume.music = Float((dragging.position.x - dragging.bar.frame.minX) / dragging.bar.frame.width)
                music?.run(SKAction.changeVolume(to: Config.volume.music, duration: 0))
            } else if dragging.name! == "soundball" {
                Config.volume.effect = Float((dragging.position.x - dragging.bar.frame.minX) / dragging.bar.frame.width)
            }
            dragging = nil
            return
        }
        let node = self.atPoint(pos)
        if node.name == "new" {
            GameSave.autosave.clearSave()
            GameSave.autosave.setTutorial(false)
            sceneorder.reset()
            music?.run(SKAction.pause())
            view?.transitionScene()
            (view?.scene as? DGIScreen)?.menu = self
        } else if node.name == "cont" {
            if let scene = returnScene {
                music?.run(SKAction.pause())
                view?.presentScene(scene)
            } else {
                if GameSave.autosave.part != "" {
                    sceneorder.set(GameSave.autosave.part)
                    music?.run(SKAction.pause())
                    view?.transitionScene(save: false)
                } else {
                    sceneorder.reset()
                    music?.run(SKAction.pause())
                    view?.transitionScene()
                }
            }
        } else if node.name == "settings" {
            toggleSettings(true)
        } else if node.name == "back" {
            if let scene = returnScene {
                music?.run(SKAction.pause())
                view?.presentScene(scene)
            } else {
                toggleSettings(false)
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        let node = self.atPoint(pos)
        if let name = node.name {
            if name.hasSuffix("ball") {
                dragging = node as? DGISlider
                return
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if dragging != nil {
            if pos.x > dragging.bar.frame.minX && pos.x < dragging.bar.frame.maxX {
                dragging.position = CGPoint(x: pos.x, y: dragging.position.y)
            } else if pos.x < dragging.bar.frame.minX {
                dragging.position = CGPoint(x: dragging.bar.frame.minX, y: dragging.position.y)
            } else if pos.x > dragging.bar.frame.maxX {
                dragging.position = CGPoint(x: dragging.bar.frame.maxX, y: dragging.position.y)
            }
            if dragging.name! == "musicball" {
                music?.run(SKAction.changeVolume(to: Float((dragging.position.x - dragging.bar.frame.minX) / dragging.bar.frame.width), duration: 0))
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
    
    func toggleSettings(_ val: Bool) {
        for child in children {
            if settings.contains(child.name ?? "") { child.isHidden = !val }
            else { if main.contains(child.name ?? "") { child.isHidden = val } }
        }
        /*let soundLine = SKShapeNode(rect: CGRect(x: 1291, y: 473, width: 578, height: 28))
        soundLine.fillColor = .blue
        addChild(soundLine)*/
    }
    
    func loadJSON() {
        do {
            let jsonData = try JSONDecoder().decode(DGIJSONMenu.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: json, ofType: "json")!)))
            sceneorder.setData(jsonData.scenes)
            if let musicname = jsonData.music {
                let musicNode = SKAudioNode(fileNamed: musicname)
                musicNode.name = "Music"
                musicNode.autoplayLooped = true
                addChild(musicNode)
            }
            imageLoop: for imageData in jsonData.images {
                if let type = imageData.type {
                    if type.hasSuffix("ball") {
                        let num = imageData.name.last!
                        let bar = childNode(withName: "Slider\(num)") as! SKSpriteNode
                        let image = DGISlider(imageNamed: imageData.image, bar: bar)
                        image.name = type
                        let volume = num == "1" ? Config.volume.music : Config.volume.effect
                        image.position = CGPoint(x: bar.frame.minX + CGFloat(volume) * bar.frame.width, y: (imageData.sub[1] + imageData.sub[3] / 2) * Config.scale)
                        if let name = image.name { if settings.contains(name) { image.isHidden = true } }
                        image.zPosition = 1
                        addChild(image)
                        settings.append(type)
                        image.isHidden = true
                        continue imageLoop
                    }
                }
                let image = SKSpriteNode(imageNamed: imageData.image, name: imageData.type ?? imageData.name)
                image.position = CGPoint(x: imageData.sub[0] * Config.scale, y: imageData.sub[1] * Config.scale)
                image.isHidden = !(imageData.visible ?? true)
                if image.isHidden { settings.append(imageData.type ?? imageData.name)}
                else { main.append(imageData.type ?? imageData.name)}
                addChild(image)
            }
        } catch let error {
            print(error)
            print("Error parsing JSON.")
        }
    }
}

class DGISlider: SKSpriteNode {
    
    unowned let bar: SKSpriteNode
    
    required init?(coder decoder: NSCoder) {
        fatalError("Coder not implemented for sliders")
    }
    
    init(imageNamed: String, bar: SKSpriteNode) {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.bar = bar
        super.init(texture: texture, color: color, size: size)
        //self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
}

class DGIMenuBar: SKSpriteNode {
    
    var titleScreen = SKLabelNode(fontNamed: "Arial")
    var settingsLabel = SKLabelNode(fontNamed: "Arial")
    var tutorialLabel = SKLabelNode(fontNamed: "Arial")
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(imageNamed: String) {
        let color = UIColor()
        let texture = SKTexture(imageNamed: imageNamed)
        let size = texture.size()
        self.init(texture: texture, color: color, size: size)
        self.name = "MenuBar"
        self.setScale(Config.inv.scale * 0.75)
        self.zRotation = CGFloat(Double.pi)
        self.zPosition = 4
        self.position = CGPoint(x: Config.inv.space + size.width / 2, y: Config.bounds.height - (Config.inv.space * 0.5 + size.height))
        
        titleScreen.text = "Title Screen"
        titleScreen.horizontalAlignmentMode = .left
        titleScreen.verticalAlignmentMode = .top
        titleScreen.fontName = "Palatino"
        titleScreen.fontSize = Config.dialogue.text * 0.75
        titleScreen.position = CGPoint(x: size.width, y: Config.dialogue.space * 0.75)
        addChild(titleScreen)
        
        settingsLabel.text = "Settings"
        settingsLabel.horizontalAlignmentMode = .left
        settingsLabel.verticalAlignmentMode = .top
        settingsLabel.fontName = "Palatino"
        settingsLabel.fontSize = Config.dialogue.text * 0.75
        settingsLabel.position = CGPoint(x: size.width + titleScreen.frame.width + Config.dialogue.space * 1.5, y: Config.dialogue.space * 0.75)
        addChild(settingsLabel)
        
        tutorialLabel.text = "Tutorial"
        tutorialLabel.horizontalAlignmentMode = .left
        tutorialLabel.verticalAlignmentMode = .top
        tutorialLabel.fontName = "Palatino"
        tutorialLabel.fontSize = Config.dialogue.text * 0.75
        tutorialLabel.position = CGPoint(x: size.width + titleScreen.frame.width + settingsLabel.frame.width + Config.dialogue.space * 3, y: Config.dialogue.space * 0.75)
        addChild(tutorialLabel)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func touchUp(pos: CGPoint) -> Int {
        if titleScreen.frame.contains(convert(pos, from: parent!)) {
            return 1
        } else if settingsLabel.frame.contains(convert(pos, from: parent!)) {
            return 2
        } else if tutorialLabel.frame.contains(convert(pos, from: parent!)) {
            return 3
        }
        return 0
    }
    
    func openBar() {
        run(SKAction.rotate(toAngle: 0, duration: 1))
    }
    
    func closeBar() {
        run(SKAction.rotate(toAngle: CGFloat(Double.pi), duration: 1))
    }
    
}
