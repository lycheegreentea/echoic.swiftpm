//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 1/30/26.
//
//
//

import SwiftUI
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit // For haptic feedback and opening Settings
#endif


class RecordingManager: ObservableObject{
    @Published var recordings: [URL] = []
}
struct RecordView: View  {
    @StateObject private var rec = MiniRecorder()
    
    
    @StateObject private var player = MiniPlayer()
    @StateObject private var recordingManager = RecordingManager()
    
    
    @State private var micDenied = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            Text("Voice Recorder")
                .font(.title3).bold()
            
            MultiBarVisualizerView(values: rec.meterHistory, barCount: 24)
                .frame(height: 54)
                .padding(.horizontal)
            
            ProgressView(value: rec.meterLevel)
                .progressViewStyle(.linear)
                .tint(.blue.opacity(0.8))
                .frame(height: 8)
                .padding(.horizontal)
                .animation(.linear(duration: 0.05), value: rec.meterLevel)
            
            HStack(spacing: 12) {
                
                // Record button toggles recording state.
                Button(rec.isRecording ? "Stop" : "Record") {
                    print("HI")
                    playTapHaptic()
                    print("PLAYED HAPTIC")
                    if rec.isRecording {
                        rec.stop()
                    } else {
                        player.stop()
                        rec.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                
                Button("Play") {
                    playTapHaptic()
                    player.play(rec.fileURL)
                }
                .buttonStyle(.bordered)
                .disabled(rec.isRecording || rec.fileURL == nil)
            }
            
            if let url = rec.fileURL {
                Text("File: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            
            
            
        }
    }
    func playTapHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}
