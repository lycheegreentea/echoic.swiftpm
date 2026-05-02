//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 2/24/26.
//

import SwiftUI
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
struct BlobView: View {
    let recording: Recording?
    let summary: DaySummary
    @Binding var isPlaying: Bool
    @State private var pulse: CGFloat = 1.0
    @State private var pulse2: CGFloat = 1.0
    @State private var pulse3: CGFloat = 1.0
    @State private var rotation: Double = 0
    var accessibilityDescription: String{
        let state = isPlaying ? "Playing": "Paused"
        let energy = (recording?.averageLoudness ?? 0)>0.05 ? "energetic": "quiet"
        let tone = (recording?.spectralCentroid ?? 0)>1500 ? "bright": "warm"
        return "\(state) recording. \(energy) and \(tone) tone."
    }
    var body: some View {
        
        ZStack{
            Circle()
                .fill(blobColor.opacity(0.25))
                .frame(width: 200 * pulse3, height: 220 * pulse3)
                .blur(radius:18)
                .shadow(color: blobColor.opacity(0.6), radius: 20*pulse)
            
                
            Ellipse()
                .fill(blobColor.opacity(0.6))
                .frame(width: 230*pulse2, height: 200*pulse2)
                .blur(radius:8)
                .rotationEffect(.degrees(-rotation*0.6))
            Circle()
                .fill(blobColor)
                .frame(width: 180*pulse, height: 180*pulse)
                .shadow(color: blobColor.opacity(0.9), radius:40*pulse)
            
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityElement(children: .ignore)
        .animation(.easeInOut(duration: 0.5), value: pulse)
        .animation(.easeInOut(duration: 1.2), value: blobColor.description)
        


        .onAppear{
            if isPlaying{startPulsing()}
        }
        .onChange(of: isPlaying) { playing in
            if playing { startPulsing() } else {stopPulsing()}}
        .onChange(of: recording?.url) {_ in
            if isPlaying {stopPulsing(); startPulsing()}}
        
    }
    

    var blobColor: Color{
        let source = recording
        
        let spectral = source?.spectralCentroid ?? summary.spectral
        let loudness = source?.averageLoudness ?? summary.loudness
        let silence = source?.silenceRatio ?? summary.silence
        let normalizedSpectral = Double(((spectral - 300) / (2500 - 300)).clamped(to: 0.0...1.0))
        return Color(
            hue: Double(0.55+normalizedSpectral*0.3),
            saturation: Double(loudness).clamped(to: 0.4...1.0),
            brightness: Double(1.0-silence*0.5)
        )
    }
    func startPulsing(){
        let variability = CGFloat(recording?.loudnessVariability ?? summary.variability)
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)){
            pulse = 1.0+0.15+variability*0.25}
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)){
            pulse2 = 1.0+0.20+variability*0.2}
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)){
            pulse3 = 1.0+0.25+variability*0.3}
        withAnimation(.linear(duration:8).repeatForever(autoreverses: false)){
            rotation=360
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
    func stopPulsing(){
        pulse = 1.0
        pulse2 = 1.0
        pulse3 = 1.0
    }
}

