//
//  camcapApp.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI
import AVFoundation

class UserSettings: ObservableObject {
    
    @Published var shape = mkEvolvingShape(.circle)
    @Published var isMirroring = true
    @Published var isAnimating = false
    @Published var device: AVCaptureDevice?
    
    var shapeSelection = ShapeType.circle
    
    func nextShape() {
        let shapes = ShapeType.allCases
        let i = shapes.firstIndex(of: shapeSelection)!
        shapeSelection = shapes[(i + 1) % shapes.count]
        shape = mkEvolvingShape(shapeSelection)
    }
    
    func setShape(_ choice: ShapeType) {
        shapeSelection = choice
        shape = mkEvolvingShape(choice)
    }
}

class TransparentWindowView: NSView {
    
    var lastEntered: DispatchTime?
    
    func titleHidden(_ hidden: Bool) {
        guard let window else { return }
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = hidden
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: self.window, queue: nil) { [weak self] notification in
            self?.titleHidden(false)
        }
        
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: self.window, queue: nil) { [weak self] notification in
            self?.titleHidden(true)
        }
        
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    override func viewDidMoveToWindow() {
        guard let window else { return }
        
        window.isReleasedWhenClosed = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        
        // titleHidden(true)
        
        self.setupNotifications()
        
        super.viewDidMoveToWindow()
    }
}

struct TransparentWindow: NSViewRepresentable {
    func updateNSView(_ nsView: NSView, context: Context) {
    }
    
    func makeNSView(context: Self.Context) -> NSView {
        let win = TransparentWindowView()
        
        let trackingOptions: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .inVisibleRect,
            .assumeInside,
            .activeAlways,
        ]
        
        let frame = win.frame
        let rect = CGRect(x: frame.minX - 100, y: frame.minY - 100, width: frame.width + 100, height: frame.height + 100)
        
        win.addTrackingArea(NSTrackingArea(rect: rect, options: trackingOptions, owner: win))

        return win
    }
}

// From https://stackoverflow.com/a/65743682
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct dispLayoverApp: App {
    
    let settings = UserSettings()
    let cameras = Cameras().getCameras()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Cameras() Should have prompted for required permissions
        guard cameras.count > 0 else { return }
        settings.device = cameras[0]
    }
    
    var body: some Scene {
        // Use WindowGroup for multiple windows
        Window("DispLayover", id: "main") {
            ContentView(settings)
                .background(TransparentWindow())
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Shape") {
              
                Button("Next") { settings.nextShape() }.keyboardShortcut("n")
                
                Button("Toggle Animation") {
                    settings.isAnimating.toggle()
                }.keyboardShortcut("e")
                
                Divider()
                
                ForEach(ShapeType.allCases, id: \.self) { st in
                    Button("\(st.rawValue)".capitalized) { settings.setShape(st) }
                }
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
