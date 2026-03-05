//
//  Number+CurrencyFormatter.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI
import Combine

struct CurrencyFormatter {
    static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static func format(_ amount: Double) -> String {
        shared.string(from: NSNumber(value: amount)) ?? "\(Int(amount)) ₽"
    }
}

