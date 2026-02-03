import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            Text("Hello, world!")
            
        }
        TabView{
            RecordView()
                .tabItem{
                    Label("Record", systemImage: "house")
                }
            RecordView()
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
