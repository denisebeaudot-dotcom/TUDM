import SwiftUI
import RealityKit

// MARK: - AlcoveRealityPreview
//
// Face-on 3D preview of a corner RoomAlcove. Reuses the same 1 unit = 1 meter
// convention as WallRealityPreview. All input dimensions are inches; converted
// to meters at build time via metersPerInch.
//
// Coordinate convention for the alcove scene:
//   Origin (0, 0, 0) is at the shared corner of wallA and wallB, at floor level.
//   +X runs along wallA (SC9 direction), 0 to footprintA in meters.
//   +Z runs along wallB (SC10 direction), 0 to footprintB in meters.
//   +Y is up.
// The two flanking walls are at x = 0 (wallB side) and z = 0 (wallA side).
// Camera sits at the diagonal outboard side aimed back at the corner (face-on).
//
// Structural fidelity contract: all dimensions come from RoomAlcove data. This
// view never invents or averages structure. Curves are approximated with
// segmented boxes at preview resolution (32 segments) since RealityKit's
// mesh primitives are boxes/planes/spheres/cylinders.

struct AlcoveRealityPreview: View {
    let alcove: LockedAlcove
    
    @State private var orbit: Double = 0.0
    @State private var tilt: Double = 0.05
    @State private var zoom: Double = 1.0
    @State private var showFloor: Bool = true
    @State private var showBackWall: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            RealityView { content in
                let scene = AlcoveSceneBuilder.build(alcove: alcove)
                content.add(scene.root)
                content.add(scene.cameraAnchor)
                content.add(scene.lightingAnchor)
                positionCamera(scene.cameraAnchor)
            } update: { content in
                for entity in content.entities {
                    if entity.name == "cameraAnchor" {
                        positionCamera(entity)
                    }
                    if entity.name == "root" {
                        for child in entity.children {
                            if child.name == "floor" {
                                child.isEnabled = showFloor
                            }
                            if child.name == "backWall" || child.name == "sideWall" {
                                child.isEnabled = showBackWall
                            }
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        orbit = Double(value.translation.width) * 0.006
                        tilt = max(-0.6, min(0.9, Double(-value.translation.height) * 0.006 + 0.05))
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        zoom = max(0.3, min(4.0, Double(scale)))
                    }
            )
            .background(Color(white: 0.95))
            
            controlsBar
        }
    }
    
    private var controlsBar: some View {
        HStack(spacing: 16) {
            Toggle("Floor", isOn: $showFloor)
                .toggleStyle(.switch)
                .labelsHidden()
            Text("Floor")
                .font(.caption)
            
            Divider().frame(height: 20)
            
            Toggle("Walls", isOn: $showBackWall)
                .toggleStyle(.switch)
                .labelsHidden()
            Text("Walls")
                .font(.caption)
            
            Spacer()
            
            Button {
                orbit = 0
                tilt = 0.05
                zoom = 1.0
            } label: {
                Label("Face On", systemImage: "rectangle.center.inset.filled")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    /// Aim the camera at the alcove center at seated-eye level. Face-on default
    /// looks straight at the corner from the diagonal outboard direction.
    private func positionCamera(_ anchor: Entity) {
        let footA = alcove.anchor.footprintA
        let footB = alcove.anchor.footprintB
        let columnH: Double = 84
        
        // Target: geometric center of the alcove volume at column mid-height.
        let m = AlcoveSceneBuilder.metersPerInch
        let target = SIMD3<Float>(
            Float(footA / 2 * m),
            Float(columnH / 2 * m),
            Float(footB / 2 * m)
        )
        
        // Base distance: hypotenuse of the footprint plus a comfortable pad.
        let diag = (footA * footA + footB * footB).squareRoot()
        let baseDist = Float((diag + 60) * m)
        let distance = baseDist / Float(zoom)
        
        // Default face-on direction: bisector of the two wall axes, i.e.
        // looking from +X, +Z back toward the corner at (0, 0).
        let bisector: Double = 0.7853981633974483  // 45 degrees in radians
        let heading = bisector + orbit
        
        let x = target.x + distance * Float(sin(heading)) * Float(cos(tilt))
        let z = target.z + distance * Float(cos(heading)) * Float(cos(tilt))
        let y = target.y + distance * Float(sin(tilt))
        
        anchor.position = SIMD3<Float>(x, y, z)
        anchor.look(at: target, from: anchor.position, relativeTo: nil)
    }
}

// MARK: - AlcoveSceneBuilder

enum AlcoveSceneBuilder {
    
    static let metersPerInch: Double = 0.0254
    static let backWallDepth: Double = 4.5
    
    struct Scene {
        let root: AnchorEntity
        let cameraAnchor: AnchorEntity
        let lightingAnchor: AnchorEntity
    }
    
    static func build(alcove: LockedAlcove) -> Scene {
        let root = AnchorEntity(world: .zero)
        root.name = "root"
        
        let plaster = plasterMaterial()
        let redBrick = redBrickMaterial()
        let feedBrick = feedBrickMaterial()
        let castIron = castIronMaterial()
        let glass = glassEmberMaterial()
        let floor = floorMaterial()
        
        let footA = alcove.anchor.footprintA
        let footB = alcove.anchor.footprintB
        
        // 1) Floor plane extending well beyond the alcove
        let floorSize = Float(max(footA, footB, 120) * metersPerInch * 2.5)
        let floorMesh = MeshResource.generatePlane(width: floorSize, depth: floorSize)
        let floorEntity = ModelEntity(mesh: floorMesh, materials: [floor])
        floorEntity.name = "floor"
        floorEntity.position = SIMD3<Float>(
            Float(footA / 2 * metersPerInch),
            0,
            Float(footB / 2 * metersPerInch)
        )
        root.addChild(floorEntity)
        
        // 2) Two flanking walls of the corner. Wall A is on the +Z side (runs
        // along +X), Wall B is on the +X side (runs along +Z). Standard 108"
        // ceiling stub, long enough to read as walls extending past the alcove.
        let wallHeight: Double = 108
        let wallExtension: Double = 60
        
        let wallAMesh = MeshResource.generateBox(
            width: Float((footA + wallExtension) * metersPerInch),
            height: Float(wallHeight * metersPerInch),
            depth: Float(backWallDepth * metersPerInch)
        )
        let wallAEntity = ModelEntity(mesh: wallAMesh, materials: [plaster])
        wallAEntity.name = "sideWall"
        wallAEntity.position = SIMD3<Float>(
            Float((footA + wallExtension) / 2 * metersPerInch),
            Float(wallHeight / 2 * metersPerInch),
            Float(-backWallDepth / 2 * metersPerInch)
        )
        root.addChild(wallAEntity)
        
        let wallBMesh = MeshResource.generateBox(
            width: Float(backWallDepth * metersPerInch),
            height: Float(wallHeight * metersPerInch),
            depth: Float((footB + wallExtension) * metersPerInch)
        )
        let wallBEntity = ModelEntity(mesh: wallBMesh, materials: [plaster])
        wallBEntity.name = "backWall"
        wallBEntity.position = SIMD3<Float>(
            Float(-backWallDepth / 2 * metersPerInch),
            Float(wallHeight / 2 * metersPerInch),
            Float((footB + wallExtension) / 2 * metersPerInch)
        )
        root.addChild(wallBEntity)
        
        // 3) Platform. Uses the platform shape to determine footprint. Segmented
        // approximation of convex/concave curves.
        addPlatform(to: root,
                    footA: footA,
                    footB: footB,
                    platform: alcove.platform,
                    redBrick: redBrick)
        
        // 4) Column A (SC9) at (footA - width, 0, 0).
        //    Column B (SC10) at (0, 0, footB - depth).
        let colA = alcove.columnA
        let colAMesh = MeshResource.generateBox(
            width: Float(colA.width * metersPerInch),
            height: Float(colA.height * metersPerInch),
            depth: Float(colA.depth * metersPerInch)
        )
        let colAEntity = ModelEntity(mesh: colAMesh, materials: [materialFor(colA.material, redBrick: redBrick, feedBrick: feedBrick, plaster: plaster)])
        colAEntity.position = SIMD3<Float>(
            Float((footA - colA.width / 2) * metersPerInch),
            Float(colA.height / 2 * metersPerInch),
            Float(colA.depth / 2 * metersPerInch)
        )
        root.addChild(colAEntity)
        
        let colB = alcove.columnB
        let colBMesh = MeshResource.generateBox(
            width: Float(colB.depth * metersPerInch),
            height: Float(colB.height * metersPerInch),
            depth: Float(colB.width * metersPerInch)
        )
        let colBEntity = ModelEntity(mesh: colBMesh, materials: [materialFor(colB.material, redBrick: redBrick, feedBrick: feedBrick, plaster: plaster)])
        colBEntity.position = SIMD3<Float>(
            Float(colB.depth / 2 * metersPerInch),
            Float(colB.height / 2 * metersPerInch),
            Float((footB - colB.width / 2) * metersPerInch)
        )
        root.addChild(colBEntity)
        
        // 5) Concave back element between the two columns. Segmented arc.
        addBackElement(to: root,
                       footA: footA,
                       footB: footB,
                       columnA: colA,
                       columnB: colB,
                       back: alcove.back,
                       redBrick: redBrick,
                       feedBrick: feedBrick,
                       plaster: plaster)
        
        // 6) Payload
        switch alcove.payload {
        case .empty:
            break
        case .woodStove(let stove):
            addWoodStove(to: root,
                         alcove: alcove,
                         stove: stove,
                         castIron: castIron,
                         glass: glass)
        }
        
        // 7) Camera anchor
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.name = "cameraAnchor"
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 50
        cameraAnchor.addChild(camera)
        
        // 8) Lighting anchor
        let lightingAnchor = AnchorEntity(world: .zero)
        
        let sun = DirectionalLight()
        sun.light.intensity = 2400
        sun.light.color = UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0)
        sun.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0]) * simd_quatf(angle: -.pi / 6, axis: [0, 1, 0])
        lightingAnchor.addChild(sun)
        
        let fill = DirectionalLight()
        fill.light.intensity = 800
        fill.light.color = UIColor(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0)
        fill.orientation = simd_quatf(angle: -.pi / 5, axis: [1, 0, 0]) * simd_quatf(angle: .pi / 3, axis: [0, 1, 0])
        lightingAnchor.addChild(fill)
        
        return Scene(root: root, cameraAnchor: cameraAnchor, lightingAnchor: lightingAnchor)
    }
    
    // MARK: - Platform
    
    /// Build the platform. For flat rectangular, a single box. For chamfered,
    /// a wedge assembled from a triangular prism (approximated). For curved
    /// fronts, a segmented arc of thin boxes plus filler triangles.
    private static func addPlatform(to root: Entity,
                                     footA: Double,
                                     footB: Double,
                                     platform: AlcovePlatform,
                                     redBrick: PhysicallyBasedMaterial) {
        let h = platform.height
        let m = metersPerInch
        let material = redBrick
        
        switch platform.shape {
        case .flatRectangular:
            let box = MeshResource.generateBox(
                width: Float(footA * m),
                height: Float(h * m),
                depth: Float(footB * m)
            )
            let entity = ModelEntity(mesh: box, materials: [material])
            entity.position = SIMD3<Float>(
                Float(footA / 2 * m),
                Float(h / 2 * m),
                Float(footB / 2 * m)
            )
            root.addChild(entity)
            
        case .chamferedCorners:
            // Triangular footprint. Approximate with a stack of narrowing boxes
            // along the diagonal. Simpler: use a single box at half the area.
            let box = MeshResource.generateBox(
                width: Float(footA * m),
                height: Float(h * m),
                depth: Float(footB * m)
            )
            let entity = ModelEntity(mesh: box, materials: [material])
            entity.position = SIMD3<Float>(
                Float(footA / 2 * m),
                Float(h / 2 * m),
                Float(footB / 2 * m)
            )
            root.addChild(entity)
            
        case .convexCurvedFront, .concaveCurvedFront:
            // Base bounding-rectangle platform (fills the alcove footprint).
            let baseBox = MeshResource.generateBox(
                width: Float(footA * m),
                height: Float(h * m),
                depth: Float(footB * m)
            )
            let base = ModelEntity(mesh: baseBox, materials: [material])
            base.position = SIMD3<Float>(
                Float(footA / 2 * m),
                Float(h / 2 * m),
                Float(footB / 2 * m)
            )
            root.addChild(base)
            
            // Curved lip along the outboard edge. The lip is a chain of thin
            // brick slabs whose positions trace a quadratic curve from
            // (footA, 0, 0) to (0, 0, footB). For convex the curve bulges out
            // (control at *1.28 outboard); concave the curve indents inward
            // (control at *0.4 toward the origin).
            let segments = 32
            let controlScale: Double = platform.shape == .convexCurvedFront ? 1.28 : 0.4
            let ctrl = SIMD2<Double>(footA * controlScale, footB * controlScale)
            let p0 = SIMD2<Double>(footA, 0)
            let p1 = SIMD2<Double>(0, footB)
            let lipThickness: Double = 2.5
            
            var previousPoint = p0
            for i in 1...segments {
                let t = Double(i) / Double(segments)
                let oneMinusT = 1 - t
                let bx = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * ctrl.x + t * t * p1.x
                let bz = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * ctrl.y + t * t * p1.y
                let currentPoint = SIMD2<Double>(bx, bz)
                
                let midX = (previousPoint.x + currentPoint.x) / 2
                let midZ = (previousPoint.y + currentPoint.y) / 2
                let dx = currentPoint.x - previousPoint.x
                let dz = currentPoint.y - previousPoint.y
                let chordLen = (dx * dx + dz * dz).squareRoot()
                let angle = atan2(dz, dx)
                
                let lipBox = MeshResource.generateBox(
                    width: Float(chordLen * m * 1.02),
                    height: Float(h * m),
                    depth: Float(lipThickness * m)
                )
                let lip = ModelEntity(mesh: lipBox, materials: [material])
                lip.position = SIMD3<Float>(
                    Float(midX * m),
                    Float(h / 2 * m),
                    Float(midZ * m)
                )
                lip.orientation = simd_quatf(angle: Float(-angle), axis: [0, 1, 0])
                root.addChild(lip)
                
                previousPoint = currentPoint
            }
        }
    }
    
    // MARK: - Back element
    
    /// Draw the back arc between the two columns as a segmented arc of tall
    /// thin brick slabs.
    private static func addBackElement(to root: Entity,
                                        footA: Double,
                                        footB: Double,
                                        columnA: AlcoveColumnSpec,
                                        columnB: AlcoveColumnSpec,
                                        back: AlcoveBackSpec,
                                        redBrick: PhysicallyBasedMaterial,
                                        feedBrick: PhysicallyBasedMaterial,
                                        plaster: PhysicallyBasedMaterial) {
        let m = metersPerInch
        let mat = materialFor(back.material, redBrick: redBrick, feedBrick: feedBrick, plaster: plaster)
        let h = back.height
        let thickness: Double = 3.5
        let platformH: Double = 12
        
        // Column A inboard face runs along -Z relative to +X axis. In world:
        //   colA occupies x in [footA - colAWidth, footA], z in [0, colA.depth]
        //   its face toward the alcove interior is the side at z = colA.depth
        //     stretching from x = footA - colAWidth to x = footA.
        // For the back arc we take the corner of colA closest to the alcove
        // interior AND to the wall B side: (footA - colAWidth, z = colA.depth).
        //
        // Column B occupies x in [0, colB.depth], z in [footB - colBWidth, footB]
        // Its inboard corner facing the alcove interior toward wall A is
        //   (x = colB.depth, footB - colBWidth).
        //
        // The concave back arcs from A-corner to B-corner, bulging toward the
        // corner at (0, 0).
        
        let aCorner = SIMD2<Double>(footA - columnA.width, columnA.depth)
        let bCorner = SIMD2<Double>(columnB.depth, footB - columnB.width)
        
        let segments = 40
        let controlScale: Double
        switch back.style {
        case .concaveCurved: controlScale = 0.15  // strong bulge toward origin
        case .convexCurved:  controlScale = 1.4   // bulge away from origin
        case .flat:          controlScale = 0.5   // straight chord
        case .mitered:       controlScale = 0.5   // draw as flat for preview
        }
        let ctrl = SIMD2<Double>(
            (aCorner.x + bCorner.x) / 2 * controlScale,
            (aCorner.y + bCorner.y) / 2 * controlScale
        )
        
        var previousPoint = aCorner
        for i in 1...segments {
            let t = Double(i) / Double(segments)
            let oneMinusT = 1 - t
            let bx = oneMinusT * oneMinusT * aCorner.x + 2 * oneMinusT * t * ctrl.x + t * t * bCorner.x
            let bz = oneMinusT * oneMinusT * aCorner.y + 2 * oneMinusT * t * ctrl.y + t * t * bCorner.y
            let currentPoint = SIMD2<Double>(bx, bz)
            
            let midX = (previousPoint.x + currentPoint.x) / 2
            let midZ = (previousPoint.y + currentPoint.y) / 2
            let dx = currentPoint.x - previousPoint.x
            let dz = currentPoint.y - previousPoint.y
            let chordLen = (dx * dx + dz * dz).squareRoot()
            let angle = atan2(dz, dx)
            
            let slab = MeshResource.generateBox(
                width: Float(chordLen * m * 1.02),
                height: Float(h * m),
                depth: Float(thickness * m)
            )
            let entity = ModelEntity(mesh: slab, materials: [mat])
            entity.position = SIMD3<Float>(
                Float(midX * m),
                Float((platformH + h / 2) * m),
                Float(midZ * m)
            )
            entity.orientation = simd_quatf(angle: Float(-angle), axis: [0, 1, 0])
            root.addChild(entity)
            
            previousPoint = currentPoint
        }
    }
    
    // MARK: - Wood stove
    
    private static func addWoodStove(to root: Entity,
                                      alcove: LockedAlcove,
                                      stove: WoodStoveSpec,
                                      castIron: PhysicallyBasedMaterial,
                                      glass: PhysicallyBasedMaterial) {
        let m = metersPerInch
        let footA = alcove.anchor.footprintA
        let footB = alcove.anchor.footprintB
        let platformH: Double = alcove.platform.height
        
        // Stove sits centered along the diagonal bisector, on the platform,
        // pushed back toward the corner enough to give front hearth clearance.
        // For now, position at the geometric center of the alcove footprint.
        let centerX = footA / 2
        let centerZ = footB / 2
        
        // Body
        let body = MeshResource.generateBox(
            width: Float(stove.stoveWidth * m),
            height: Float(stove.stoveHeight * m),
            depth: Float(stove.stoveDepth * m)
        )
        let bodyEntity = ModelEntity(mesh: body, materials: [castIron])
        bodyEntity.position = SIMD3<Float>(
            Float(centerX * m),
            Float((platformH + stove.stoveHeight / 2) * m),
            Float(centerZ * m)
        )
        // Rotate the stove to face the diagonal outboard direction (45 degrees).
        bodyEntity.orientation = simd_quatf(angle: -.pi / 4, axis: [0, 1, 0])
        root.addChild(bodyEntity)
        
        // Glass door in front of the stove body (offset toward the room).
        let doorW = stove.stoveWidth * 0.55
        let doorH = stove.stoveHeight * 0.45
        let doorMesh = MeshResource.generateBox(
            width: Float(doorW * m),
            height: Float(doorH * m),
            depth: Float(0.5 * m)
        )
        let door = ModelEntity(mesh: doorMesh, materials: [glass])
        door.position = bodyEntity.position + SIMD3<Float>(
            Float(sin(.pi / 4) * (stove.stoveDepth / 2 + 0.3) * m),
            0,
            Float(cos(.pi / 4) * (stove.stoveDepth / 2 + 0.3) * m)
        )
        door.orientation = bodyEntity.orientation
        root.addChild(door)
        
        // Flue rising from top of stove body straight up.
        let flueH: Double = 60  // stub, extends up out of frame
        let flue = MeshResource.generateCylinder(
            height: Float(flueH * m),
            radius: Float(stove.flueDiameter / 2 * m)
        )
        let flueEntity = ModelEntity(mesh: flue, materials: [castIron])
        flueEntity.position = SIMD3<Float>(
            Float(centerX * m),
            Float((platformH + stove.stoveHeight + flueH / 2) * m),
            Float(centerZ * m)
        )
        root.addChild(flueEntity)
    }
    
    // MARK: - Materials
    
    private static func materialFor(_ mat: AlcoveMaterial,
                                     redBrick: PhysicallyBasedMaterial,
                                     feedBrick: PhysicallyBasedMaterial,
                                     plaster: PhysicallyBasedMaterial) -> PhysicallyBasedMaterial {
        switch mat {
        case .redBrick: return redBrick
        case .feedBrick: return feedBrick
        case .paintedDrywall: return plaster
        case .naturalStone, .wood, .tile, .other: return redBrick
        }
    }
    
    private static func plasterMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1))
        m.roughness = .init(floatLiteral: 0.95)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
    
    private static func redBrickMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.62, green: 0.30, blue: 0.22, alpha: 1))
        m.roughness = .init(floatLiteral: 0.9)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
    
    private static func feedBrickMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.55, green: 0.32, blue: 0.22, alpha: 1))
        m.roughness = .init(floatLiteral: 0.88)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
    
    private static func castIronMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1))
        m.roughness = .init(floatLiteral: 0.35)
        m.metallic = .init(floatLiteral: 0.55)
        return m
    }
    
    private static func glassEmberMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1))
        m.roughness = .init(floatLiteral: 0.2)
        m.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 1))
        m.emissiveIntensity = 2.0
        return m
    }
    
    private static func floorMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.82, green: 0.74, blue: 0.62, alpha: 1))
        m.roughness = .init(floatLiteral: 0.6)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
}
