//
//  camcapApp.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI
import AVFoundation

//extension AVCaptureDevice: Equatable {
//    
//}

class UserSettings: ObservableObject {
    @Published var shape = AnyShape(Circle())
    @Published var isMirroring = true
    @Published var device: AVCaptureDevice?
}

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
        window.hasShadow = true
        
        // Remove close button parent, and grandparent to just show the circle.
        window.standardWindowButton(.closeButton)?.superview?.isHidden = true
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true

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
struct dispLayoverApp: App {
    
    let settings = UserSettings()
    let cameras = Cameras().getCameras()
    
    init() {
        // Cameras() Should have prompted for required permissions
        settings.device = cameras[0]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings)
                .background(TransparentWindow())
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Shape") {
                Button("Circle")    { settings.shape = AnyShape(Circle())                             }.keyboardShortcut("c")
                Button("Rectangle") { settings.shape = AnyShape(Rectangle())                          }.keyboardShortcut("r")
                Button("Capsule")   { settings.shape = AnyShape(Capsule())                            }.keyboardShortcut("s")
                Button("Ellipse")   { settings.shape = AnyShape(RoundedRectangle(cornerRadius: 20))   }.keyboardShortcut("e")
                Button("Hexagon")   { settings.shape = AnyShape(Hexagon())                            }.keyboardShortcut("h")
                Button("Heart")     { settings.shape = AnyShape(Heart())                              }.keyboardShortcut("t")
                Button("Cloud")     { settings.shape = AnyShape(Blob1(count: 10))                     }.keyboardShortcut("d")
                Button("Blob")      { settings.shape = AnyShape(try! Blob2(count: 7))                 }.keyboardShortcut("b")
            }
            
            CommandMenu("Mirroring") {
                Button("Mirror") { settings.isMirroring.toggle() }.keyboardShortcut("f")
            }

            // Commands technique taken from https://developer.apple.com/forums/thread/668139
            CommandMenu("Cameras") {
                let zero = ("1" as UnicodeScalar).value
                ForEach(Array(cameras.enumerated()), id: \.0) { (i, device) in
                    if let c = UnicodeScalar(zero + UInt32(i)) {
                        Button("\(device.localizedName)") { settings.device = device }
                          .keyboardShortcut(KeyboardShortcut(KeyEquivalent(Character(c))))
                    }
                }
            }
        }
    }
}
