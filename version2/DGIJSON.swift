//
//  DGIJSON.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class ParseConfig {
    
    let name: String
    var bounds: CGSize
    let scale: CGFloat
    let textspeed: TimeInterval
    let subtitle: (text: CGFloat, y: CGFloat)
    let inv: (unit: CGFloat, space: CGFloat, scale: CGFloat)
    let dialogue: (text: CGFloat, space: CGFloat, rows: CGFloat)
    let avatarspace: CGFloat
    var volume: (music: Float, effect: Float) {
        didSet {
            GameSave.autosave.volume = [volume.music, volume.effect]
        }
    }
    
    init (jsonFile: String = "config") {
        do {
            let config = try JSONDecoder().decode(DGIJSONConfig.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: jsonFile, ofType: "json")!)))
            name = config.name
            bounds = CGSize(width: config.basewidth, height: config.baseheight)
            scale = config.scale
            textspeed = config.textspeed
            subtitle = (config.subtitletext * config.scale, config.subtitley * config.scale)
            inv = (config.invunit * config.invscale * config.scale, config.invspace * config.invscale * config.scale, config.invscale * config.scale)
            dialogue = (config.dialoguetext * config.scale, config.dialoguespace * config.scale, config.dialoguerows)
            avatarspace = config.avatarspace
            volume = (GameSave.autosave.volume[0], GameSave.autosave.volume[1])
        } catch {
            print("Error loading default config.")
            name = ""
            bounds = CGSize(width: 1920, height: 1080)
            scale = 1
            textspeed = 5
            subtitle = (46, 200)
            inv = (100, 25, 1)
            dialogue = (42, 20, 5)
            avatarspace = 40
            volume = (0.5, 1)
        }
    }
}

struct DGIJSONConfig: Decodable {
    let name: String
    let basewidth: CGFloat
    let baseheight: CGFloat
    let scale: CGFloat
    let textspeed: TimeInterval
    let subtitletext: CGFloat
    let subtitley: CGFloat
    let invunit: CGFloat
    let invspace: CGFloat
    let invscale: CGFloat
    let dialoguetext: CGFloat
    let dialoguespace: CGFloat
    let dialoguerows: CGFloat
    let avatarspace: CGFloat
}

struct DGIJSONRoom: Decodable {
    let name: String
    let start: String
    let invsounds: [String]
    let music: [String]?
    let debugitems: [String]?
    let screens: [DGIJSONScreen]
    let sharedactions: [DGIJSONGrid]?
    let globanims: [DGIJSONAnimation]?
    let objects: [DGIJSONInvObj]
    let states: [DGIJSONGrid]?
    let dialogues: [DGIJSONDialogue]?
}

struct DGIJSONVoid: Decodable {
    let name: String
    let music: String?
    let delay: Double?
    let preload: [String]?
    let images: [DGIJSONSub]?
    let dialogue: [DGIJSONDialogue]
}

struct DGIJSONMenu: Decodable {
    let name: String
    let music: String?
    let scenes: [String]
    let images: [DGIJSONSub]
}

struct DGIJSONScreen: Decodable {
    let name: String
    let image: String
    let left: String?
    let right: String?
    let back: String?
    let backaction: String?
    let onaction: String?
    let sequence: Int?
    let sequencedraw: DGIJSONSequenceDraw?
    let subs: [DGIJSONSub]?
    let grid: [DGIJSONGrid]?
    let wait: [DGIJSONMove]?
    let gearbox: DGIJSONGearBox?
}

struct DGIJSONSub: Decodable {
    let name: String
    let displayname: String?
    let image: String
    let sub: [CGFloat]
    let visible: Bool?
    var preload: Bool?
    let setZ: CGFloat?
    let rotate: CGFloat?
    let alpha: CGFloat?
    let anchor: [CGFloat]?
    let contains: String?
    let blur: CGFloat?
    let drags: DGIJSONDrags?
    let subsubs: [DGIJSONSub]?
    let special: [DGIJSONSpecialLoc]?
    let label: DGIJSONLabel?
    let solve: DGIJSONGrid?
    let frames: [DGIJSONFrame]?
    let running: Bool?
    let type: String?
    let clock: String?
}

enum DGISpecialType: String {
    case counter = "counter"
    case scramble = "scramble"
    case guessnos = "guessnos"
    case slidebox = "slidebox"
}

enum DGIStateType: String, Codable {
    case once, cont, wrong
}

class DGIJSONGrid: Decodable {
    let name: String
    let pos: [CGFloat]?
    var active: Bool?
    let saves: Bool?
    let value: Int?
    let flag: String?
    let flagactions: [DGIJSONGrid]?
    let sequenceactions: [DGIJSONGrid]?
    let contents: [DGIJSONContents]?
    var randoms: [[DGIJSONGrid]]?
    let sharedaction: String?
    let sharedafter: String?
    let sound: String?
    let zoom: String?
    let swipe: String?
    let phonezoom: [CGFloat]?
    let view: String?
    let subgrid: [DGIJSONGrid]?
    let subsubs: [DGIJSONSub]?
    let object: String?
    let removes: String?
    let animate: String?
    let animoffset: [CGFloat]?
    let selectable: String?
    let selects: [DGIJSONGrid]?
    let invdisplay: [String]?
    let special: Int?
    let color: [DGIJSONColor]?
    let sequence: String?
    let container: [DGIJSONContainer]?
    let speech: [DGIJSONSpeech]?
    var speechcounter: Int?
    let dialogue: String?
    let music: [DGIJSONMusic]?
    let cycle: [DGIJSONCycle]?
    var cyclecounter: Int!
    let cyclerev: String?
    let cycleif: [DGIJSONCycleIf]?
    let choices: [DGIJSONChoice]?
    let draws: [DGIJSONDraw]?
    let drawclear: [String]?
    var drawcolor: String?
    let drawchange: [DGIJSONColor]?
    let down: DGIJSONCycleIf?
    let shows: [DGIJSONLoc]?
    let hides: [DGIJSONLoc]?
    let toggles: [DGIJSONLoc]?
    let moves: [DGIJSONMove]?
    let transition: Bool?
    let type: DGIStateType?
    let screen: String?
    let match: String?
    let cycles: [DGIJSONCycleState]?
    let visibles: [DGIJSONVisible]?
    let flags: [DGIJSONFlagState]?
    let setflags: [DGIJSONFlagState]?
    let containers: [DGIJSONContentsState]?
}

struct DGIJSONSequenceDraw: Decodable {
    let characters: [String]
    let positions: [DGIJSONSubList]
}

struct DGIJSONSubList: Decodable {
    let subs: [String]
}

struct DGIJSONLoc: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
}

enum DGIDragType: String, Codable {
    case dragX, dragY, free, rotate
}

struct DGIJSONDrags: Decodable {
    let dragtype: DGIDragType
    let dragbeds: [Int]?
    let dragrect: [CGFloat]?
    let dragrot: CGFloat?
    let dragcycle: [DGIJSONCycle]?
    let dragaction: String?
}

struct DGIJSONSpecialLoc: Decodable {
    let name: String
    let parent: String?
    let pos: [CGFloat]
    let active: Bool?
    let scramble: DGIJSONScramble?
    let guessnos: DGIJSONGuessNos?
    let slidebox: DGIJSONSlideBox?
    let counter: DGIJSONLabel?
}

struct DGIJSONScramble: Decodable {
    let image: String
}

struct DGIJSONGuessNos: Decodable {
    let numbers: [String]
    let lights: [String]
    let header: String
}

struct DGIJSONSlideBox: Decodable {
    let size: Int
    let images: [String]
    let locations: [[[Int]]]
}

struct DGIJSONLabel: Decodable {
    let font: String?
    let size: CGFloat?
    let text: String?
    let color: String?
    let alpha: CGFloat?
    let align: String?
}

struct DGIJSONColor: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let color: String?
    let alpha: CGFloat?
}

struct DGIJSONSpeech: Decodable {
    let line: String
    let frequency: Double?
    let offset: CGFloat?
    let boxalpha: CGFloat?
}

struct DGIJSONInvObj: Decodable {
    let name: String
    let displayname: String?
    let image: String
    let scale: CGFloat
    let collects: [String]?
    let animations: [DGIJSONAnimation]?
    let subs: [DGIJSONInvSub]?
}

struct DGIJSONInvSub: Decodable {
    let name: String
    let image: String
    let visible: Bool?
    let relZ: CGFloat?
}

struct DGIJSONContainer: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let add: String?
    let fill: String?
    let addpiece: String?
    let addfrom: DGIJSONLoc?
    let addmax: String?
    let addfail: DGIJSONGrid?
}

struct DGIJSONContents: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let values: [DGIJSONGrid]
}

struct DGIJSONMusic: Decodable {
    let name: String
    let on: Bool
    let fade: Double?
}

struct DGIJSONCycle: Decodable {
    let parent: String
    let subs: [DGIJSONCycleSub]
}

struct DGIJSONCycleSub : Decodable {
    let sub: String
    let label: String?
}

struct DGIJSONCycleIf: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let values: [DGIJSONGrid]
}

struct DGIJSONDraw: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let draw: String
    let maxoff: Int
    let pos: [CGFloat]
}

struct DGIJSONMove: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let pos: [CGFloat]
}

struct DGIParsedState {
    let name: String
    let type: DGIStateType
    let sequencescreen: DGIRoomNode?
    let sequence: String?
    let visibles: [(sub: DGIRoomSub?, vis: Bool, name: String?, parent: String?, color: UIColor?)]?
    let cycles: [(screen: DGIRoomNode, index: Int, val: Int)]?
    let flags: [DGIJSONFlagState]?
    let containers: [(sub: DGIRoomSub?, label: SKLabelNode?, values: [String])]?
    let saves: Bool?
    var action: DGIJSONGrid
}

struct DGIJSONFlagState: Decodable {
    let name: String
    let value: Bool
}

struct DGIJSONVisible: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let visible: Bool
    let color: String?
}

struct DGIJSONCycleState: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let cycle: Int
}

struct DGIJSONContentsState: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let values: [String]
}

enum DGIChoiceType: String, Codable {
    case enable, disable, remove
}

struct DGIJSONChoice: Decodable {
    let name: String
    let dialogue: String
    let type: DGIChoiceType
    let parent: String?
}

enum DGIFrameType {
    case temp, permscreen, permsub
}

struct DGIJSONAnimation: Decodable {
    let name: String
    var freeze: Bool?
    let running: Bool?
    let frequency: Double?
    let offset: Double?
    var frames: [DGIJSONFrame]
}

struct DGIJSONFrame: Decodable {
    let frame: String
    let name: String?
    let parent: String?
    let grandparent: String?
    let pos: [CGFloat]?
    let sound: String?
    let color: String?
    let colorblend: CGFloat?
    let pauses: Bool?
    let reset: Bool?
    let subs: [String]?
    let duration: Double
    let offset: Double?
    let chain: String?
    let flag: String?
    let flagframes: [DGIJSONFrame]?
}

struct DGIJSONDialogue: Decodable {
    let name: String
    let type: String?
    var lines: [DGIJSONLine]?
    var branch: [DGIJSONBranch]?
    var sharedexit: [DGIJSONGrid]?
}

struct DGIJSONLine: Decodable {
    let name: String
    var active: Bool?
    let character: String
    let line: String
    let duration: Double
    let skippable: Bool?
    let randoms: [DGIJSONLine]?
}

enum DGIBranchType: String, Codable {
    case remove, cont
}

class DGIJSONBranch: Decodable {
    let name: String
    let text: String?
    let type: DGIBranchType?
    var active: Bool?
    let exittype: String?
    var lines: [DGIJSONLine]?
    var branch: [DGIJSONBranch]?
    var action: [DGIJSONGrid]?
}

struct DGIJSONGearBox: Decodable {
    let name: String
    let front: String?
    let pos: [CGFloat]
    let flag: String?
    let solve: String?
    let clearsolve: Bool?
    let speed: Double
    let geartypes: [DGIJSONGearType]
    let gears: [DGIJSONGear]
    let pegimage: String
    let pegextra: Int?
    let pegs: [[CGFloat]]
}

struct DGIJSONGearType: Decodable {
    let name: String
    let image: String
    let teeth: Int
    let radius: CGFloat
}

struct DGIJSONGear: Decodable {
    let type: String
    let name: String?
    let pos: [CGFloat]
    let running: Int?
    let fixed: Bool?
}

enum DGIClockType: String {
    case hour = "hour"
    case minute = "minute"
}
