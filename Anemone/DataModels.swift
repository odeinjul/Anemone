//
//  DataModels.swift
//  Anemone
//
//  Created by Ode on 6/28/25.
//
import Foundation
import SwiftData

@Model
class Account {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var currency: String
    var initialBalance: Decimal
    var createDate: Date = Date()
    var checkpointBalance: Decimal
    var checkpointDate: Date = Date()
    
    init(name: String, currency: String, initialBalance: Decimal) {
        self.name = name
        self.currency = currency
        self.initialBalance = initialBalance
        self.checkpointBalance = initialBalance
        self.createDate = Date.now
        self.checkpointDate = Date.now
    }
}

@Model
class Category {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    init(name: String) {
        self.name = name
    }
}

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
    var category: Category
    var note: String?
    var transferAccount: Account?
    var transferAmount: Decimal? // in case transfer between different currencies, w/ handling fee
    init(name: String, type: TransactionType, amount: Decimal, account: Account, category: Category, note: String? = nil, transferAccount: Account? = nil, transferAmount: Decimal? = nil) {
        self.name = name
        self.type = type
        self.amount = amount
        self.account = account
        self.category = category
        self.note = note
        self.transferAccount = transferAccount
        self.transferAmount = transferAmount
    }
}
