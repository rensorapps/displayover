//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation

extension Int {
    var degrees: Angle { return Angle(degrees: Double(self)) }
    var radians: Angle { return Angle(radians: Double(self)) }
}

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

enum ShapeType: String, CaseIterable {
    case circle
    case rectangle
    case capsule
    case ellipse
    case pentagon
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
    case .pentagon:  return AnyShape(NGon(sides: 5))
    case .hexagon:   return AnyShape(NGon(sides: 6))
    case .heart:     return AnyShape(Heart())
    case .cloud:     return AnyShape(Cloud(count: 10))
    case .blob:      return AnyShape(try! Blob(count: 7))
    }
}

func mkEvolvingShape(_ t: ShapeType) -> ((TimeInterval) -> AnyShape) {
    switch t {
        
    case .pentagon:
        var reference = NGon(sides: 5)
        return {
            reference.rotationRadians = $0 / 10
            return AnyShape(reference)
        }
        
    case .hexagon:
        var reference = NGon(sides: 6)
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
