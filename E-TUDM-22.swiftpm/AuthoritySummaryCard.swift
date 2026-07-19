import SwiftUI

struct AuthoritySummaryCard: View {

    let record: AuthorityRecord
    let geometry: AuthorityGeometryRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.code)
                    .font(.headline)

                Spacer()

                Text(record.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            Text(record.name)
                .font(.title3)
                .fontWeight(.semibold)

            Text(record.type.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let geometry {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Width: \(geometry.width, specifier: "%.1f") in")
                    Text("Height: \(geometry.height, specifier: "%.1f") in")
                    Text("Ceiling: \(geometry.ceilingHeight, specifier: "%.1f") in")
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
