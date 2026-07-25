import Foundation

/// Parses a measured wall chain string into registry segments, so a wall can be entered
/// by pasting the same notation the worksheets and render prompts already use:
///
///     C1=8in | Z1=43in | C2=8in | Z2=12.75in | Z3A=5in | Z3B=96in | Z3C=5in | Z4=12.75in | C3=8in | Z5=39.5in | C4=8in
///
/// Optional extras per token:
/// * height — `Z3B=96in x 60in`
/// * panel split — `Z3B=96in(22/52/22)`
///
/// Widths accept carpentry fractions (`12 3/4`, `12-3/4`, `3/4`) and an optional inch suffix.
enum WallRegistryChainParser {
    struct ParsedSegment: Equatable {
        var globalId: String
        var width: Double
        var height: Double?
        var panelSplit: [Double]?
    }

    static let tokenSeparators: Set<Character> = ["|", ";", ",", "\n", "\r"]

    private static let unitSuffixes = ["inches", "inch", "in.", "in", "\"", "”", "″"]

    static func parse(_ raw: String) throws -> [ParsedSegment] {
        let tokens = raw
            .split { tokenSeparators.contains($0) }
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { throw WallRegistryChainParseError.empty }
        return try tokens.map(parseToken)
    }

    static func parseToken(_ token: String) throws -> ParsedSegment {
        var body = token
        var panelSplit: [Double]?

        if let open = body.firstIndex(of: "("), let close = body.lastIndex(of: ")"), open < close {
            let inner = body[body.index(after: open)..<close]
            let widths = try inner
                .split(separator: "/")
                .map { try measurement(String($0)) }
            guard !widths.isEmpty else { throw WallRegistryChainParseError.emptyPanelSplit(token: token) }
            panelSplit = widths
            body.removeSubrange(open...close)
        }

        let halves = body
            .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            .map { String($0).trimmed }
        guard halves.count == 2 else { throw WallRegistryChainParseError.malformedToken(token) }

        let globalId = halves[0]
        guard !globalId.isEmpty else { throw WallRegistryChainParseError.missingGlobalId(token: token) }

        let dimensions = halves[1]
            .lowercased()
            .split(separator: "x")
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
        guard let widthText = dimensions.first else { throw WallRegistryChainParseError.malformedToken(token) }

        return ParsedSegment(
            globalId: globalId,
            width: try measurement(widthText),
            height: dimensions.count > 1 ? try measurement(dimensions[1]) : nil,
            panelSplit: panelSplit
        )
    }

    /// `43` / `12.75` / `12 3/4` / `12-3/4` / `3/4`, with an optional inch suffix.
    static func measurement(_ raw: String) throws -> Double {
        var text = raw.trimmed.lowercased()
        for suffix in unitSuffixes where text.hasSuffix(suffix) {
            text = String(text.dropLast(suffix.count)).trimmed
            break
        }
        // A leading "-" is a typo rather than a mixed-fraction separator.
        guard !text.isEmpty, !text.hasPrefix("-") else {
            throw WallRegistryChainParseError.invalidMeasurement(raw.trimmed)
        }

        let parts = text
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { throw WallRegistryChainParseError.invalidMeasurement(raw.trimmed) }

        var total: Double = 0
        for part in parts {
            if part.contains("/") {
                let fraction = part.split(separator: "/", maxSplits: 1).map(String.init)
                guard
                    fraction.count == 2,
                    let numerator = Double(fraction[0]),
                    let denominator = Double(fraction[1]),
                    denominator != 0
                else {
                    throw WallRegistryChainParseError.invalidMeasurement(raw.trimmed)
                }
                total += numerator / denominator
            } else {
                guard let value = Double(part) else {
                    throw WallRegistryChainParseError.invalidMeasurement(raw.trimmed)
                }
                total += value
            }
        }
        return total
    }
}

enum WallRegistryChainParseError: Error, LocalizedError, Equatable {
    case empty
    case malformedToken(String)
    case missingGlobalId(token: String)
    case invalidMeasurement(String)
    case emptyPanelSplit(token: String)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Nothing to parse. Paste a chain like C1=8in | Z1=43in | C2=8in."
        case let .malformedToken(token):
            return "\"\(token)\" is not a chain entry. Use ID=width, for example Z1=43in."
        case let .missingGlobalId(token):
            return "\"\(token)\" is missing a global ID before the = sign."
        case let .invalidMeasurement(value):
            return "\"\(value)\" is not a measurement. Use 43, 12.75, or 12 3/4."
        case let .emptyPanelSplit(token):
            return "\"\(token)\" has an empty panel split. List the panel widths, e.g. Z3B=96in(22/52/22)."
        }
    }
}
