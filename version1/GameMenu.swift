//
//  GameMenu.swift
//  DGI: Soldier
//
//  Created by William Frank on 1/29/19.
//  Copyright © 2019 William Frank. All rights reserved.
//

import SpriteKit
import AVFoundation

var loadingPercent = 100.0

class GameMenu: SKScene {
    
    var config: GameJSONConfig
    var thisscene: GameCommon?
    var loading: GameLoading?
    var sceneorder: [String] = []
    var thiscount: Int = 0
   
    var newGame = SKLabelNode(fontNamed: "Arial")
    var contGame = SKLabelNode(fontNamed: "Arial")
    var queuePlayer = AVQueuePlayer()
    var music: AVPlayerLooper?
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        super.init(coder: decoder)
    }
    
    override init(size: CGSize)
    {
        config = GameJSONConfig()
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
    }
    
    convenience init(config: GameJSONConfig, sceneorder: [String])
    {
        self.init(size: CGSize(width: config.basewidth, height: config.baseheight))
        self.config = config
        self.sceneorder = sceneorder
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
        loading = GameLoading(config: config)
        newGame.text = "New Game"
        newGame.position = CGPoint(x: size.width / 2, y: size.height / 2 + 0.2 * config.baseheight)
        addChild(newGame)
        contGame.text = "Continue"
        contGame.position = CGPoint(x: size.width / 2, y: size.height / 2 - 0.2 * config.baseheight)
        addChild(contGame)
        if let url = Bundle.main.url(forResource: "music_menu", withExtension: "mp3")
        {
            music = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        }
    }
    
    override func didMove(to view: SKView)
    {
        queuePlayer.play()
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = self.atPoint(pos)
        if node == newGame
        {
            thisscene = nil
            thiscount = 0
            GameSave.autosave.clearSave()
            if sceneorder[0].hasPrefix("cut") {
                thisscene = GameCutscene(config: config, jsonfile: sceneorder[0], menu: self)
                view?.presentScene(thisscene)
            } else {
                thisscene = GameScene(config: config, jsonfile: sceneorder[0], menu: self)
                view?.presentScene(thisscene)
            }
            queuePlayer.removeAllItems()
        }
        else if node == contGame
        {
            if let thisscene = self.thisscene
            {
                view?.presentScene(thisscene)
                return
            }
            let currpart = GameSave.autosave.part
            if currpart != sceneorder[0]
            {
                for (count, scene) in sceneorder.enumerated()
                {
                    if scene == currpart { thiscount = count }
                }
            }
            queuePlayer.removeAllItems()
            if sceneorder[thiscount].hasPrefix("cut") {
                thisscene = GameCutscene(config: config, jsonfile: sceneorder[thiscount], menu: self)
                view?.presentScene(thisscene)
            } else {
                thisscene = GameScene(config: config, jsonfile: sceneorder[thiscount], menu: self)
                view?.presentScene(thisscene)
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
    
    func setScene(scene: GameCommon)
    {
        thisscene = scene
    }
    
    func runNextScene()
    {
        thisscene?.view?.isUserInteractionEnabled = false
        queuePlayer.removeAllItems()
        thisscene?.music?.stop()
        thiscount += 1
        if thiscount < sceneorder.count
        {
            if thiscount < sceneorder.count - 1
            {
                GameSave.autosave.clearSave()
                GameSave.autosave.setPart(part: sceneorder[thiscount])
                GameSave.autosave.save()
            }
            thisscene?.removeAllChildren()
            thisscene?.removeAllActions()
            if sceneorder[thiscount].hasPrefix("cut") {
                let nextscene: GameCutscene = GameCutscene(config: config, jsonfile: sceneorder[thiscount], menu: self)
                thisscene?.view?.presentScene(nextscene)
                thisscene = nil
                thisscene = nextscene
            } else {
                loadingPercent = 0
                loading?.setNext(jsonfile: sceneorder[thiscount], menu: self)
                thisscene?.view?.presentScene(loading)
                thisscene = nil
            }
        }
    }
    
}

class GameLoading: SKScene {

    var config: GameJSONConfig
    var loadingBar: SKShapeNode?
    var jsonfile: String?
    weak var menu: GameMenu?
    weak var nextscene: GameCommon?
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        super.init(coder: decoder)
    }
    
    override init(size: CGSize)
    {
        config = GameJSONConfig()
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
    }
    
    convenience init(config: GameJSONConfig)
    {
        self.init(size: CGSize(width: config.basewidth, height: config.baseheight))
        self.config = config
        loadingBar = SKShapeNode.init(rectOf: CGSize(width: config.basewidth, height: config.baseheight / 10), cornerRadius: config.basewidth * 0.01)
        loadingBar!.name = "LoadingBar"
        loadingBar!.fillColor = UIColor.red
        loadingBar!.alpha = 0.35
        loadingBar!.position = CGPoint(x: config.basewidth / 2, y: config.baseheight / 2)
        loadingBar!.zPosition = 1
        addChild(loadingBar!)
    }
    
    func setNext(jsonfile: String, menu: GameMenu)
    {
        self.jsonfile = jsonfile
        self.menu = menu
    }
    
    override func didMove(to view: SKView) {
        let scene = GameScene(config: config, jsonfile: jsonfile!, menu: menu!)
        nextscene = scene
        menu?.setScene(scene: scene)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if loadingPercent == 100, let nextscene = self.nextscene {
            view?.isUserInteractionEnabled = true
            view?.presentScene(nextscene)
        }
    }
}
