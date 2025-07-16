//
//  AccountsView.swift
//  Anemone
//
//  Created by Ode on 7/14/25.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var storedAccounts: [Account] = []
    @State private var showingAddAccount = false
    @State private var selectedAccount: Account?
    @State private var showingEditAccount = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                AccountsListView(accounts: $storedAccounts,
                             showingAddAccount: $showingAddAccount,
                             selectedAccount: $selectedAccount,
                             showingEditAccount: $showingEditAccount,
                             showingDeleteAlert: $showingDeleteAlert)
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddAccount = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            storedAccounts = accounts
        }
        .onChange(of: accounts) { oldValue, newValue in
            storedAccounts = newValue
        }
    }
}

struct AccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var accounts: [Account]
    @Binding var showingAddAccount: Bool
    @Binding var selectedAccount: Account?
    @Binding var showingEditAccount: Bool
    @Binding var showingDeleteAlert: Bool
    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountRow(account: account)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAccount = account
                        showingEditAccount = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            selectedAccount = account
                            showingDeleteAlert = true
                        }
                        .tint(.red)
                        
                        Button("Edit") {
                            selectedAccount = account
                            showingEditAccount = true
                        }
                        .tint(.blue)
                    }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddEditAccountView()
        }
        .sheet(isPresented: $showingEditAccount) { [selectedAccount] in
            if let account = selectedAccount {
                AddEditAccountView(account: account)
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let account = selectedAccount {
                    deleteAccount(account)
                }
            }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
    
    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
        try? modelContext.save()
    }
}

struct AccountRow: View {
    let account: Account
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(account.name)
                    .font(.headline)
                Spacer()
                Text(CurrencyFormatter.format(account.checkpointBalance, currency: account.currency))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            HStack {
                Text("Updated \(account.checkpointDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
                Text(account.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)

            }
        }
        .padding(.vertical, 4)
    }
}


struct AddEditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let account: Account?
    
    @State private var name = ""
    @State private var currency = "USD"
    @State private var initialBalance = ""
    @State private var showingError = false
    @State private var createDate = Date()
    @State private var errorMessage = ""
    
    private let commonCurrencies = ["USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD"]
    
    init(account: Account? = nil) {
        self.account = account
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Account Details Section
                Section("Account Details") {
                    HStack {
                        Text("Account Name")
                        Spacer()
                        TextField("Name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                    }
                    
                    Picker("Currency", selection: $currency) {
                        ForEach(commonCurrencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                    .pickerStyle(.menu)
                    HStack {
                        Text("Initial Balance")
                        TextField("0.00", text: $initialBalance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: initialBalance) { oldValue, newValue in
                                    // Only allow numbers and one decimal point with max 2 decimal places
                                    let filtered = filterNumericInput(newValue)
                                    if filtered != newValue {
                                        initialBalance = filtered
                                    }
                                }
                    }
                    if account != nil {
                        HStack {
                            DatePicker(
                                "Created Date",
                                selection: $createDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }
                
                // Account Info Section (only for editing)
                if let account = account {
                    Section("Account Information") {
                        HStack {
                            Text("Current Balance")
                            Spacer()
                            Text(CurrencyFormatter.format(account.checkpointBalance, currency: account.currency))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(account == nil ? "Add Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty || initialBalance.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadAccountData()
        }
    }
    
    private func filterNumericInput(_ input: String) -> String {
        let numbersAndDots = input.filter { $0.isNumber || $0 == "." }
        
        let components = numbersAndDots.components(separatedBy: ".")
        
        if components.count <= 1 {
            return numbersAndDots
        } else {
            let integerPart = components[0]
            let decimalPart = String(components[1].prefix(2))
            return integerPart + "." + decimalPart
        }
    }
    
    private func loadAccountData() {
        guard let account = account else { return }
        name = account.name
        currency = account.currency
        initialBalance = String(describing: account.initialBalance)
        createDate = account.createDate
    }
    
    private func saveAccount() {
        guard let balanceDecimal = Decimal(string: initialBalance) else {
            errorMessage = "Please enter a valid balance amount"
            showingError = true
            return
        }
        
        if let existingAccount = account {
            existingAccount.name = name
            existingAccount.currency = currency
            existingAccount.initialBalance = balanceDecimal
            existingAccount.createDate = createDate
            existingAccount.checkpointBalance = balanceDecimal
        } else {
            let newAccount = Account(name: name, currency: currency, initialBalance: balanceDecimal)
            modelContext.insert(newAccount)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct AccountSummaryRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(account.currency)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.format(account.checkpointBalance, currency: account.currency))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    let preview = Preview()
    preview.addExamples(
        accounts: [Account.example],
        categories: [Category.example],
        transactions: [Transaction.example]
    )
    return HomeView()
        .modelContainer(preview.modelContainer)
}
