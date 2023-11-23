//
//  Shapes.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation
import SVGShape

struct SVG: Shape {
    var shape: SVGShape
    
    func path(in rect: CGRect) -> Path {
        return shape.path(in: rect)
    }
        
    init(doc: XMLDocument) throws {
        shape = try! SVGShape.init(document: doc)
    }
}
