//
//  QuoteRow.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct QuoteRow: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\"\(quote.text)\"")
                .font(.body)
            
            Text("- \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}
