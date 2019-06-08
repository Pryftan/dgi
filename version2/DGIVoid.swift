//
//  DGIVoid.swift
//  DGI: Engine
//
//  Created by William Frank on 5/31/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import SpriteKit
import AVFoundation

class DGIVoid: DGIScreen {
    
    private var delay: Double = 0
    private var dialno = 0
    private var preloadnames: [String] = []
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init(from json: String) {
        super.init(from: json)
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        disableGestures(except: ["scrollUp", "scrollDown"])
        childNode(withName: "Avatar")?.run(SKAction.sequence([SKAction.wait(forDuration: delay),SKAction.fadeAlpha(to: 0.8, duration: 1), SKAction.run{ self.runDialogue() }]))
        menubar.isHidden = true
        music.run(SKAction.play())
    }
    
    override func touchUp(atPoint pos : CGPoint) {
        if gestures.allSatisfy( {$0.value.state == .possible || $0.value.state == .failed} ) {
            if !choicebox.isHidden {
                choicebox.selectLine(at: pos)
                return
            }
            if !playerbox.isHidden || !avatarbox.isHidden {
                playerbox.skipLine()
                avatarbox.skipLine()
                return
            }
        }
    }
    
    func runDialogue() {
        playerbox.isHidden = true
        avatarbox.isHidden = true
        choicebox.isHidden = true
        if let lines = dialogues[dialno].lines {
            playerbox.runLines(jsonlines: lines, name: "Player", branch: dialogues[dialno].branch)
            avatarbox.runLines(jsonlines: lines, name: "Avatar", branch: dialogues[dialno].branch)
            choicebox.dialno = dialno
        } else if let branch = dialogues[dialno].branch {
            choicebox.dialno = dialno
            choicebox.runBranch(branch)
        }
    }
    
    override func closeDialogue() {
        dialno += 1
        if dialno < dialogues.count { runDialogue() }
        else { view?.transitionScene() }
    }
    
    override func loadJSON() {
        do {
            let jsonData = try JSONDecoder().decode(DGIJSONVoid.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: json, ofType: "json")!)))
            if let delay  = jsonData.delay { self.delay = delay }
            if let musicname = jsonData.music {
                let musicNode = SKAudioNode(fileNamed: musicname)
                musicNode.name = "Music"
                musicNode.autoplayLooped = true
                addChild(musicNode)
            }
            if let preloadnames = jsonData.preload {
                //for image in preloadnames { preload.append(SKTexture(imageNamed: image)) }
                self.preloadnames = preloadnames
            }
            if let images = jsonData.images {
                var currZ: CGFloat = 0.1
                for image in images {
                    let addimage = SKSpriteNode(imageNamed: image.image)
                    addimage.name = image.name
                    if let anchor:[CGFloat] = image.anchor {
                        addimage.anchorPoint = CGPoint(x:anchor[0], y:anchor[1])
                    } else { addimage.anchorPoint = CGPoint(x:0, y:0) }
                    addimage.position = CGPoint(x: image.sub[0] * Config.scale, y: image.sub[1] * Config.scale)
                    addimage.zPosition = currZ
                    currZ += 0.01
                    if let vis = image.visible { addimage.isHidden = !vis }
                    if let opacity = image.opacity { addimage.alpha = CGFloat(opacity)}
                    if let rotate = image.rotate { addimage.zRotation = -1 * rotate * CGFloat(Double.pi)/180 }
                    if let frames = image.frames {
                        var actions: [SKAction] = []
                        for frame in frames {
                            if frame.frame == "rotateby" {
                                actions.append(SKAction.rotate(byAngle: -1 * frame.pos![0] * CGFloat(Double.pi/180), duration: frame.duration))
                            }
                            else if frame.frame == "opacityto" {
                                actions.append(SKAction.fadeAlpha(to: frame.pos![0], duration: frame.duration))
                            }
                        }
                        addimage.run(SKAction.repeatForever(SKAction.sequence(actions)))
                    }
                    addChild(addimage)
                }
            }
            dialogues = jsonData.dialogue
        } catch let error {
            print(error)
            print("Error parsing JSON.")
        }
    }
}
