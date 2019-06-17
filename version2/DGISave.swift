//
//  DGISave.swift
//  DGI: Engine
//
//  Created by William Frank on 4/19/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation

class GameSave: NSObject, NSCoding {
    static var autosave: GameSave = {
        do {
            if let checkSave: Any = UserDefaults.standard.object(forKey: "autosave") {
                if var decodedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(checkSave as! Data) as? GameSave {
                    //decodedData.clearSave()
                    return decodedData
                }
                else {
                    print(("No save data found; creating new."))
                    return GameSave()
                }
            } else {
                print(("No save data found; creating new."))
                return GameSave()
            }
        } catch {
            print(("Error in decoding."))
            return GameSave()
        }
    }()
    
    var part = ""
    var tutorial = ""
    var volume: [Float] = [0.5,1]
    var inventory: [String] = []
    var shows: [[String]] = []
    var hides: [[String]] = []
    var toggles: [String: String] = [:]
    var flags: [String: Bool] = [:]
    var cyclelocs: [String: String] = [:]
    var cyclevals: [String: Int] = [:]
    var states: [String] = []
    var choices: [[String]] = []
    var finalechoice: String = "None"
    
    override init() { }
    
    convenience init(part: String) {
        self.init()
        self.part = part
    }
    
    required init?(coder decoder: NSCoder) {
        if let part = decoder.decodeObject(forKey: "part") {
            self.part = part as! String
        }
        if let tutorial = decoder.decodeObject(forKey: "tutorial") {
            self.tutorial = tutorial as! String
        }
        if let volume = decoder.decodeObject(forKey: "volume") {
            self.volume = volume as! [Float]
        }
        if let inventory = decoder.decodeObject(forKey: "inventory") {
            self.inventory = inventory as! [String]
        }
        if let shows = decoder.decodeObject(forKey: "shows") {
            if let showscheck: [[String]] = shows as? [[String]] { self.shows = showscheck }
        }
        if let hides = decoder.decodeObject(forKey: "hides") {
            if let hidescheck: [[String]] = hides as? [[String]] { self.hides = hidescheck }
        }
        if let toggles = decoder.decodeObject(forKey: "toggles") {
            if let togglescheck: [String:String] = toggles as? [String: String] { self.toggles = togglescheck }
        }
        if let flags = decoder.decodeObject(forKey: "flags") {
            self.flags = flags as! [String: Bool]
        }
        if let cyclelocs = decoder.decodeObject(forKey: "cyclelocs") {
            self.cyclelocs = cyclelocs as! [String: String]
        }
        if let cyclevals = decoder.decodeObject(forKey: "cyclevals") {
            if let cyclescheck: [String:Int] = cyclevals as? [String: Int] { self.cyclevals = cyclescheck }
        }
        if let states = decoder.decodeObject(forKey: "states") {
            self.states = states as! [String]
        }
        if let choices = decoder.decodeObject(forKey: "choices") {
            if let choicescheck: [[String]] = choices as? [[String]] { self.choices = choicescheck }
        }
        if let finalechoice = decoder.decodeObject(forKey: "finalechoice") {
            if let finalechoicecheck: String = finalechoice as? String { self.finalechoice = finalechoicecheck }
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(part, forKey: "part")
        coder.encode(tutorial, forKey: "tutorial")
        coder.encode(volume, forKey: "volume")
        coder.encode(inventory, forKey: "inventory")
        coder.encode(shows, forKey: "shows")
        coder.encode(hides, forKey: "hides")
        coder.encode(toggles, forKey: "toggles")
        coder.encode(flags, forKey: "flags")
        coder.encode(cyclelocs, forKey: "cyclelocs")
        coder.encode(cyclevals, forKey: "cyclevals")
        coder.encode(states, forKey: "states")
        coder.encode(choices, forKey: "choices")
        coder.encode(finalechoice, forKey: "finalechoice")
    }
    
    func setPart(part: String) {
        self.part = part
    }
    
    func setTutorial(_ run: Bool) {
        if run { self.tutorial = "run" }
        else { self.tutorial = "" }
    }
    
    func addInv(object: String) {
        inventory.append(object)
    }
    
    func removeInv(object: String) {
        inventory = inventory.filter { $0 != object }
    }
    
    func addShow(name: String, parent: String, grandparent: String?) {
        for (index, hide) in hides.enumerated() {
            if hide[0] == name {
                hides.remove(at: index)
                return
            }
        }
        if let gp = grandparent {
            shows.append([name, parent, gp])
        }
        else {
            shows.append([name, parent])
        }
    }
    
    func addHide(name: String, parent: String, grandparent: String?) {
        for (index, show) in shows.enumerated() {
            if show[0] == name {
                shows.remove(at: index)
                return
            }
        }
        if let gp = grandparent {
            hides.append([name, parent, gp])
        }
        else {
            hides.append([name, parent])
        }
    }
    
    func addToggle(name: String, parent: String) {
        if let _ = toggles[name] {
            toggles[name] = nil
        } else {
            toggles[name] = parent
        }
    }
    
    func setFlag(name: String, value: Bool) {
        flags[name] = value
    }
    
    func addCycle(name: String, parent: String, val: Int) {
        if val > 0 {
            cyclelocs[name] = parent
            cyclevals[name] = val
        } else {
            cyclelocs.removeValue(forKey: name)
            cyclevals.removeValue(forKey: name)
        }
    }
    
    func addState(name: String) {
        states.append(name)
    }
    
    func addChoice(name: String, dialogue: String, type: String, parent: String?) {
        if let p = parent {
            choices.append([name, dialogue, type, p])
        } else {
            choices.append([name, dialogue, type])
        }
    }
    
    func setFinale(choice: String) {
        if finalechoice == "None" { finalechoice = choice }
    }
    
    func save() {
        do {
            volume = [Config.volume.music, Config.volume.effect]
            try UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false), forKey: "autosave")
        } catch {
            print("Error")
        }
    }
    
    func clearSave() {
        part = ""
        inventory = []
        shows = []
        hides = []
        toggles = [:]
        flags = [:]
        cyclelocs = [:]
        cyclevals = [:]
        states = []
        choices = []
        save()
    }
}
