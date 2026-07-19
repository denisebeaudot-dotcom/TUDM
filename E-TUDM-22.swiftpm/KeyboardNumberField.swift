import SwiftUI

struct KeyboardIntegerField: View {

    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...30

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            TextField(
                "0",
                value: $value,
                format: .number
            )
            .multilineTextAlignment(.trailing)
            .frame(width: 90)
            .onChange(of: value) { newValue in

                if newValue < range.lowerBound {
                    value = range.lowerBound
                } else if newValue > range.upperBound {
                    value = range.upperBound
                }
            }
        }
    }
}
