//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

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
