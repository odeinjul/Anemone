//
//  TransactionsView.swift
//  test
//
//  Created by Ode on 7/15/25.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    
    @State private var storedTransactions: [Transaction] = []
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var showingEditTransaction = false
    @State private var showingDeleteAlert = false
    @State private var filterAccount: Account?
    @State private var filterType: TransactionType?
    @State private var sortOrder: TransactionSortOrder = .dateDescending
    
    enum TransactionSortOrder: String, CaseIterable {
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (Highest)"
        case amountAscending = "Amount (Lowest)"
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
    }
    
    var filteredAndSortedTransactions: [Transaction] {
        var filtered = storedTransactions
        
        // Apply filters
        if let filterAccount = filterAccount {
            filtered = filtered.filter { $0.account.id == filterAccount.id || $0.transferAccount?.id == filterAccount.id }
        }
        
        if let filterType = filterType {
            filtered = filtered.filter { $0.type == filterType }
        }
        
        // Apply sorting
        switch sortOrder {
        case .dateDescending:
            filtered.sort { $0.account.checkpointDate > $1.account.checkpointDate }
        case .dateAscending:
            filtered.sort { $0.account.checkpointDate < $1.account.checkpointDate }
        case .amountDescending:
            filtered.sort { $0.amount > $1.amount }
        case .amountAscending:
            filtered.sort { $0.amount < $1.amount }
        case .nameAscending:
            filtered.sort { $0.name < $1.name }
        case .nameDescending:
            filtered.sort { $0.name > $1.name }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filter and Sort Controls
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Account Filter
                        Menu {
                            Button("All Accounts") {
                                filterAccount = nil
                            }
                            ForEach(accounts) { account in
                                Button(account.name) {
                                    filterAccount = account
                                }
                            }
                        } label: {
                            HStack {
                                Text(filterAccount?.name ?? "All Accounts")
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        // Type Filter
                        Menu {
                            Button("All Types") {
                                filterType = nil
                            }
                            Button("Income") {
                                filterType = .income
                            }
                            Button("Expense") {
                                filterType = .expense
                            }
                            Button("Transfer") {
                                filterType = .transfer
                            }
                        } label: {
                            HStack {
                                Text(filterType?.rawValue.capitalized ?? "All Types")
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        // Sort Order
                        Menu {
                            ForEach(TransactionSortOrder.allCases, id: \.self) { order in
                                Button(order.rawValue) {
                                    sortOrder = order
                                }
                            }
                        } label: {
                            HStack {
                                Text("Sort")
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Transactions List
                TransactionsListView(
                    transactions: .constant(filteredAndSortedTransactions),
                    showingAddTransaction: $showingAddTransaction,
                    selectedTransaction: $selectedTransaction,
                    showingEditTransaction: $showingEditTransaction,
                    showingDeleteAlert: $showingDeleteAlert
                )
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            storedTransactions = transactions
        }
        .onChange(of: transactions) { oldValue, newValue in
            storedTransactions = newValue
        }
    }
}

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var transactions: [Transaction]
    @Binding var showingAddTransaction: Bool
    @Binding var selectedTransaction: Transaction?
    @Binding var showingEditTransaction: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        List {
            if transactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add your first transaction to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .listRowSeparator(.hidden)
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTransaction = transaction
                            showingEditTransaction = true
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                selectedTransaction = transaction
                                showingDeleteAlert = true
                            }
                            .tint(.red)
                            
                            Button("Edit") {
                                selectedTransaction = transaction
                                showingEditTransaction = true
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddEditTransactionView()
        }
        .sheet(isPresented: $showingEditTransaction) { [selectedTransaction] in
            if let transaction = selectedTransaction {
                AddEditTransactionView(transaction: transaction)
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let transaction = selectedTransaction {
                    deleteTransaction(transaction)
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            // Transaction Type Icon
            Image(systemName: transactionIcon)
                .font(.title2)
                .foregroundColor(transactionColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(formatCurrency(transaction.amount, currency: transaction.account.currency))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(transactionColor)
                }
                
                HStack {
                    Text(transaction.category.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(transaction.account.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if transaction.type == .transfer, let transferAccount = transaction.transferAccount {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(transferAccount.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let transferAmount = transaction.transferAmount {
                            Spacer()
                            Text(formatCurrency(transferAmount, currency: transferAccount.currency))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var transactionIcon: String {
        switch transaction.type {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    private var transactionColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return .blue
        }
    }
    
    private func formatCurrency(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

struct AddEditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    
    let transaction: Transaction?
    
    @State private var name = ""
    @State private var type: TransactionType = .expense
    @State private var amount = ""
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var transferAccount: Account?
    @State private var transferAmount = ""
    @State private var transactionDate = Date()
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingNewCategoryAlert = false
    @State private var newCategoryName = ""
    
    init(transaction: Transaction? = nil) {
        self.transaction = transaction
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section("Transaction Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Transaction name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                    }
                    
                    Picker("Type", selection: $type) {
                        Text("Income").tag(TransactionType.income)
                        Text("Expense").tag(TransactionType.expense)
                        Text("Transfer").tag(TransactionType.transfer)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { oldValue, newValue in
                        // Reset transfer fields when type changes
                        if newValue != .transfer {
                            transferAccount = nil
                            transferAmount = ""
                        }
                    }
                    
                    DatePicker(
                        "Date",
                        selection: $transactionDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                }
                
                // Amount Section
                Section("Amount") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: amount) { oldValue, newValue in
                                let filtered = filterNumericInput(newValue)
                                if filtered != newValue {
                                    amount = filtered
                                }
                            }
                    }
                    
                    if let selectedAccount = selectedAccount {
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(selectedAccount.currency)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Account Section
                Section("Account") {
                    Picker("From Account", selection: $selectedAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text("\(account.name) (\(account.currency))").tag(Account?.some(account))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if type == .transfer {
                        Picker("To Account", selection: $transferAccount) {
                            Text("Select Account").tag(Account?.none)
                            ForEach(accounts.filter { $0.id != selectedAccount?.id }) { account in
                                Text("\(account.name) (\(account.currency))").tag(Account?.some(account))
                            }
                        }
                        .pickerStyle(.menu)
                        
                        // Transfer amount (if different currencies)
                        if let fromAccount = selectedAccount,
                           let toAccount = transferAccount,
                           fromAccount.currency != toAccount.currency {
                            HStack {
                                Text("Amount to \(toAccount.currency)")
                                Spacer()
                                TextField("0.00", text: $transferAmount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: transferAmount) { oldValue, newValue in
                                        let filtered = filterNumericInput(newValue)
                                        if filtered != newValue {
                                            transferAmount = filtered
                                        }
                                    }
                            }
                        }
                    }
                }
                
                // Category Section
                Section("Category") {
                    HStack {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(Category?.none)
                            ForEach(categories) { category in
                                Text(category.name).tag(Category?.some(category))
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button("New") {
                            showingNewCategoryAlert = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                }
                
                // Note Section
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Current Balance Preview (for editing)
                if let transaction = transaction {
                    Section("Transaction Info") {
                        HStack {
                            Text("Account Balance")
                            Spacer()
                            Text(formatCurrency(transaction.account.checkpointBalance, currency: transaction.account.currency))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("New Category", isPresented: $showingNewCategoryAlert) {
                TextField("Category name", text: $newCategoryName)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Add") {
                    addNewCategory()
                }
                .disabled(newCategoryName.isEmpty)
            } message: {
                Text("Enter a name for the new category")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadTransactionData()
            if selectedAccount == nil && !accounts.isEmpty {
                selectedAccount = accounts.first
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty &&
               !amount.isEmpty &&
               selectedAccount != nil &&
               selectedCategory != nil &&
               (type != .transfer || transferAccount != nil) &&
               Decimal(string: amount) != nil
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
    
    private func loadTransactionData() {
        guard let transaction = transaction else { return }
        name = transaction.name
        type = transaction.type
        amount = String(describing: transaction.amount)
        selectedAccount = transaction.account
        selectedCategory = transaction.category
        note = transaction.note ?? ""
        transferAccount = transaction.transferAccount
        if let transferAmt = transaction.transferAmount {
            transferAmount = String(describing: transferAmt)
        }
    }
    
    private func addNewCategory() {
        let newCategory = Category(name: newCategoryName)
        modelContext.insert(newCategory)
        
        do {
            try modelContext.save()
            selectedCategory = newCategory
            newCategoryName = ""
        } catch {
            errorMessage = "Failed to create category: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func saveTransaction() {
        guard let amountDecimal = Decimal(string: amount),
              let account = selectedAccount,
              let category = selectedCategory else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        var transferAmountDecimal: Decimal?
        if type == .transfer {
            if let transferAcc = transferAccount {
                if transferAcc.currency != account.currency {
                    guard let transferAmt = Decimal(string: transferAmount) else {
                        errorMessage = "Please enter a valid transfer amount"
                        showingError = true
                        return
                    }
                    transferAmountDecimal = transferAmt
                } else {
                    transferAmountDecimal = amountDecimal
                }
            } else {
                errorMessage = "Please select a transfer account"
                showingError = true
                return
            }
        }
        
        if let existingTransaction = transaction {
            existingTransaction.name = name
            existingTransaction.type = type
            existingTransaction.amount = amountDecimal
            existingTransaction.account = account
            existingTransaction.category = category
            existingTransaction.note = note.isEmpty ? nil : note
            existingTransaction.transferAccount = transferAccount
            existingTransaction.transferAmount = transferAmountDecimal
        } else {
            let newTransaction = Transaction(
                name: name,
                type: type,
                amount: amountDecimal,
                account: account,
                category: category,
                note: note.isEmpty ? nil : note,
                transferAccount: transferAccount,
                transferAmount: transferAmountDecimal
            )
            modelContext.insert(newTransaction)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save transaction: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func formatCurrency(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

/*

#Preview {
    @Previewable @State var testAccount = Account(name: "Test Account", currency: "USD", initialBalance: 1000)
    @Previewable @State var testCategory = Category(name: "Food")
    @Previewable @State var testTransaction = Transaction(
        name: "Grocery Shopping",
        type: .expense,
        amount: 150.50,
        account: testAccount,
        category: testCategory,
        note: "Weekly groceries"
    )
    
    TransactionsListView(
        transactions: .constant([testTransaction]),
        showingAddTransaction: .constant(false),
        selectedTransaction: .constant(nil),
        showingEditTransaction: .constant(false),
        showingDeleteAlert: .constant(false)
    )
    .modelContainer(for: [Transaction.self, Account.self, Category.self], inMemory: true)
}

#Preview {
    TransactionsView()
}
*/
