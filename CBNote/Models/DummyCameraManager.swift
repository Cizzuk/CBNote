//
//  DummyCameraManager.swift
//  CBNote
//
//  Created by Cizzuk on 2026/02/17.
//

import Combine
import Foundation

// Launch a dummy camera to avoid being killed by the system.
// In the test, system killed the app when it was below 0.8 - 1s.

@MainActor
final class DummyCameraManager: ObservableObject {
    static let shared = DummyCameraManager()

    @Published private var nonce: UUID?

    private init() {}

    var isShowing: Bool {
        nonce != nil
    }

    func open(duration: TimeInterval = 2) {
        let newNonce = UUID()
        nonce = newNonce

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            if self.nonce == newNonce {
                self.close()
            }
        }
    }

    func close() {
        nonce = nil
    }
}
