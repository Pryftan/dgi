//
//  DGIViewController.swift
//  DGI: Engine
//
//  Created by William Frank on 4/17/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

let Config = ParseConfig()
var sceneorder = Next<String>([])

class DGIViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = SKView(frame: view.bounds)
        
        if let view = self.view as! SKView? {
            //Config.bounds = view.bounds.size
            view.presentScene(DGIMenu(from: "soldier"))
            //view.presentScene(DGIRoom(from: "endroom"))
            //view.presentScene(DGIVoid(from: "cuts2"))
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
}

extension SKView {
    
    func transitionScene(save: Bool = true) {
        //let nextname = increment ? sceneorder.next : sceneorder.now
        let nextname = sceneorder.next
        isUserInteractionEnabled = true
        if save {
            GameSave.autosave.clearSave()
            GameSave.autosave.setPart(part: nextname)
            GameSave.autosave.save()
        }
        if nextname.hasPrefix("cut") {
            let nextscene = DGIVoid(from: nextname)
            if let menu = scene as? DGIMenu { nextscene.menu = menu }
            else if let scene = self.scene as? DGIScreen { nextscene.menu = scene.menu }
            presentScene(nextscene, transition: SKTransition.fade(withDuration: 1.7))
        } else {
            let nextscene = DGIRoom(from: nextname)
            if let menu = scene as? DGIMenu { nextscene.menu = menu }
            else if let scene = self.scene as? DGIScreen { nextscene.menu = scene.menu }
            /*SKTextureAtlas(named: "cabin").preload(completionHandler: { [weak self] in
                self?.presentScene(nextscene, transition: SKTransition.fade(withDuration: 1.7))
             })*/
            presentScene(nextscene, transition: SKTransition.fade(withDuration: 1.7))
        }
    }
}
