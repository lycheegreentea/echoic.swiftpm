//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 1/30/26.
//

import SwiftUI
import Swift
import AVFoundation
import Combine

struct RecordView: View {
    @StateObject private var rec = Recorder()
    @State private var recordings: [URL] = []
    
    var body: some View {
        VStack{
            BarVisualizer(values: rec.meterHistory, barCount: 24)
                .frame(height: 60)
                .padding(.horizontal)
            
            ProgressView(value: rec.meterLevel)
                .progressViewStyle(.linear)
                .animation(.linear, value: rec.meterLevel)
                .tint(.green)
            HStack{
                Button(rec.isRecording ? "Stop": "Record"){
                    if rec.isRecording{
                        rec.stop()
                    } else {
                        rec.start()
                    }
                }
            }
            
            if let url = rec.fileURL{
                Text("File: \(url.lastPathComponent)")
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            List{
                Section("Recordings"){
                    ForEach(recordings, id: \.self){ url in
                        HStack{
                            Text(url.lastPathComponent)
                            .font(.footnote)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        }
                    }
                }
            }
        }
        .padding()
        .task{
            rec.requestPermission{_ in}
            recordings = recordingList()
        }
    }
    func recordingList() -> [URL]{
        let dir = try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Recordings", isDirectory: true)
        guard let dir, let files = try?
                FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)else {return []}
        return files.filter{$0.pathExtension == "m4a"}.sorted{ $0.lastPathComponent > $1.lastPathComponent}
    }
}

#Preview {
    RecordView()
}
