//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let side = min(width, height) / 2
        let x = rect.midX
        let y = rect.midY
        path.move(to: CGPoint(x: x + side, y: y))
        for theta in ((1...6).map { CGFloat($0) * Double.pi / 3.0 }) {
            path.addLine(to: CGPoint(x: x + side * cos(theta), y: y + side * sin(theta)))
        }
        
        path.closeSubpath()
        return path
    }
}

/// From: https://swdevnotes.com/swift/2021/create-blob-shape-in-swiftui/
struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let xOffset = (rect.width > rect.height) ? (rect.width - rect.height) / 2.0 : 0.0
        let yOffset = (rect.height > rect.width) ? (rect.height - rect.width) / 2.0 : 0.0

        func offsetPoint(p: CGPoint) -> CGPoint {
            return CGPoint(x: p.x + xOffset, y: p.y+yOffset)
        }
        var path = Path()

        path.move(to: offsetPoint(p: (CGPoint(x: (size * 0.50), y: (size * 0.25)))))
        path.addCurve(to: offsetPoint(p: CGPoint(x: 0, y: (size * 0.25))),
                      control1: offsetPoint(p: CGPoint(x: (size * 0.50), y: (-size * 0.10))),
                      control2: offsetPoint(p: CGPoint(x: 0, y: 0)))
        path.addCurve(to: offsetPoint(p: CGPoint(x: (size * 0.50), y: size)),
                      control1: offsetPoint(p: CGPoint(x: 0, y: (size * 0.60))),
                      control2: offsetPoint(p: CGPoint(x: (size * 0.50), y: (size * 0.80))))
        path.addCurve(to: offsetPoint(p: CGPoint(x: size, y: (size * 0.25))),
                      control1: offsetPoint(p: CGPoint(x: (size * 0.50), y: (size * 0.80))),
                      control2: offsetPoint(p: CGPoint(x: size, y: (size * 0.60))))
        path.addCurve(to: offsetPoint(p: CGPoint(x: (size * 0.50), y: (size * 0.25))),
                      control1: offsetPoint(p: CGPoint(x: size, y: 0)),
                      control2: offsetPoint(p: CGPoint(x: (size * 0.50), y: (-size * 0.10))))
        return path
    }
}

struct Blob1: Shape {
    
    var count: Int
    var points: Array<CGPoint>
    
    init(count: Int) {
        self.count = count
        
        let sigma = 2 * CGFloat.pi / CGFloat(count)
        
        points = Array((0...count).map { i in
            let theta =  CGFloat.random(in: 0.95...1.05) * CGFloat(i) * sigma
            let mx = 0.7 * CGFloat.random(in: 0.95...1)
            let my = 0.7 * CGFloat.random(in: 0.75...0.95)
            return CGPoint(x: mx * cos(theta), y: my * sin(theta))
        })
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let side = min(width, height) / 2
        let x = rect.midX
        let y = rect.midY
        
        path.move(to: CGPoint(x: x + side * points[0].x, y: y + side * points[0].y))
        
        for (i, point) in points.enumerated() {
            let c = points[(i+1) % count]

            path.addQuadCurve(
                to: CGPoint(x: x + side * c.x, y: y + side * c.y),
                control: CGPoint(x: x + 2 * side * point.x, y: y + 1.5 * side * point.y)
            )
        }
        
        path.closeSubpath()
        return path
    }
}

struct Blob2: Shape {
    
    var count: Int
    var points: Array<CGPoint>
    
    enum Problem: Error {
        case NotEnoughPoints
    }
    
    init(count: Int) throws {
        
        guard count > 2 else { throw Problem.NotEnoughPoints }
        
        self.count = count
        
        let sigma = 2 * CGFloat.pi / CGFloat(count)
        
        let ps = Array((0..<count).map { i in
            let theta =  CGFloat.random(in: 0.95...1.05) * CGFloat(i) * sigma
            let mx = CGFloat.random(in: 0.95...1)
            let my = CGFloat.random(in: 0.75...1)
            return CGPoint(x: mx * cos(theta), y: my * sin(theta))
        })
        
        points = ps
    }
    
    static func avg(_ pa: CGPoint, _ pb: CGPoint) -> CGPoint {
        return CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2)
    }
    
    static func scale(_ x: CGFloat, _ y: CGFloat, _ sx: CGFloat, _ sy: CGFloat) -> ((_ p: CGPoint) -> CGPoint) {
        return { p in
            CGPoint(x: x + sx * p.x, y: y + sy * p.y)
        }
    }
    
    static func sub(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
    }
    
    static func add(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: p2.x + p1.x, y: p2.y + p1.y)
    }
    
    static func control1(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
        let an = Blob2.sub(a,b)
        let cn = Blob2.sub(c,b)
        let m = avg(an, cn)
        let n = CGPoint(x: 0 - m.y, y: m.x)
        let s = Blob2.scale(0, 0, 0.7, 0.7)
        let o = s(n)
        return Blob2.add(o,b)
    }
    
    static func control2(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
        let an = Blob2.sub(a,b)
        let cn = Blob2.sub(c,b)
        let m = avg(an, cn)
        let n = CGPoint(x: m.y, y: 0 - m.x)
        let s = Blob2.scale(0, 0, 0.7, 0.7)
        let o = s(n)
        return Blob2.add(o,b)
    }
    
    func bendy(_ i: Int) -> (CGPoint, CGPoint) {
        let c = points.count
        let pa = points[(i + c - 2) % c]
        let pb = points[(i + c - 1) % c]
        let pc = points[i]
        let pd = points[(i + 1) % c]
        let p1 = Blob2.control1(pa, pb, pc)
        let p2 = Blob2.control2(pb, pc, pd)
        return (p1, p2)
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w2 = rect.width / 2
        let h2 = rect.height / 2
        let x = rect.midX
        let y = rect.midY
        let s = Blob2.scale(x, w2, y, h2)
        
        path.move(to: s(points[points.count - 1]))
        
        for (i, point) in points.enumerated() {
            let (p1, p2) = bendy(i)
            path.addCurve(to: s(point), control1: s(p1), control2: s(p2))
        }
        
        path.closeSubpath()
        return path
    }
}

struct Shapes_Previews: PreviewProvider {

    static var previews: some View {

        VStack {
            HStack {
                Circle()
                Rectangle()
                Hexagon()
            }
            HStack {
                Heart()
                Blob1(count: 10)
                try! Blob2(count: 7)
            }
        }
    }
}
