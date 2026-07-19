import SwiftUI

struct AuthorityGeometryCard: View {

    let geometry: AuthorityGeometryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Width") {
                Text("\(geometry.width, specifier: "%.1f") in")
            }

            LabeledContent("Height") {
                Text("\(geometry.height, specifier: "%.1f") in")
            }

            LabeledContent("Ceiling Height") {
                Text("\(geometry.ceilingHeight, specifier: "%.1f") in")
            }
        }
        .padding(.vertical, 4)
    }
}
