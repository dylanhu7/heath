//
//  NewTransactionView.swift
//  Heath
//
//  Created by Dylan Hu on 11/29/22.
//

import SwiftUI

struct NewTransactionView: View {
    @ObservedObject var ledger: Ledger
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var split = 0.5
    @State private var isExpanded = false
    private let formatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter
    }()
    @ObservedObject private var currencyManager = CurrencyManager(amount: 0)
    
    var body: some View {
        let hasAmount = currencyManager.amount != 0
        NavigationStack {
            Form {
                Section(header: Text("Description")) {
                    TextField("Required", text: $description)
                }
                Section(header: Text("Amount")) {
                    TextField("Required", text: $currencyManager.string)
                        .keyboardType(.numberPad)
                        .onChange(of: currencyManager.string, perform: currencyManager.valueChanged)
                    DisclosureGroup(isExpanded: hasAmount ? $isExpanded : .constant(false), content: {
                        VStack {
                            HStack {
                                Text("Me").font(.headline)
                                Spacer()
                                Text("Nick").font(.headline)
                            }.padding(.bottom, -2)
                            Slider(value: $split, in: 0...1)
                            HStack {
                                Text(formatter.string(for: split * NSDecimalNumber(decimal: currencyManager.amount).doubleValue) ?? "")
                                Spacer()
                                Text(formatter.string(for: (1 - split) * NSDecimalNumber(decimal: currencyManager.amount).doubleValue) ?? "")
                            }.padding(.top, -2)
                        }
                    }, label: {
                        HStack {
                            Text("Split")
                            Spacer()
                            Text(split == 0.5 ? "50/50" : "Custom").foregroundColor(.secondary)
                        }
                    }).disabled(!hasAmount)
                }
            }
            .navigationTitle("Track Spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let transaction = Transaction(context: context)
                        transaction.amount = NSDecimalNumber(decimal: currencyManager.amount).doubleValue
                        transaction.split = split
                        transaction.createdAt = .now
                        transaction.detail = description
                        ledger.addToTransactions(transaction)
                        context.save(with: .addTransaction)
                        dismiss()
                    }.disabled(description == "" || currencyManager.amount == 0)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}


struct NewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            
        }
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                NewTransactionView(ledger: Ledger())
            }
        }
        .interactiveDismissDisabled()
    }
}
