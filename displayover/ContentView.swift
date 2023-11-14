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
                preview.connection?.isVideoMirrored = isMirroring
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    init(_ initialSettings: UserSettings) {
        viewModel.device = initialSettings.device
    }

    var body: some View {
        ZStack {
            PlayerContainerView(captureSession: viewModel.captureSession, settings: settings)
                .clipShape(settings.shape)
                // Update viewModel.device when it changes.
                .onChange(of: settings.device) { device in
                    guard let device else { return }
                    print("Device changed: \(device)")
                    viewModel.device = device
                }
            VStack(spacing: 0) {
                if(hover) {
                    Spacer()
                    HStack(spacing: 5) {
                        Link(destination: URL(string: "https://github.com/sordina/displayover")!, label: {
                            Image(systemName: "questionmark.circle.fill").padding(5)
                        }).background(.gray).foregroundColor(.white).cornerRadius(5)
//                        Button(action: { print("LOL") }, label: { Text("LOL").padding(5) })
                    }
                }
            }
            .transition(.opacity)
        }
        .onHover { x in
            hover = x
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        let settings = UserSettings()
        ContentView(settings).environmentObject(settings)
    }
}
