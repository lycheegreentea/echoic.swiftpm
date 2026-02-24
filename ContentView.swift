import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            
        }
        TabView{
            RecordView()
                .tabItem{
                    Label("Record", systemImage: "house")
                }
            DailyView()
                .tabItem{
                    Label("View", systemImage: "house")
                }
            RecordView()
                .tabItem{
                    Label("Insights", systemImage: "house")
                }
            
        }
    }
}
