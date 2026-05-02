//
//  info.swift
//  echoic
//
//  Created by Lauren Chen on 2/27/26.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 80, height: 80)
                        Image(systemName: "waveform")
                            .font(.system(size: 32))
                            .foregroundStyle(.background)
                    }
                    Text("echoic")
                        .font(.largeTitle.bold())
                    Text("Your life's soundtrack")
                        .font(.subheadline)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 20) {
                    InfoParagraph(
                        icon: "brain",
                        text: "Auditory memories evoke strong emotional responses and have deep links to nostalgia. Yet many people don't realize this, and miss out on the role these memories could play in their lives."
                    )
                    InfoParagraph(
                        icon: "ear",
                        text: "This app was created so that you can recall the fleeting and seemingly ordinary sounds that ultimately define parts of your life."
                    )
                    InfoParagraph(
                        icon: "sparkles",
                        text: "Collect snippets of ambience, even if they seem mundane, because those mundane things might end up being the most memorable."
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoParagraph: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
        }
    }
}
