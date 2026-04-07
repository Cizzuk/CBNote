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
    @ObservedObject private var userSettings = UserSettings.shared
    @State private var cameraAccessStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var nameFormatSample: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Auto Paste from Clipboard", isOn: $userSettings.autoPasteWhenOpening)
                    if TrueDevice.isCamControlAvailable {
                        Picker("Camera Control Action", selection: $userSettings.cameraControlAction) {
                            ForEach(OpenAppOption.allCases) { action in
                                Text(action.displayName).tag(action)
                            }
                        }
                        if userSettings.cameraControlAction == .openURL {
                            TextField("URL", text: $userSettings.cameraControlActionOpenURL, prompt: Text(verbatim: "cbnote://open/camera"))
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .environment(\.layoutDirection, .leftToRight)
                                .submitLabel(.done)
                        }
                    }
                } footer: {
                    if userSettings.cameraControlAction.shouldOpenDummyCamera && TrueDevice.isCamControlAvailable {
                        let actionName = OpenAppOption.launchCamera.displayName
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
                        
                        Toggle("Remain in Camera After Shooting", isOn: $userSettings.remainCameraAfterCapture)
                        
                        if TrueDevice.isSaveToPhotosAllowed() {
                            Toggle("Save Captured Image to Photos", isOn: $userSettings.saveCapturedImageToPhotos)
                        }
                    } header: {
                        Text("Camera")
                    }
                }
                
                Section {
                    Toggle("Show Image Preview", isOn: $userSettings.showImagePreview)
                    Toggle("Show Hidden Files", isOn: $userSettings.showHiddenFiles)
                    Toggle("Enable Note List Animations", isOn: $userSettings.enableNoteListAnimations)
                } header: {
                    Text("Note List")
                } footer: {
                    Text("To avoid display issues, some animations in note list are disabled by default.")
                }
                
                Section {
                    TextField("yyyy-MM-dd-HH-mm-ss", text: $userSettings.nameFormat)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onChange(of: userSettings.nameFormat) {
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
                    TextField("URL", text: $userSettings.searchEngine, prompt: Text(verbatim: TrueDevice.defaultSearchEngine))
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .environment(\.layoutDirection, .leftToRight)
                        .submitLabel(.done)
                } header: {
                    Text("Search Engine")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Set a search engine used for searching within notes.")
                        Text("Replace query with %s.")
                    }
                }
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                            .foregroundStyle(.primary)
                    }
                    if UIApplication.shared.supportsAlternateIcons {
                        NavigationLink(destination: ChangeIconView()) {
                            Label("Change App Icon", systemImage: "app.dashed")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .animation(.default, value: userSettings.cameraControlAction)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
        dateFormatter.dateFormat = userSettings.nameFormat
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
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(currentVersion ?? "Unknown") (\(currentBuild ?? "Unknown"))")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    HStack {
                        Label("Developer", systemImage: "hammer")
                            .foregroundStyle(.primary)
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
