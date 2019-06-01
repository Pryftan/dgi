//
//  DGIScreen.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit
import AVFoundation

class DGIScreen: SKScene {
    
    let json: String!
    let gestures = ["leftSwipe": UISwipeGestureRecognizer(), "rightSwipe": UISwipeGestureRecognizer(), "upSwipe": UISwipeGestureRecognizer(), "downSwipe": UISwipeGestureRecognizer()]
    var music: AVAudioPlayer?
    var soundEffect: AVAudioPlayer?
    var dialogues: [DGIJSONDialogue] = []
    var playerbox: DGISpeechBox! {
        get { return childNode(withName: "PlayerBox") as? DGISpeechBox }
    }
    var avatarbox: DGISpeechBox! {
        get { return childNode(withName: "AvatarBox") as? DGISpeechBox }
    }
    var choicebox: DGIChoiceBox! {
        get { return childNode(withName: "ChoiceBox") as? DGIChoiceBox }
    }
    
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
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode
        
        loadJSON()
        
        gestures["leftSwipe"]?.addTarget(self, action: #selector(self.moveRight))
        gestures["leftSwipe"]?.direction = .left
        gestures["rightSwipe"]?.addTarget(self, action: #selector(self.moveLeft))
        gestures["rightSwipe"]?.direction = .right
        gestures["upSwipe"]?.addTarget(self, action: #selector(self.scrollDown))
        gestures["upSwipe"]?.direction = .up
        gestures["downSwipe"]?.addTarget(self, action: #selector(self.scrollUp))
        gestures["downSwipe"]?.direction = .down
        for gesture in gestures {
            gesture.value.cancelsTouchesInView = true
            gesture.value.delaysTouchesEnded = true
        }
        
        let avatar = SKSpriteNode(imageNamed: "avatar", name: "Avatar")
        avatar.position = CGPoint(x: Config.bounds.width - Config.avatarspace - avatar.size.width, y: Config.bounds.height - Config.avatarspace - avatar.size.height)
        avatar.zPosition = 3
        avatar.alpha = 0
        addChild(avatar)
        
        let avatarbox = DGISpeechBox(name: "AvatarBox", at: .top)
        avatarbox.text.preferredMaxLayoutWidth = avatarbox.frame.maxX - (Config.avatarspace * 2 + avatar.size.width)
        addChild(avatarbox)
        let playerbox = DGISpeechBox(name: "PlayerBox", at: .bottom)
        addChild(playerbox)
        let choicebox = DGIChoiceBox(name: "ChoiceBox", at: .bottom)
        addChild(choicebox)
    }
    
    override func didMove(to view: SKView) {
        for gesture in gestures {
            self.view!.addGestureRecognizer(gesture.value)
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        //override
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
    
    @objc func moveLeft() {
        //override
    }
    
    @objc func moveRight() {
        //override
    }
    
    @objc func scrollUp() {
        if let choicebox = childNode(withName: "ChoiceBox") as? DGIChoiceBox {
            if !choicebox.isHidden && choicebox.scroll > 0 {
                choicebox.scroll -= 1
                for (index, line) in choicebox.children.enumerated() {
                    if index < choicebox.scroll  {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: -1 * (Config.dialogue.text + Config.dialogue.space), duration: 0.1), SKAction.fadeOut(withDuration: 0.1), SKAction.hide()]))
                    } else {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: -1 * (Config.dialogue.text + Config.dialogue.space), duration: 0.1), SKAction.unhide(), SKAction.fadeIn(withDuration: 0.1)]))
                    }
                }
            }
        }
    }
    
    @objc func scrollDown() {
        if let choicebox = childNode(withName: "ChoiceBox") as? DGIChoiceBox {
            if !choicebox.isHidden && (choicebox.scroll + Int(Config.dialogue.rows)) < choicebox.lineno {
                choicebox.scroll += 1
                for (index, line) in choicebox.children.enumerated() {
                    if index < choicebox.scroll {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: Config.dialogue.text + Config.dialogue.space, duration: 0.1), SKAction.fadeOut(withDuration: 0.1), SKAction.hide()]))
                    } else {
                        line.run(SKAction.group([SKAction.moveBy(x:0, y: Config.dialogue.text + Config.dialogue.space, duration: 0.1), SKAction.unhide(), SKAction.fadeIn(withDuration: 0.1)]))
                    }
                }
            }
        }
    }
    
    func setTouches(_ touch: Bool) {
        self.view?.isUserInteractionEnabled = touch
    }
    
    func disableGestures(except names: [String] = []) {
        for gesture in gestures {
            if !names.contains(gesture.key) { gesture.value.isEnabled = false }
        }
    }
    
    func enableGestures(except names: [String] = []) {
        for gesture in gestures {
            if !names.contains(gesture.key) { gesture.value.isEnabled = true }
        }
    }
    
    func playSound(_ sound: String) {
        do {
            soundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: sound + ".mp3", ofType: nil)!))
            soundEffect?.play()
        } catch {
            print("sound \(sound) not found")
        }
    }
    
    func closeDialogue() {
        //override
    }
    
    func loadJSON() {
        //override
    }
}
