//
//  CameraPreview.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

#if !targetEnvironment(macCatalyst)

import AVFoundation
import SwiftUI

struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let onTap: (CGPoint) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = VideoPreviewController()
        let view = VideoPreviewView()
        
        view.videoPreviewLayer.videoGravity = .resizeAspect
        view.videoPreviewLayer.session = session
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        controller.view = view
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject {
        let onTap: (CGPoint) -> Void
        
        init(onTap: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? VideoPreviewView else { return }
            let location = gesture.location(in: view)
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
            onTap(devicePoint)
            
            showFocusIndicator(at: location, in: view)
        }
        
        private func showFocusIndicator(at point: CGPoint, in view: UIView) {
            let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
            focusView.center = point
            focusView.layer.borderColor = UIColor.yellow.cgColor
            focusView.layer.borderWidth = 1.5
            focusView.backgroundColor = .clear
            focusView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            focusView.alpha = 0.0
            
            view.addSubview(focusView)
            
            UIView.animate(withDuration: 0.25, animations: {
                // Show focus indicator
                focusView.alpha = 1.0
                focusView.transform = .identity
            }) { _ in
                UIView.animate(withDuration: 0.25, delay: 0.5, options: [], animations: {
                    // Hide focus indicator
                    focusView.alpha = 0.0
                }) { _ in
                    focusView.removeFromSuperview()
                }
            }
        }
    }
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            // Set Video Orientation
            switch UIDevice.current.orientation {
            case .portrait:
                videoPreviewLayer.connection?.videoRotationAngle = 90.0
            case .landscapeLeft:
                videoPreviewLayer.connection?.videoRotationAngle = 0.0
            case .landscapeRight:
                videoPreviewLayer.connection?.videoRotationAngle = 180.0
            case .portraitUpsideDown:
                videoPreviewLayer.connection?.videoRotationAngle = 270.0
            default:
                break
            }
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    class VideoPreviewController: UIViewController {
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            
            // Detect orientation change
            coordinator.animate(alongsideTransition: nil) { _ in
                if let previewView = self.view as? VideoPreviewView {
                    previewView.layoutSubviews()
                }
            }
        }
    }
}

#endif
