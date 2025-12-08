//
//  Settings.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import SwiftUI
import AVFoundation
import Photos

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var cameraAccessStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if cameraAccessStatus == .notDetermined {
                        Button("Request Camera Access") {
                            AVCaptureDevice.requestAccess(for: .video) { _ in
                                cameraAccessStatus = AVCaptureDevice.authorizationStatus(for: .video)
                            }
                        }
                    }
                } footer: {
                    if cameraAccessStatus == .denied {
                        Text("Camera access is denied. Please grant permission in Settings.")
                    } else if cameraAccessStatus == .restricted {
                        Text("Camera access is restricted.")
                    }
                }
                
                Section {
                    Toggle("Auto Paste when Opening", isOn: $viewModel.autoPasteWhenOpening)
                } footer: {
                    Text("Recommended to set \"Paste from Other Apps\" to \"Allow\" in the Settings.")
                }
                
                Section {
                    Toggle("Remain in Camera After Shooting", isOn: $viewModel.remainCameraAfterCapture)
                }
                
                Section {
                    Picker("When Launching with Camera Control", selection: $viewModel.cameraControlAction) {
                        ForEach(OpenAppOption.allCases) { action in
                            Text(String(localized: action.localizedName)).tag(action)
                        }
                    }
                } footer: {
                    if viewModel.cameraControlAction != .launchCamera {
                        let actionName = String(localized: viewModel.cameraControlAction.localizedName)
                        Text("Even when setting something other than \(actionName), the camera will temporarily launch in the background.")
                    }
                }
                
                Section {
                    Picker("Locked Camera Action", selection: $viewModel.captureLaunchAction) {
                        ForEach(CaptureContext.LaunchAction.allCases) { action in
                            Text(String(localized: action.localizedName)).tag(action)
                        }
                    }
                } footer: {
                    Text("Choose action when launching from the Lock Screen.")
                }
                
                // App Information
                Section {
                    Text("CBNote")
                        .textSelection(.enabled)
                    HStack {
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                        Text("Version")
                        Spacer()
                        Text("\(currentVersion ?? "Unknown") (\(currentBuild ?? "Unknown"))")
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    HStack {
                        Text("Developer")
                        Spacer()
                        Link(destination:URL(string: "https://cizzuk.net/")!, label: {
                            Text("Cizzuk")
                        })
                    }
                    Link(destination:URL(string: "https://i.cizzuk.net/privacy/")!, label: {
                        Text("Privacy Policy")
                    })
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
    }
}
