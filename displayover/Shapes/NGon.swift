//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

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
