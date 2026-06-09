//
//  TrueDevice.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

#if canImport(AVFoundation)
import AVFoundation
#endif
import Photos
import UIKit

// Return true device state
struct TrueDevice {
    static let userInterfaceIdiom: UIUserInterfaceIdiom = {
        #if targetEnvironment(macCatalyst)
        return .mac
        
        #else
        if ProcessInfo().isiOSAppOnMac {
            return .mac
        } else if ProcessInfo().isiOSAppOnVision {
            return .vision
        }
        
        return UIDevice.current.userInterfaceIdiom
        
        #endif
    }()
    
    static let isCameraAvailable: Bool = {
        if AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
            return false
        }
        
        return true
    }()
    
    static let isCamControlAvailable: Bool = {
        if !isCameraAvailable {
            return false
        }
        
        #if canImport(AVFoundation)
            #if targetEnvironment(simulator)
            return true
            #else
            return AVCaptureSession().supportsControls
            #endif
        
        #else
        return false
        
        #endif
    }()
    
    static func isSaveToPhotosAllowed() -> Bool {
        #if targetEnvironment(macCatalyst)
        return false
        
        #else
        if userInterfaceIdiom == .mac {
            return false
        }
        
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .notDetermined, .limited:
            return true
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
        
        #endif
    }
    
    static let defaultSearchEngine: String = {
        let defaultEngine: String
        if let url = URL(string: "x-web-search://?test"),
           UIApplication.shared.canOpenURL(url) {
            defaultEngine = "x-web-search://?%s"
        } else {
            defaultEngine = "https://www.google.com/search?q=%s"
        }
        return defaultEngine
    }()
}
