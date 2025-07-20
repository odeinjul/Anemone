//
//  Transactions.swift
//  Anemone
//
//  Created by Ode on 7/16/25.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case income, expense, transfer
}

@Model
class Transaction {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var type: TransactionType
    var amount: Decimal
    var account: Account
    var category: Category?
    var note: String?
    var date: Date
    var transferAccount: Account?
    var transferAmount: Decimal? // in case transfer between different currencies, w/ handling fee
    init(name: String, type: TransactionType, amount: Decimal, account: Account, category: Category? = nil, date: Date = Date(),
         note: String? = nil, transferAccount: Account? = nil, transferAmount: Decimal? = nil) {
        self.name = name
        self.type = type
        self.amount = amount
        self.account = account
        self.category = category
        self.note = note
        self.date = date
        self.transferAccount = transferAccount
        self.transferAmount = transferAmount
    }
    
    static let example: Transaction = Transaction (
        name: "Target",
        type: TransactionType.expense,
        amount: 10.0,
        account: Account.example,
        category: Category.example,
        note: "Bought a bag of milk inside a bag of milk."
    )
}
