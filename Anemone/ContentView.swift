//
//  ContentView.swift
//  Anemone
//
//  Created by Ode on 6/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(accounts) { account in
                    NavigationLink {
                        Text("Account at \(account.createDate, format: Date.FormatStyle(date: .numeric, time: .standard)), \(account.name), \(account.currency)")
                    } label: {
                        Text("Account at \(account.createDate, format: Date.FormatStyle(date: .numeric, time: .standard)), \(account.name), \(account.currency)")
                    }
                }
                .onDelete(perform: deleteAccounts)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addAccount) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an account")
        }
    }

    private func addAccount() {
        withAnimation {
            let newAccount = Account(name: "A", currency: "USD", initialBalance: 0.0)
            modelContext.insert(newAccount)
        }
    }

    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(accounts[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Account.self, inMemory: true)
}
