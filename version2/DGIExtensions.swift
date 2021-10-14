//
//  DGIExtensions.swift
//  DGI: Engine
//
//  Created by William Frank on 4/18/19.
//  Copyright © 2019 DGI. All rights reserved.
//

import Foundation
import SpriteKit

struct Point: Hashable {
    let x: CGFloat
    let y: CGFloat
    
    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

extension CGPoint {
    init(_ point: Point) {
        self.init(x: point.x, y: point.y)
    }
    
    func distance(to p: CGPoint) -> CGFloat {
        return sqrt(pow(x-p.x,2) + pow(y-p.y,2))
    }
}

extension CGFloat {
    func mod(_ by: Int) -> Int {
        let r = Int(self >= 0 ? self : self + CGFloat(by)) % by
        return r
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
    func intParse() -> [Int] {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).filter{$0.count > 0}.map{Int($0)!}
    }
    func stringParse() -> [String] {
        return components(separatedBy: CharacterSet.decimalDigits).filter{$0.count > 0}
    }
}

extension Array where Element == String {
    func merge(padding: Character = " ", length: Int? = nil) -> String {
        var result = ""
        for line in self { result += line }
        return result.leftPadding(toLength: length ?? count, withPad: padding)
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Element {
        return self[index(startIndex, offsetBy: offset)]
    }
}

extension Collection {
    //shouldn't be needed in a future Swift version
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    convenience init(hex: String) {
        let r, g, b: CGFloat
        
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
           let scanner = Scanner(string: hexColor)
           var hexNumber: UInt64 = 0
           
           if scanner.scanHexInt64(&hexNumber) {
               r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
               g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
               b = CGFloat((hexNumber & 0x0000ff)) / 255
            
                self.init(red: r, green: g, blue: b, alpha: 1)
                return
            }
        }
        self.init(rgb: 0)
    }
    
    convenience init(hex: String, from oldColor: UIColor?) {
        let r, g, b: CGFloat
        
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff)) / 255
                
                if hex.hasPrefix("#") {
                    self.init(red: r, green: g, blue: b, alpha: 1)
                    return
                } else if hex.hasPrefix("+"), let old = oldColor {
                    var or: CGFloat = 0
                    var og: CGFloat = 0
                    var ob: CGFloat = 0
                    var oa: CGFloat = 0
                    if old.getRed(&or, green: &og, blue: &ob, alpha: &oa) {
                        self.init(red: min(1, or + r), green: min(1, og + g), blue: min(1, ob + b), alpha: oa)
                        return
                    }
                } else if hex.hasPrefix("-"), let old = oldColor {
                    var or: CGFloat = 0
                    var og: CGFloat = 0
                    var ob: CGFloat = 0
                    var oa: CGFloat = 0
                    if old.getRed(&or, green: &og, blue: &ob, alpha: &oa) {
                        self.init(red: max(0, or - r), green: max(0, og - g), blue: max(0, ob - b), alpha: oa)
                        return
                    }
                }
            }
        }
        
        self.init(rgb: 0)
    }
    
    func equals (other: UIColor) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return (r1 - r2) < 0.0001 && (g1 - g2) < 0.0001 && (b1 - b2) < 0.0001 && (a1 - a2) < 0.0001
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

extension SKSpriteNode {
    
    convenience init(imageNamed: String, name: String) {
        self.init(imageNamed: imageNamed)
        self.name = name
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
    }
    
    convenience init(imageNamed: String, name: String, position: CGPoint) {
        self.init(imageNamed: imageNamed)
        self.name = name
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
        self.position = position
    }
    
    convenience init(imageNamed: String, name: String, position: CGPoint, size: CGSize) {
        self.init(imageNamed: imageNamed)
        self.name = name
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.setScale(Config.scale)
        self.position = position
        self.size = size
    }
    
    func addTint() {
        color = UIColor.green
        colorBlendFactor = 0.2
    }
    
    func clearTint() {
        color = UIColor.white
        colorBlendFactor = 1
    }
    
    func addOutline() {
        let outline = SKSpriteNode(texture: texture)
        outline.color = .yellow
        outline.zPosition = -0.01
        outline.setScale(1.2)
        addChild(outline)
    }
    
}

struct Next<T: Equatable> {
    private var data = [T]()
    private var counter = 0
    var next: T {
        mutating get {
            let curr = counter
            counter = (counter + 1) % data.count
            return data[curr]
        }
    }
    var now: T {
        get { return data[counter] }
    }
    var peek: T {
        get { return data[(counter + 1) % data.count] }
    }
    
    init(_ data: [T]) {
        self.data = data
    }
    
    mutating func set(_ element: T) {
        counter = 0
        while data[counter] != element { counter += 1; if counter > data.count { break } }
    }
    
    mutating func add(_ element: T) {
        data.append(element)
    }
    
    mutating func reset() {
        counter = 0
    }
    
    mutating func increment() {
        counter = (counter + 1) % data.count
    }
    
    mutating func decrement() {
        counter = counter == 0 ? data.count - 1 : counter - 1
    }
    
    mutating func setData(_ data: [T]) {
        self.data = data
    }
}
