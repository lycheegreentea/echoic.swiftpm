//
//  Recording.swift
//  echoic
//
//  Created by Lauren Chen on 2/23/26.
//
import Foundation
struct Recording: Identifiable, Codable{
    var id = UUID()
    let spectralCentroid: Float
    let silenceRatio: Float
    let averageLoudness: Float
    let loudnessVariability: Float
    let url: URL
    let date: Date
    init(spectralCentroid: Float, silenceRatio: Float, averageLoudness: Float, loudnessVariability: Float, url: URL, date: Date) {
        self.spectralCentroid = spectralCentroid
        self.silenceRatio = silenceRatio
        self.averageLoudness = averageLoudness
        self.loudnessVariability = loudnessVariability
        self.url = url
        self.date = date
    }
    
}

