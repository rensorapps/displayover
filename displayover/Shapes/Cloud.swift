//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

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
