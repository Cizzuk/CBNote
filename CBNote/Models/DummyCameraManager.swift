//
//  DummyCameraManager.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/17.
//

import Combine
import SwiftUI
import UIKit

// Launch a dummy camera to avoid being killed by the system.
// In the test, system killed the app when it was below 0.8 - 1s.

@MainActor
final class DummyCameraManager: ObservableObject {
    static let shared = DummyCameraManager()
    
    @Published private var isShowing = false
    
    private var dummyWindow: UIWindow?
    private var closeWorkItem: DispatchWorkItem?
    
    private init() {}
    
    func open(duration: TimeInterval = 2) {
        isShowing = true
        createWindow()
        
        // (Re)Schedule closing the dummy camera
        closeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.close()
        }
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    func close() {
        // Cancel close actions
        closeWorkItem?.cancel()
        closeWorkItem = nil
        
        // Remove the dummy window
        dummyWindow?.isHidden = true
        dummyWindow = nil
        
        isShowing = false
    }
    
    // Create the dummy camera window if it is not already shown
    private func createWindow() {
        guard dummyWindow == nil else { return }
        guard let scene = activeWindowScene() else { return }
        
        let window = PassThroughWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .statusBar + 1 // Put above status bar
        
        let hostingController = UIHostingController(rootView: DummyCameraView())
        hostingController.view.backgroundColor = .clear
        
        window.rootViewController = hostingController
        window.isHidden = false
        dummyWindow = window
    }
    
    // Find the active window scene
    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
    
    // A UIWindow subclass that ignores all touch events.
    private class PassThroughWindow: UIWindow {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            nil
        }
    }
}
