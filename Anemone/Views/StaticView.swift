//
//  StaticView.swift
//  Anemone
//
//  Created by Ode on 7/13/25.
//

//TODO: Chart won't be updated automatically.

import SwiftUI
import Charts
import SwiftData

enum TimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"
    
    var displayName: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .all: return "All Time"
        }
    }
    
    func dateRange(from endDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: endDate) ?? endDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .all:
            return calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        }
    }
}

struct NetWorthDataPoint {
    let date: Date
    let netWorth: Decimal
    
    var doubleValue: Double {
        return NSDecimalNumber(decimal: netWorth).doubleValue
    }
}

struct StaticView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedEndDate = Date()
    @State private var showingDatePicker = false
    @State private var netWorthData: [NetWorthDataPoint] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    HStack {
                        Text("End Date:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingDatePicker.toggle()
                        }) {
                            Text(formatDate(selectedEndDate))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if showingDatePicker {
                        DatePicker("Select End Date", selection: $selectedEndDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button(action: {
                                    selectedTimeRange = range
                                    generateNetWorthData()
                                }) {
                                    Text(range.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Net Worth Over Time")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("\(selectedTimeRange.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let currentNetWorth = netWorthData.last?.netWorth {
                                VStack(alignment: .trailing) {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(CurrencyFormatter.format(currentNetWorth))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(currentNetWorth >= 0 ? .green : .red)
                                }
                            }
                        }
                        
                        if netWorthData.count >= 2,
                           let firstValue = netWorthData.first?.netWorth,
                           let lastValue = netWorthData.last?.netWorth {
                            let change = lastValue - firstValue
                            let percentChange = firstValue != 0 ? (change / abs(firstValue)) * 100 : 0
                            
                            HStack(spacing: 8) {
                                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor(change >= 0 ? .green : .red)
                                
                                Text(CurrencyFormatter.format(change))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(change >= 0 ? .green : .red)
                                
                                Text("(\(formatPercentage(percentChange)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Chart
                    if netWorthData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No data available for this period")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    } else {
                        Chart(netWorthData, id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Net Worth", dataPoint.doubleValue)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Net Worth", dataPoint.doubleValue)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text(formatCurrencyShort(Decimal(doubleValue)))
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: getXAxisStride())) { value in
                                AxisGridLine()
                                AxisValueLabel(format: getDateFormat())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Net Worth Chart")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                generateNetWorthData()
            }
            .onChange(of: selectedEndDate) { oldValue, newValue in
                generateNetWorthData()
            }
            .onChange(of: transactions) { oldValue, newValue in
                generateNetWorthData()
            }
            .animation(.easeInOut(duration: 0.3), value: showingDatePicker)
        }
    }
    
    // MARK: - Data Generation
    
    private func generateNetWorthData() {
        let startDate = selectedTimeRange.dateRange(from: selectedEndDate)
        let calendar = Calendar.current
        
        let interval: Calendar.Component
        let intervalValue: Int
        
        switch selectedTimeRange {
        case .week:
            interval = .day
            intervalValue = 1
        case .month:
            interval = .day
            intervalValue = 1
        case .threeMonths:
            interval = .day
            intervalValue = 3
        case .sixMonths:
            interval = .weekOfYear
            intervalValue = 1
        case .year:
            interval = .weekOfYear
            intervalValue = 2
        case .all:
            interval = .year
            intervalValue = 2
        }
        
        var dataPoints: [NetWorthDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= selectedEndDate {
            let netWorth = calculateNetWorth(at: currentDate)
            dataPoints.append(NetWorthDataPoint(date: currentDate, netWorth: netWorth))
            
            guard let nextDate = calendar.date(byAdding: interval, value: intervalValue, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        if let lastPoint = dataPoints.last, !calendar.isDate(lastPoint.date, inSameDayAs: selectedEndDate) {
            let finalNetWorth = calculateNetWorth(at: selectedEndDate)
            dataPoints.append(NetWorthDataPoint(date: selectedEndDate, netWorth: finalNetWorth))
        }
        
        netWorthData = dataPoints
    }
    
    private func calculateNetWorth(at date: Date) -> Decimal {
        var total: Decimal = 0
        
        for account in accounts {
            guard account.createDate <= date else { continue }
            
            var accountBalance: Decimal
            
            if date < account.checkpointDate {
                accountBalance = account.initialBalance
                
                let relevantTransactions = transactions.filter { transaction in
                    transaction.date >= account.createDate &&
                    transaction.date <= date &&
                    (transaction.account.id == account.id || transaction.transferAccount?.id == account.id)
                }
                
                for transaction in relevantTransactions {
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
            } else {
                accountBalance = account.checkpointBalance
                
                let relevantTransactions = transactions.filter { transaction in
                    transaction.date >= account.checkpointDate &&
                    transaction.date <= date &&
                    (transaction.account.id == account.id || transaction.transferAccount?.id == account.id)
                }
                
                for transaction in relevantTransactions {
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
            }
            
            total += accountBalance
        }
        
        return total
    }
    
    // MARK: - Helper Functions
    
    private func getXAxisStride() -> Calendar.Component {
        switch selectedTimeRange {
        case .week:
            return .day
        case .month:
            return .weekOfYear
        case .threeMonths:
            return .weekOfYear
        case .sixMonths:
            return .month
        case .year:
            return .month
        case .all:
            return .year
        }
    }
    
    private func getDateFormat() -> Date.FormatStyle {
        switch selectedTimeRange {
        case .week, .month:
            return .dateTime.month(.abbreviated).day()
        case .threeMonths, .sixMonths:
            return .dateTime.month(.abbreviated).day()
        case .year:
            return .dateTime.month(.abbreviated)
        case .all:
            return .dateTime.year()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatCurrencyShort(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        
        let absAmount = abs(amount)
        
        if absAmount >= 1_000_000 {
            let millions = amount / 1_000_000
            return formatter.string(from: NSDecimalNumber(decimal: millions))?.replacingOccurrences(of: "$", with: "$") ?? "$0" + "M"
        } else if absAmount >= 1_000 {
            let thousands = amount / 1_000
            return formatter.string(from: NSDecimalNumber(decimal: thousands))?.replacingOccurrences(of: "$", with: "$") ?? "$0" + "K"
        } else {
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0"
        }
    }
    
    private func formatPercentage(_ percentage: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSDecimalNumber(decimal: percentage / 100)) ?? "0%"
    }
}
