//
//  RecorderActivityWidget.swift
//  WidgetExtension
//
//  Created by Cizzuk on 2026/03/03.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RecorderActivityWidget: Widget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.RecorderActivityWidget"
    
    struct IconImage: View {
        var size: CGFloat? = nil

        var body: some View {
            Image("cbnote")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(3)
                .accessibilityLabel("CBNote")
                .foregroundStyle(.white)
        }
    }
    
    struct RecordImage: View {
        var size: CGFloat? = nil

        var body: some View {
            Image(systemName: "waveform.badge.microphone")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(2)
                .accessibilityLabel("Recording")
                .foregroundStyle(.red)
        }
    }
    
    struct DescriptionText: View {
        var showSubtitle: Bool = true
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Recording")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                if showSubtitle {
                    Text("CBNote")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
    
    struct FinishRecordButton: View {
        var body: some View {
            Button(intent: FinishRecordButtonIntent()) {
                Label("Finish Record", systemImage: "stop.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 30, weight: .bold))
                    .padding(5)
            }
            .tint(.red)
            .padding(5)
        }
    }
    
    struct FinishRecordButtonIntent: AppIntent {
        static let title: LocalizedStringResource = "Finish Record"
        static var openAppWhenRun = false
        static var isDiscoverable = false

        @MainActor
        func perform() async throws -> some OpensIntent {
            return .result()
        }
    }
    
    struct MainActivityView: View {
        @Environment(\.activityFamily) var activityFamily
        
        var body: some View {
            switch activityFamily {
            case .small:
                HStack(spacing: 10) {
                    IconImage(size: 30)
                    DescriptionText(showSubtitle: false)
                }
            case .medium:
                HStack(spacing: 10) {
                    IconImage(size: 40)
                        .padding(.leading, 10)
                    DescriptionText()
                    Spacer()
                    FinishRecordButton()
                }
                .padding()
            @unknown default:
                EmptyView()
            }
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecorderActivityAttributes.self) { context in
            MainActivityView()
                .activitySystemActionForegroundColor(.red)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IconImage(size: 50)
                        .padding(5)
                }
                DynamicIslandExpandedRegion(.center) {
                    DescriptionText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FinishRecordButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                IconImage()
            } compactTrailing: {
                RecordImage()
            } minimal: {
                IconImage()
            }
            .keylineTint(.red)
        }
        .supplementalActivityFamilies([.small])
    }
}
