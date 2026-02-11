//
//  ParentingApplication_secondApp.swift
//  ParentingApplication_second
//
//  Created by Michael on 2026/2/8.
//

import SwiftUI
import SwiftData

@main
struct ParentingApplication: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WakeupActivity.self,
            SleepActivity.self,
            CustomActivity.self,
            FeedingBottleActivity.self,
            DiaperActivity.self
        ])

        // 關鍵點：將 isStoredInMemoryOnly 設為 true
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // 資料只會留在記憶體，App 關閉即消失
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("無法建立容器: \(error)")
        }
    }()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Initialize the SwiftData container for our model
        .modelContainer(for: [
            UserProfile.self,
            WakeupActivity.self,
            SleepActivity.self,
            CustomActivity.self,
            FeedingBottleActivity.self,
            DiaperActivity.self
        ])
    }
}
