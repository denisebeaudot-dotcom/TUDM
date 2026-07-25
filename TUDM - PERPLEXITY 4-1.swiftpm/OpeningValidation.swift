import Foundation

// MARK: - Validation Issue

/// A single problem found while validating a wall, opening, or segment.
/// Severity decides whether Save is blocked (error) or just flagged (warning).
struct ValidationIssue: Identifiable, Hashable {
    enum Severity: String, Hashable {
        case error
        case warning
    }
    
    let id = UUID()
    let severity: Severity
    let message: String
    let subject: String  // short human-readable subject like "Wall 1 · WIN1" or "Wall 3"
    
    var isBlocking: Bool { severity == .error }
}

// MARK: - OpeningSpec validation

extension OpeningSpec {
    /// Check that this opening's dimensions are internally consistent and fit
    /// under the ceiling. Returns every issue found; empty array means valid.
    ///
    /// - subject: short label used in the message ("W1 · WIN1", "Wall 3 · Z6").
    /// - ceilingHeight: total ceiling height in inches for the wall this opening lives on.
    func validate(subject: String, ceilingHeight: Double) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Sanity — sizes must be positive.
        if openingWidth <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Opening width must be greater than 0 (got \(String(format: "%.2f", openingWidth))in).",
                subject: subject
            ))
        }
        if openingHeight <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Opening height must be greater than 0 (got \(String(format: "%.2f", openingHeight))in).",
                subject: subject
            ))
        }
        if sillOrBottomAFF < 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Sill / bottom AFF must be zero or positive (got \(String(format: "%.2f", sillOrBottomAFF))in).",
                subject: subject
            ))
        }
        
        // Casings must be zero or positive.
        for (name, value) in [
            ("casing left", casingLeft),
            ("casing right", casingRight),
            ("casing head", casingHead),
            ("casing bottom", casingBottom)
        ] {
            if value < 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "\(name.capitalized) must be zero or positive (got \(String(format: "%.2f", value))in).",
                    subject: subject
                ))
            }
        }
        
        // Vertical fit — the whole unit stack (sill + bottom casing + opening + head casing)
        // must fit under the ceiling. Casing is treated as part of the unit per project rule.
        let stackTop = sillOrBottomAFF + casingBottom + openingHeight + casingHead
        if ceilingHeight > 0 && stackTop > ceilingHeight + 0.001 {
            let overshoot = stackTop - ceilingHeight
            issues.append(ValidationIssue(
                severity: .error,
                message: "Opening + casing extends \(String(format: "%.2f", overshoot))in above the ceiling. Sill \(String(format: "%.2f", sillOrBottomAFF)) + bottom casing \(String(format: "%.2f", casingBottom)) + opening height \(String(format: "%.2f", openingHeight)) + head casing \(String(format: "%.2f", casingHead)) = \(String(format: "%.2f", stackTop))in, ceiling is \(String(format: "%.2f", ceilingHeight))in.",
                subject: subject
            ))
        }
        
        // Panel-share sanity. Panels are relative shares; each must be positive
        // and the panel array (when present) should match panelCount.
        if !panels.isEmpty {
            if panels.count != panelCount {
                issues.append(ValidationIssue(
                    severity: .warning,
                    message: "Panel array has \(panels.count) entries but panelCount is \(panelCount). The renderer will use the array count.",
                    subject: subject
                ))
            }
            for (i, panel) in panels.enumerated() {
                if panel.widthShare <= 0 {
                    issues.append(ValidationIssue(
                        severity: .warning,
                        message: "Panel \(i + 1) has non-positive width share (\(String(format: "%.2f", panel.widthShare))). It will be invisible in the render.",
                        subject: subject
                    ))
                }
            }
        }
        
        return issues
    }
}

// MARK: - WallSegment validation

extension WallSegment {
    /// Validate this segment's own dimensions and, if it carries an opening, that opening too.
    func validate(subject: String, ceilingHeight: Double) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Width sanity for non-opening segments. Opening segments carry width in the opening spec.
        if opening == nil && width < 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Segment width must be zero or positive (got \(String(format: "%.2f", width))in).",
                subject: subject
            ))
        }
        
        if let opening {
            let openingSubject = subject + (label.isEmpty ? "" : " · \(label)")
            issues.append(contentsOf: opening.validate(subject: openingSubject, ceilingHeight: ceilingHeight))
        }
        
        return issues
    }
}

// MARK: - WallSpec validation

extension WallSpec {
    /// Validate the whole wall: segment widths must sum to totalWidth, and each
    /// opening must fit under the ceiling.
    ///
    /// - wallLabel: human-readable name for use in issue subjects ("Wall 1").
    /// - ceilingHeight: effective ceiling height for this wall (RoomDefaults or override).
    func validate(wallLabel: String, ceilingHeight: Double) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Wall must have positive total width.
        if totalWidth <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Wall total width must be greater than 0 (got \(String(format: "%.2f", totalWidth))in).",
                subject: wallLabel
            ))
        }
        
        // Segment chain must sum to totalWidth within tolerance.
        let sum = segmentTotal
        let delta = sum - totalWidth
        if abs(delta) > 0.01 {
            let sign = delta > 0 ? "over" : "under"
            issues.append(ValidationIssue(
                severity: .error,
                message: "Segment widths sum to \(String(format: "%.2f", sum))in but wall total is \(String(format: "%.2f", totalWidth))in — chain is \(String(format: "%.2f", abs(delta)))in \(sign).",
                subject: wallLabel
            ))
        }
        
        // Each segment (and its opening, if any).
        for (index, segment) in segments.enumerated() {
            let segLabel = segment.label.isEmpty ? "segment \(index + 1)" : segment.label
            let segSubject = "\(wallLabel) · \(segLabel)"
            issues.append(contentsOf: segment.validate(subject: segSubject, ceilingHeight: ceilingHeight))
        }
        
        return issues
    }
}
