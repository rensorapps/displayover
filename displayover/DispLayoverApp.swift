//
//  camcapApp.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI
import AVFoundation

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let side = min(width, height) / 2
        let x = rect.midX
        let y = rect.midY
        path.move(to: CGPoint(x: x + side, y: y))
        for theta in ((1...6).map { CGFloat($0) * Double.pi / 3.0 }) {
            path.addLine(to: CGPoint(x: x + side * cos(theta), y: y + side * sin(theta)))
        }
        
        path.closeSubpath()
        return path
    }
}

class UserSettings: ObservableObject {
    @Published var shape = Shape.circle
    @Published var isMirroring = true
    
    enum Shape {
        case circle
        case rectangle
        case capsule
        case ellipse
        case hexagon
    }
    
    func shapeView() -> AnyShape {
        switch shape {
        case .circle:
            return AnyShape(Circle())
        case .rectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 20))
        case .capsule:
            return AnyShape(Capsule())
        case .ellipse:
            return AnyShape(Ellipse())
        case .hexagon:
            return AnyShape(Hexagon())
        }
    }
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
        
        // Remove buttons, button parent, and button grandparent to just show the circle.
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(TransparentWindow())
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Shape") {
                Button("Circle")    { settings.shape = .circle    }.keyboardShortcut("c")
                Button("Rectangle") { settings.shape = .rectangle }.keyboardShortcut("r")
                Button("Capsule")   { settings.shape = .capsule   }.keyboardShortcut("s")
                Button("Ellipse")   { settings.shape = .ellipse   }.keyboardShortcut("e")
                Button("Hexagon")   { settings.shape = .hexagon   }.keyboardShortcut("h")
            }
            
            CommandMenu("Mirroring") {
                Button("Mirror") { settings.isMirroring.toggle() }.keyboardShortcut("m")
            }

            // Commands technique taken from https://developer.apple.com/forums/thread/668139
            CommandMenu("Cameras") {
                // TODO: Authorization may need to be conducted prior to this.
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera, .deskViewCamera],
                    mediaType: .video,
                    position: .unspecified
                )
                let zero = ("0" as UnicodeScalar).value
                ForEach(Array(discoverySession.devices.enumerated()), id: \.0) { (i, device) in
                    if let c = UnicodeScalar(zero + UInt32(i)) {
                        Button("\(device.localizedName)") { print("You pressed sub menu.") }
                            // TODO: Actually switch cameras
                            .keyboardShortcut(KeyboardShortcut(KeyEquivalent(Character(c))))
                    }
                }
            }
        }
    }
}
