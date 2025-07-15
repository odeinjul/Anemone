//
//  AnemoneApp.swift
//  Anemone
//
//  Created by Ode on 6/27/25.
//

import SwiftUI
import SwiftData

@main
struct AnemoneApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Category.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                /*
                AnalyzeView()
                    .tabItem {
                        Label("Analyze", systemImage: "chart.line.text.clipboard")
                    }
                */
                StaticView()
                    .tabItem {
                        Label("Static", systemImage: "wallet.bifold")
                    }
                /*
                TestView()
                    .tabItem {
                        Label("Test", systemImage: "gear")
                    }
                */
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
