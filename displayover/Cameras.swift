
import SwiftUI
import AVFoundation
import AppKit
import Combine

class Cameras: ObservableObject {
    @Published var granted: Bool = false
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                granted = true

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.granted = granted
                        }
                    }
                }

            case .denied: // The user has previously denied access.
                granted = false

            case .restricted: // The user can't grant access due to restrictions.
                granted = false
            
        @unknown default:
            fatalError("Unknown AVCaptureDevice.authorizationStatus(for: .video)")
        }
    }

    func getCameras() -> Array<AVCaptureDevice> {
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .deskViewCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        return discoverySession.devices
    }
}
