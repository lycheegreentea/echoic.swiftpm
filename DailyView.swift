//
//  SwiftUIView.swift
//  echoic
//
//  Created by Lauren Chen on 2/23/26.
//

import SwiftUI

struct DailyView: View {
    @StateObject var manager = RecordingManager.shared
    var body: some View {
        NavigationStack {
            List{
                ForEach(manager.sortedDays, id: \.self) { day in
                    NavigationLink{
                        DayDetailView(initialDay: day)
                        
                    } label: {
                        Text(formattedDate(day))
                    }
                    .accessibilityHint("Opens sound summaries for this day")
                }
            }
            .navigationTitle("Your life's soundtrack")
            .accessibilityLabel("List of days")
        }
    }
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    DailyView()
}
