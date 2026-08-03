// ============================================================
// DENISEBEAUDOT — BUILD MARKER — alcove bump-out + point C
// 2026-08-03 18:27 EDT   branch: alcove-bumpout-point-c
// If you cannot see this line at the very top, this file did
// not load or the paste was truncated.
// ============================================================

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
        
        // Step 7c — declared back wall C.
        //
        // C is only validated when it has actually been authored. A nil C means
        // "not measured yet" and every renderer falls back to the long leg, so
        // there is nothing to police.
        //
        // C runs from the SHORT leg's endpoint, parallel to the LONG leg's wall,
        // so C reads against the opening. It is therefore compared to the LONG
        // leg, not the short one.
        if let declaredC = anchor.backWallC {
            let longLeg = max(anchor.footprintA, anchor.footprintB)
            
            if declaredC <= 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "Back wall C must be greater than 0 (got \(String(format: "%.2f", declaredC))in). Clear C instead of setting it to zero if the back wall has not been measured.",
                    subject: subject
                ))
            }
            
            // A back wall wider than the opening means the recess undercuts the
            // wall it sits in. Buildable, but it is never accidental, so say so.
            if declaredC > longLeg + 0.01 {
                let over = declaredC - longLeg
                let consequence = anchor.projection.isBumpOut
                    ? "The bump-out flares wider than the opening it is entered through."
                    : "The recess widens toward the back and undercuts the wall."
                issues.append(ValidationIssue(
                    severity: .warning,
                    message: "Back wall C (\(String(format: "%.2f", declaredC))in) is \(String(format: "%.2f", over))in wider than the opening (\(String(format: "%.2f", longLeg))in). \(consequence)",
                    subject: subject
                ))
            }
            
            // A back wall narrower than the columns it sits between cannot be
            // built. Warning rather than error: the columns may be re-specced.
            let columnSpan = columnA.width + columnB.width
            if declaredC > 0, declaredC < columnSpan - 0.01 {
                issues.append(ValidationIssue(
                    severity: .warning,
                    message: "Back wall C (\(String(format: "%.2f", declaredC))in) is narrower than the combined column widths (\(String(format: "%.2f", columnSpan))in). The flanking columns would overlap.",
                    subject: subject
                ))
            }
            
            // Note: C exactly equal to the long leg is legitimate — it squares
            // point D off and the footprint becomes a plain rectangle. That is
            // not an issue, so nothing is emitted. ValidationIssue only carries
            // .error and .warning; the form's readout is where the author sees
            // the rectangle-vs-cant verdict.
        }
        
        // MARK: Bump-out host wall
        //
        // A bump-out removes a segment of its host wall to open into the body.
        // That removal is the whole point, but it is destructive to declared
        // wall geometry, so it is surfaced explicitly rather than done quietly.
        if anchor.projection.isBumpOut {
            let throughA = anchor.projection == .outwardThroughWallA
            let openingWidth = throughA ? anchor.footprintA : anchor.footprintB
            let hostLabel = throughA ? "Wall A" : "Wall B"
            let hostWall = walls[throughA ? anchor.wallA : anchor.wallB]
            
            if anchor.openingOffset < 0 {
                issues.append(ValidationIssue(
                    severity: .error,
                    message: "Offset along \(hostLabel) must be zero or positive (got \(String(format: "%.2f", anchor.openingOffset))in).",
                    subject: subject
                ))
            }
            
            // If the host wall does not resolve, the missing-reference errors
            // further down already cover it; skip rather than double-report.
            if let hostTotal = hostWall?.totalWidth {
                // The opening plus its offset has to land inside the host wall.
                let farEdge = anchor.openingOffset + openingWidth
                if farEdge > hostTotal + 0.01 {
                    let over = farEdge - hostTotal
                    issues.append(ValidationIssue(
                        severity: .error,
                        message: "Bump-out runs past the end of \(hostLabel) by \(String(format: "%.2f", over))in (offset \(String(format: "%.2f", anchor.openingOffset))in + opening \(String(format: "%.2f", openingWidth))in exceeds \(String(format: "%.2f", hostTotal))in).",
                        subject: subject
                    ))
                }
                
                if openingWidth >= hostTotal - 0.01 {
                    issues.append(ValidationIssue(
                        severity: .error,
                        message: "Bump-out opening (\(String(format: "%.2f", openingWidth))in) consumes the full width of \(hostLabel) (\(String(format: "%.2f", hostTotal))in). Nothing would remain of that wall.",
                        subject: subject
                    ))
                } else {
                    let remaining = hostTotal - openingWidth
                    issues.append(ValidationIssue(
                        severity: .warning,
                        message: "Bump-out removes \(String(format: "%.2f", openingWidth))in of \(hostLabel), leaving \(String(format: "%.2f", remaining))in of wall. The room outline becomes an L and floor area is added, not removed.",
                        subject: subject
                    ))
                }
            }
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
