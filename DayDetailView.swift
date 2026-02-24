//
//  DayDetailView.swift
//  echoic
//
//  Created by Lauren Chen on 2/23/26.
//

import SwiftUI

struct DayDetailView: View{
    @StateObject var manager = RecordingManager.shared
    let initialDay: Date
    let day: Date
    @State private var selectedIndex: Int = 0
    var body: some View{
        let days = manager.sortedDays
        
        TabView(selection: $selectedIndex) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                DailyBlobView(day: day)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .onAppear{
            if let index = days.firstIndex(of: initialDay){
                selectedIndex = index
            }
        }
    }
    func play(_ url: URL) {
        //implemnet
    }
    func formattedDate(_ date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
