//
//  HomeView.swift
//  Anemone
//
//  Created by Ode on 7/13/25.
//

import SwiftUI
import SwiftData
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var storedAccounts: [Account] = []
    @State private var storedTransactions: [Transaction] = []
    @State private var showingAddAccount = false
    @State private var showingAddTransaction = false
    @State private var selectedAccount: Account?
    @State private var showingEditAccount = false
    @State private var showingDeleteAlert = false
    @State private var selectedTransaction: Transaction?
    @State private var showingEditTransaction = false
    @State private var showingDeleteTransactionAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        VStack (alignment: .leading) {
                            Text("Net Worth")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.format(netWorth))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        HStack (spacing: 20){
                            VStack(alignment: .leading) {
                                Text("Income")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(CurrencyFormatter.format(monthlyIncome))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Expenses")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(CurrencyFormatter.format(monthlyExpenses))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 25)
                    .padding(.top, 15)
                    
                    // Quick Add Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            showingAddTransaction = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Transaction")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                        }
                        .disabled(accounts.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    // Accounts Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Accounts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(accounts.count) account\(accounts.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: AccountsView()) {
                                HStack {
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if accounts.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No accounts yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Add your first account to get started")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(accounts.prefix(3)) { account in
                                    AccountSummaryRow(account: account)
                                        .onTapGesture {
                                            selectedAccount = account
                                            showingEditAccount = true
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                                        
                    // Transactions Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Transactions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(transactions.count) transaction\(transactions.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: TransactionsView()) {
                                HStack {
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if transactions.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No transactions yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Add your first transaction to start tracking")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(recentTransactions.prefix(3)) { transaction in
                                    TransactionSummaryRow(transaction: transaction)
                                        .onTapGesture {
                                            selectedTransaction = transaction
                                            showingEditTransaction = true
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingAddAccount) {
            AddEditAccountView()
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddEditTransactionView()
        }
        .sheet(isPresented: $showingEditAccount) { [selectedAccount] in
            if let account = selectedAccount {
                AddEditAccountView(account: account)
            }
        }
        .sheet(isPresented: $showingEditTransaction) { [selectedTransaction] in
            if let transaction = selectedTransaction {
                AddEditTransactionView(transaction: transaction)
            }
        }
        .onAppear {
            storedAccounts = accounts
            storedTransactions = transactions
        }
        .onChange(of: accounts) { oldValue, newValue in
            storedAccounts = newValue
        }
        .onChange(of: transactions) { oldValue, newValue in
            storedTransactions = newValue
        }
    }
    
    private var recentTransactions: [Transaction] {
        transactions.sorted { transaction1, transaction2 in
            transaction1.date > transaction2.date
        }
    }
    
    // MARK: - Computed Properties for Financial Summary
    
    private var netWorth: Decimal {
        var total: Decimal = 0
        
        for account in accounts {
            var accountBalance = account.checkpointBalance
            
            let transactionsAfterCheckpoint = transactions.filter { transaction in
                transaction.date >= account.checkpointDate &&
                (transaction.account.id == account.id || transaction.transferAccount?.id == account.id)
            }
            
            for transaction in transactionsAfterCheckpoint {
                if transaction.account.id == account.id {
                    switch transaction.type {
                    case .income:
                        accountBalance += transaction.amount
                    case .expense:
                        accountBalance -= transaction.amount
                    case .transfer:
                        accountBalance -= transaction.amount
                    }
                } else if transaction.transferAccount?.id == account.id {
                    if let transferAmount = transaction.transferAmount {
                        accountBalance += transferAmount
                    } else {
                        accountBalance += transaction.amount
                    }
                }
            }
            
            total += accountBalance
        }
        
        return total
    }
    
    private var monthlyIncome: Decimal {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        return transactions
            .filter { transaction in
                transaction.date >= startOfMonth &&
                transaction.date < endOfMonth &&
                transaction.type == .income
            }
            .reduce(0) { total, transaction in
                total + transaction.amount
            }
    }
    
    private var monthlyExpenses: Decimal {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        return transactions
            .filter { transaction in
                transaction.date >= startOfMonth &&
                transaction.date < endOfMonth &&
                transaction.type == .expense
            }
            .reduce(0) { total, transaction in
                total + transaction.amount
            }
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
