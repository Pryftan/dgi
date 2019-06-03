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

let Config = ParseConfig()
var sceneorder = Next<String>(["cuts1", "cabin", "cuts2", "endroom", "cuts3"])

class ParseConfig {
    
    var bounds: CGSize
    let scale: CGFloat
    let textspeed: TimeInterval
    let subtitle: (text: CGFloat, y: CGFloat)
    let inv: (unit: CGFloat, space: CGFloat, scale: CGFloat)
    let dialogue: (text: CGFloat, space: CGFloat, rows: CGFloat)
    let avatarspace: CGFloat
    
    init (jsonFile: String = "config") {
        do {
            let config = try JSONDecoder().decode(DGIJSONConfig.self, from: Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: jsonFile, ofType: "json")!)))
            bounds = CGSize(width: config.basewidth, height: config.baseheight)
            scale = config.scale
            textspeed = config.textspeed
            subtitle = (config.subtitletext * config.scale, config.subtitley * config.scale)
            inv = (config.invunit * config.invscale * config.scale, config.invspace * config.invscale * config.scale, config.invscale * config.scale)
            dialogue = (config.dialoguetext * config.scale, config.dialoguespace * config.scale, config.dialoguerows)
            avatarspace = config.avatarspace
        } catch {
            print("Error loading default config.")
            bounds = CGSize(width: 1920, height: 1080)
            scale = 1
            textspeed = 5
            subtitle = (46, 200)
            inv = (100, 25, 1)
            dialogue = (42, 20, 5)
            avatarspace = 40
        }
    }
}

struct DGIJSONConfig: Decodable {
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
    let music: String?
    let screens: [DGIJSONScreen]
    let globanims: [DGIJSONAnimation]?
    let objects: [DGIJSONInvObj]
    let states: [DGIJSONGrid]?
    let dialogues: [DGIJSONDialogue]?
}

struct DGIJSONVoid: Decodable {
    let name: String
    let music: String?
    let delay: Double?
    let images: [DGIJSONSub]?
    let dialogue: [DGIJSONDialogue]
}

struct DGIJSONScreen: Decodable {
    let name: String
    let image: String
    let left: String?
    let right: String?
    let back: String?
    let backaction: String?
    let sequence: Int?
    let subs: [DGIJSONSub]?
    let grid: [DGIJSONGrid]?
}

struct DGIJSONSub: Decodable {
    let name: String
    let displayname: String?
    let image: String
    let sub: [CGFloat]
    let visible: Bool?
    let setZ: CGFloat?
    let rotate: CGFloat?
    let opacity: CGFloat?
    let anchor: [CGFloat]?
    let subsubs: [DGIJSONSub]?
    let frames: [DGIJSONFrame]?
    let running: Bool?
    let type: String?
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
    var randoms: [DGIJSONGrid]?
    let sound: String?
    let zoom: String?
    let phonezoom: [CGFloat]?
    let view: String?
    let subgrid: [DGIJSONGrid]?
    let subsubs: [DGIJSONSub]?
    let object: String?
    let removes: String?
    let animate: String?
    let selectable: String?
    let selects: [DGIJSONGrid]?
    let invdisplay: [String]?
    let sequence: String?
    let speech: [DGIJSONSpeech]?
    var speechcounter: Int?
    let dialogue: String?
    let cycle: [DGIJSONCycle]?
    var cyclecounter: Int!
    let cyclerev: String?
    let cycleif: [DGIJSONCycleIf]?
    let choices: [DGIJSONChoice]?
    let draws: [DGIJSONDraw]?
    let drawclear: [String]?
    let shows: [DGIJSONLoc]?
    let hides: [DGIJSONLoc]?
    let toggles: [DGIJSONLoc]?
    let transition: Bool?
    let type: DGIStateType?
    let screen: String?
    let match: String?
    let cycles: [DGIJSONCycleState]?
    let visibles: [DGIJSONVisible]?
    let flags: [DGIJSONFlagState]?
    
}

struct DGIJSONLoc: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
}

struct DGIJSONSpeech: Decodable {
    let line: String
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


struct DGIJSONCycle: Decodable {
    let parent: String
    let subs: [DGIJSONCycleSub]
}

struct DGIJSONCycleSub : Decodable {
    let sub: String
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
    let draw: String
    let maxoff: Int
    let pos: [CGFloat]
}

struct DGIParsedState {
    let name: String
    let type: DGIStateType
    let sequencescreen: DGIRoomNode?
    let sequence: String?
    let visibles: [(sub: DGIRoomSub, vis: Bool)]?
    let cycles: [(screen: DGIRoomNode, index: Int, val: Int)]?
    let flags: [DGIJSONFlagState]?
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
}

struct DGIJSONCycleState: Decodable {
    let name: String
    let parent: String
    let grandparent: String?
    let cycle: Int
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
    var frames: [DGIJSONFrame]
}

struct DGIJSONFrame: Decodable {
    let frame: String
    let name: String?
    let parent: String?
    let grandparent: String?
    let pos: [CGFloat]?
    let sound: String?
    let pauses: Bool?
    let subs: [String]?
    let duration: Double
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
