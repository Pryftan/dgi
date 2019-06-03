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
    
    var newGame = SKLabelNode(fontNamed: "Arial")
    var contGame = SKLabelNode(fontNamed: "Arial")
    var queuePlayer = AVQueuePlayer()
    var music: AVPlayerLooper?
    weak var returnScene: DGIScreen?
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
    }
    
    override init() {
        super.init(size: Config.bounds)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
        newGame.text = "New Game"
        newGame.fontSize = Config.dialogue.text
        newGame.position = CGPoint(x: size.width / 2, y: size.height / 2 + 0.2 * Config.bounds.height)
        addChild(newGame)
        contGame.text = "Continue"
        contGame.fontSize = Config.dialogue.text
        contGame.position = CGPoint(x: size.width / 2, y: size.height / 2 - 0.2 * Config.bounds.height)
        addChild(contGame)
        if let url = Bundle.main.url(forResource: "music_menu", withExtension: "mp3") {
            music = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(asset: AVAsset(url: url)))
        }
    }
    
    override func didMove(to view: SKView) {
        queuePlayer.play()
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = self.atPoint(pos)
        if node == newGame {
            GameSave.autosave.clearSave()
            sceneorder.reset()
            view?.transitionScene()
        } else if node == contGame {
            if let scene = returnScene {
                view?.presentScene(scene)
            } else {
                if GameSave.autosave.part != "" {
                    while sceneorder.peek != GameSave.autosave.part { sceneorder.increment() }
                    view?.transitionScene(increment: false)
                } else {
                    sceneorder.reset()
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
}
