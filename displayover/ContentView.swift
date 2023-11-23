//
//  ContentView.swift
//  camcap
//
//  Created by Lyndon Maydwell on 26/10/2023.
//

import SwiftUI
import AVFoundation
import AppKit
import Combine

class PlayerView: NSView {
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var settings: UserSettings?
    private lazy var cancellables = Set<AnyCancellable>()
    
    init(captureSession: AVCaptureSession, settings: UserSettings) {
        self.settings = settings
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(frame: .zero)
        setupLayer()
    }

    func setupLayer() {
        
        guard let preview = previewLayer else { return }

        preview.frame = self.frame
        preview.contentsGravity = .resizeAspectFill
        preview.videoGravity = .resizeAspectFill
        preview.connection?.automaticallyAdjustsVideoMirroring = false
        preview.connection?.isVideoMirrored = true
        
        layer = previewLayer
        
        guard let settings else { return }
        
        settings.$isMirroring
            .subscribe(on: RunLoop.main)
            .sink { isMirroring in
                preview.connection?.automaticallyAdjustsVideoMirroring = false
                preview.connection?.isVideoMirrored = isMirroring
            }
            .store(in: &cancellables)
        
        registerForDraggedTypes(PlayerView.allowedDropTypes)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // Drag SVG Files
    // Example from: https://stackoverflow.com/questions/75652413/how-can-i-accept-a-drop-for-a-dragged-item-on-a-window-tab-in-macos-appkit
    
    static let allowedDropTypes: Array<NSPasteboard.PasteboardType> = [.URL]

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        // Optional: Ignore drags from the same window
        guard (sender.draggingSource as? NSView)?.window != window else { return false }

        // Check if the dropped item contains text:
        let pasteboard = sender.draggingPasteboard
        guard let url = NSURL(from: pasteboard),
              let path = url.path,
              path.hasSuffix(".svg"),
              let u = .some(URL(fileURLWithPath: path)),
              let x = try? XMLDocument(contentsOf: u),
              let root = x.rootElement(),
              let n = root.name,
              n == "svg",
              let shape = try? SVG(doc: x),
              let settings
              else { return false }
        
        settings.shape = {
            let s = Shrinkable(reference: shape, offset: (1+CGFloat(sin($0))) / 2)
            return AnyShape(s)
        }
        return true
    }
}

struct PlayerContainerView: NSViewRepresentable {
    let settings: UserSettings
    let captureSession: AVCaptureSession

    init(captureSession: AVCaptureSession, settings: UserSettings) {
        self.captureSession = captureSession
        self.settings = settings
    }

    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(captureSession: captureSession, settings: settings)
    }

    func updateNSView(_ nsView: PlayerView, context: Context) {
        nsView.setupLayer() // Fixes mirroring!
    }
}

class ContentViewModel: ObservableObject {
    
    @Published var device: AVCaptureDevice?

    var captureSession: AVCaptureSession!
    private var cancellables = Set<AnyCancellable>()

    init() {
        captureSession = AVCaptureSession()
        
        if let d = device {
            startSessionForDevice(d)
        }
        
        $device
            .sink { [weak self] device in
                guard let device else { return }
                self?.startSessionForDevice(device)
            }
            .store(in: &cancellables)
        
    }

    func startSession() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func prepareCamera() {
        guard let device else { return }
        startSessionForDevice(device)
    }

    func startSessionForDevice(_ device: AVCaptureDevice) {
        do {
            let input = try AVCaptureDeviceInput(device: device)
            addInput(input)
            startSession()
        }
        catch {
            print("Something went wrong - ", error.localizedDescription)
        }
    }

    func addInput(_ input: AVCaptureInput) {
        for i in captureSession.inputs {
            captureSession.removeInput(i)
        }
        guard captureSession.canAddInput(input) else {
            return
        }
        captureSession.addInput(input)
    }
}

struct ContentView: View {

    @EnvironmentObject var settings: UserSettings
    @ObservedObject var viewModel = ContentViewModel()
    @State var hover = false
    @State var theta: TimeInterval = .zero
    
    static let sampleRate = 0.2
    let timer = Timer.publish(every: sampleRate, on: .main, in: .common).autoconnect()
    
    init(_ initialSettings: UserSettings) {
        viewModel.device = initialSettings.device
    }
    
    var body: some View {
        ZStack {
            PlayerContainerView(captureSession: viewModel.captureSession, settings: settings)
                .clipShape(settings.shape(theta)) // , style: .init(eoFill: false, antialiased: false))
                // Update viewModel.device when it changes.
                .onChange(of: settings.device) { device in
                    guard let device else { return }
                    print("Device changed: \(device)")
                    viewModel.device = device
                }
            VStack(spacing: 0) {
                if(hover) {
                    // This is a hack because image padding is excessive and asymmetrical
                    let buttonInsets = EdgeInsets(top: 4, leading: -1, bottom: 4, trailing: -7)
                    Spacer()
                    HStack(spacing: 5) {
                        
                        Button(action: { settings.nextShape() }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill").padding(buttonInsets)
                        }).background(.gray).foregroundColor(.white).cornerRadius(5)
                            .help("Next Shape")

                        Button(action: { settings.isMirroring.toggle() }, label: {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill").padding(buttonInsets)
                        }).background(.gray).foregroundColor(.white).cornerRadius(5)
                            .help("Toggle Mirroring")

                        Button(action: { settings.isAnimating.toggle() }, label: {
                            settings.isAnimating
                                ? Image(systemName: "stop.circle.fill").padding(buttonInsets)
                                : Image(systemName: "play.circle.fill").padding(buttonInsets)
                        }).background(.gray).foregroundColor(.white).cornerRadius(5)
                            .help("Toggle Animation")
                        
                        Link(destination: URL(string: "https://rensor.app/pages/displayover")!, label: {
                            Image(systemName: "questionmark.circle.fill").padding(5)
                        }).background(.gray).foregroundColor(.white).cornerRadius(5)
                            .help("Go to rensor.app")

                    }.font(.system(size: 20))
                }
            }
            .transition(.opacity)
        }
        .onHover { x in
            hover = x
        }
        .onReceive(timer) { time in
            if(settings.isAnimating) {
                withAnimation(Animation.linear(duration: ContentView.sampleRate)) {
                    theta += ContentView.sampleRate
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        let settings = UserSettings()
        ContentView(settings).environmentObject(settings)
    }
}
