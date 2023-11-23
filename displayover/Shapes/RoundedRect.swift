//
//  Simple.swift
//  DispLayover
//
//  Created by Lyndon Maydwell on 31/10/2023.
//

import SwiftUI
import Foundation


struct RoundedRect: Shape {
    func path(in rect: CGRect) -> Path {
        let rr = RoundedRectangle(cornerRadius: max(rect.height, rect.width) / 6, style: .continuous)
        return rr.path(in: rect)
    }
}

