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
    var shows: [String: [String]] = [:]
    var hides: [String: [String]] = [:]
    var toggles: [String: String] = [:]
    var color: [String: [String]] = [:]
    var flags: [String: Bool] = [:]
    var cyclelocs: [String: String] = [:]
    var cyclevals: [String: Int] = [:]
    var sequences: [String: [String]] = [:]
    var states: [String] = []
    var choices: [[String]] = []
    var displaynames: [String: String] = [:]
    var gearsolves: [String] = []
    var specials: [String: Int] = [:]
    var finalechoice: String = "None"
    
    override init() { }
    //NEED TO ADD: COLORS, INITALPHAS, VIEWSHOWS (?), MUSIC
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
            if let showscheck: [String:[String]] = shows as? [String:[String]]  { self.shows = showscheck }
        }
        if let hides = decoder.decodeObject(forKey: "hides") {
            if let hidescheck: [String:[String]]  = hides as? [String:[String]]  { self.hides = hidescheck }
        }
        if let toggles = decoder.decodeObject(forKey: "toggles") {
            if let togglescheck: [String:String] = toggles as? [String: String] { self.toggles = togglescheck }
        }
        if let color = decoder.decodeObject(forKey: "color") {
            if let colorcheck: [String:[String]]  = color as? [String:[String]]  { self.color = colorcheck }
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
        if let sequences = decoder.decodeObject(forKey: "sequences") {
            if let sequencescheck: [String:[String]] = sequences as? [String: [String]] { self.sequences = sequencescheck }
        }
        if let states = decoder.decodeObject(forKey: "states") {
            self.states = states as! [String]
        }
        if let choices = decoder.decodeObject(forKey: "choices") {
            if let choicescheck: [[String]] = choices as? [[String]] { self.choices = choicescheck }
        }
        if let displaynames = decoder.decodeObject(forKey: "displaynames") {
            if let displaynamescheck: [String:String] = displaynames as? [String: String] { self.displaynames = displaynamescheck }
        }
        if let gearsolves = decoder.decodeObject(forKey: "gearsolves") {
            if let gearsolvescheck: [String] = gearsolves as? [String] { self.gearsolves = gearsolvescheck }
        }
        if let specials = decoder.decodeObject(forKey: "specials") {
            if let specialscheck: [String: Int] = specials as? [String: Int] { self.specials = specialscheck }
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
        coder.encode(color, forKey: "color")
        coder.encode(flags, forKey: "flags")
        coder.encode(cyclelocs, forKey: "cyclelocs")
        coder.encode(cyclevals, forKey: "cyclevals")
        coder.encode(sequences, forKey: "sequences")
        coder.encode(states, forKey: "states")
        coder.encode(choices, forKey: "choices")
        coder.encode(displaynames, forKey: "displaynames")
        coder.encode(gearsolves, forKey: "gearsolves")
        coder.encode(specials, forKey: "specials")
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
        if hides[name] != nil {
            hides[name] = nil
        } else {
            if let gp = grandparent {
                shows[name] = [parent, gp]
            }
            else {
                shows[name] = [parent]
            }
        }
    }
    
    func addHide(name: String, parent: String, grandparent: String?) {
        if shows[name] != nil {
            shows[name] = nil
        } else {
            if let gp = grandparent {
                hides[name] = [parent, gp]
            }
            else {
                hides[name] = [parent]
            }
        }
    }
    
    func addToggle(name: String, parent: String) {
        if let _ = toggles[name] {
            toggles[name] = nil
        } else {
            toggles[name] = parent
        }
    }
    
    func addColor(name: String, parent: String, grandparent: String?, hex: String, alpha: String?) {
        if let gp = grandparent {
            if let alpha = alpha {
                color[name] = [parent, gp, hex, alpha]
            } else {
                color[name] = [parent, gp, hex]
            }
        } else {
            if let alpha = alpha {
                color[name] = [parent, hex, alpha]
            } else {
                color[name] = [parent, hex]
            }
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
    
    func addSequence(name: String, sequence: [String]) {
        sequences[name] = sequence
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
    
    func addDisplayName(object: String, newname: String) {
        if newname == "Reset" { displaynames[object] = nil }
        else { displaynames[object] = newname }
    }
    
    func addGearSolve(gearsolve: String) {
        gearsolves.append(gearsolve)
    }
    
    func addSpecial(special: String, state: Int) {
        specials[special] = state
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
        shows = [:]
        hides = [:]
        toggles = [:]
        color = [:]
        flags = [:]
        cyclelocs = [:]
        cyclevals = [:]
        sequences = [:]
        states = []
        choices = []
        displaynames = [:]
        gearsolves = []
        specials = [:]
        save()
    }
    
    func printString() {
        print(part)
        for object in inventory { print(object) }
        for show in shows { print("Show: " + show.key) }
        for hide in hides { print("Hide: " + hide.key) }
        for toggle in toggles { print("Toggle: " + toggle.key) }
        for color in color { print("Color: " + color.key) }
        for flag in flags { if flag.value { print("Flag: " + flag.key) } }
        //INCOMPLETE
        for state in states { print("State:" + state ) }
        for displayname in displaynames { print("DisplayName: " + displayname.key + " as " + displayname.value) }
        for special in specials { print("Special: " + special.key + " state: " + String(special.value))}
    }
    
}
