//
//  camcapApp.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI

class TransparentWindowView: NSView {
    override func viewDidMoveToWindow() {
        guard let window else { return }
        
        window.isReleasedWhenClosed = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = true
        window.isMovableByWindowBackground = true

        super.viewDidMoveToWindow()
    }
}

struct TransparentWindow: NSViewRepresentable {
    func updateNSView(_ nsView: NSView, context: Context) {
        // Do Nothing
    }
    
    func makeNSView(context: Self.Context) -> NSView {
        return TransparentWindowView()
    }
}


@main
struct camcapApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(TransparentWindow())
        }
        .windowStyle(.hiddenTitleBar)
    }
}
