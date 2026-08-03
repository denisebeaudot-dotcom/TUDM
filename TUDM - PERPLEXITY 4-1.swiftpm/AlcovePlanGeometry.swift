// ============================================================
// DENISEBEAUDOT — BUILD MARKER — alcove bump-out + point C
// 2026-08-03 18:27 EDT   branch: alcove-bumpout-point-c
// If you cannot see this line at the very top, this file did
// not load or the paste was truncated.
// ============================================================

import Foundation
import CoreGraphics

// MARK: - AlcovePlanGeometry
//
// Step 7c — explicit plan-view geometry for a corner alcove.
//
// Until now the alcove footprint was IMPLIED: two leg lengths (footprintA,
// footprintB) and a back element whose width was DERIVED from whatever the
// distance between the two columns happened to be. That inverts the
// structural-fidelity rule. The back wall is the thing you can actually put a
// tape on, so the back wall should be DECLARED and the closing face should be
// the derived value — not the other way round.
//
// The point-C rule
// ----------------
//
//   O   the shared corner of wallA and wallB. Alcove-local origin (0, 0).
//   A   end of the leg along wallA                -> (footprintA, 0)
//   B   end of the leg along wallB                -> (0, footprintB)
//   C   the BACK WALL length. C starts at the endpoint of the SHORTER leg and
//       runs PARALLEL to the longer leg's wall. Its width therefore reads
//       against the alcove opening, not across the depth.
//   D   the derived third point — the far end of C. D closes back onto the
//       endpoint of the LONGER leg.
//
// The footprint always closes as the quadrilateral  O -> A -> D -> B.
//
//   * C == longer leg    D lands square. Footprint is a clean rectangle.
//   * C <  longer leg    D pulls inboard. The closing face cants. This is the
//                        L / splayed plan.
//   * C >  longer leg    D pushes past the opening. The alcove widens toward
//                        the back — legal, but flagged, since it means the
//                        recess undercuts the wall it sits in.
//
// Worked example (Ina's Room, W3/W4 corner):
//   footprintA = 26.00  (W3, longer)   footprintB = 15.00  (W4, shorter)
//   backWallC  = 26.00
//   -> C starts at B (0, 15), runs parallel to W3, D = (26.00, 15.00)
//   -> closing face D..A = 15.00, cant 0 deg, plain 26 x 15 rectangle
//
// Coordinates are INCHES in alcove-local space: +x runs along wallA, +y runs
// along wallB. Converting to screen space is the renderer's job, not this
// file's.

// MARK: - AlcovePlanFootprint

/// The fully resolved plan-view footprint of a corner alcove, in inches.
/// Build one with `anchor.planFootprint`. Every value here is derived — this
/// struct never stores authored data, so it can be recomputed freely.
struct AlcovePlanFootprint: Hashable {

    /// Shared corner of the two walls. Always (0, 0).
    let pointO: CGPoint

    /// End of the leg measured along wallA.
    let pointA: CGPoint

    /// End of the leg measured along wallB.
    let pointB: CGPoint

    /// The derived third point — far end of the back wall C.
    let pointD: CGPoint

    /// The declared (or defaulted) back wall length, in inches.
    let backWallC: Double

    /// True when the leg along wallA is the longer of the two. The back wall
    /// then runs parallel to wallA, starting from point B.
    let longLegIsA: Bool

    let longLegLength: Double
    let shortLegLength: Double

    /// Outline in draw order. Closing the path returns along wallB to O.
    var polygon: [CGPoint] { [pointO, pointA, pointD, pointB] }

    // MARK: Back wall (declared)

    /// Where the back wall starts — the endpoint of the SHORTER leg.
    var backWallStart: CGPoint { longLegIsA ? pointB : pointA }

    /// Where the back wall ends — always the derived point D.
    var backWallEnd: CGPoint { pointD }

    // MARK: Closing face (derived)

    /// The face that closes D back onto the LONGER leg's endpoint.
    var closingFaceStart: CGPoint { pointD }
    var closingFaceEnd: CGPoint { longLegIsA ? pointA : pointB }

    /// Length of the derived closing face, in inches.
    var closingFaceLength: Double {
        let s = closingFaceStart
        let e = closingFaceEnd
        let dx = Double(e.x) - Double(s.x)
        let dy = Double(e.y) - Double(s.y)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// True when C equals the long leg, which squares D off and makes the
    /// footprint a plain rectangle. Anything else is the L / splayed case.
    var isRectangular: Bool {
        abs(backWallC - longLegLength) < 0.005
    }

    /// True when the back wall runs wider than the opening, so the recess
    /// undercuts the wall it sits in. Buildable, but worth flagging.
    var widensTowardBack: Bool {
        backWallC > longLegLength + 0.005
    }

    /// Angle of the closing face away from square, in degrees. Zero when the
    /// footprint is rectangular. Useful as a drafting callout.
    var closingFaceCantDegrees: Double {
        let s = closingFaceStart
        let e = closingFaceEnd
        let dx = abs(Double(e.x) - Double(s.x))
        let dy = abs(Double(e.y) - Double(s.y))
        if longLegIsA {
            // Square case runs purely in -y, so any dx is the cant.
            guard dy > 0.0001 else { return 0 }
            return atan2(dx, dy) * 180 / .pi
        } else {
            guard dx > 0.0001 else { return 0 }
            return atan2(dy, dx) * 180 / .pi
        }
    }

    /// Plan area enclosed by the footprint, in square inches (shoelace).
    var area: Double {
        let pts = polygon
        var sum: Double = 0
        for i in 0..<pts.count {
            let p = pts[i]
            let q = pts[(i + 1) % pts.count]
            sum += Double(p.x) * Double(q.y) - Double(q.x) * Double(p.y)
        }
        return abs(sum) / 2
    }

    var longLegLabel: String { longLegIsA ? "A" : "B" }
    var shortLegLabel: String { longLegIsA ? "B" : "A" }

    // MARK: Projection

    /// Which side of the host walls this footprint sits on.
    let projection: AlcoveProjection

    /// How far along the host wall the opening was slid from the anchor end.
    let openingOffset: Double

    /// True when the body floats mid-wall rather than sitting in the corner.
    /// A floating bump-out has wall on BOTH sides of its opening, and its side
    /// returns are free-standing rather than continuations of the other wall.
    var isFloating: Bool { projection.isBumpOut && openingOffset > 0.01 }

    /// Signed floor-area change, in square inches. A bump-out ADDS area to the
    /// room; an inward recess REMOVES it. Sign matters when the plan totals are
    /// rolled up, so it is carried here rather than left to the caller.
    var signedAreaChange: Double {
        projection.isBumpOut ? area : -area
    }

    // MARK: Removed host-wall segment

    /// For a bump-out, the two ends of the host-wall segment that gets deleted
    /// to open into the alcove. Nil for an inward recess, which removes no wall.
    ///
    /// The host wall keeps its full registry length — W3 is still 130" — but the
    /// run between these two points is an opening, not wall.
    var removedWallSegment: (start: CGPoint, end: CGPoint)? {
        switch projection {
        case .inward:
            return nil
        case .outwardThroughWallA:
            return (pointO, pointA)
        case .outwardThroughWallB:
            return (pointO, pointB)
        }
    }

    /// Width of the removed host-wall segment, in inches. Zero for a recess.
    /// Measured from the segment itself so it stays correct once the opening
    /// has been slid along the wall by `openingOffset`.
    var removedWallWidth: Double {
        guard let seg = removedWallSegment else { return 0 }
        let dx = Double(seg.end.x) - Double(seg.start.x)
        let dy = Double(seg.end.y) - Double(seg.start.y)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Unit vector pointing away from the opening, perpendicular to the back
    /// wall. This is the direction a convex (bowed) back envelope bulges, and
    /// the direction a concave one is pulled back from.
    ///
    /// Derived from the back wall's own perpendicular, disambiguated by testing
    /// which side the opening's midpoint falls on — so it stays correct for a
    /// recess, a bump-out, either long leg, and any offset.
    var backWallOutwardNormal: (dx: Double, dy: Double) {
        let s = backWallStart, e = backWallEnd
        let ex = Double(e.x) - Double(s.x)
        let ey = Double(e.y) - Double(s.y)
        let len = (ex * ex + ey * ey).squareRoot()
        guard len > 0.0001 else { return (0, 0) }

        // Perpendicular to the back wall.
        var nx = -ey / len
        var ny = ex / len

        // Flip it to point away from the opening.
        let openStart = removedWallSegment?.start ?? pointO
        let openEnd = removedWallSegment?.end ?? pointA
        let openMidX = (Double(openStart.x) + Double(openEnd.x)) / 2
        let openMidY = (Double(openStart.y) + Double(openEnd.y)) / 2
        let backMidX = (Double(s.x) + Double(e.x)) / 2
        let backMidY = (Double(s.y) + Double(e.y)) / 2
        if nx * (backMidX - openMidX) + ny * (backMidY - openMidY) < 0 {
            nx = -nx; ny = -ny
        }
        return (nx, ny)
    }

    /// Edge lengths in polygon order: O-A, A-D, D-B, B-O.
    var edgeLengths: [Double] {
        let pts = polygon
        return (0..<pts.count).map { i in
            let p = pts[i]
            let q = pts[(i + 1) % pts.count]
            let dx = Double(q.x) - Double(p.x)
            let dy = Double(q.y) - Double(p.y)
            return (dx * dx + dy * dy).squareRoot()
        }
    }

    /// Index into `edgeLengths` of the declared back wall.
    /// Long leg A puts the back on D-B; long leg B puts it on A-D.
    private var backEdgeIndex: Int { longLegIsA ? 2 : 1 }

    /// Index into `edgeLengths` of the removed host-wall opening, if any.
    private var removedEdgeIndex: Int? {
        switch projection {
        case .inward: return nil
        case .outwardThroughWallA: return 0   // O-A
        case .outwardThroughWallB: return 3   // B-O
        }
    }

    /// The two side returns of a bump-out — the short walls connecting the
    /// removed opening to the back wall. Nil for an inward recess.
    ///
    /// Derived by elimination rather than hard-coded, so it stays correct for
    /// every combination of long leg and host wall.
    var sideReturns: (first: Double, second: Double)? {
        guard let removed = removedEdgeIndex else { return nil }
        let lengths = edgeLengths
        let remaining = (0..<lengths.count)
            .filter { $0 != removed && $0 != backEdgeIndex }
            .map { lengths[$0] }
        guard remaining.count == 2 else { return nil }
        return (remaining[0], remaining[1])
    }

    /// Length of the declared back wall run.
    var backWallLength: Double {
        let s = backWallStart
        let e = backWallEnd
        let dx = Double(e.x) - Double(s.x)
        let dy = Double(e.y) - Double(s.y)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// One-line human description of where C runs, for the form footer.
    var backWallDescription: String {
        longLegIsA
            ? "C runs from point B, parallel to wall A."
            : "C runs from point A, parallel to wall B."
    }
}

// MARK: - AlcoveCornerAnchor plan geometry

extension AlcoveCornerAnchor {

    var longLegLength: Double { max(footprintA, footprintB) }
    var shortLegLength: Double { min(footprintA, footprintB) }

    /// Ties break toward A so the geometry stays deterministic when the two
    /// legs are equal. An equal-leg alcove is square either way.
    var longLegIsA: Bool { footprintA >= footprintB }

    /// The back wall length actually used for drawing. When the author has not
    /// declared a C, fall back to the LONG leg, which reproduces the plain
    /// rectangular footprint the app drew before point C existed.
    var effectiveBackWallC: Double {
        guard let c = backWallC, c > 0 else { return longLegLength }
        return c
    }

    /// True when the author has explicitly declared a back wall length.
    /// Renderers should keep their legacy path when this is false so existing
    /// locked alcoves are not silently re-drawn.
    var hasDeclaredBackWall: Bool {
        guard let c = backWallC else { return false }
        return c > 0
    }

    /// Resolve the full plan footprint from the authored legs, C, and the
    /// projection direction.
    ///
    /// The point maths is identical for a recess and a bump-out — only the sign
    /// of one axis flips. A bump-out through wallA mirrors across wallA, so the
    /// body lands on the far side of it; through wallB mirrors across wallB.
    var planFootprint: AlcovePlanFootprint {
        let c = effectiveBackWallC
        let aIsLong = longLegIsA

        // Mirror factors. wallA runs along +x, so projecting THROUGH wallA
        // flips y. wallB runs along +y, so projecting through wallB flips x.
        let sx: Double
        let sy: Double
        switch projection {
        case .inward:
            sx = 1;  sy = 1
        case .outwardThroughWallA:
            sx = 1;  sy = -1
        case .outwardThroughWallB:
            sx = -1; sy = 1
        }

        // The opening offset slides the whole body ALONG the host wall. Only a
        // bump-out has a single host wall to slide along, so a corner recess
        // ignores it rather than translating into an undefined direction.
        let tx: Double
        let ty: Double
        switch projection {
        case .inward:
            tx = 0; ty = 0
        case .outwardThroughWallA:
            tx = openingOffset; ty = 0   // wallA runs along x
        case .outwardThroughWallB:
            tx = 0; ty = openingOffset   // wallB runs along y
        }

        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: x * sx + tx, y: y * sy + ty)
        }

        let pointO = pt(0, 0)
        let pointA = pt(footprintA, 0)
        let pointB = pt(0, footprintB)

        // C starts at the SHORT leg's endpoint and runs parallel to the LONG
        // leg's wall.
        let pointD = aIsLong
            ? pt(c, footprintB)   // from B, parallel to wallA
            : pt(footprintA, c)   // from A, parallel to wallB

        return AlcovePlanFootprint(
            pointO: pointO,
            pointA: pointA,
            pointB: pointB,
            pointD: pointD,
            backWallC: c,
            longLegIsA: aIsLong,
            longLegLength: longLegLength,
            shortLegLength: shortLegLength,
            projection: projection,
            openingOffset: openingOffset
        )
    }
}

// MARK: - Convenience

extension RoomAlcove {
    /// Plan footprint for this alcove. Pure derivation from `anchor`.
    var planFootprint: AlcovePlanFootprint { anchor.planFootprint }
}

extension LockedAlcove {
    /// Plan footprint for this alcove. Pure derivation from `anchor`.
    var planFootprint: AlcovePlanFootprint { anchor.planFootprint }
}
