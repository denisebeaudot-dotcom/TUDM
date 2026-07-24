import SwiftUI

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct NumericFieldRow: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(
                title,
                value: $value,
                format: .number.precision(.fractionLength(2))
            )
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .frame(maxWidth: 120)
        }
    }
}
