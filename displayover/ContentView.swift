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
    
    init(captureSession: AVCaptureSession, settings: UserSettings? = nil) {
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
//    typealias NSViewType = PlayerView
    
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

    @Published var isGranted: Bool = false
    var captureSession: AVCaptureSession!
    private var cancellables = Set<AnyCancellable>()

    init() {
        captureSession = AVCaptureSession()
        setupBindings()
    }

    func setupBindings() {
        $isGranted
            .sink { [weak self] isGranted in
                if isGranted {
                    self?.prepareCamera()
                } else {
                    self?.stopSession()
                }
            }
            .store(in: &cancellables)
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.isGranted = true

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.isGranted = granted
                        }
                    }
                }

            case .denied: // The user has previously denied access.
                self.isGranted = false
                return

            case .restricted: // The user can't grant access due to restrictions.
                self.isGranted = false
                return
        @unknown default:
            fatalError()
        }
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
        captureSession.sessionPreset = .high
        
        // Should this be done in another thread or on launch?
        // Should we have a menu item to allow the user to choose another device?
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .deskViewCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        guard !discoverySession.devices.isEmpty else { fatalError("Missing capture device.")}
        let device = discoverySession.devices[0]
        startSessionForDevice(device)

//        if let device = AVCaptureDevice.default(for: .video) {
//            startSessionForDevice(device)
//        }
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
        guard captureSession.canAddInput(input) == true else {
            return
        }
        captureSession.addInput(input)
    }
}

struct ContentView: View {

    @ObservedObject var viewModel = ContentViewModel()
    @EnvironmentObject var settings: UserSettings
    
    init() {
        viewModel.checkAuthorization()
    }

    var body: some View {
        PlayerContainerView(captureSession: viewModel.captureSession, settings: settings)
           .clipShape(settings.shapeView())
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        let settings = UserSettings()

        VStack {
            HStack {
                Button("Circle") {settings.shape = .circle}
                Button("Rectangle") {settings.shape = .rectangle}
                Button("Hexagon") {settings.shape = .hexagon}
            }
            Button("Mirror") {settings.isMirroring.toggle()}

            ContentView().environmentObject(settings)
        }
    }
}
