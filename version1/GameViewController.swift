//
//  GameViewController.swift
//  GameTest1
//
//  Created by William Frank on 8/27/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    private var config: GameJSONConfig?
    private var sceneorder: [String] = ["classroom"]
    //private var sceneorder: [String] = ["cuts1", "cabin", "cuts2", "endroom", "cuts3"]

    override func viewDidLoad() {
        super.viewDidLoad()
        config = loadJSONConfig()
        
        //GameSave.autosave.setPart(part: sceneorder[0])
        
        if let view = self.view as! SKView? {
            
            view.presentScene(GameMenu(config: config!, sceneorder: sceneorder))
            //let scene = GameCutscene(config: config!, sceneorder: sceneorder)
            //let scene = GameScene(config: config!, jsonfile: "part2")
            //let scene = GameCutscene(config: config!, cutscene: "cut1")
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override func loadView() {
        self.view = SKView.init(frame: UIScreen.main.bounds)
        //self.view.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.size.width * config!.scale, height: self.view.bounds.size.height * config!.scale)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscape
        } else {
            return .landscape
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func loadJSONConfig() -> GameJSONConfig? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json") else {
            print("Error finding JSON")
            return nil
        }
        guard let data = try? Data(contentsOf: url) else
        {
            print("Error loading JSON")
            return nil
        }
        guard let config = try? JSONDecoder().decode(GameJSONConfig.self, from: data) else
        {
            print("Error parsing JSON")
            return nil
        }
        return config
    }
    
    /*func runNextScene()
    {
        sceneorder.removeFirst()
        if !sceneorder.isEmpty
        {
            //self.view = SKView.init(frame: UIScreen.main.bounds)
            //super.viewDidLoad()
            if let view = self.view as! SKView?
            {
                GameSave.autosave.setPart(part: sceneorder[0])
                view.scene?.removeAllChildren()
                view.scene?.removeAllActions()
                view.scene?.removeFromParent()
                view.presentScene(nil)
                if sceneorder[0].hasPrefix("cut")
                {
                    view.presentScene(GameCutscene(config: config!, sceneorder: sceneorder, viewcontroller: self))
                }
                else
                {
                    view.presentScene(GameScene(config: config!, sceneorder: sceneorder, viewcontroller: self))
                }
                
                view.ignoresSiblingOrder = true
                view.showsFPS = true
                view.showsNodeCount = true
            }
        }
    }*/
}
