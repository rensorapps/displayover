//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

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
