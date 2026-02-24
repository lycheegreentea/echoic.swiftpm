//
//  RecordingManager.swift
//  echoic
//
//  Created by Lauren Chen on 2/23/26.
//

import SwiftUI
import Combine

@MainActor
class RecordingManager: ObservableObject{
    static let shared = RecordingManager()
    @Published var recordings: [Recording] = []
    
    var recordingsByDay: [Date: [Recording]]{
        Dictionary(grouping: recordings) { recording in
            Calendar.current.startOfDay(for: recording.date)
        }
    }
    var sortedDays: [Date] {
        recordingsByDay.keys.sorted(by: >)
    }
}
