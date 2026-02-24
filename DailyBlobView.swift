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
    let day: Date
    var body: some View {
        let recordings = manager.recordingsByDay[day] ?? []
        let summary = summarize(recordings)
        VStack{
            Circle()
                    .fill(.blue)
                    .frame(height: 300)
            //BlobView(summary: summary)
                //.frame(height: 300)
            Text(formattedDate(day))
                .font(.headline)
        }
    }
    func summarize(_ recordings: [Recording]) -> DaySummary {
        guard !recordings.isEmpty else {
            return DaySummary(loudness: 0, silence: 1, variability: 0, spectral: 0)
        }
        let avgLoudness = recordings.map { $0.averageLoudness}.reduce(0, +) / Float(recordings.count)
        let avgSilence = recordings.map { $0.silenceRatio}.reduce(0, +) / Float(recordings.count)
        let avgVariability = recordings.map { $0.loudnessVariability}.reduce(0, +) / Float(recordings.count)
        let avgSpectralCentroid = recordings.map { $0.spectralCentroid}.reduce(0, +) / Float(recordings.count)
        return DaySummary(
            loudness: avgLoudness,
            silence: avgSilence,
            variability: avgVariability,
            spectral: avgSpectralCentroid
        )
    }
    func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
}

#Preview {
    DailyBlobView( day: Date())
}
