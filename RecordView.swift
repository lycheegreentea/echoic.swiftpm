import SwiftUI
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import Accelerate

struct RecordView: View {
    @StateObject private var rec = MiniRecorder()
    @StateObject private var player = MiniPlayer()
    @StateObject var manager = RecordingManager.shared
    @State private var micDenied = false

    func trimAudio(from source: URL, to dest: URL, completion: @escaping () -> Void) {
        let asset = AVURLAsset(url: source)
        let duration = CMTimeGetSeconds(asset.duration)
        let trimSeconds = 0.3
        let start = trimSeconds
        let end = max(start + 0.1, duration - trimSeconds)
        guard end > start else {
            try? FileManager.default.moveItem(at: source, to: dest)
            completion()
            return
        }
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            try? FileManager.default.moveItem(at: source, to: dest)
            completion()
            return
        }
        exporter.outputURL = dest
        exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 44100),
            end: CMTime(seconds: end, preferredTimescale: 44100)
        )
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter.status != .completed {
                    print("Export failed:", exporter.error ?? "unknown")
                    completion()
                    return
                }
                try? FileManager.default.removeItem(at: source)
                completion()
            }
        }
    }

    func saveRecordings() {
        let url = recordingsDirectory().appendingPathComponent("recordings.plist")
        try? PropertyListEncoder().encode(manager.recordings).write(to: url)
    }

    func loadRecording() -> [Recording] {
        let plist = recordingsDirectory().appendingPathComponent("recordings.plist")
        guard let data = try? Data(contentsOf: plist),
              let saved = try? PropertyListDecoder().decode([Recording].self, from: data)
        else { return [] }

        return saved.compactMap { rec in
            let url = recordingsDirectory().appendingPathComponent(rec.url.lastPathComponent)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }

            let features = analyzeRecording(url: url)
            return Recording(
                spectralCentroid: features.spectralCentroid,
                silenceRatio: features.silenceRatio,
                averageLoudness: features.averageLoudness,
                loudnessVariability: features.loudnessVariability,
                url: url,
                date: rec.date
            )
        }
    }


    func recordingsDirectory() -> URL {
        let dir = (try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Recordings", isDirectory: true)) ?? URL(fileURLWithPath: "")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func analyzeRecording(url: URL) -> Recording {
        guard let file = try? AVAudioFile(forReading: url) else {
            return Recording(spectralCentroid: 0, silenceRatio: 0, averageLoudness: 0, loudnessVariability: 1, url: url, date: Date())
        }
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return Recording(spectralCentroid: 0, silenceRatio: 0, averageLoudness: 0, loudnessVariability: 1, url: url, date: Date())
        }
        do { try file.read(into: buffer) } catch {
            return Recording(spectralCentroid: 0, silenceRatio: 0, averageLoudness: 0, loudnessVariability: 1, url: url, date: Date())
        }
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else {
            return Recording(spectralCentroid: 0, silenceRatio: 0, averageLoudness: 0, loudnessVariability: 1, url: url, date: Date())
        }
        let sampleCount = Int(buffer.frameLength)
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(sampleCount))
        let frameSize = Int(format.sampleRate * 0.05)
        var rmsValues: [Float] = []
        for i in stride(from: 0, to: sampleCount - frameSize, by: frameSize) {
            var frameRMS: Float = 0
            vDSP_rmsqv(samples + i, 1, &frameRMS, vDSP_Length(frameSize))
            rmsValues.append(frameRMS)
        }
        let loudnessVariability = standardDeviation(rmsValues)
        let silenceThreshold: Float = 0.01
        let silentFrames = rmsValues.filter { $0 < silenceThreshold }.count
        let silenceRatio = rmsValues.isEmpty ? 0 : Float(silentFrames) / Float(rmsValues.count)
        var spectralCentroid: Float = 0
        if sampleCount >= frameSize {
            let fftSize = frameSize
            let log2n = vDSP_Length(log2(Float(fftSize)))
            if let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) {
                defer { vDSP_destroy_fftsetup(fftSetup) }
                var centroidSum: Float = 0
                var magnitudeSum: Float = 0
                let halfSize = fftSize / 2
                for i in stride(from: 0, to: sampleCount - fftSize, by: fftSize) {
                    var frame = Array(UnsafeBufferPointer(start: samples.advanced(by: i), count: fftSize))
                    var window = [Float](repeating: 0, count: fftSize)
                    vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
                    vDSP_vmul(frame, 1, window, 1, &frame, 1, vDSP_Length(fftSize))
                    var realPart = [Float](repeating: 0, count: halfSize)
                    var imagPart = [Float](repeating: 0, count: halfSize)
                    var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
                    frame.withUnsafeBytes { ptr in
                        let complexPtr = ptr.bindMemory(to: DSPComplex.self)
                        vDSP_ctoz(complexPtr.baseAddress!, 2, &splitComplex, 1, vDSP_Length(halfSize))
                    }
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    var magnitudes = [Float](repeating: 0, count: halfSize)
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))
                    let binToHz = Float(format.sampleRate) / Float(fftSize)
                    for k in 0..<halfSize {
                        centroidSum += Float(k) * binToHz * magnitudes[k]
                        magnitudeSum += magnitudes[k]
                    }
                }
                spectralCentroid = magnitudeSum > 0 ? centroidSum / magnitudeSum : 0
            }
        }
        return Recording(
            spectralCentroid: spectralCentroid,
            silenceRatio: silenceRatio,
            averageLoudness: rms,
            loudnessVariability: loudnessVariability,
            url: url,
            date: Date()
        )
    }

    func standardDeviation(_ values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Float(values.count)
        let sumOfSquares = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
        return sqrt(sumOfSquares / Float(values.count))
    }

    var body: some View {
        NavigationStack{
            VStack(spacing: 24) {
                ZStack{
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 80 + CGFloat(rec.meterLevel) * 120,
                               height: 80 + CGFloat(rec.meterLevel) * 120)
                        .animation(.easeOut(duration: 0.1), value: rec.meterLevel)
                        .accessibilityHidden(true)
                }
                .frame(width: 200, height: 200)
                .accessibilityHidden(true)
                HStack(spacing: 12) {
                    Button(rec.isRecording ? "Stop" : "Record") {
                        playTapHaptic()
                        if rec.isRecording {
                            rec.stop {
                                guard let originalURL = rec.fileURL else { return }
                                let tempDest = recordingsDirectory()
                                    .appendingPathComponent("trimming_\(originalURL.lastPathComponent)")
                                trimAudio(from: originalURL, to: tempDest) {
                                    try? FileManager.default.removeItem(at: originalURL)
                                    try? FileManager.default.moveItem(at: tempDest, to: originalURL)
                                    let features = analyzeRecording(url: originalURL)
                                    manager.recordings.append(features)
                                    saveRecordings()
                                }
                            }
                        } else {
                            player.stop()
                            rec.start()
                        }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(rec.isRecording ? "Stop recording" : "Start recording")
                    .accessibilityHint(rec.isRecording ? "Saves and trims the recording" : "Begins a new voice recording")
                    
                    
                }
                
                List {
                    Section(header: Text("Recordings")
                        .foregroundColor(.primary)
                        .dynamicTypeSize(.xSmall ... .accessibility5)) {
                            ForEach(manager.recordings.reversed()) { recording in
                                HStack(spacing: 8) {
                                    Text(friendlyDate(for: recording.url))
                                        .font(.footnote)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    
                                    Button {
                                        if player.playingURL == recording.url && player.isPlaying {
                                            player.pause()
                                        } else {
                                            player.play(recording.url)
                                        }
                                    } label: {
                                        Image(systemName: (player.playingURL == recording.url && player.isPlaying) ? "pause.fill" : "play.fill")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    ProgressView(value: player.playingURL == recording.url ? player.progress : 0)
                                        .frame(width: 60)
                                        .accessibilityLabel("Playback progress")
                                }
                                .listRowBackground(Color(UIColor.secondarySystemBackground))
                                .accessibilityElement(children: .combine)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let recording = manager.recordings[index]
                                    try? FileManager.default.removeItem(at: recording.url)
                                    if player.playingURL == recording.url {
                                        player.stop()
                                    }
                                }
                                manager.recordings.remove(atOffsets: indexSet)
                                saveRecordings()
                            }
                        }
                }
                .accessibilityIdentifier("MainRecorderView")
                .accessibilityElement(children: .contain)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemBackground))
                
                Spacer()
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .task {
                rec.requestPermission { ok in
                    micDenied = (ok == false)
                }
                manager.recordings = recordingsList()
            }
            .onChange(of: rec.isRecording) { isRecording in
                if isRecording { player.stop() }
            }
            .alert("Microphone Access Needed", isPresented: $micDenied) {
                Button("OK", role: .cancel) {}
#if canImport(UIKit)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
#endif
            } message: {
                Text("Please allow microphone access in Settings to record audio.")
            }
        }
        .navigationTitle("Recorder")
    }
        

    func recordingsList() -> [Recording] { loadRecording() }

    private func playTapHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func friendlyDate(for url: URL) -> String {
        if let values = try? url.resourceValues(forKeys: [.creationDateKey]), let date = values.creationDate {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        return url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "T", with: " ")
    }

    private func audioDurationString(for url: URL) -> String {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds > 0 else { return "—" }
        let s = Int(seconds.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
