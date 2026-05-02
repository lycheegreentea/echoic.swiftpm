//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 2/24/26.
//

import SwiftUI
@MainActor
class DayAudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentRecordingIndex = 0
    @Published var currentRecordingFeatures: DaySummary = .empty
    @Published var recordings: [Recording] = []
    @ObservedObject var manager = RecordingManager.shared
    var currentRecording: Recording? {
        guard currentRecordingIndex < recordings.count else {return nil}
        return recordings[currentRecordingIndex]
    }

    private var player = MiniPlayer()
    var day: Date
    init(day: Date){
        self.day = day
        self.recordings = manager.recordingsByDay[day] ?? []
    }
    
    func playAll() {
        guard !recordings.isEmpty else { return }
        isPlaying = true
        currentRecordingIndex = 0
        
        playNext()
    }

    private func playNext() {
        guard currentRecordingIndex < recordings.count else {isPlaying=false
            currentRecordingIndex = 0
            return}
        let recording = recordings[currentRecordingIndex]
        player.play(recording.url) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentRecordingIndex += 1
                self.playNext()
                
            }
            
        }
    }

    func pause() {
        player.pause()
        isPlaying = false
    }
}

extension DaySummary {
    static var empty: DaySummary { DaySummary(loudness: 0, silence: 1, variability: 0, spectral: 0) }
}



#Preview {
    let _ = DayAudioPlayer(day: Date())
    return Text("Player Initialized")
}
