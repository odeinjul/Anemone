//
//  Utils.swift
//  Anemone
//
//  Created by Ode on 7/15/25.
//

import Foundation

struct CurrencyFormatter {
    static func format(_ amount: Decimal, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

struct InputValidation {
    static func filterNumericInput(_ input: String) -> String {
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
}

extension Decimal {
    var formattedString: String {
        return String(describing: self)
    }
}
