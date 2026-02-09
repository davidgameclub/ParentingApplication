//
//  ParentingApplication_secondApp.swift
//  ParentingApplication_second
//
//  Created by Michael on 2026/2/8.
//

import SwiftUI
import SwiftData

@main
struct ParentingApplication_secondApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Initialize the SwiftData container for our model
        .modelContainer(for: UserProfile.self)
    }
}
