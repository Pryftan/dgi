//
//  GameSpot.swift
//  GameTest1
//
//  Created by William Frank on 8/28/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameSpot
{
    private var spot: CGRect?
    private var name: String
    private var active: Bool
    private var saves: Bool
    private var value: Int?
    private var flag: String?
    private var flagactions: [GameSpot]?
    private var sequenceactions: [GameSpot]?
    private var randoms: [GameSpot]?
    private var sound: AVAudioPlayer?
    private weak var zoom: GameScreen?
    private var phonezoom: GameJSONPhoneZoom?
    private weak var view: GameScreen?
    private var object: GameInvObj?
    private var removes: GameInvObj?
    private var animatename: String?
    private var animate: GameJSONAnimation?
    private var selectable: SKSpriteNode?
    private var selects: [GameSpot]?
    private var invdisplay: [String]?
    private var sequence: String?
    private var speech: [GameJSONSpeech]?
    private var speechcounter: Int?
    private var dialoguename: String?
    private var dialogue: GameDialogue?
    private var cyclelocs: [GameJSONCycle]?
    private var cycle: [[SKSpriteNode?]]?
    private var cyclecounter: Int?
    private var cyclerevname: String?
    private var cyclerev: GameSpot?
    private var cycleifnames: [(cycle: GameJSONLoc, values: [GameSpot])]?
    private var cycleifs: [(cycle: GameSpot, values: [GameSpot])]?
    private var choicenames: [(name: String, dialogue: String, act: String, parent: String?)]?
    private var choices: [(choice: GameDialogue, act: String, line: String?)]?
    private var draws: [GameJSONDraw]?
    private var drawclear: [GameScreen]?
    private var showlocs: [GameJSONLoc]?
    private var shows: [SKSpriteNode]?
    private var hidelocs: [GameJSONLoc]?
    private var hides: [SKSpriteNode]?
    private var togglelocs: [GameJSONLoc]?
    private var toggles: [GameSpot]?
    private var transition: Bool = false
    
    init(name: String)
    {
        self.active = true
        self.saves = true
        self.name = name
    }
    
    func getSpot() -> CGRect?
    {
        return spot
    }
    
    func setSpot(spot: CGRect)
    {
        self.spot = spot
    }
    
    func getName() -> String
    {
        return name
    }
    
    func getActive() -> Bool
    {
        return active
    }
    
    func setActive(active: Bool)
    {
        self.active = active
    }
    
    func getSaves() -> Bool
    {
        return saves
    }
    
    func setSaves(saves: Bool)
    {
        self.saves = saves
    }
    
    func toggle()
    {
        active = !active
    }
    
    func getValue() -> Int?
    {
        return value
    }
    
    func setValue(value: Int)
    {
        self.value = value
    }
    
    func getFlag() -> String?
    {
        return flag
    }
    
    func setFlag(flag: String)
    {
        self.flag = flag
    }
    
    func getFlagAction(name: String) -> GameSpot?
    {
        if let flagactions = self.flagactions
        {
            for action in flagactions
            {
                if action.getName() == name { return action }
            }
        }
        return nil
    }
    
    func getFlagActions() -> [GameSpot]?
    {
        return flagactions
    }
    
    func setFlagActions(flagactions: [GameSpot])
    {
        self.flagactions = flagactions
    }
    
    func getSequenceAction(name: String) -> GameSpot?
    {
        if let sequenceactions = self.sequenceactions
        {
            for action in sequenceactions
            {
                if action.getName() == name { return action }
            }
        }
        return nil
    }
    
    func getSequenceActions() -> [GameSpot]?
    {
        return sequenceactions
    }
    
    func setSequenceActions(sequenceactions: [GameSpot])
    {
        self.sequenceactions = sequenceactions
    }
    
    func getRandom() -> GameSpot?
    {
        if let randoms = self.randoms
        {
            let rndm: Int = Int.random(in: 0..<randoms.count)
            return randoms[rndm]
        }
        return nil
    }
    
    func getRandoms() -> [GameSpot]?
    {
        return randoms
    }
    
    func setRandoms(randoms: [GameSpot])
    {
        self.randoms = randoms
    }
    
    func getSound() -> AVAudioPlayer?
    {
        return sound
    }
    
    func setSound(sound: AVAudioPlayer)
    {
        self.sound = sound
    }
    
    func setZoom(zoom: GameScreen)
    {
        self.zoom = zoom
    }
    
    func getZoom() -> GameScreen?
    {
        return zoom
    }
    
    func getPhoneZoom() -> GameJSONPhoneZoom?
    {
        return phonezoom
    }
    
    func setPhoneZoom(phonezoom: GameJSONPhoneZoom)
    {
        self.phonezoom = phonezoom
    }
    
    func getView() -> GameScreen?
    {
        return view
    }
    
    func setView(view: GameScreen)
    {
        self.view = view
    }
    
    func setObject(object: GameInvObj)
    {
        self.object = object
    }
    
    func getObject() -> GameInvObj?
    {
        return object
    }
    
    func setRemoves(removes: GameInvObj)
    {
        self.removes = removes
    }
    
    func getRemoves() -> GameInvObj?
    {
        return removes
    }
    
    func getAnimateName() -> String?
    {
        return animatename
    }
    
    func setAnimateName(animatename: String)
    {
        self.animatename = animatename
    }
    
    func getAnimate() -> GameJSONAnimation?
    {
        return animate
    }
    
    func setAnimate(animate: GameJSONAnimation)
    {
        self.animate = animate
    }
    
    func getSelectable() -> SKSpriteNode?
    {
        return selectable
    }
    
    func setSelectable(selectable: SKSpriteNode)
    {
        self.selectable = selectable
    }
    
    func setSelects(selects: [GameSpot])
    {
        self.selects = selects
    }
    
    func getSelect(select: String) -> GameSpot?
    {
        if let selects = self.selects
        {
            for spot in selects
            {
                if spot.getName() == select
                {
                    return spot
                }
            }
        }
        return nil
    }
    
    func getSelects() -> [GameSpot]?
    {
        return selects
    }
    
    func getSpeech() -> [GameJSONSpeech]?
    {
        return speech
    }
    
    func getInvDisplay() -> [String]?
    {
        return invdisplay
    }
    
    func setInvDisplay(invdisplay: [String])
    {
        self.invdisplay = invdisplay
    }
    
    func getSequence() -> String?
    {
        return sequence
    }
    
    func setSequence(sequence: String)
    {
        self.sequence = sequence
    }
    
    func getSpeechLine() -> String?
    {
        if let speech = self.speech
        {
            speechcounter! = (speechcounter! + 1) % speech.count
            return speech[speechcounter!].line
        }
        else
        {
            return nil
        }
    }
    
    func setSpeech(speech: [GameJSONSpeech])
    {
        self.speech = speech
        self.speechcounter = speech.count - 1
    }
    
    func getDialogueName() -> String?
    {
        return dialoguename
    }
    
    func setDialogueName(dialoguename: String)
    {
        self.dialoguename = dialoguename
    }
    
    func getDialogue() -> GameDialogue?
    {
        return dialogue
    }
    
    func setDialogue(dialogue: GameDialogue)
    {
        self.dialogue = dialogue
    }
    
    func getCycleLocs() -> [GameJSONCycle]?
    {
        return cyclelocs
    }
    
    func setCycleLocs(cyclelocs: [GameJSONCycle])
    {
        self.cyclelocs = cyclelocs
    }
    
    func getCycle() -> [[SKSpriteNode?]]?
    {
        return cycle
    }
    
    func setCycle(cycle: [[SKSpriteNode?]])
    {
        self.cycle = cycle
        self.cyclecounter = 0
    }
    
    func hasCycle() -> Bool
    {
        if cyclecounter != nil
        {
            return true
        }
        return false
    }
    
    func getCycleCounter() -> Int?
    {
        return cyclecounter
    }
    
    func incrementCycle()
    {
        if let cycle: [[SKSpriteNode?]] = self.cycle
        {
            for currcycle in cycle
            {
                if let sub: SKSpriteNode = currcycle[cyclecounter!] { sub.isHidden = true }
                if let sub: SKSpriteNode = currcycle[(cyclecounter! + 1) % cycle[0].count]{ sub.isHidden = false }
            }
            cyclecounter! = (cyclecounter! + 1) % cycle[0].count
        }
    }
    
    func decrementCycle()
    {
        if let cycle: [[SKSpriteNode?]] = self.cycle
        {
            cyclecounter! = (cyclecounter! - 1)
            if cyclecounter! == -1 { cyclecounter! = cycle[0].count - 1}
            for currcycle in cycle
            {
                if let sub: SKSpriteNode = currcycle[(cyclecounter! + 1) % cycle[0].count] { sub.isHidden = true }
                if let sub: SKSpriteNode = currcycle[cyclecounter!] { sub.isHidden = false }
            }
        }
    }
    
    func setCycleCounter(count: Int)
    {
        if count == 0 { return }
        for _ in 1...count {
            incrementCycle()
        }
    }
    
    func getCycleRev() -> GameSpot?
    {
        return cyclerev
    }
    
    func setCycleRev(cyclerev: GameSpot)
    {
        self.cyclerev = cyclerev
    }
    
    func getCycleRevName() -> String?
    {
        return cyclerevname
    }
    
    func setCycleRevName(cyclerevname: String)
    {
        self.cyclerevname = cyclerevname
    }
    
    func getCycleIfNames() -> [(cycle: GameJSONLoc, values: [GameSpot])]?
    {
        return cycleifnames
    }
    
    func setCycleIfNames(cycleifnames: [(cycle: GameJSONLoc, values: [GameSpot])])
    {
        self.cycleifnames = cycleifnames
    }
    
    func getCycleIfs() -> [(cycle: GameSpot, values: [GameSpot])]?
    {
        return cycleifs
    }
    
    func setCycleIfs(cycleifs: [(cycle: GameSpot, values: [GameSpot])])
    {
        self.cycleifs = cycleifs
    }
    
    func getChoices() -> [(choice: GameDialogue, act: String, line: String?)]?
    {
        return choices
    }
    
    func setChoices(choices: [(choice: GameDialogue, act: String, line: String?)])
    {
        self.choices = choices
    }
    
    func getChoiceNames() -> [(name: String, dialogue: String, act: String, parent: String?)]?
    {
        return choicenames
    }
    
    func setChoiceNames(choicenames: [(name: String, dialogue: String, act: String, parent: String?)])
    {
        self.choicenames = choicenames
    }
    
    func getDraws() -> [GameJSONDraw]?
    {
        return draws
    }
    
    func setDraws(draws: [GameJSONDraw])
    {
        self.draws = draws
    }
    
    func getDrawClear() -> [GameScreen]?
    {
        return drawclear
    }
    
    func setDrawClear(drawclear: [GameScreen])
    {
        self.drawclear = drawclear
    }
    
    func getShows() -> [SKSpriteNode]?
    {
        return shows
    }
    
    func setShows(shows: [SKSpriteNode])
    {
        self.shows = shows
    }
    
    func getShowLocs() -> [GameJSONLoc]?
    {
        return showlocs
    }
    
    func setShowLocs(showlocs: [GameJSONLoc])
    {
        self.showlocs = showlocs
    }
    
    func getHides() -> [SKSpriteNode]?
    {
        return hides
    }
    
    func getHideLocs() -> [GameJSONLoc]?
    {
        return hidelocs
    }
    
    func setHideLocs(hidelocs: [GameJSONLoc])
    {
        self.hidelocs = hidelocs
    }
    
    func setHides(hides: [SKSpriteNode])
    {
        self.hides = hides
    }
    
    func getToggleLocs() -> [GameJSONLoc]?
    {
        return togglelocs
    }
    
    func setToggleLocs(togglelocs: [GameJSONLoc])
    {
        self.togglelocs = togglelocs
    }

    func getToggles() -> [GameSpot]?
    {
        return toggles
    }
    
    func setToggles(toggles: [GameSpot])
    {
        self.toggles = toggles
    }
    
    func getTransition() -> Bool
    {
        return transition
    }
    
    func setTransition(transition: Bool)
    {
        self.transition = transition
    }
}
