//
//  Recorder.swift
//  echoic
//
//  Created by Lauren Chen on 1/30/26.
//
    

import Combine
import AVFoundation
import UIKit
import AudioToolbox

// MARK: - MiniRecorder

final class MiniRecorder: ObservableObject {
    
 
    @Published var isRecording = false
    @Published var meterLevel: Float = 0
    @Published var meterHistory: [Float] = []

    var meterInterval: TimeInterval = 0.05
    var maxHistoryCount: Int = 80
    private var recorder: AVAudioRecorder?
    private var meterTimer: AnyCancellable?
    private(set) var fileURL: URL?
    func requestPermission(_ done: @escaping @Sendable (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        }
    }
    
    @MainActor func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let dir = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("Recordings", isDirectory: true)
            
          
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            // 3) Create a timestamped filename to avoid collisions.
            // Replace ":" with "-" since ":" is not allowed in filenames on some platforms.
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
            let url = dir.appendingPathComponent("\(stamp).m4a")
            fileURL = url
            
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            playStartFeedback()
            isRecording = true
            
            startMetering()
        } catch {
            print("Start failed:", error)
        }
    }
    
    @MainActor func stop() {
        stopMetering()
        recorder?.stop()
        playStopFeedback()
        isRecording = false
        recorder = nil
    }
    
   
    private func startMetering() {
        meterTimer?.cancel()
        
        meterTimer = Timer.publish(every: meterInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let rec = self.recorder, rec.isRecording else { return }
                rec.updateMeters()
                let power = rec.averagePower(forChannel: 0)
                self.meterLevel = Self.normalize(power)
                
                self.meterHistory.append(self.meterLevel)
                
                if self.meterHistory.count > self.maxHistoryCount {
                    self.meterHistory.removeFirst(self.meterHistory.count - self.maxHistoryCount)
                }
            }
    }
    
    private func stopMetering() {
        meterTimer?.cancel()
        meterTimer = nil
        meterLevel = 0
        meterHistory.removeAll()
    }
    
    private static func normalize(_ db: Float) -> Float {
        let floor: Float = -60
        if db <= floor { return 0 }
        let clamped = max(min(db, 0), floor)
        return (clamped - floor) / -floor
    }
    
    @MainActor private func playStartFeedback() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        AudioServicesPlaySystemSound(1113)
    }
    
    @MainActor private func playStopFeedback() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
        AudioServicesPlaySystemSound(1114) 
    }
}
