//
//  camcapApp.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI
import AVFoundation

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
    
    let cameras = Cameras().getCameras()
    @ObservedObject var settings = UserSettings()
    
    init() {
        // Cameras() Should have prompted for required permissions
        settings.device = cameras[0]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(TransparentWindow())
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Shape") {
                var shape = 0
                let shapes = ShapeType.allCases
                Button("Next") {
                    shape += 1
                    settings.shape = mkShape(shapes[shape % shapes.count])
                }.keyboardShortcut("n")
                
                Button("Circle")    { settings.shape = mkShape(.circle) }
                Button("Rectangle") { settings.shape = mkShape(.rectangle) }
                Button("Capsule")   { settings.shape = mkShape(.capsule) }
                Button("Ellipse")   { settings.shape = mkShape(.ellipse) }
                Button("Hexagon")   { settings.shape = mkShape(.hexagon) }
                Button("Heart")     { settings.shape = mkShape(.heart) }
                Button("Cloud")     { settings.shape = mkShape(.cloud) }
                Button("Blob")      { settings.shape = mkShape(.blob) }
            }
            
            CommandMenu("Mirroring") {
                Button("Mirror") { settings.isMirroring.toggle() }.keyboardShortcut("f")
            }

            // Commands technique taken from https://developer.apple.com/forums/thread/668139
            CommandMenu("Cameras") {
                let zero = ("1" as UnicodeScalar).value
                ForEach(Array(cameras.enumerated()), id: \.0) { (i, device) in
                    if let c = UnicodeScalar(zero + UInt32(i)) {
                        Button("\(device.localizedName)") {
                            print("Changing Device to \(device)")
                            settings.device = device
                        }.keyboardShortcut(KeyboardShortcut(KeyEquivalent(Character(c))))
                    }
                }
            }
        }
    }
}
