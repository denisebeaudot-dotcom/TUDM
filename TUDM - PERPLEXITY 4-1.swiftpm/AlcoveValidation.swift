import Foundation

// MARK: - RoomAlcove validation
//
// Extends the G2/G3 validation pattern to alcoves. Alcoves are validated
// against the two walls they reference so the anchor's declared footprint
// actually fits inside each wall.

extension RoomAlcove {
    /// Validate this alcove's own geometry and check that its anchor footprints
    /// fit inside the referenced walls. Returns every issue found; empty means
    /// valid.
    ///
    /// - subject: human-readable subject prefix ("Wood Stove Corner").
    /// - walls: the room's wallSpecs, keyed by id so we can look up wallA / wallB.
    func validate(subject: String, walls: [UUID: WallSpec]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Sanity — positive dimensions.
        if platform.height < 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Platform height must be zero or positive (got \(String(format: "%.2f", platform.height))in).",
                subject: subject
            ))
        }
        if anchor.footprintA <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Footprint on wall A must be greater than 0 (got \(String(format: "%.2f", anchor.footprintA))in).",
                subject: subject
            ))
        }
        if anchor.footprintB <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Footprint on wall B must be greater than 0 (got \(String(format: "%.2f", anchor.footprintB))in).",
                subject: subject
            ))
        }
        
        // Columns must have positive dimensions.
        for (label, col) in [("Column A", columnA), ("Column B", columnB)] {
            if col.width <= 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "\(label) width must be greater than 0 (got \(String(format: "%.2f", col.width))in).",
                    subject: subject
                ))
            }
            if col.depth <= 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "\(label) depth must be greater than 0 (got \(String(format: "%.2f", col.depth))in).",
                    subject: subject
                ))
            }
            if col.height <= 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "\(label) height must be greater than 0 (got \(String(format: "%.2f", col.height))in).",
                    subject: subject
                ))
            }
        }
        
        // Back element height must be positive.
        if back.height <= 0 {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Back element height must be greater than 0 (got \(String(format: "%.2f", back.height))in).",
                subject: subject
            ))
        }
        
        // Anchor A must reference an existing wall.
        if let wallA = walls[anchor.wallA] {
            if anchor.footprintA > wallA.totalWidth + 0.01 {
                let over = anchor.footprintA - wallA.totalWidth
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "Footprint on wall A (\(String(format: "%.2f", anchor.footprintA))in) exceeds wall A total width (\(String(format: "%.2f", wallA.totalWidth))in) by \(String(format: "%.2f", over))in.",
                    subject: subject
                ))
            }
        } else {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Wall A reference does not resolve to an existing wall in this room.",
                subject: subject
            ))
        }
        
        // Anchor B must reference an existing wall.
        if let wallB = walls[anchor.wallB] {
            if anchor.footprintB > wallB.totalWidth + 0.01 {
                let over = anchor.footprintB - wallB.totalWidth
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "Footprint on wall B (\(String(format: "%.2f", anchor.footprintB))in) exceeds wall B total width (\(String(format: "%.2f", wallB.totalWidth))in) by \(String(format: "%.2f", over))in.",
                    subject: subject
                ))
            }
        } else {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Wall B reference does not resolve to an existing wall in this room.",
                subject: subject
            ))
        }
        
        // Same wall used for both anchors — that would be a straight-wall
        // alcove, not a corner alcove. Flag as a warning for now; may be
        // legitimate for future non-corner alcoves.
        if anchor.wallA == anchor.wallB {
            issues.append(ValidationIssue(
                severity: .warning,
                message: "Wall A and Wall B reference the same wall. Corner alcoves span two different walls.",
                subject: subject
            ))
        }
        
        return issues
    }
}
