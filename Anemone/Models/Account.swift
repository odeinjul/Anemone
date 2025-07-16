//
//  Account.swift
//  Anemone
//
//  Created by Ode on 7/16/25.
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
    
    static let example: Account = Account(
        name: "Chase Disney",
        currency: "USD",
        initialBalance: 0
    )
}
