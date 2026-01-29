//
//  ContentView.swift
//  IConnect
//

import SwiftUI

struct ContentView: View {
    @State private var showHomePage = true
    @State private var selectedTab = 0 // Start with Pin Art tab
    
    var body: some View {
        if showHomePage {
            HomeView {
                showHomePage = false
            }
            .frame(minWidth: 700, minHeight: 500)
        } else {
            TabView(selection: $selectedTab) {
                PinArtView()
                    .tabItem {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("Pin Art")
                    }
                    .tag(0)
                
                IConnectView()
                    .tabItem {
                        Image(systemName: "arrow.3.trianglepath")
                        Text("Guided (Experimental)")
                    }
                    .tag(1)
                
                ScaleView()
                    .tabItem {
                        Image(systemName: "scalemass")
                        Text("Scale")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .frame(minWidth: 700, minHeight: 500)
        }
    }
}


#Preview {
    ContentView()
}
