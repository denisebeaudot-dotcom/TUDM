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
                platformPath(
                    shape: alcove.platform.shape,
                    footAPixels: footAPixels,
                    footBPixels: footBPixels
                )
                .fill(Color.orange.opacity(0.14))
                .offset(x: originX, y: originY)
                
                platformPath(
                    shape: alcove.platform.shape,
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
                backElementPath(
                    style: alcove.back.style,
                    footAPixels: footAPixels,
                    footBPixels: footBPixels,
                    colAWidth: colAWidth,
                    colADepth: colADepth,
                    colBWidth: colBWidth,
                    colBDepth: colBDepth
                )
                .stroke(backStrokeColor(alcove.back.material), lineWidth: 2)
                .offset(x: originX, y: originY)
                
                // Payload icon in the center of the platform
                payloadIcon
                    .frame(width: footAPixels, height: footBPixels)
                    .offset(x: originX, y: originY)
            }
        }
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
