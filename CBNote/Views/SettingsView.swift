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
    @State private var nameFormatSample: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Paste from Clipboard", isOn: $viewModel.autoPasteWhenOpening)
                    if TrueDevice.isCamControlAvailable {
                        Picker("Camera Control Action", selection: $viewModel.cameraControlAction) {
                            ForEach(OpenAppOption.allCases) { action in
                                Text(action.localizedName).tag(action)
                            }
                        }
                    }
                } header: {
                    Text("When App Opening")
                } footer: {
                    if viewModel.cameraControlAction != .launchCamera {
                        let actionName = OpenAppOption.launchCamera.localizedName
                        Text("Even when setting something other than \(actionName), the camera will temporarily launch in the background.")
                    }
                }
                
                if TrueDevice.isCameraAvailable {
                    Section {
                        if cameraAccessStatus == .notDetermined {
                            Button("Request Camera Access") {
                                AVCaptureDevice.requestAccess(for: .video) { _ in
                                    cameraAccessStatus = AVCaptureDevice.authorizationStatus(for: .video)
                                }
                            }
                        }
                        Toggle("Remain in Camera After Shooting", isOn: $viewModel.remainCameraAfterCapture)
                        if TrueDevice.isCamControlAvailable {
                            Picker("Locked Camera Action", selection: $viewModel.captureLaunchAction) {
                                ForEach(CaptureContext.LaunchAction.allCases) { action in
                                    Text(action.localizedName).tag(action)
                                }
                            }
                        }
                    } header: {
                        Text("Camera")
                    } footer: {
                        if TrueDevice.isCamControlAvailable {
                            Text("Set the behavior when you start the CBNote camera from the lock screen.")
                        }
                    }
                }
                
                Section {
                    TextField("yyyy-MM-dd-HH-mm-ss", text: $viewModel.nameFormat)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .onChange(of: viewModel.nameFormat) {
                            updateNameFormatSample()
                        }
                } header: {
                    Text("File Name Format")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Use date format patterns to customize file names.")
                        Text("Sample: \(nameFormatSample)")
                    }
                }
                .onAppear {
                    updateNameFormatSample()
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
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
        }
    }
    
    private func updateNameFormatSample() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = viewModel.nameFormat
        nameFormatSample = dateFormatter.string(from: Date()) + ".txt"
    }
    
    struct AboutView: View {
        var body: some View {
            List {
                Section {
                    HStack {
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                        Label("Version", systemImage: "info.circle")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(currentVersion ?? "Unknown") (\(currentBuild ?? "Unknown"))")
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    HStack {
                        Label("Developer", systemImage: "hammer")
                            .foregroundColor(.primary)
                        Spacer()
                        Link(destination:URL(string: "https://cizzuk.net/")!, label: {
                            Text("Cizzuk")
                        })
                    }
                    Link(destination:URL(string: "https://github.com/Cizzuk/CBNote")!, label: {
                        Label("Source", systemImage: "ladybug")
                    })
                    Link(destination:URL(string: "https://i.cizzuk.net/privacy/")!, label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    })
                } header: {
                    Text("CBNote")
                }
                
                Section {} header: {
                    Text("License")
                } footer: {
                    Text("MIT License\n\nCopyright (c) 2025 Cizzuk\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
                        .environment(\.layoutDirection, .leftToRight)
                        .textSelection(.enabled)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
