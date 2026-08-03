// ============================================================
// DENISEBEAUDOT — BUILD MARKER — alcove bump-out + point C
// 2026-08-03 18:27 EDT   branch: alcove-bumpout-point-c
// If you cannot see this line at the very top, this file did
// not load or the paste was truncated.
// ============================================================

import SwiftUI

// MARK: - AlcovePlanThumbnail
//
// A minimal top-down plan-view of a corner alcove for the room card list.
// Renderer stub for Step 7b — draws the platform footprint as a rectangle
// with the two flanking columns at the far ends. The back element is drawn
// as an arc (or straight line) between the columns depending on style.
//
// This is not the final render pipeline. It only exists so the room card
// can carry a small visual so the user can eyeball the geometry.
// The RealityKit and photorealistic render pipelines will build on top of
// LockedAlcove in later steps.

struct AlcovePlanThumbnail: View {
    let alcove: LockedAlcove
    let wallATotalWidth: Double
    let wallBTotalWidth: Double
    
    var body: some View {
        GeometryReader { geo in
            let padding: Double = 8
            let availW = Double(geo.size.width) - padding * 2
            let availH = Double(geo.size.height) - padding * 2
            
            let footA = alcove.anchor.footprintA
            let footB = alcove.anchor.footprintB
            
            // Scale the alcove footprint so it fits the thumbnail.
            let inchesLongSide = max(footA, footB, 1)
            let scale = min(availW, availH) / inchesLongSide
            
            let footAPixels = footA * scale
            let footBPixels = footB * scale
            
            let originX = padding + (availW - footAPixels) / 2
            let originY = padding + (availH - footBPixels) / 2
            
            ZStack(alignment: .topLeading) {
                // Platform footprint. Shape follows alcove.platform.shape so a
                // convex curved front reads as a curve bulging out into the room,
                // and a concave front as a curve indenting toward the shared
                // corner. Chamfered draws a straight diagonal front.
                // Step 7c — when the author has declared a back wall C, the
                // footprint is the resolved O -> A -> D -> B quadrilateral.
                // Otherwise fall through to the pre-C path so locked alcoves
                // authored before point C existed render byte-identical.
                resolvedPlatformPath(
                    scale: scale,
                    footAPixels: footAPixels,
                    footBPixels: footBPixels
                )
                .fill(Color.orange.opacity(0.14))
                .offset(x: originX, y: originY)
                
                resolvedPlatformPath(
                    scale: scale,
                    footAPixels: footAPixels,
                    footBPixels: footBPixels
                )
                .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                .offset(x: originX, y: originY)
                
                // Column A sits at the far-along-A corner (inboard end on wall A).
                // In alcove coordinates that's the (footA, 0) corner.
                let colAWidth = min(alcove.columnA.width * scale, footAPixels)
                let colADepth = min(alcove.columnA.depth * scale, footBPixels)
                Rectangle()
                    .fill(columnFill(alcove.columnA.material))
                    .overlay(
                        Rectangle()
                            .stroke(Color.primary.opacity(0.5), lineWidth: 0.75)
                    )
                    .frame(width: colAWidth, height: colADepth)
                    .offset(x: originX + footAPixels - colAWidth, y: originY)
                
                // Column B sits at the far-along-B corner (inboard end on wall B).
                // That's the (0, footB) corner.
                let colBWidth = min(alcove.columnB.width * scale, footAPixels)
                let colBDepth = min(alcove.columnB.depth * scale, footBPixels)
                Rectangle()
                    .fill(columnFill(alcove.columnB.material))
                    .overlay(
                        Rectangle()
                            .stroke(Color.primary.opacity(0.5), lineWidth: 0.75)
                    )
                    .frame(width: colBWidth, height: colBDepth)
                    .offset(x: originX, y: originY + footBPixels - colBDepth)
                
                // Back element between the outer faces of the two columns.
                // Concave curved: arcs INTO the alcove (bulges toward the corner).
                // Convex curved: arcs OUT toward the room.
                // Flat: straight line.
                // Mitered: two straight lines meeting at a 45 corner (drawn as a chevron).
                resolvedBackElementPath(
                    scale: scale,
                    footAPixels: footAPixels,
                    footBPixels: footBPixels,
                    colAWidth: colAWidth,
                    colADepth: colADepth,
                    colBWidth: colBWidth,
                    colBDepth: colBDepth
                )
                .stroke(backStrokeColor(alcove.back.material), lineWidth: 2)
                .offset(x: originX, y: originY)
                
                // Derived point D marker. Only shown once C is authored, so
                // the marker doubles as the visual signal that this alcove
                // carries measured back-wall geometry.
                if alcove.anchor.hasDeclaredBackWall {
                    let d = alcove.anchor.planFootprint.pointD
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        .background(Circle().fill(Color(white: 1, opacity: 0.9)))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: originX + Double(d.x) * scale - 3,
                            y: originY + Double(d.y) * scale - 3
                        )
                }
                
                // Host wall guides. For a bump-out the body sits OUTSIDE the
                // room, so the two wall runs from the shared corner are drawn
                // as context and the opening is drawn as a dashed gap — that
                // dashed run is the wall segment that gets removed.
                if alcove.anchor.projection.isBumpOut {
                    hostWallGuidePath(footAPixels: footAPixels, footBPixels: footBPixels)
                        .stroke(Color.primary.opacity(0.45), lineWidth: 1.5)
                        .offset(x: originX, y: originY)
                    
                    openingPath(footAPixels: footAPixels, footBPixels: footBPixels)
                        .stroke(
                            Color.primary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                        )
                        .offset(x: originX, y: originY)
                }
                
                // Payload icon in the center of the platform
                payloadIcon
                    .frame(width: footAPixels, height: footBPixels)
                    .offset(x: originX, y: originY)
            }
            // A bump-out is the mirror image of the equivalent recess across
            // its host wall. Rather than sign every coordinate above, the whole
            // assembly — platform, columns, back element, payload — is flipped
            // once here, which keeps the pre-C drawing code untouched.
            .scaleEffect(x: planMirror.x, y: planMirror.y)
        }
    }
    
    /// Mirror factors for the plan drawing, driven by projection direction.
    /// Projecting through wall A (which runs along x) flips y, and vice versa.
    private var planMirror: (x: CGFloat, y: CGFloat) {
        switch alcove.anchor.projection {
        case .inward:              return (1, 1)
        case .outwardThroughWallA: return (1, -1)
        case .outwardThroughWallB: return (-1, 1)
        }
    }
    
    /// The two host wall runs meeting at the shared corner, drawn past the
    /// alcove so the L in the room outline is legible at thumbnail size.
    private func hostWallGuidePath(footAPixels: Double, footBPixels: Double) -> Path {
        var p = Path()
        let overrun: Double = 10
        let throughA = alcove.anchor.projection == .outwardThroughWallA
        if throughA {
            // Wall A is the host: it continues past point A. Wall B's run is
            // the side return, already part of the footprint.
            p.move(to: CGPoint(x: footAPixels, y: 0))
            p.addLine(to: CGPoint(x: footAPixels + overrun, y: 0))
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 0, y: footBPixels))
        } else {
            p.move(to: CGPoint(x: 0, y: footBPixels))
            p.addLine(to: CGPoint(x: 0, y: footBPixels + overrun))
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: footAPixels, y: 0))
        }
        return p
    }
    
    /// The host-wall segment that is deleted to open into the bump-out.
    private func openingPath(footAPixels: Double, footBPixels: Double) -> Path {
        var p = Path()
        p.move(to: .zero)
        if alcove.anchor.projection == .outwardThroughWallA {
            p.addLine(to: CGPoint(x: footAPixels, y: 0))
        } else {
            p.addLine(to: CGPoint(x: 0, y: footBPixels))
        }
        return p
    }
    
    @ViewBuilder
    private var payloadIcon: some View {
        switch alcove.payload {
        case .empty:
            EmptyView()
        case .woodStove:
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange.opacity(0.8))
                .font(.system(size: 18))
        }
    }
    
    private func columnFill(_ material: AlcoveMaterial) -> Color {
        switch material {
        case .redBrick: return Color.red.opacity(0.5)
        case .feedBrick: return Color(red: 0.55, green: 0.3, blue: 0.2).opacity(0.5)
        case .naturalStone: return Color.gray.opacity(0.5)
        case .paintedDrywall: return Color.white.opacity(0.7)
        case .wood: return Color.brown.opacity(0.5)
        case .tile: return Color.teal.opacity(0.4)
        case .other: return Color.secondary.opacity(0.35)
        }
    }
    
    private func backStrokeColor(_ material: AlcoveMaterial) -> Color {
        switch material {
        case .redBrick: return Color.red.opacity(0.8)
        case .feedBrick: return Color(red: 0.55, green: 0.3, blue: 0.2).opacity(0.9)
        case .naturalStone: return Color.gray
        case .paintedDrywall: return Color.primary.opacity(0.6)
        case .wood: return Color.brown
        case .tile: return Color.teal
        case .other: return Color.secondary
        }
    }
    
    // MARK: - Point-C aware paths (Step 7c)
    
    /// Platform outline. Branches on whether a back wall C has been declared.
    private func resolvedPlatformPath(
        scale: Double,
        footAPixels: Double,
        footBPixels: Double
    ) -> Path {
        guard alcove.anchor.hasDeclaredBackWall else {
            return platformPath(
                shape: alcove.platform.shape,
                footAPixels: footAPixels,
                footBPixels: footBPixels
            )
        }
        return pointCFootprintPath(scale: scale, shape: alcove.platform.shape)
    }
    
    /// Draw the back wall edge of the footprint.
    ///
    /// For an INWARD recess the back element is a feature sitting inside the
    /// footprint, so the footprint edge itself stays straight and the curve is
    /// drawn separately on top — that is the original wood stove behaviour and
    /// it is preserved exactly.
    ///
    /// For a BUMP-OUT the back wall IS the building envelope. A bowed back has
    /// to bend the footprint outline too, otherwise the filled body and the
    /// drawn wall disagree. So the style is applied to the edge itself.
    private func appendBackEnvelope(
        _ path: inout Path,
        from start: CGPoint,
        to end: CGPoint,
        footprint fp: AlcovePlanFootprint
    ) {
        guard fp.projection.isBumpOut else {
            path.addLine(to: end)
            return
        }
        
        let n = fp.backWallOutwardNormal
        let dx = Double(end.x) - Double(start.x)
        let dy = Double(end.y) - Double(start.y)
        let len = (dx * dx + dy * dy).squareRoot()
        // Bow depth as a fraction of the back wall run. A quad curve reaches
        // half its control offset, so the control point is doubled to make the
        // drawn bow match the intended depth.
        let bow = len * 0.18
        let midX = (Double(start.x) + Double(end.x)) / 2
        let midY = (Double(start.y) + Double(end.y)) / 2
        
        func control(_ signedBow: Double) -> CGPoint {
            CGPoint(
                x: midX + n.dx * signedBow * 2,
                y: midY + n.dy * signedBow * 2
            )
        }
        
        switch alcove.back.style {
        case .flat:
            // Square bump-out. Straight back wall.
            path.addLine(to: end)
        case .convexCurved:
            // Bow window — the back bulges away from the room.
            path.addQuadCurve(to: end, control: control(bow))
        case .concaveCurved:
            // The back is scooped back toward the opening.
            path.addQuadCurve(to: end, control: control(-bow))
        case .mitered:
            // Canted bay — two 45-degree splays into a flat back.
            let inset = 0.25
            let p1 = CGPoint(
                x: Double(start.x) + dx * inset + n.dx * bow,
                y: Double(start.y) + dy * inset + n.dy * bow
            )
            let p2 = CGPoint(
                x: Double(start.x) + dx * (1 - inset) + n.dx * bow,
                y: Double(start.y) + dy * (1 - inset) + n.dy * bow
            )
            path.addLine(to: p1)
            path.addLine(to: p2)
            path.addLine(to: end)
        }
    }
    
    private func pointCFootprintPath(scale: Double, shape: PlatformShape) -> Path {
        let fp = alcove.anchor.planFootprint
        func px(_ p: CGPoint) -> CGPoint {
            CGPoint(x: Double(p.x) * scale, y: Double(p.y) * scale)
        }
        
        let o = px(fp.pointO)
        let a = px(fp.pointA)
        let b = px(fp.pointB)
        let d = px(fp.pointD)
        
        var path = Path()
        path.move(to: o)
        
        if fp.longLegIsA {
            // A is the long leg. C runs from B parallel to wallA, so edge D->B
            // is the back wall and edge A->D is the derived closing face.
            path.addLine(to: a)
            appendClosingFace(&path, from: a, to: d, shape: shape)
            appendBackEnvelope(&path, from: d, to: b, footprint: fp)
        } else {
            // B is the long leg. C runs from A parallel to wallB, so edge A->D
            // is the back wall and edge D->B is the derived closing face.
            path.addLine(to: a)
            appendBackEnvelope(&path, from: a, to: d, footprint: fp)
            appendClosingFace(&path, from: d, to: b, shape: shape)
        }
        
        path.closeSubpath()
        return path
    }
    
    /// The derived closing face. Straight for rectangular and chamfered;
    /// curved variants bow relative to the shared corner at (0, 0).
    private func appendClosingFace(
        _ path: inout Path,
        from start: CGPoint,
        to end: CGPoint,
        shape: PlatformShape
    ) {
        let mid = CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
        
        switch shape {
        case .flatRectangular, .chamferedCorners:
            path.addLine(to: end)
        case .convexCurvedFront:
            // Bow away from the corner, out into the room.
            let ctrl = CGPoint(x: mid.x * 1.28, y: mid.y * 1.28)
            path.addQuadCurve(to: end, control: ctrl)
        case .concaveCurvedFront:
            // Bow back toward the corner.
            let ctrl = CGPoint(x: mid.x * 0.82, y: mid.y * 0.82)
            path.addQuadCurve(to: end, control: ctrl)
        }
    }
    
    /// Back element. Once C is declared the back element IS the C run, inset a
    /// touch at each end so it reads as masonry sitting between the columns
    /// rather than as the footprint edge itself.
    private func resolvedBackElementPath(
        scale: Double,
        footAPixels: Double,
        footBPixels: Double,
        colAWidth: Double,
        colADepth: Double,
        colBWidth: Double,
        colBDepth: Double
    ) -> Path {
        guard alcove.anchor.hasDeclaredBackWall else {
            return backElementPath(
                style: alcove.back.style,
                footAPixels: footAPixels,
                footBPixels: footBPixels,
                colAWidth: colAWidth,
                colADepth: colADepth,
                colBWidth: colBWidth,
                colBDepth: colBDepth
            )
        }
        
        let fp = alcove.anchor.planFootprint
        let start = CGPoint(
            x: Double(fp.backWallStart.x) * scale,
            y: Double(fp.backWallStart.y) * scale
        )
        let end = CGPoint(
            x: Double(fp.backWallEnd.x) * scale,
            y: Double(fp.backWallEnd.y) * scale
        )
        
        var path = Path()
        path.move(to: start)
        
        // For a bump-out the back wall is the envelope, so the drawn element
        // must trace exactly the same curve the footprint outline uses.
        // Sharing one routine is what keeps the fill and the stroke agreeing.
        if fp.projection.isBumpOut {
            appendBackEnvelope(&path, from: start, to: end, footprint: fp)
            return path
        }
        
        switch alcove.back.style {
        case .flat:
            path.addLine(to: end)
        case .concaveCurved:
            let ctrl = CGPoint(x: (start.x + end.x) / 2 * 0.80, y: (start.y + end.y) / 2 * 0.80)
            path.addQuadCurve(to: end, control: ctrl)
        case .convexCurved:
            let ctrl = CGPoint(x: (start.x + end.x) / 2 * 1.20, y: (start.y + end.y) / 2 * 1.20)
            path.addQuadCurve(to: end, control: ctrl)
        case .mitered:
            let mid = CGPoint(x: (start.x + end.x) / 2 * 0.88, y: (start.y + end.y) / 2 * 0.88)
            path.addLine(to: mid)
            path.addLine(to: end)
        }
        
        return path
    }
    
    // MARK: - Legacy paths (pre point-C)
    
    /// Return the SwiftUI Path for the platform footprint. The platform's
    /// two "wall" edges run along the wallA and wallB axes, meeting at the
    /// shared corner (0, 0). The front edge runs diagonally from the far end
    /// of wallA (footAPixels, 0) to the far end of wallB (0, footBPixels).
    /// That front edge is what curves depending on shape:
    ///  - flatRectangular: two straight edges forming a full rectangle,
    ///    front is a straight line from (footAPixels, 0) to (0, footBPixels)
    ///    inside the rectangle — but rectangular alcoves have no diagonal;
    ///    they use the full rectangle. Represented as the rectangle.
    ///  - convexCurvedFront: front arcs OUT into the room (away from origin)
    ///  - concaveCurvedFront: front arcs IN toward the origin
    ///  - chamferedCorners: straight diagonal front, forming a triangular
    ///    footprint touching wallA and wallB with a hypotenuse across
    private func platformPath(
        shape: PlatformShape,
        footAPixels: Double,
        footBPixels: Double
    ) -> Path {
        var path = Path()
        
        switch shape {
        case .flatRectangular:
            path.addRect(CGRect(x: 0, y: 0, width: footAPixels, height: footBPixels))
            return path
            
        case .chamferedCorners:
            // Triangular platform: (0,0) → (footAPixels, 0) → (0, footBPixels)
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: footAPixels, y: 0))
            path.addLine(to: CGPoint(x: 0, y: footBPixels))
            path.closeSubpath()
            return path
            
        case .convexCurvedFront:
            // Wall edges + curved front bulging OUT to the room (positive both
            // directions, i.e. control point outside the straight chord).
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: footAPixels, y: 0))
            let chordMidX = footAPixels / 2
            let chordMidY = footBPixels / 2
            let convexCtrl = CGPoint(
                x: chordMidX + footAPixels * 0.28,
                y: chordMidY + footBPixels * 0.28
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: footBPixels),
                control: convexCtrl
            )
            path.closeSubpath()
            return path
            
        case .concaveCurvedFront:
            // Wall edges + curved front indenting TOWARD the shared corner
            // (control point on the origin side of the chord).
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: footAPixels, y: 0))
            let chordMidX = footAPixels / 2
            let chordMidY = footBPixels / 2
            let concaveCtrl = CGPoint(
                x: chordMidX - footAPixels * 0.18,
                y: chordMidY - footBPixels * 0.18
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: footBPixels),
                control: concaveCtrl
            )
            path.closeSubpath()
            return path
        }
    }
    
    /// Return the SwiftUI Path for the back element between the two columns.
    /// The back spans from the outer face of column A to the outer face of
    /// column B (in alcove coordinates). The "outer face" is the face of
    /// the column that looks into the alcove interior — i.e. the face
    /// nearest the corner (0, 0) shared by wallA and wallB.
    private func backElementPath(
        style: BackElementStyle,
        footAPixels: Double,
        footBPixels: Double,
        colAWidth: Double,
        colADepth: Double,
        colBWidth: Double,
        colBDepth: Double
    ) -> Path {
        // Column A occupies rectangle
        //   x in [footAPixels - colAWidth, footAPixels]
        //   y in [0, colADepth]
        // Its inner face (toward the corner (0,0)) is the left+bottom-inner corner:
        //   (footAPixels - colAWidth, colADepth)
        // Column B occupies rectangle
        //   x in [0, colBWidth]
        //   y in [footBPixels - colBDepth, footBPixels]
        // Its inner face is (colBWidth, footBPixels - colBDepth)
        
        let aInner = CGPoint(x: footAPixels - colAWidth, y: colADepth)
        let bInner = CGPoint(x: colBWidth, y: footBPixels - colBDepth)
        
        var path = Path()
        path.move(to: aInner)
        
        switch style {
        case .flat:
            path.addLine(to: bInner)
        case .concaveCurved:
            // Bulge toward the shared corner at (0, 0).
            let ctrl = CGPoint(x: (aInner.x + bInner.x) / 2 * 0.35, y: (aInner.y + bInner.y) / 2 * 0.35)
            path.addQuadCurve(to: bInner, control: ctrl)
        case .convexCurved:
            // Bulge away from the shared corner toward the room interior.
            let mx = (aInner.x + bInner.x) / 2
            let my = (aInner.y + bInner.y) / 2
            let ctrl = CGPoint(x: mx + (footAPixels - mx) * 0.4, y: my + (footBPixels - my) * 0.4)
            path.addQuadCurve(to: bInner, control: ctrl)
        case .mitered:
            // Two straight legs meeting at a 45 corner between them.
            let mid = CGPoint(x: (aInner.x + bInner.x) / 2, y: (aInner.y + bInner.y) / 2)
            path.addLine(to: mid)
            path.addLine(to: bInner)
        }
        
        return path
    }
}
