//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

struct Shrinkable: Shape {
    var reference: any Shape
    var offset: CGFloat = 0
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let amount = offset * min(rect.width, rect.height) / 20
        return reference.path(in: rect.insetBy(dx: amount, dy: amount))
    }
}

struct NGon: Shape {
    var sides: Int
    var rotationRadians: CGFloat = .zero
    
    var animatableData: CGFloat {
        get { rotationRadians }
        set { rotationRadians = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let side = min(width, height) / 2
        let x = rect.midX
        let y = rect.midY
        let sidesF = CGFloat(sides)
        
        func at(_ theta: CGFloat) -> CGPoint {
            return CGPoint(x: x + side * Foundation.cos(theta), y: y + side * sin(theta))
        }
        
        path.move(to: at(rotationRadians))
        for n in (1...sides) {
            path.addLine(to: at(rotationRadians + 2 * Double.pi * CGFloat(n) / sidesF))
        }
        path.closeSubpath()
        return path
    }
}

struct RoundedRect: Shape {
    func path(in rect: CGRect) -> Path {
        let rr = RoundedRectangle(cornerRadius: max(rect.height, rect.width) / 6, style: .continuous)
        return rr.path(in: rect)
    }
}

extension Int {
    var degrees: Angle { return Angle(degrees: Double(self)) }
    var radians: Angle { return Angle(radians: Double(self)) }
}

struct Heart: Shape {
    
    // From https://developer.apple.com/tutorials/sample-apps/animatingshapes
    
    func path(in rect: CGRect) -> Path {
        let len = min(rect.width, rect.height)
        let sideOne = len * 0.4
        let sideTwo = len * 0.3
        let arcRadius = sqrt(sideOne*sideOne + sideTwo*sideTwo)/2

        var path = Path()
        
        //Left Hand Curve
        path.addArc(center: CGPoint(x: len * 0.3, y: len * 0.35), radius: arcRadius, startAngle: 135.degrees, endAngle: 315.degrees, clockwise: false)

        //Top Centre Dip
        path.addLine(to: CGPoint(x: len/2, y: len * 0.2))

        //Right Hand Curve
        path.addArc(center: CGPoint(x: len * 0.7, y: len * 0.35), radius: arcRadius, startAngle: 225.degrees, endAngle: 45.degrees, clockwise: false)

        //Right Bottom Line
        path.addLine(to: CGPoint(x: len * 0.5, y: len * 0.95))

        //Left Bottom Line
        path.closeSubpath()
        
        // Shunt the heart back to the middle of our frame
        // It would be better to just draw it in the right place, but then
        // I would have to understand how it's drawn like a chump.
        let br = path.boundingRect
        let deltaX = rect.midX - br.midX
        let deltaY = rect.midY - br.midY

        return path.transform(CGAffineTransform(translationX: deltaX, y: deltaY)).path(in: rect)
    }
}

struct Cloud: Shape {
    
    var count: Int
    var points: Array<CGPoint>
    
    init(count: Int) {
        self.count = count
        
        let sigma = 2 * CGFloat.pi / CGFloat(count)
        
        points = Array((0...count).map { i in
            let theta =  CGFloat.random(in: 0.95...1.05) * CGFloat(i) * sigma
            let d = 0.8 * CGFloat.random(in: 0.95...1)
            return CGPoint(x: d * cos(theta), y: d * sin(theta))
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

struct Blob: Shape {
    
    var count: Int
    var points: Array<CGPoint>
    var time: TimeInterval = .zero
    
    var animatableData: TimeInterval {
        get { time }
        set { time = newValue }
    }
    
    enum Problem: Error {
        case NotEnoughPoints
    }
    
    init(count: Int, time: TimeInterval = .zero) throws {
        
        guard count > 2 else { throw Problem.NotEnoughPoints }
        
        self.count = count
        
        let sigma = 2 * CGFloat.pi / CGFloat(count)
        
        let ps = Array((0..<count).map { i in
            let theta =  CGFloat.random(in: 0.95...1.05) * CGFloat(i) * sigma
            let d = CGFloat.random(in: 0.75...0.9)
            return CGPoint(x: d * cos(theta), y: d * sin(theta))
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
    
    static func mag(_ p1: CGPoint) -> CGFloat {
        return sqrt(p1.x * p1.x + p1.y * p1.y)
    }
    
    static func like(_ p1: CGPoint, _ times: CGFloat, magnitude p2: CGPoint) -> CGPoint {
        let p1mag = mag(p1)
        let p2mag = mag(p2)
        let ratio = times * p2mag / p1mag
        return CGPoint(x: ratio * p1.x, y: ratio * p1.y)
    }
    
    static func control1(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
        let an = Blob.sub(a,b)
        let cn = Blob.sub(c,b)
        let m = avg(an, cn)
        let n = CGPoint(x: 0 - m.y, y: m.x)
        let o = like(n, 0.5, magnitude: cn)
        return Blob.add(o,b)
    }
    
    static func control2(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
        let an = Blob.sub(a,b)
        let cn = Blob.sub(c,b)
        let m = avg(an, cn)
        let n = CGPoint(x: m.y, y: 0 - m.x)
        let o = like(n, 0.5, magnitude: an)
        return Blob.add(o,b)
    }
    
    static func bendy(_ points: Array<CGPoint>, _ i: Int) -> (CGPoint, CGPoint) {
        let c = points.count
        let pa = points[(i + c - 2) % c]
        let pb = points[(i + c - 1) % c]
        let pc = points[i]
        let pd = points[(i + 1) % c]
        let p1 = Blob.control1(pa, pb, pc)
        let p2 = Blob.control2(pb, pc, pd)
        return (p1, p2)
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w2 = rect.width / 2
        let h2 = rect.height / 2
        let x = rect.midX
        let y = rect.midY
        let s = Blob.scale(x, y, w2, h2)
        let ps = points.enumerated().map { (n,p) in
            CGPoint(x: p.x + 0.03 * Foundation.sin(time + Double(n)), y: p.y + 0.03 * cos(time + Double(n)))
        }
        
        path.move(to: s(ps[ps.count - 1]))
        
        for (i, point) in ps.enumerated() {
            let (p1, p2) = Blob.bendy(points,i)
            path.addCurve(to: s(point), control1: s(p1), control2: s(p2))
        }
        
        path.closeSubpath()
        return path
    }
}

enum ShapeType: String, CaseIterable {
    case circle
    case rectangle
    case capsule
    case ellipse
    case hexagon
    case heart
    case cloud
    case blob
}

func mkShape(_ t: ShapeType) -> AnyShape {
    switch t {
    case .circle:    return AnyShape(Circle())
    case .rectangle: return AnyShape(RoundedRect())
    case .capsule:   return AnyShape(Capsule())
    case .ellipse:   return AnyShape(Ellipse())
    case .hexagon:   return AnyShape(NGon(sides: 6))
    case .heart:     return AnyShape(Heart())
    case .cloud:     return AnyShape(Cloud(count: 10))
    case .blob:      return AnyShape(try! Blob(count: 7))
    }
}

func mkEvolvingShape(_ t: ShapeType) -> ((TimeInterval) -> AnyShape) {
    switch t {
        
    case .hexagon:
        var reference = NGon(sides: 5)
        return {
            reference.rotationRadians = $0 / 10
            return AnyShape(reference)
        }
        
    case .heart:
        let reference = Heart()
        return {
            let s = Shrinkable(reference: reference, offset: (1+CGFloat(sin($0 * 3))) / 2)
            return AnyShape(s)
        }
        
    case .blob:
        var reference = try! Blob(count: 7)
        return {
            reference.time = $0
            return AnyShape(reference)
        }
    
    // Everything that isn't special-cased is a regular Shrinkable with a 2s period
    default:
        let reference = mkShape(t)
        return {
            let s = Shrinkable(reference: reference, offset: (1+CGFloat(sin($0))) / 2)
            return AnyShape(s)
        }
    }
}

#Preview {
    func preview(_ t: ShapeType, _ c: Color) -> some View {
        return ZStack {
            mkShape(t).frame(width: 200, height: 90).background(c)
            Text(t.rawValue).foregroundColor(.black)
        }
    }

    return VStack {
        HStack {
            preview(.circle, .red)
            preview(.rectangle, .green)
            preview(.hexagon, .blue)
        }
        HStack {
            preview(.heart, .purple)
            preview(.cloud, .cyan)
            preview(.blob, .indigo)
        }
    }
}
