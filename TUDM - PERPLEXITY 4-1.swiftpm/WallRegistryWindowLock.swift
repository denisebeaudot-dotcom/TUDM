import Foundation

/// Code-frozen window specifications. A `WindowLock` is the single
/// source of truth for a specific window on a specific wall. Nothing —
/// no import, no template, no edit path — is allowed to change these
/// values at runtime. Validators and renderers pull from `WindowLock`
/// instead of trusting segment payloads.
///
/// If a window ever needs to change, edit the lock constant here in
/// code, ship a new build, and bump the version. That is the only path.
struct WindowLock: Equatable, Codable {
    /// Wall this lock applies to (matches `WallRegistryEnvelope.wallId`).
    let wallId: String
    /// Global segment ID this lock applies to.
    let globalId: String
    /// Total window unit width in inches.
    let width: Double
    /// Total window unit height in inches.
    let height: Double
    /// Panel split across the window width. Must sum to `width`.
    let panelSplit: [Double]
    /// Casing width (each side leg) in inches. Informational only —
    /// casing segments (Z3A / Z3C) still live as their own registry
    /// segments; this is here so renderers can double-check.
    let casingWidth: Double
    /// Human-readable version tag, bumped by hand when the lock changes.
    let version: String
    
    /// Sanity check that the lock itself is internally consistent.
    /// Called during app startup so a bad edit in this file fails
    /// loud instead of quietly rendering the wrong window.
    func assertSelfConsistent() {
        precondition(width > 0, "WindowLock width must be positive.")
        precondition(height > 0, "WindowLock height must be positive.")
        precondition(!panelSplit.isEmpty, "WindowLock panelSplit must not be empty.")
        let panelTotal = panelSplit.reduce(0, +)
        precondition(
            abs(panelTotal - width) <= 0.001,
            "WindowLock panelSplit (\(panelTotal)) must equal width (\(width)) for \(wallId)/\(globalId)."
        )
    }
}

/// All code-frozen window locks in the app. Renderers, validators, and
/// the Wall 1 example template all read from here.
enum WindowLockLibrary {
    /// Wall 1 primary window (family room, W1 registry).
    /// 22 / 52 / 22 panel split × 60in tall × 96in total width.
    /// Do not edit these numbers without bumping the version tag.
    static let wall1Z3B = WindowLock(
        wallId: "W1",
        globalId: "Z3B",
        width: 96,
        height: 60,
        panelSplit: [22, 52, 22],
        casingWidth: 5,
        version: "wall1-Z3B-1.0.0"
    )
    
    /// All locks, keyed by "wallId/globalId".
    static let all: [String: WindowLock] = [
        "\(wall1Z3B.wallId)/\(wall1Z3B.globalId)": wall1Z3B
    ]
    
    static func lock(for wallId: String, globalId: String) -> WindowLock? {
        return all["\(wallId)/\(globalId)"]
    }
    
    /// Kick every lock's self-check. Call this once at app startup so
    /// any drift introduced by a bad code edit fails on launch.
    static func assertAllSelfConsistent() {
        for lock in all.values {
            lock.assertSelfConsistent()
        }
    }
}

// MARK: - Registry envelope enforcement

extension WallRegistryEnvelope {
    /// Verifies that every segment with a matching lock in
    /// `WindowLockLibrary` exactly matches its lock. Throws
    /// `WallRegistryValidationError.windowLockViolation` on any drift.
    /// Call this alongside `validate()` — it is not automatic so callers
    /// can opt in per-context, but the shared `validateAndLock()` helper
    /// does both.
    func validateWindowLocks(tolerance: Double = 0.001) throws {
        for segment in segments {
            guard let lock = WindowLockLibrary.lock(
                for: wallId,
                globalId: segment.globalId
            ) else { continue }
            
            var drifts: [String] = []
            if abs(segment.width - lock.width) > tolerance {
                drifts.append("width \(segment.width) != \(lock.width)")
            }
            if let height = segment.height,
               abs(height - lock.height) > tolerance {
                drifts.append("height \(height) != \(lock.height)")
            } else if segment.height == nil {
                drifts.append("height missing (locked at \(lock.height))")
            }
            let panels = segment.panelSplit ?? []
            if panels.count != lock.panelSplit.count {
                drifts.append("panel count \(panels.count) != \(lock.panelSplit.count)")
            } else {
                for (i, panel) in panels.enumerated() {
                    if abs(panel - lock.panelSplit[i]) > tolerance {
                        drifts.append("panel[\(i)] \(panel) != \(lock.panelSplit[i])")
                    }
                }
            }
            if !drifts.isEmpty {
                throw WallRegistryValidationError.windowLockViolation(
                    wallId: wallId,
                    globalId: segment.globalId,
                    detail: drifts.joined(separator: "; ")
                )
            }
        }
    }
    
    /// Validate structure AND enforce every window lock. Preferred entry
    /// point for any code path that consumes a wall envelope for
    /// rendering, saving, or exporting.
    func validateAndLock(tolerance: Double = 0.001) throws {
        try validate(tolerance: tolerance)
        try validateWindowLocks(tolerance: tolerance)
    }
    
    /// Defense in depth. Returns a copy of the envelope with any window
    /// segments force-corrected back to their canonical lock values.
    /// Use this on any pathway that constructs an envelope from an
    /// untrusted source (paste, JSON import, external proxy) before
    /// handing it downstream. Prints a console diagnostic if any
    /// segment was rewritten.
    func applyWindowLocks() -> WallRegistryEnvelope {
        var copy = self
        var didRewrite = false
        for i in copy.segments.indices {
            let seg = copy.segments[i]
            guard let lock = WindowLockLibrary.lock(
                for: copy.wallId,
                globalId: seg.globalId
            ) else { continue }
            
            var seg2 = seg
            var rewrittenFields: [String] = []
            if abs(seg2.width - lock.width) > 0.001 {
                rewrittenFields.append("width \(seg2.width) -> \(lock.width)")
                seg2.width = lock.width
            }
            if seg2.height == nil || abs((seg2.height ?? 0) - lock.height) > 0.001 {
                rewrittenFields.append("height -> \(lock.height)")
                seg2.height = lock.height
            }
            if (seg2.panelSplit ?? []) != lock.panelSplit {
                rewrittenFields.append("panelSplit -> \(lock.panelSplit)")
                seg2.panelSplit = lock.panelSplit
            }
            if !rewrittenFields.isEmpty {
                print("[WindowLock] Rewrote \(copy.wallId)/\(seg.globalId): \(rewrittenFields.joined(separator: ", "))")
                copy.segments[i] = seg2
                didRewrite = true
            }
        }
        if didRewrite {
            print("[WindowLock] Envelope was corrected. Source data drifted from lock.")
        }
        return copy
    }
}
