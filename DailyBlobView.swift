//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 2/24/26.
//

import SwiftUI

struct DaySummary {
    let loudness: Float
    let silence: Float
    let variability: Float
    let spectral: Float
}

struct DailyBlobView: View {
    
    @StateObject var manager = RecordingManager.shared
    @StateObject var player: DayAudioPlayer
    
    let day: Date
    var body: some View {
        let normalizedDay = Calendar.current.startOfDay(for: day)
        let recordings = manager.recordingsByDay[normalizedDay] ?? []

        VStack{
            
            BlobView(recording: player.currentRecording, summary: player.currentRecordingFeatures, isPlaying: $player.isPlaying)
                .frame(height: 300)
            
            Text(formattedDate(day))
                .font(.headline)
                Button(player.isPlaying ? "Pause" : "Play") {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        player.playAll()
                        player.isPlaying = true
                    }
                }
                .buttonStyle(.borderedProminent)
                
        }
        .padding()
    }
    
    func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    init(day: Date) {
            self.day = day
            _player = StateObject(wrappedValue: DayAudioPlayer(day: day))
        }
}

