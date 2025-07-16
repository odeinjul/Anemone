//
//  CategoriesView.swift
//  Anemone
//
//  Created by Ode on 7/16/25.
//

import SwiftUI
import Foundation
import SwiftData


struct CategorySummaryRow: View {
    let category: Category
    let transactions: [Transaction]

    // Calculate monthly income and outcome for this category
    private var monthlyIncome: Decimal {
        let (start, end) = Self.monthBounds()
        return transactions
            .filter { $0.category.id == category.id && $0.type == .income && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyOutcome: Decimal {
        let (start, end) = Self.monthBounds()
        return transactions
            .filter { $0.category.id == category.id && $0.type == .expense && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack {
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(CurrencyFormatter.format(monthlyOutcome))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private static func monthBounds() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (start, now)
    }
}
