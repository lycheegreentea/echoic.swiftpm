import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            
        }
        TabView{
            RecordView()
                .tabItem{
                    Label("Record", systemImage: "waveform")
                }
            DailyView()
                .tabItem{
                    Label("Listen", systemImage: "headphones")
                }
            InfoView()
                .tabItem{
                    Label("About", systemImage: "text.rectangle")
                }
            
        }
    }
}
