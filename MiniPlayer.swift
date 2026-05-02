//
//  Player.swift
//  echoic
//
//  Created by Lauren Chen on 2/2/26.
//
//

    
import Combine
import SwiftUI
import AVFoundation


final class MiniPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    
    @Published var progress: Double = 0
    
    private var player: AVAudioPlayer?
    
    private var timer: AnyCancellable?
    
    private var currentURL: URL?
    private var completion: (() -> Void)?
    
    func play(_ url: URL?, completion: (()-> Void)?=nil) {
        guard let url else { return }
        
        if isPlaying, currentURL == url {
            pause()
            return
        }
        
        stop()
        self.completion = completion
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            currentURL = url
            
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            
            startUpdatingProgress()
        } catch {
            print("Playback failed:", error)
            isPlaying = false
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopUpdatingProgress()
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        progress = 0
        stopUpdatingProgress()
        player = nil
        currentURL = nil
    }
    
    func seek(to prog: Double) {
        guard let player, player.duration > 0 else { return }
        player.currentTime = prog * player.duration
        progress = prog
    }
    
    private func startUpdatingProgress() {
        stopUpdatingProgress()
        
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.player else { return }
                
                if player.isPlaying {
                    self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                } else {
                    self.isPlaying = false
                    self.stopUpdatingProgress()
                }
            }
    }
    
    private func stopUpdatingProgress() {
        timer?.cancel()
        timer = nil
    }
    
    var isPaused: Bool {
        player != nil && !isPlaying && progress > 0 && progress < 1
    }
    
    var playingURL: URL? { currentURL }
}
extension MiniPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        progress = 0
        currentURL = nil
        stopUpdatingProgress()
        completion?()
        completion = nil
    }
}
