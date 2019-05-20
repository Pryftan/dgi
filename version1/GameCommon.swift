//
//  GameCommon.swift
//  GameTest1
//
//  Created by William Frank on 9/2/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameCommon: SKScene {
    
    var config: GameJSONConfig
    var jsonfile: String
    var cam: SKCameraNode?
    var menu: GameMenu?
    var dialogue: [GameDialogue] = []
    var dialoguecount = 0
    var currdialogue: GameDialogue = GameDialogue()
    var avatarlines: [SKAction] = []
    var playerlines: [SKAction] = []
    var scrollVal: Int = 0
    var music: AVAudioPlayer?
    var soundEffect: AVAudioPlayer?
    
    let leftSwipe = UISwipeGestureRecognizer()
    let rightSwipe = UISwipeGestureRecognizer()
    let downSwipe = UISwipeGestureRecognizer()
    let upSwipe = UISwipeGestureRecognizer()
    
    required init?(coder decoder: NSCoder)
    {
        config = GameJSONConfig()
        jsonfile = ""
        super.init(coder: decoder)
    }
    
    override init(size: CGSize)
    {
        config = GameJSONConfig()
        jsonfile = ""
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
    }
    
    init(config: GameJSONConfig, jsonfile: String, menu: GameMenu)
    {
        //self.init(size: CGSize(width: config.basewidth, height: config.baseheight))
        self.config = config
        self.jsonfile = jsonfile
        self.menu = menu
        super.init(size: CGSize(width: config.basewidth, height: config.baseheight))
        self.scaleMode = .aspectFit
        self.backgroundColor = UIColor.black
        
        loadJSON(withName: jsonfile)
        loadAutoSave()
        
        cam = SKCameraNode()
        cam!.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.camera = cam
        addChild(cam!)
        
        leftSwipe.addTarget(self, action: #selector(self.moveRight))
        leftSwipe.direction = .left
        leftSwipe.cancelsTouchesInView = true
        leftSwipe.delaysTouchesEnded = true
        
        rightSwipe.addTarget(self, action: #selector(self.moveLeft))
        rightSwipe.direction = .right
        rightSwipe.cancelsTouchesInView = true
        rightSwipe.delaysTouchesEnded = true
    
        downSwipe.addTarget(self, action: #selector(self.scrollUp))
        downSwipe.direction = .down
        downSwipe.cancelsTouchesInView = true
        downSwipe.delaysTouchesEnded = true
        
        upSwipe.addTarget(self, action: #selector(self.scrollDown))
        upSwipe.direction = .up
        upSwipe.cancelsTouchesInView = true
        upSwipe.delaysTouchesEnded = true
        
        let avatar = SKSpriteNode(imageNamed: "avatar")
        avatar.anchorPoint = CGPoint(x: 0, y: 0)
        avatar.position = CGPoint(x: config.basewidth - config.avatarspace * config.scale - avatar.size.width, y: config.baseheight - config.avatarspace * config.scale - avatar.size.height)
        avatar.alpha = 0
        avatar.zPosition = 2
        avatar.name = "Avatar"
        addChild(avatar)
        
        let avatarbox = SKShapeNode.init(rectOf: CGSize(width: config.basewidth, height: config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1)), cornerRadius: config.basewidth * 0.01)
        avatarbox.position = CGPoint(x: config.basewidth / 2, y: config.baseheight - ((config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1))/2))
        avatarbox.fillColor = UIColor.black
        avatarbox.alpha = 0.35
        avatarbox.zPosition = 1
        avatarbox.name = "AvatarBox"
        avatarbox.isHidden = true
        addChild(avatarbox)
        let avatarText = SKLabelNode(fontNamed: "Arial")
        avatarText.name = "AvatarText"
        avatarText.fontSize = config.dialoguetext * config.scale
        avatarText.color = UIColor.white
        avatarText.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        avatarText.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        avatarText.lineBreakMode = NSLineBreakMode.byWordWrapping
        avatarText.numberOfLines = 0
        avatarText.preferredMaxLayoutWidth = avatarbox.frame.maxX - (config.avatarspace * config.scale * 2 + avatar.size.width)
        avatarText.position = CGPoint(x: -1 * avatarbox.frame.maxX / 2 + config.dialoguespace * config.scale, y: config.baseheight - avatarbox.frame.midY - config.dialoguespace * config.scale)
        avatarbox.addChild(avatarText)
        
        let playerbox = SKShapeNode.init(rectOf: CGSize(width: config.basewidth, height: config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1)), cornerRadius: config.basewidth * 0.01)
        playerbox.position = CGPoint(x: config.basewidth / 2, y: (config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1))/2)
        playerbox.fillColor = UIColor.black
        playerbox.alpha = 0.35
        playerbox.zPosition = 1
        playerbox.name = "PlayerBox"
        playerbox.isHidden = true
        addChild(playerbox)
        let playerText = SKLabelNode(fontNamed: "Arial")
        playerText.name = "PlayerText"
        playerText.fontSize = config.dialoguetext * config.scale
        playerText.color = UIColor.white
        playerText.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        playerText.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        playerText.lineBreakMode = NSLineBreakMode.byWordWrapping
        playerText.numberOfLines = 0
        playerText.preferredMaxLayoutWidth = playerbox.frame.maxX
        playerText.position = CGPoint(x: -1 * avatarbox.frame.maxX / 2 + config.dialoguespace * config.scale, y: playerbox.frame.midY - config.dialoguespace * config.scale)
        //playerText.text = "Test Avatar Line"
        playerbox.addChild(playerText)
        
        let dialoguebox = SKShapeNode.init(rectOf: CGSize(width: config.basewidth, height: config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1)), cornerRadius: config.basewidth * 0.01)
        dialoguebox.position = CGPoint(x: config.basewidth / 2, y: (config.dialoguerows * (config.dialoguetext * config.scale + config.dialoguespace * config.scale + 1))/2)
        dialoguebox.fillColor = UIColor.black
        dialoguebox.alpha = 0.35
        dialoguebox.zPosition = 1
        dialoguebox.name = "DialogueBox"
        dialoguebox.isHidden = true
        addChild(dialoguebox)
        
        for val in (0..<10)
        {
            let dialogueline = SKLabelNode(fontNamed: "Arial")
            //dialogueline.text = "Line \(val+1)"
            dialogueline.fontSize = config.dialoguetext * config.scale
            dialogueline.color = UIColor.white
            dialogueline.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            dialogueline.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            var ypos = (config.dialoguetext * config.scale + config.dialoguespace * config.scale) * (config.dialoguerows - CGFloat(val))
            ypos -= dialoguebox.frame.maxY / 2 + config.dialoguespace * config.scale
            dialogueline.position = CGPoint(x: -1 * dialoguebox.frame.maxX / 2 + config.dialoguespace * config.scale, y: ypos)
            dialogueline.name = "Line \(val+1)"
            if val > Int(config.dialoguerows) { dialogueline.isHidden = true }
            dialoguebox.addChild(dialogueline)
        }
    }
    
    override func didMove(to view: SKView)
    {
        self.view!.addGestureRecognizer(leftSwipe)
        self.view!.addGestureRecognizer(rightSwipe)
        self.view!.addGestureRecognizer(downSwipe)
        self.view!.addGestureRecognizer(upSwipe)
        self.music?.play()
    }
    
    @objc func moveLeft()
    {
        //override
    }
    
    @objc func moveRight()
    {
        //override
    }
    
    @objc func scrollUp()
    {
        //override
    }
    
    @objc func scrollDown()
    {
        //override
    }
    
    func disableGestures()
    {
        leftSwipe.isEnabled = false
        rightSwipe.isEnabled = false
        upSwipe.isEnabled = false
        downSwipe.isEnabled = false
    }
    
    func enableGestures()
    {
        leftSwipe.isEnabled = true
        rightSwipe.isEnabled = true
        upSwipe.isEnabled = true
        downSwipe.isEnabled = true
    }
    
    func runNextScene()
    {
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.7),SKAction.run({ [menu] in self.removeAllChildren();
                self.removeFromParent(); menu?.runNextScene()})]))
    }
    
    func loadJSON(withName: String)
    {
        //override
    }
    
    func loadAutoSave()
    {
        //override
    }
    
    deinit {
        print("Deinit called")
    }
}
