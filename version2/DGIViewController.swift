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

class DGIViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = SKView(frame: view.bounds)
        
        if let view = self.view as! SKView? {
            view.presentScene(DGIRoom(from: "endroom"))
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
