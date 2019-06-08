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
    var music: AVAudioPlayer?
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
        music?.play()
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = self.atPoint(pos)
        if node.name == "new" {
            GameSave.autosave.clearSave()
            sceneorder.reset()
            music?.stop()
            view?.transitionScene()
            (view?.scene as? DGIScreen)?.menu = self
        } else if node.name == "cont" {
            if let scene = returnScene {
                music?.stop()
                view?.presentScene(scene)
            } else {
                if GameSave.autosave.part != "" {
                    sceneorder.set(GameSave.autosave.part)
                    music?.stop()
                    view?.transitionScene(save: false)
                } else {
                    sceneorder.reset()
                    music?.stop()
                    view?.transitionScene()
                }
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
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
    
    func loadJSON() {
        do {
            let jsonData = try JSONDecoder().decode(DGIJSONMenu.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: json, ofType: "json")!)))
            sceneorder.setData(jsonData.scenes)
            if let musicname = jsonData.music {
                music = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: musicname, ofType: "mp3")!))
                music?.numberOfLoops = -1
            }
            for imageData in jsonData.images {
                let image = SKSpriteNode(imageNamed: imageData.image, name: imageData.type ?? imageData.name)
                image.position = CGPoint(x: imageData.sub[0] * Config.scale, y: imageData.sub[1] * Config.scale)
                addChild(image)
            }
        } catch let error {
            print(error)
            print("Error parsing JSON.")
        }
    }
}

class DGIMenuBar: SKSpriteNode {
    
    var titleScreen = SKLabelNode(fontNamed: "Arial")
    var manualSave = SKLabelNode(fontNamed: "Arial")
    var settings = SKLabelNode(fontNamed: "Arial")
    
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
        //self.position = CGPoint(x: 30, y: 400)
        self.zPosition = 4
        self.position = CGPoint(x: Config.inv.space + size.width / 2, y: Config.bounds.height - (Config.inv.space * 0.5 + size.height))
        
        titleScreen.text = "Title Screen"
        titleScreen.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        titleScreen.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        titleScreen.fontName = "Palatino"
        titleScreen.fontSize = Config.dialogue.text * 0.75
        titleScreen.position = CGPoint(x: size.width, y: 0)
        addChild(titleScreen)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func touchUp(pos: CGPoint) -> Int {
        if titleScreen.frame.contains(convert(pos, from: parent!)) {
            return 1
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
