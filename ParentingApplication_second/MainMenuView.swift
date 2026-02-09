//
//  MainMenuView.swift
//  ParentingApplication_second
//
//  Created by Assistant on [Current Date].
//

import SwiftUI

struct MainMenuView: View {
    // State to track the currently selected tab
    @State private var selectedTab: Tab = .home
    
    // Enum to define the tabs and conform to Hashable
    private enum Tab: Hashable { // FIX 2: Explicitly conforming to Hashable
        case home
        case activity
        case stats
        case settings
    }
    
    var body: some View {
        // Use TabView for the bottom tab bar interface
        TabView(selection: $selectedTab) {
            
            // 1. Home Tab
            NavigationStack { // FIX 1: Wrapping in NavigationStack
                HomePageView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(Tab.home)
            
            // 2. Activity Tab
            NavigationStack { // FIX 1: Wrapping in NavigationStack
                ActivityView()
            }
            .tabItem {
                Label("Activity", systemImage: "calendar")
            }
            .tag(Tab.activity)
            
            // 3. Stats Tab
            NavigationStack { // FIX 1: Wrapping in NavigationStack
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(Tab.stats)
            
            // 4. Settings Tab
            NavigationStack { // FIX 1: Wrapping in NavigationStack (Standardizing)
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        // Applying this here controls the navigation bar appearance across all pushed views if they have titles set.
        .navigationBarBackButtonHidden(true)
    }
}
