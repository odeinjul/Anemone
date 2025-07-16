//
//  Preview.swift
//  Anemone
//
//  Created by Ode on 7/16/25.
//

import SwiftData

struct Preview {
    let modelContainer: ModelContainer

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            // Register all your models
            modelContainer = try ModelContainer(
                for: Account.self, Category.self, Transaction.self,
                configurations: config
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    func addExamples(accounts: [Account], categories: [Category], transactions: [Transaction]) {
        Task { @MainActor in
            accounts.forEach { modelContainer.mainContext.insert($0) }
            categories.forEach { modelContainer.mainContext.insert($0) }
            transactions.forEach { modelContainer.mainContext.insert($0) }
        }
    }
}
