//
//  Settings.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/04.
//

import Photos
import SwiftUI

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
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
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
    
    struct AboutView: View {
        var body: some View {
            List {
                Section {
                    HStack {
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("\(currentVersion ?? "Unknown") (\(currentBuild ?? "Unknown"))")
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    HStack {
                        Label("Developer", systemImage: "hammer")
                        Spacer()
                        Link(destination:URL(string: "https://cizzuk.net/")!, label: {
                            Text("Cizzuk")
                        })
                    }
                    Link(destination:URL(string: "https://i.cizzuk.net/privacy/")!, label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    })
                    Link(destination:URL(string: "https://github.com/Cizzuk/CBNote")!, label: {
                        Label("Source", systemImage: "ladybug")
                    })
                }
                
                Section {} header: {
                    Text("License")
                } footer: {
                    Text("MIT License\n\nCopyright (c) 2025 Cizzuk\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
                        .environment(\.layoutDirection, .leftToRight)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
