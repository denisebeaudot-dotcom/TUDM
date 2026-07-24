import SwiftUI
import RealityKit

// MARK: - Public entry point

// A live 3D preview of a single Wall, built entirely from the Wall's
// structural data. Reads WallSpec + RoomDefaults + its segments and
// creates a RealityKit scene of chalk-white plaster wall, columns,
// beam, door slabs, and window glass. Camera can be set to preset
// architectural views (Front, Plan, Left, Right, Iso) or dragged
// freely with one finger.
//
// Requirements: iOS 18+ (RealityView).

enum WallCameraPreset: String, CaseIterable, Identifiable {
    case front = "Front"
    case plan = "Plan"
    case left = "Left"
    case right = "Right"
    case iso = "Iso"
    case free = "Free"
    var id: String { rawValue }
}

struct WallRealityPreview: View {
    let wall: WallSpec
    let defaults: RoomDefaults
    
    @State private var preset: WallCameraPreset = .front
    @State private var orbit: Double = 0
    @State private var tilt: Double = 0
    @State private var zoom: Double = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            Picker("Camera", selection: $preset) {
                ForEach(WallCameraPreset.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: preset) { _, newValue in
                applyPreset(newValue)
            }
            
            RealityView { content in
                let scene = WallSceneBuilder.build(wall: wall, defaults: defaults)
                content.add(scene.root)
                content.add(scene.cameraAnchor)
                content.add(scene.lightingAnchor)
                scene.cameraAnchor.name = "cameraAnchor"
            } update: { content in
                if let camAnchor = content.entities.first(where: { $0.name == "cameraAnchor" }) {
                    positionCamera(camAnchor,
                                   wallWidthInches: wall.totalWidth,
                                   wallHeightInches: defaults.ceilingHeight,
                                   preset: preset,
                                   orbit: orbit,
                                   tilt: tilt,
                                   zoom: zoom)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if preset != .free { preset = .free }
                        orbit = Double(value.translation.width) * 0.005 + orbit * 0.9
                        tilt = Double(-value.translation.height) * 0.003 + tilt * 0.9
                        tilt = min(max(tilt, -1.4), 1.4)
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        zoom = max(0.3, min(4.0, Double(scale)))
                    }
            )
            .background(Color(white: 0.95))
        }
        .onAppear { applyPreset(preset) }
    }
    
    private func applyPreset(_ p: WallCameraPreset) {
        switch p {
        case .front:
            orbit = 0
            tilt = 0
            zoom = 1.0
        case .plan:
            // Top-down looking straight down
            orbit = 0
            tilt = 1.35   // near pi/2, looking down
            zoom = 1.1
        case .left:
            orbit = -0.9  // ~-52 degrees, sees wall from the left
            tilt = 0.1
            zoom = 0.9
        case .right:
            orbit = 0.9
            tilt = 0.1
            zoom = 0.9
        case .iso:
            orbit = 0.55
            tilt = 0.45
            zoom = 0.85
        case .free:
            break   // leave current orbit/tilt/zoom
        }
    }
    
    private func positionCamera(_ anchor: Entity,
                                wallWidthInches: Double,
                                wallHeightInches: Double,
                                preset: WallCameraPreset,
                                orbit: Double,
                                tilt: Double,
                                zoom: Double) {
        let widthM = Float(wallWidthInches * WallSceneBuilder.metersPerInch)
        let heightM = Float(wallHeightInches * WallSceneBuilder.metersPerInch)
        let target = SIMD3<Float>(0, heightM / 2, 0)
        let baseDist = max(widthM, heightM) * 1.6
        let distance = baseDist / Float(zoom)
        
        let x: Float
        let y: Float
        let z: Float
        
        if preset == .plan {
            // Straight down, above the wall midline
            x = 0
            y = target.y + distance
            z = 0.001   // tiny offset so look(at:) has a defined up vector
        } else {
            x = target.x + distance * Float(sin(orbit))
            z = target.z + distance * Float(cos(orbit)) * Float(cos(tilt))
            y = target.y + distance * Float(sin(tilt))
        }
        
        anchor.position = SIMD3<Float>(x, y, z)
        anchor.look(at: target, from: anchor.position, relativeTo: nil)
    }
}

// MARK: - Scene builder

enum WallSceneBuilder {
    
    struct Scene {
        let root: AnchorEntity
        let cameraAnchor: AnchorEntity
        let lightingAnchor: AnchorEntity
    }
    // World unit convention: 1 unit = 1 meter. Convert inches -> meters.
    static let metersPerInch: Double = 0.0254
    static let wallDepthInches: Double = 4.5
    static let columnProtrusionDefault: Double = 9.25
    
    static func build(wall: WallSpec, defaults: RoomDefaults) -> Scene {
        let root = AnchorEntity(world: .zero)
        
        let plaster = plasterMaterial()
        let limedOak = limedOakMaterial()
        let glass = glassMaterial()
        let dark = darkOakMaterial()
        let floor = floorMaterial()
        
        let ceilingH = defaults.ceilingHeight
        let colProtrusion = max(defaults.columnDepth, columnProtrusionDefault)
        let wallW = wall.totalWidth
        let wallDepth = wallDepthInches
        
        // 1) Base wall plane
        let wallMesh = MeshResource.generateBox(
            width: Float(wallW * metersPerInch),
            height: Float(ceilingH * metersPerInch),
            depth: Float(wallDepth * metersPerInch)
        )
        let wallEntity = ModelEntity(mesh: wallMesh, materials: [plaster])
        wallEntity.position = SIMD3<Float>(
            0,
            Float(ceilingH / 2 * metersPerInch),
            Float(-wallDepth / 2 * metersPerInch)
        )
        root.addChild(wallEntity)
        
        // 2) Floor
        let floorSize = Float(max(wallW, 120) * metersPerInch * 2.5)
        let floorMesh = MeshResource.generatePlane(width: floorSize, depth: floorSize)
        let floorEntity = ModelEntity(mesh: floorMesh, materials: [floor])
        floorEntity.position = SIMD3<Float>(0, 0, Float(floorSize / 2 - 0.05))
        root.addChild(floorEntity)
        
        // 3) Segments
        var cursor: Double = -wallW / 2
        
        for seg in wall.segments {
            let segW = seg.resolvedWidth
            let segXCenter = cursor + segW / 2
            
            switch seg.kind {
            case .column:
                let colH = min(defaults.columnHeight, ceilingH)
                let colBox = MeshResource.generateBox(
                    width: Float(segW * metersPerInch),
                    height: Float(colH * metersPerInch),
                    depth: Float(colProtrusion * metersPerInch)
                )
                let col = ModelEntity(mesh: colBox, materials: [plaster])
                col.position = SIMD3<Float>(
                    Float(segXCenter * metersPerInch),
                    Float(colH / 2 * metersPerInch),
                    Float(colProtrusion / 2 * metersPerInch)
                )
                root.addChild(col)
                
            case .bookcase:
                addBookcase(to: root,
                            xCenter: segXCenter,
                            width: segW,
                            ceilingH: ceilingH,
                            shelfCount: seg.shelfCount ?? 5,
                            floorToCeiling: seg.isFloorToCeiling ?? true,
                            plaster: plaster,
                            oak: limedOak)
                
            case .windowUnit, .door, .opening:
                if let op = seg.opening {
                    addOpening(to: root,
                               xCenter: segXCenter,
                               segWidth: segW,
                               opening: op,
                               kind: seg.kind,
                               plaster: plaster,
                               oak: limedOak,
                               darkOak: dark,
                               glass: glass)
                }
                
            case .beam:
                let bH = defaults.beamHeight
                let bMesh = MeshResource.generateBox(
                    width: Float(segW * metersPerInch),
                    height: Float(bH * metersPerInch),
                    depth: Float((colProtrusion + 2) * metersPerInch)
                )
                let beam = ModelEntity(mesh: bMesh, materials: [limedOak])
                beam.position = SIMD3<Float>(
                    Float(segXCenter * metersPerInch),
                    Float((ceilingH - bH / 2) * metersPerInch),
                    Float((colProtrusion / 2 + 1) * metersPerInch)
                )
                root.addChild(beam)
                
            case .shelf:
                let count = max(1, seg.shelfCount ?? 1)
                let depth = max(0.25, seg.shelfDepth ?? 10)
                let thickness = max(0.25, seg.shelfThickness ?? 1.5)
                let spacedEvenly = seg.shelfSpacedEvenly ?? true
                for i in 0..<count {
                    let centerY: Double
                    if spacedEvenly {
                        let step = ceilingH / Double(count + 1)
                        centerY = step * Double(i + 1)
                    } else {
                        centerY = 12.0 * Double(i + 1)
                    }
                    let shelfMesh = MeshResource.generateBox(
                        width: Float(segW * metersPerInch),
                        height: Float(thickness * metersPerInch),
                        depth: Float(depth * metersPerInch)
                    )
                    let shelfEntity = ModelEntity(mesh: shelfMesh, materials: [limedOak])
                    shelfEntity.position = SIMD3<Float>(
                        Float(segXCenter * metersPerInch),
                        Float(centerY * metersPerInch),
                        Float((depth / 2) * metersPerInch)
                    )
                    root.addChild(shelfEntity)
                }
                
            default:
                break
            }
            
            cursor += segW
        }
        
        // 4) Auto-beam across columns
        if defaults.beamHeight > 0 && !wall.segments.contains(where: { $0.kind == .beam }) {
            addBeamOverColumns(root: root,
                               wall: wall,
                               ceilingH: ceilingH,
                               beamH: defaults.beamHeight,
                               colProtrusion: colProtrusion,
                               oak: limedOak)
        }
        
        // 5) Baseboard
        if defaults.baseboardHeight > 0 {
            let bbMesh = MeshResource.generateBox(
                width: Float(wallW * metersPerInch),
                height: Float(defaults.baseboardHeight * metersPerInch),
                depth: Float(0.75 * metersPerInch)
            )
            let bb = ModelEntity(mesh: bbMesh, materials: [limedOak])
            bb.position = SIMD3<Float>(
                0,
                Float(defaults.baseboardHeight / 2 * metersPerInch),
                Float(0.375 * metersPerInch)
            )
            root.addChild(bb)
        }
        
        // 6) Camera
        let cameraAnchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 45
        cameraAnchor.addChild(camera)
        
        // 7) Lighting
        let lightingAnchor = AnchorEntity(world: .zero)
        let sun = DirectionalLight()
        sun.light.intensity = 4000
        sun.light.color = UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0)
        sun.orientation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0])
        * simd_quatf(angle: .pi / 6, axis: [0, 1, 0])
        sun.position = SIMD3<Float>(2, 3, 3)
        lightingAnchor.addChild(sun)
        
        let fill = PointLight()
        fill.light.intensity = 30000
        fill.light.color = UIColor(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0)
        fill.light.attenuationRadius = 8
        fill.position = SIMD3<Float>(
            Float(-wallW / 4 * metersPerInch),
            Float(ceilingH * 0.7 * metersPerInch),
            2.5
        )
        lightingAnchor.addChild(fill)
        
        return Scene(root: root,
                     cameraAnchor: cameraAnchor,
                     lightingAnchor: lightingAnchor)
    }
    
    // MARK: - Bookcase
    
    private static func addBookcase(to root: Entity,
                                    xCenter: Double,
                                    width: Double,
                                    ceilingH: Double,
                                    shelfCount: Int,
                                    floorToCeiling: Bool,
                                    plaster: PhysicallyBasedMaterial,
                                    oak: PhysicallyBasedMaterial) {
        let bayDepth: Double = 12.0
        let boardThickness: Double = 1.0
        let bayHeight: Double = floorToCeiling ? ceilingH : (ceilingH * 0.75)
        
        let backMesh = MeshResource.generateBox(
            width: Float(width * metersPerInch),
            height: Float(bayHeight * metersPerInch),
            depth: Float(0.25 * metersPerInch)
        )
        let back = ModelEntity(mesh: backMesh, materials: [plaster])
        back.position = SIMD3<Float>(
            Float(xCenter * metersPerInch),
            Float(bayHeight / 2 * metersPerInch),
            Float(-bayDepth * metersPerInch)
        )
        root.addChild(back)
        
        let spacing = bayHeight / Double(shelfCount + 1)
        for i in 1...shelfCount {
            let yInches = spacing * Double(i)
            let shelf = ModelEntity(
                mesh: MeshResource.generateBox(
                    width: Float(width * metersPerInch),
                    height: Float(boardThickness * metersPerInch),
                    depth: Float(bayDepth * metersPerInch)
                ),
                materials: [oak]
            )
            shelf.position = SIMD3<Float>(
                Float(xCenter * metersPerInch),
                Float(yInches * metersPerInch),
                Float(-bayDepth / 2 * metersPerInch)
            )
            root.addChild(shelf)
        }
    }
    
    // MARK: - Opening
    
    private static func addOpening(to root: Entity,
                                   xCenter: Double,
                                   segWidth: Double,
                                   opening: OpeningSpec,
                                   kind: SegmentKind,
                                   plaster: PhysicallyBasedMaterial,
                                   oak: PhysicallyBasedMaterial,
                                   darkOak: PhysicallyBasedMaterial,
                                   glass: PhysicallyBasedMaterial) {
        let openingW = opening.openingWidth
        let openingH = opening.openingHeight
        let sillAFF = opening.sillOrBottomAFF
        let casingL = opening.casingLeft
        let casingR = opening.casingRight
        let casingHead = opening.casingHead
        
        let innerXCenter = xCenter + (casingL - casingR) / 2
        
        if casingL > 0 || casingR > 0 || casingHead > 0 {
            if casingL > 0 {
                let leftMesh = MeshResource.generateBox(
                    width: Float(casingL * metersPerInch),
                    height: Float((openingH + casingHead) * metersPerInch),
                    depth: Float(1.0 * metersPerInch)
                )
                let left = ModelEntity(mesh: leftMesh, materials: [oak])
                left.position = SIMD3<Float>(
                    Float((innerXCenter - openingW / 2 - casingL / 2) * metersPerInch),
                    Float((sillAFF + (openingH + casingHead) / 2) * metersPerInch),
                    Float(0.5 * metersPerInch)
                )
                root.addChild(left)
            }
            if casingR > 0 {
                let rightMesh = MeshResource.generateBox(
                    width: Float(casingR * metersPerInch),
                    height: Float((openingH + casingHead) * metersPerInch),
                    depth: Float(1.0 * metersPerInch)
                )
                let right = ModelEntity(mesh: rightMesh, materials: [oak])
                right.position = SIMD3<Float>(
                    Float((innerXCenter + openingW / 2 + casingR / 2) * metersPerInch),
                    Float((sillAFF + (openingH + casingHead) / 2) * metersPerInch),
                    Float(0.5 * metersPerInch)
                )
                root.addChild(right)
            }
            if casingHead > 0 {
                let headMesh = MeshResource.generateBox(
                    width: Float((openingW + casingL + casingR) * metersPerInch),
                    height: Float(casingHead * metersPerInch),
                    depth: Float(1.0 * metersPerInch)
                )
                let head = ModelEntity(mesh: headMesh, materials: [oak])
                head.position = SIMD3<Float>(
                    Float(innerXCenter * metersPerInch),
                    Float((sillAFF + openingH + casingHead / 2) * metersPerInch),
                    Float(0.5 * metersPerInch)
                )
                root.addChild(head)
            }
        }
        
        if kind == .door || opening.category == .door {
            let doorMesh = MeshResource.generateBox(
                width: Float(openingW * metersPerInch),
                height: Float(openingH * metersPerInch),
                depth: Float(1.75 * metersPerInch)
            )
            let door = ModelEntity(mesh: doorMesh, materials: [oak])
            door.position = SIMD3<Float>(
                Float(innerXCenter * metersPerInch),
                Float((sillAFF + openingH / 2) * metersPerInch),
                Float(0.9 * metersPerInch)
            )
            root.addChild(door)
            
            let handleMesh = MeshResource.generateSphere(radius: Float(1.0 * metersPerInch))
            let handle = ModelEntity(mesh: handleMesh, materials: [darkOak])
            handle.position = SIMD3<Float>(
                Float((innerXCenter + openingW / 2 - 3) * metersPerInch),
                Float((sillAFF + openingH / 2) * metersPerInch),
                Float(2.0 * metersPerInch)
            )
            root.addChild(handle)
        } else {
            let panelCount = max(1, opening.panelCount)
            let mullionW = opening.mullionWidth
            let mullionsDrawnCount = max(0, panelCount - 1)
            let totalMullionsW = Double(mullionsDrawnCount) * mullionW
            let panelsGlassW = max(0, openingW - totalMullionsW)
            
            let shares: [Double]
            if opening.panels.count == panelCount {
                let raw = opening.panels.map { max(0.0001, $0.widthShare) }
                let sum = raw.reduce(0, +)
                shares = raw.map { $0 / sum }
            } else {
                shares = Array(repeating: 1.0 / Double(panelCount), count: panelCount)
            }
            
            var pCursor = innerXCenter - openingW / 2
            
            for p in 0..<panelCount {
                let pW = shares[p] * panelsGlassW
                let pCenter = pCursor + pW / 2
                
                let paneMesh = MeshResource.generateBox(
                    width: Float(pW * metersPerInch),
                    height: Float(openingH * metersPerInch),
                    depth: Float(0.25 * metersPerInch)
                )
                let pane = ModelEntity(mesh: paneMesh, materials: [glass])
                pane.position = SIMD3<Float>(
                    Float(pCenter * metersPerInch),
                    Float((sillAFF + openingH / 2) * metersPerInch),
                    Float(0.4 * metersPerInch)
                )
                root.addChild(pane)
                
                let hasGrid = (p < opening.panels.count) ? opening.panels[p].hasMuntinGrid
                : (opening.muntinsRows > 0 || opening.muntinsCols > 0)
                let rowsRaw = (p < opening.panels.count) ? opening.panels[p].muntinRows : opening.muntinsRows
                let colsRaw = (p < opening.panels.count) ? opening.panels[p].muntinCols : opening.muntinsCols
                let rows = rowsRaw > 0 ? rowsRaw : opening.muntinsRows
                let cols = colsRaw > 0 ? colsRaw : opening.muntinsCols
                
                if hasGrid && (rows > 1 || cols > 1) {
                    addMuntinGrid(root: root,
                                  panelXCenter: pCenter,
                                  panelYCenter: sillAFF + openingH / 2,
                                  panelW: pW,
                                  panelH: openingH,
                                  rows: rows,
                                  cols: cols,
                                  barW: opening.muntinWidth,
                                  oak: oak)
                }
                
                pCursor += pW
                
                if p < panelCount - 1 && mullionW > 0 {
                    let mullMesh = MeshResource.generateBox(
                        width: Float(mullionW * metersPerInch),
                        height: Float(openingH * metersPerInch),
                        depth: Float(1.5 * metersPerInch)
                    )
                    let mull = ModelEntity(mesh: mullMesh, materials: [oak])
                    mull.position = SIMD3<Float>(
                        Float((pCursor + mullionW / 2) * metersPerInch),
                        Float((sillAFF + openingH / 2) * metersPerInch),
                        Float(0.75 * metersPerInch)
                    )
                    root.addChild(mull)
                    pCursor += mullionW
                }
            }
        }
    }
    
    private static func addMuntinGrid(root: Entity,
                                      panelXCenter: Double,
                                      panelYCenter: Double,
                                      panelW: Double,
                                      panelH: Double,
                                      rows: Int,
                                      cols: Int,
                                      barW: Double,
                                      oak: PhysicallyBasedMaterial) {
        if cols > 1 {
            for c in 1..<cols {
                let frac = Double(c) / Double(cols)
                let x = (panelXCenter - panelW / 2) + panelW * frac
                let bar = ModelEntity(
                    mesh: MeshResource.generateBox(
                        width: Float(barW * metersPerInch),
                        height: Float(panelH * metersPerInch),
                        depth: Float(0.6 * metersPerInch)
                    ),
                    materials: [oak]
                )
                bar.position = SIMD3<Float>(
                    Float(x * metersPerInch),
                    Float(panelYCenter * metersPerInch),
                    Float(0.5 * metersPerInch)
                )
                root.addChild(bar)
            }
        }
        if rows > 1 {
            for r in 1..<rows {
                let frac = Double(r) / Double(rows)
                let y = (panelYCenter - panelH / 2) + panelH * frac
                let bar = ModelEntity(
                    mesh: MeshResource.generateBox(
                        width: Float(panelW * metersPerInch),
                        height: Float(barW * metersPerInch),
                        depth: Float(0.6 * metersPerInch)
                    ),
                    materials: [oak]
                )
                bar.position = SIMD3<Float>(
                    Float(panelXCenter * metersPerInch),
                    Float(y * metersPerInch),
                    Float(0.5 * metersPerInch)
                )
                root.addChild(bar)
            }
        }
    }
    
    // MARK: - Auto beam over columns
    
    private static func addBeamOverColumns(root: Entity,
                                           wall: WallSpec,
                                           ceilingH: Double,
                                           beamH: Double,
                                           colProtrusion: Double,
                                           oak: PhysicallyBasedMaterial) {
        var xCursor = -wall.totalWidth / 2
        var firstColRight: Double? = nil
        var lastColLeft: Double? = nil
        for seg in wall.segments {
            let segW = seg.resolvedWidth
            if seg.kind == .column {
                let colLeft = xCursor
                let colRight = xCursor + segW
                if firstColRight == nil { firstColRight = colRight }
                lastColLeft = colLeft
            }
            xCursor += segW
        }
        guard let leftX = firstColRight, let rightX = lastColLeft, rightX > leftX else { return }
        let beamW = rightX - leftX
        let beamXCenter = (leftX + rightX) / 2
        let beamMesh = MeshResource.generateBox(
            width: Float(beamW * metersPerInch),
            height: Float(beamH * metersPerInch),
            depth: Float((colProtrusion + 2) * metersPerInch)
        )
        let beam = ModelEntity(mesh: beamMesh, materials: [oak])
        beam.position = SIMD3<Float>(
            Float(beamXCenter * metersPerInch),
            Float((ceilingH - beamH / 2) * metersPerInch),
            Float((colProtrusion / 2 + 1) * metersPerInch)
        )
        root.addChild(beam)
    }
    
    // MARK: - Materials
    
    private static func plasterMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1))
        m.roughness = .init(floatLiteral: 0.95)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
    
    private static func limedOakMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.78, green: 0.68, blue: 0.54, alpha: 1))
        m.roughness = .init(floatLiteral: 0.75)
        m.metallic = .init(floatLiteral: 0.0)
        return m
    }
    
    private static func darkOakMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.30, green: 0.22, blue: 0.16, alpha: 1))
        m.roughness = .init(floatLiteral: 0.4)
        m.metallic = .init(floatLiteral: 0.3)
        return m
    }
    
    private static func glassMaterial() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(red: 0.75, green: 0.85, blue: 0.88, alpha: 1))
        m.roughness = .init(floatLiteral: 0.05)
        m.metallic = .init(floatLiteral: 0.0)
        m.blending = .transparent(opacity: .init(floatLiteral: 0.35))
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
