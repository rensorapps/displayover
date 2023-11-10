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

    func updateNSView(_ nsView: PlayerView, context: Context) { }
}

class ContentViewModel: ObservableObject {
    
    var device: AVCaptureDevice

    var captureSession: AVCaptureSession!
    private var cancellables = Set<AnyCancellable>()

    init(_ device: AVCaptureDevice) {
        captureSession = AVCaptureSession()
        self.device = device
        startSessionForDevice(device)
    }

    func startSession() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
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
    @State var hover = false
    var device: AVCaptureDevice
    
    var body: some View {
        ZStack {
            let viewModel = ContentViewModel(device)
            PlayerContainerView(captureSession:  viewModel.captureSession, settings: settings)
                .clipShape(settings.shape)
            VStack(spacing: 0) {
                if(hover) {
                    Spacer()
                    HStack(spacing: 0) {
                        // Button(action: { print("smaller") }, label: { Image(systemName: "minus.circle.fill") })
                        // Button(action: { print("bigger") }, label: { Image(systemName: "plus.circle.fill") })
                        Button(action: { print("help") }, label: {
                            Link(destination: URL(string: "https://github.com/rensorapps/displayover")!, label: {
                                Image(systemName: "questionmark.circle.fill")
                            })
                        })
                    }
                }
            }
            .transition(.opacity)
        }
        .onHover { x in
            hover = x
        }
        .onAppear {
            print("Created ContentView")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = UserSettings()
        ContentView(device: settings.device!).environmentObject(settings)
    }
}
