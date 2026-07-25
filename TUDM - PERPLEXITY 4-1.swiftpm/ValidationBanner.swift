import SwiftUI

/// A compact banner that lists validation issues above a form's Save button.
/// Errors are shown in red, warnings in amber. Silent when there are no issues.
struct ValidationBanner: View {
    let issues: [ValidationIssue]
    
    private var errors: [ValidationIssue] {
        issues.filter { $0.severity == .error }
    }
    
    private var warnings: [ValidationIssue] {
        issues.filter { $0.severity == .warning }
    }
    
    var body: some View {
        if issues.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if !errors.isEmpty {
                    section(title: "Errors block Save", tint: .red, entries: errors)
                }
                if !warnings.isEmpty {
                    section(title: "Warnings", tint: .orange, entries: warnings)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    @ViewBuilder
    private func section(title: String, tint: Color, entries: [ValidationIssue]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
            ForEach(entries) { issue in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: issue.severity == .error ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(tint)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issue.subject)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(issue.message)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}
