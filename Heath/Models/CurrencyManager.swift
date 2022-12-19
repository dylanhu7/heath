//
//  CurrencyManager.swift
//  Heath
//
//  Created by Dylan Hu on 12/18/22.
//  Adapted from https://stackoverflow.com/a/65783711
//

import Foundation

class CurrencyManager: ObservableObject {
    @Published var string: String = ""
    @Published var amount: Decimal = .zero
    private let formatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter
    }()
    private var maximum: Decimal = 999_999_999.99
    private var lastValue: String = ""
    
    init(amount: Decimal, maximum: Decimal = 999_999_999.99, locale: Locale = .current) {
        formatter.locale = locale
        self.string = amount == 0 ? "" : (formatter.string(for: amount) ?? "")
        self.lastValue = string
        self.amount = amount
        self.maximum = maximum
    }
    
    func valueChanged(_ value: String) {
        let newValue = (value.decimal ?? .zero) / pow(10, formatter.maximumFractionDigits)
        if newValue > maximum {
            string = lastValue
        } else {
            string = newValue == 0 ? "" : (formatter.string(for: newValue) ?? "")
            lastValue = string
            amount = newValue
        }
    }
}

fileprivate extension Character {
    var isDigit: Bool { "0"..."9" ~= self }
}

fileprivate extension LosslessStringConvertible {
    var string: String { .init(self) }
}

fileprivate extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self { filter (\.isDigit) }
    var decimal: Decimal? { Decimal(string: digits.string) }
}
