//
//  GameData.swift
//  GameTest1
//
//  Created by William Frank on 8/28/18.
//  Copyright © 2018 William Frank. All rights reserved.
//

import SpriteKit

struct GameJSONConfig: Decodable
{
    init (basewidth: CGFloat = 1920, baseheight: CGFloat = 1080, scale: CGFloat = 1, subtitletext: CGFloat = 46, subtitley: CGFloat = 200, sidepx: CGFloat = 200, textspeed: Double = 5, invunit: CGFloat = 100, invspace: CGFloat = 25, invscale: CGFloat = 1.5, dialoguetext: CGFloat = 46, dialoguespace: CGFloat = 20, dialoguerows: CGFloat = 5, avatarspace: CGFloat = 40)
    {
        self.basewidth = basewidth
        self.baseheight = baseheight
        self.scale = scale
        self.subtitletext = subtitletext
        self.subtitley = subtitley
        self.sidepx = sidepx
        self.textspeed = textspeed
        self.invunit = invunit
        self.invspace = invspace
        self.invscale = invscale
        self.dialoguetext = dialoguetext
        self.dialoguespace = dialoguespace
        self.dialoguerows = dialoguerows
        self.avatarspace = avatarspace
    }
    
    let basewidth: CGFloat
    let baseheight: CGFloat
    let scale: CGFloat
    let subtitletext: CGFloat
    let subtitley: CGFloat
    let sidepx: CGFloat
    let textspeed: Double
    let invunit: CGFloat
    let invspace: CGFloat
    let invscale: CGFloat
    let dialoguetext: CGFloat
    let dialoguespace: CGFloat
    let dialoguerows: CGFloat
    let avatarspace: CGFloat
}

struct GameJSONPart: Decodable
{
    let name: String
    let start: String
    let invsounds: [String]
    let music: String?
    let screens: [GameJSONScreen]
    let objects: [GameJSONInvObj]
    let globanims: [GameJSONAnimation]?
    let states: [GameJSONState]?
    let flickers: [GameJSONFlicker]?
    let gearboxes: [GameJSONGearbox]?
    let dialogues: [GameJSONDialogue]?
}

struct GameJSONCutscene: Decodable
{
    let name: String
    let music: String?
    let delay: Double?
    let images: [GameJSONSub]?
    let dialogue: [GameJSONDialogue]
}

struct GameJSONScreen: Decodable
{
    let name: String
    let image: String
    let left: String?
    let right: String?
    let back: String?
    let backaction: String?
    let sequence: Int?
    let arcade: String?
    let subs: [GameJSONSub]?
    let grid: [GameJSONGrid]?
}

struct GameJSONSub: Decodable
{
    let name: String
    let displayname: String?
    let image: String
    let sub: [CGFloat]
    let rotate: CGFloat?
    let opacity: CGFloat?
    let anchor: [CGFloat]?
    var visible: Bool?
    let setZ: CGFloat?
    let subsubs: [GameJSONSub]?
    let running: Bool?
    let type: String?
    let frames: [GameJSONFrame]?
}

struct GameJSONGrid: Decodable
{
    let name: String
    let pos: [CGFloat]?
    let posX: CGFloat?
    let posY: CGFloat?
    let width: CGFloat?
    let height: CGFloat?
    var active: Bool?
    var saves: Bool?
    let value: Int?
    let flag: String?
    let flagactions: [GameJSONGrid]?
    let sequenceactions: [GameJSONGrid]?
    let randoms: [GameJSONGrid]?
    let sound: String?
    let zoom: String?
    let phonezoom: [GameJSONPhoneZoom]?
    let view: String?
    let subgrid: [GameJSONGrid]?
    let subsubs: [GameJSONSub]?
    let object: String?
    let removes: String?
    let animate: String?
    let selectable: String?
    let selects: [GameJSONGrid]?
    let invdisplay: [String]?
    let sequence: String?
    let speech: [GameJSONSpeech]?
    let dialogue: String?
    let cycle: [GameJSONCycle]?
    let cyclerev: String?
    let cycleif: [GameJSONCycleIf]?
    let choices: [GameJSONChoice]?
    let draws: [GameJSONDraw]?
    let drawclear: [String]?
    let shows: [GameJSONLoc]?
    let hides: [GameJSONLoc]?
    let toggles: [GameJSONLoc]?
    let transition: Bool?
}

struct GameJSONGearbox: Decodable
{
    let name: String
    let front: String?
    let pos: [CGFloat]
    let flag: String?
    let solve: [GameJSONGrid]?
    let clearsolve: Bool?
    let speed: Double
    let geartypes: [GameJSONGearType]
    let gears: [GameJSONGear]
    let pegimage: String
    let pegextra: Int?
    let pegs: [GameJSONPoint]
}

struct GameJSONGearType: Decodable
{
    let name: String
    let image: String
    let teeth: Int
    let radius: CGFloat
}

struct GameJSONGear: Decodable
{
    let type: String
    let name: String?
    let posX: CGFloat
    let posY: CGFloat
    let running: Int?
    let fixed: Bool?
}

struct GameJSONLoc: Decodable
{
    let name: String
    let parent: String
    let grandparent: String?
}

struct GameJSONPoint: Decodable
{
    let posX: CGFloat
    let posY: CGFloat
}

struct GameJSONPhoneZoom: Decodable
{
    let posX: CGFloat
    let posY: CGFloat
}

struct GameJSONSound: Decodable
{
    let sound: String
}

struct GameJSONSpeech: Decodable
{
    let line: String
}

struct GameJSONInvObj: Decodable
{
    let name: String
    let displayname: String?
    let image: String
    let scale: CGFloat
    let collects: [String]?
    let animations: [GameJSONAnimation]?
    let subs: [GameJSONInvSub]?
}

struct GameJSONInvSub: Decodable
{
    let name: String
    let image: String
    let visible: Bool?
    let relZ: CGFloat?
}

struct GameJSONName: Decodable
{
    let name: String
}

struct GameJSONAnimation: Decodable
{
    let name: String
    var freeze: Bool?
    var frames: [GameJSONFrame]
}

struct GameJSONFrame: Decodable
{
    let frame: String
    let name: String?
    let parent: String?
    let grandparent: String?
    let pos: [CGFloat]?
    let posX: CGFloat?
    let posY: CGFloat?
    let sound: String?
    let pauses: Bool?
    let subs: [String]?
    let duration: Double
    let chain: String?
    let flag: String?
    let flagframes: [GameJSONFrame]?
}

struct GameJSONImage: Decodable
{
    let image: String
}

struct GameJSONCycle: Decodable
{
    let parent: String
    let subs: [GameJSONCycleSub]
}

struct GameJSONCycleSub : Decodable
{
    let sub: String
}

struct GameJSONCycleIf: Decodable
{
    let name: String
    let parent: String
    let grandparent: String?
    let values: [GameJSONGrid]
}

struct GameJSONDraw: Decodable
{
    let name: String
    let parent: String
    let draw: String
    let maxoff: Int
    let pos: [CGFloat]?
    let posX: CGFloat?
    let posY: CGFloat?
}

struct GameJSONState: Decodable
{
    let name: String
    let type: String
    let active: Bool?
    let saves: Bool?
    let cycles: [GameJSONCycleState]?
    let visibles: [GameJSONVisible]?
    let flags: [GameJSONFlagState]?
    let flag: String?
    let screen: String?
    let match: String?
    let choices: [GameJSONChoice]?
    let animate: String?
    let object: String?
    let removes: String?
    let sequence: String?
    let shows: [GameJSONLoc]?
    let hides: [GameJSONLoc]?
    let toggles: [GameJSONLoc]?
    let transition: Bool?
}

struct GameParsedState
{
    let name: String
    let type: String
    let sequencescreen: GameScreen?
    let sequence: String?
    let visibles: [(sub: SKSpriteNode, vis: Bool)]?
    let cycles: [(spot: GameSpot, val: Int)]?
    let flags: [GameJSONFlagState]?
    let action: GameSpot?
}

struct GameJSONFlagState: Decodable
{
    let name: String
    let value: Bool
}

struct GameJSONVisible: Decodable
{
    let name: String
    let parent: String
    let grandparent: String?
    let visible: Bool
}

struct GameJSONCycleState: Decodable
{
    let name: String
    let parent: String
    let grandparent: String?
    let cycle: Int
}

struct GameJSONFlicker: Decodable
{
    let name: String
    let type: String
    let frequency: Double
    let subs: [GameJSONLoc]
}

struct GameParsedFlicker
{
    let name: String
    let type: String
    let frequency: Double
    let subs: [SKSpriteNode]
}

struct GameJSONDialogue: Decodable
{
    let name: String
    let type: String?
    let lines: [GameJSONLine]?
    let branch: [GameJSONBranch]?
    let sharedexit: [GameJSONGrid]?
}

struct GameJSONLine: Decodable
{
    let name: String
    var active: Bool?
    let character: String
    let line: String
    let duration: Double
    let skippable: Bool?
    let randoms: [GameJSONLine]?
}

struct GameJSONBranch: Decodable
{
    let name: String
    let text: String?
    let type: String?
    let active: Bool?
    let exittype: String?
    let lines: [GameJSONLine]?
    let branch: [GameJSONBranch]?
    let action: [GameJSONGrid]?
}

struct GameJSONChoice: Decodable
{
    let name: String
    let dialogue: String
    let type: String
    let parent: String?
}
