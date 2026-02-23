//
//  BarVisualizer.swift
//  echoic
//
//  Created by Lauren Chen on 1/30/26.
//
//

    
import SwiftUI
import Combine
import AVFoundation

struct MultiBarVisualizerView: View {
    let values: [Float]
    let barCount: Int
    
    var body: some View {
        GeometryReader { geo in
            let rawWidth = geo.size.width
            let rawHeight = geo.size.height
            let width = rawWidth.isFinite ? max(0, rawWidth) : 0
            let height = rawHeight.isFinite ? max(0, rawHeight) : 0
            
            let safeBarCount = max(1, barCount)
            let barSpacing: CGFloat = 0.1
            
            let totalSpacing = CGFloat(safeBarCount - 1) * barSpacing
            let availableWidth = max(0, width - totalSpacing)
            let barWidth = availableWidth / CGFloat(safeBarCount)
            
            let chunkSize = max(1, values.count / safeBarCount)
            
            let barValues: [Float] = (0..<safeBarCount).map { i in
                let start = i * chunkSize
                let end = min(start + chunkSize, values.count)
                if start >= end { return 0 }
                let slice = values[start..<end]
                return slice.reduce(0, +) / Float(slice.count)
            }
            
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<safeBarCount, id: \.self) { i in
                    // Draw each bar with a minimum height for visibility.
                    let base = CGFloat(barValues[i])
                    let v = base.isFinite ? base : 0
                    let capped = max(0.07, min(v, 1)) // Ensure thin min bar to see quiet sections.
                    let barHeight = max(0, min(height, capped * height))
                    let safeBarWidth = max(0, barWidth)
                    let yOffset = (height - barHeight) / 2
                    
                    Rectangle()
                    
                    
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: safeBarWidth, height: barHeight)
                        .cornerRadius(safeBarWidth / 2)
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                        .offset(y: yOffset)
                }
            }
        }
    }
}
