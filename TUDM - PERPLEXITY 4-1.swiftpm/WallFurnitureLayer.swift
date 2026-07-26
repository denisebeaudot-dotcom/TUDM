import SwiftUI
import RealityKit

// MARK: - Wall Furniture Layer
//
// Adds a deterministic furniture layer to a wall's RealityKit preview.
// Furniture placement is derived from the wall's own structural data:
//   - Sofa centered on the widest window opening's center X
//   - Coffee table centered in front of the sofa
//   - Side tables flanking the sofa with a fixed gap
//   - Table lamps sitting on top of the side tables
//   - Roman blinds mounted inside the top of each window casing
//   - Two curtain panels flanking each window at the outer casing edges
//
// No dimensions are hardcoded to Wall 1. Everything computes from the
// LockedWall segments. Same wall data in, same scene out.
//
// G-numbers preserved from LockedWall: this layer only reads, never
// mutates. G1 (dimensions immutable) holds.

// MARK: - Furniture placement plan

struct WallFurniturePlan {
    struct SofaPlan {
        let centerX: Double        // wall-local X in inches, from wall left
        let width: Double          // inches
        let depth: Double          // inches (Z out from wall)
        let seatHeight: Double     // inches from floor
        let backHeight: Double     // inches from floor
        let armHeight: Double      // inches from floor
        let legHeight: Double      // inches from floor
        let cushionCount: Int
    }
    struct SideTablePlan {
        let centerX: Double
        let width: Double
        let depth: Double
        let height: Double
    }
    struct CoffeeTablePlan {
        let centerX: Double
        let centerZ: Double        // distance out from wall (inches)
        let diameter: Double
        let height: Double
    }
    struct LampPlan {
        let centerX: Double
        let sitOnTopOfHeight: Double   // height at which base of lamp starts
        let baseDiameter: Double
        let baseHeight: Double
        let shadeTopDiameter: Double
        let shadeBottomDiameter: Double
        let shadeHeight: Double
    }
    struct BlindPlan {
        let xLeft: Double
        let xRight: Double
        let yTop: Double
        let yBottom: Double     // pulled down by fraction of window height
        let mountDepth: Double  // Z offset from wall face
    }
    struct CurtainPanelPlan {
        let centerX: Double
        let width: Double        // typical 10 inches
        let topY: Double
        let bottomY: Double
        let mountDepth: Double
    }
    struct CurtainRodPlan {
        let xLeft: Double
        let xRight: Double
        let y: Double
        let mountDepth: Double
        let diameter: Double
    }
    struct RugPlan {
        let centerX: Double
        let width: Double
        let depth: Double        // in Z direction (out from wall)
    }
    
    let sofa: SofaPlan?
    let leftSideTable: SideTablePlan?
    let rightSideTable: SideTablePlan?
    let coffeeTable: CoffeeTablePlan?
    let leftLamp: LampPlan?
    let rightLamp: LampPlan?
    let blinds: [BlindPlan]
    let curtainRods: [CurtainRodPlan]
    let curtainPanels: [CurtainPanelPlan]
    let rug: RugPlan?
    
    // Derive a plan from the wall's own data. Returns an empty plan if
    // no window opening is found (the anchor needed for placement).
    static func derive(from wall: LockedWall, defaults: RoomDefaults) -> WallFurniturePlan {
        // Find the largest window opening. Sofa centers on its center X.
        var cursor: Double = -wall.totalWidth / 2
        var windowSegs: [(centerX: Double, width: Double, opening: OpeningSpec)] = []
        var windowCasingBoundsByCenter: [Double: (Double, Double)] = [:]  // centerX -> (leftEdge, rightEdge) of casing pair around the window
        // Also collect casings so we can compute the casing pair around each window
        struct SegBox {
            let centerX: Double
            let width: Double
            let kind: SegmentKind
        }
        var boxes: [SegBox] = []
        for seg in wall.segments {
            let w = seg.resolvedWidth
            let cx = cursor + w / 2
            boxes.append(SegBox(centerX: cx, width: w, kind: seg.kind))
            if seg.kind == .windowUnit, let op = seg.opening {
                windowSegs.append((cx, w, op))
            }
            cursor += w
        }
        
        guard let anchorWindow = windowSegs.max(by: { $0.width < $1.width }) else {
            return WallFurniturePlan(sofa: nil,
                                     leftSideTable: nil,
                                     rightSideTable: nil,
                                     coffeeTable: nil,
                                     leftLamp: nil,
                                     rightLamp: nil,
                                     blinds: [],
                                     curtainRods: [],
                                     curtainPanels: [],
                                     rug: nil)
        }
        
        // For each window, find the pair of adjacent casings so we know
        // the outer casing edges (for curtain rod and panel placement).
        var blinds: [BlindPlan] = []
        var rods: [CurtainRodPlan] = []
        var panels: [CurtainPanelPlan] = []
        for (i, box) in boxes.enumerated() {
            if box.kind != .windowUnit { continue }
            // Recover the opening for this window
            let matchWin = windowSegs.first(where: {
                abs($0.centerX - box.centerX) < 0.001
            })
            guard let win = matchWin else { continue }
            let winLeft = box.centerX - box.width / 2
            let winRight = box.centerX + box.width / 2
            let winBottom = win.opening.sillOrBottomAFF
            let winTop = winBottom + win.opening.openingHeight
            // Adjacent casings (if present) sit immediately outside the window
            var leftCasingOuter = winLeft
            if i > 0 {
                let prev = boxes[i - 1]
                if prev.kind == .casing {
                    leftCasingOuter = prev.centerX - prev.width / 2
                }
            }
            var rightCasingOuter = winRight
            if i < boxes.count - 1 {
                let next = boxes[i + 1]
                if next.kind == .casing {
                    rightCasingOuter = next.centerX + next.width / 2
                }
            }
            
            // Roman blinds: pulled down 30% of the window height
            let pullFraction = 0.30
            let blindBottom = winTop - (winTop - winBottom) * pullFraction
            blinds.append(BlindPlan(
                xLeft: winLeft + 0.5,
                xRight: winRight - 0.5,
                yTop: winTop - 0.5,
                yBottom: blindBottom,
                mountDepth: 1.0
            ))
            
            // Curtain rod: from just outboard of left casing to just outboard of right casing
            let rodY = winTop + 2.0    // 2 inches above window head
            let rodExtension = 1.0
            rods.append(CurtainRodPlan(
                xLeft: leftCasingOuter - rodExtension,
                xRight: rightCasingOuter + rodExtension,
                y: rodY,
                mountDepth: 3.5,
                diameter: 0.75
            ))
            
            // Curtain panels: just inboard of casing outer edges
            let panelW = 10.0
            let leftPanelCX = leftCasingOuter + panelW / 2 + 0.5
            let rightPanelCX = rightCasingOuter - panelW / 2 - 0.5
            let panelTop = rodY - 0.5
            let panelBottom = defaults.baseboardHeight + 0.5
            panels.append(CurtainPanelPlan(
                centerX: leftPanelCX,
                width: panelW,
                topY: panelTop,
                bottomY: panelBottom,
                mountDepth: 3.5
            ))
            panels.append(CurtainPanelPlan(
                centerX: rightPanelCX,
                width: panelW,
                topY: panelTop,
                bottomY: panelBottom,
                mountDepth: 3.5
            ))
        }
        
        // Sofa centered on the anchor window
        let sofaW = 84.0
        let sofaD = 36.0
        let sofaCX = anchorWindow.centerX
        let sofaLegH = 6.0
        let sofaSeatH = 16.0
        let sofaArmH = 26.0
        let sofaBackH = 32.0
        let sofa = SofaPlan(centerX: sofaCX,
                            width: sofaW,
                            depth: sofaD,
                            seatHeight: sofaSeatH,
                            backHeight: sofaBackH,
                            armHeight: sofaArmH,
                            legHeight: sofaLegH,
                            cushionCount: 3)
        
        // Side tables flanking the sofa with a 4in gap
        let stW = 18.0
        let stD = 18.0
        let stH = 24.0
        let stGap = 4.0
        let leftST = SideTablePlan(centerX: sofaCX - sofaW / 2 - stGap - stW / 2,
                                   width: stW,
                                   depth: stD,
                                   height: stH)
        let rightST = SideTablePlan(centerX: sofaCX + sofaW / 2 + stGap + stW / 2,
                                    width: stW,
                                    depth: stD,
                                    height: stH)
        
        // Coffee table centered in front of the sofa
        let ctD = 42.0
        let ctH = 18.0
        let ctCZ = sofaD + 8.0 + ctD / 2   // 8" gap between sofa front and coffee table
        let coffee = CoffeeTablePlan(centerX: sofaCX,
                                     centerZ: ctCZ,
                                     diameter: ctD,
                                     height: ctH)
        
        // Table lamps
        func lamp(on table: SideTablePlan) -> LampPlan {
            return LampPlan(centerX: table.centerX,
                            sitOnTopOfHeight: table.height,
                            baseDiameter: 6.0,
                            baseHeight: 8.0,
                            shadeTopDiameter: 8.0,
                            shadeBottomDiameter: 11.0,
                            shadeHeight: 8.0)
        }
        let leftLamp = lamp(on: leftST)
        let rightLamp = lamp(on: rightST)
        
        // Rug under coffee table, centered on sofa, wider than sofa
        let rug = RugPlan(centerX: sofaCX,
                          width: max(sofaW + 24.0, ctD + 30.0),
                          depth: sofaD + ctD + 24.0)
        
        return WallFurniturePlan(sofa: sofa,
                                 leftSideTable: leftST,
                                 rightSideTable: rightST,
                                 coffeeTable: coffee,
                                 leftLamp: leftLamp,
                                 rightLamp: rightLamp,
                                 blinds: blinds,
                                 curtainRods: rods,
                                 curtainPanels: panels,
                                 rug: rug)
    }
}

// MARK: - Furniture scene builder

enum WallFurnitureSceneBuilder {
    static let metersPerInch: Double = 0.0254
    static func m(_ inches: Double) -> Float { Float(inches * metersPerInch) }
    
    // Materials
    static func linenCream() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1),
                          texture: nil)
        mat.roughness = 0.85
        mat.metallic = 0.0
        return mat
    }
    static func linenCushion() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.87, green: 0.82, blue: 0.72, alpha: 1),
                          texture: nil)
        mat.roughness = 0.90
        mat.metallic = 0.0
        return mat
    }
    static func linenIvory() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.94, green: 0.90, blue: 0.82, alpha: 1),
                          texture: nil)
        mat.roughness = 0.95
        mat.metallic = 0.0
        return mat
    }
    static func warmOak() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.60, green: 0.44, blue: 0.28, alpha: 1),
                          texture: nil)
        mat.roughness = 0.70
        mat.metallic = 0.0
        return mat
    }
    static func rattanBase() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.66, green: 0.50, blue: 0.32, alpha: 1),
                          texture: nil)
        mat.roughness = 0.80
        mat.metallic = 0.0
        return mat
    }
    static func lampShade() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.95, green: 0.92, blue: 0.82, alpha: 1),
                          texture: nil)
        mat.roughness = 0.80
        mat.metallic = 0.0
        return mat
    }
    static func lampGlow() -> UnlitMaterial {
        var mat = UnlitMaterial()
        mat.color = .init(tint: UIColor(red: 1.0, green: 0.92, blue: 0.78, alpha: 1),
                          texture: nil)
        return mat
    }
    static func ironBlack() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1),
                          texture: nil)
        mat.roughness = 0.35
        mat.metallic = 0.90
        return mat
    }
    static func rugWool() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.87, green: 0.82, blue: 0.72, alpha: 1),
                          texture: nil)
        mat.roughness = 1.0
        mat.metallic = 0.0
        return mat
    }
    
    // MARK: Build entities and add to root
    
    static func add(plan: WallFurniturePlan, to root: Entity, wallWidth: Double) {
        // The wall's coordinate system in InteriorAuthorityRealityView:
        //   x is along the wall (centered at 0),
        //   y is up from the floor,
        //   z is out from the wall (positive is toward the viewer).
        // We convert plan coords (wall-local from left edge) to wall-centered X.
        
        func wx(_ planX: Double) -> Double {
            // planX is measured from wall left edge (0 to wallWidth)
            return planX - wallWidth / 2
        }
        
        // Rug (draw first so it sits under everything)
        if let rug = plan.rug {
            let mesh = MeshResource.generateBox(width: m(rug.width),
                                                height: m(0.4),
                                                depth: m(rug.depth))
            let rugEntity = ModelEntity(mesh: mesh, materials: [rugWool()])
            // Center under the sofa area; centerZ is midway between sofa and viewer
            let centerZ = (plan.sofa?.depth ?? 36) / 2 + 8.0 + (rug.depth / 2 - 20)
            rugEntity.position = SIMD3<Float>(
                m(wx(rug.centerX)),
                m(0.2),
                m(centerZ)
            )
            root.addChild(rugEntity)
        }
        
        // Sofa
        if let s = plan.sofa {
            let sofaCX = wx(s.centerX)
            // Sofa sits with back nearly against the wall (small gap of 2" for return clearance)
            let sofaBackZ = 6.0                // back face 6" from wall face
            let sofaFrontZ = sofaBackZ + s.depth
            let sofaCZ = (sofaBackZ + sofaFrontZ) / 2
            
            // Base seat block (from leg top to seat top)
            let baseMesh = MeshResource.generateBox(
                width: m(s.width),
                height: m(s.seatHeight - s.legHeight),
                depth: m(s.depth)
            )
            let base = ModelEntity(mesh: baseMesh, materials: [linenCream()])
            base.position = SIMD3<Float>(
                m(sofaCX),
                m((s.legHeight + s.seatHeight) / 2),
                m(sofaCZ)
            )
            root.addChild(base)
            
            // Seat cushions (visible above base)
            let cushionH = 4.0
            let cushionD = s.depth - 6.0
            let cushionW = (s.width - 6.0) / Double(s.cushionCount)
            for i in 0..<s.cushionCount {
                let cushX = -s.width / 2 + 3.0 + (Double(i) + 0.5) * cushionW
                let mesh = MeshResource.generateBox(
                    width: m(cushionW - 0.5),
                    height: m(cushionH),
                    depth: m(cushionD)
                )
                let c = ModelEntity(mesh: mesh, materials: [linenCushion()])
                c.position = SIMD3<Float>(
                    m(sofaCX + cushX),
                    m(s.seatHeight + cushionH / 2),
                    m(sofaCZ - 1.0)
                )
                root.addChild(c)
            }
            
            // Back (from arm height to back height, along the back edge)
            let backMesh = MeshResource.generateBox(
                width: m(s.width),
                height: m(s.backHeight - s.seatHeight),
                depth: m(6.0)
            )
            let back = ModelEntity(mesh: backMesh, materials: [linenCream()])
            back.position = SIMD3<Float>(
                m(sofaCX),
                m((s.seatHeight + s.backHeight) / 2),
                m(sofaBackZ + 3.0)
            )
            root.addChild(back)
            
            // Back cushions
            for i in 0..<s.cushionCount {
                let cushX = -s.width / 2 + 3.0 + (Double(i) + 0.5) * cushionW
                let mesh = MeshResource.generateBox(
                    width: m(cushionW - 0.5),
                    height: m(s.backHeight - s.seatHeight - 4.0),
                    depth: m(4.0)
                )
                let c = ModelEntity(mesh: mesh, materials: [linenCushion()])
                c.position = SIMD3<Float>(
                    m(sofaCX + cushX),
                    m(s.seatHeight + (s.backHeight - s.seatHeight) / 2),
                    m(sofaBackZ + 7.0)
                )
                root.addChild(c)
            }
            
            // Arms (left and right)
            for side in [-1.0, 1.0] {
                let armMesh = MeshResource.generateBox(
                    width: m(4.0),
                    height: m(s.armHeight - s.legHeight),
                    depth: m(s.depth)
                )
                let arm = ModelEntity(mesh: armMesh, materials: [linenCream()])
                arm.position = SIMD3<Float>(
                    m(sofaCX + side * (s.width / 2 - 2)),
                    m((s.legHeight + s.armHeight) / 2),
                    m(sofaCZ)
                )
                root.addChild(arm)
            }
            
            // Four tapered legs
            let legPositions: [(Double, Double)] = [
                (-s.width / 2 + 2, -s.depth / 2 + 2),
                ( s.width / 2 - 2, -s.depth / 2 + 2),
                (-s.width / 2 + 2,  s.depth / 2 - 2),
                ( s.width / 2 - 2,  s.depth / 2 - 2)
            ]
            for (lx, lz) in legPositions {
                let legMesh = MeshResource.generateBox(
                    width: m(1.5),
                    height: m(s.legHeight),
                    depth: m(1.5)
                )
                let leg = ModelEntity(mesh: legMesh, materials: [warmOak()])
                leg.position = SIMD3<Float>(
                    m(sofaCX + lx),
                    m(s.legHeight / 2),
                    m(sofaCZ + lz)
                )
                root.addChild(leg)
            }
        }
        
        // Side tables
        func drawSideTable(_ st: WallFurniturePlan.SideTablePlan) {
            // Drum-style pedestal: single cylinder from floor to top
            let mesh = MeshResource.generateCylinder(
                height: m(st.height),
                radius: m(st.width / 2)
            )
            let table = ModelEntity(mesh: mesh, materials: [warmOak()])
            let stCX = wx(st.centerX)
            // Position: aligned with sofa depth center in Z
            let sofaBackZ = 6.0
            let sofaFrontZ = sofaBackZ + (plan.sofa?.depth ?? 36)
            let sofaCZ = (sofaBackZ + sofaFrontZ) / 2
            table.position = SIMD3<Float>(
                m(stCX),
                m(st.height / 2),
                m(sofaCZ)
            )
            root.addChild(table)
        }
        if let lst = plan.leftSideTable { drawSideTable(lst) }
        if let rst = plan.rightSideTable { drawSideTable(rst) }
        
        // Coffee table
        if let ct = plan.coffeeTable {
            // Round table top
            let topMesh = MeshResource.generateCylinder(
                height: m(2.0),
                radius: m(ct.diameter / 2)
            )
            let top = ModelEntity(mesh: topMesh, materials: [warmOak()])
            top.position = SIMD3<Float>(
                m(wx(ct.centerX)),
                m(ct.height - 1.0),
                m(ct.centerZ)
            )
            root.addChild(top)
            
            // Two rectangular pedestals
            for side in [-1.0, 1.0] {
                let pMesh = MeshResource.generateBox(
                    width: m(6.0),
                    height: m(ct.height - 2.0),
                    depth: m(10.0)
                )
                let ped = ModelEntity(mesh: pMesh, materials: [warmOak()])
                ped.position = SIMD3<Float>(
                    m(wx(ct.centerX) + side * 5.0),
                    m((ct.height - 2.0) / 2),
                    m(ct.centerZ)
                )
                root.addChild(ped)
            }
        }
        
        // Lamps
        func drawLamp(_ lamp: WallFurniturePlan.LampPlan, sofaCZ: Double) {
            let cx = wx(lamp.centerX)
            // Rattan base: sphere-ish (use cylinder for simplicity)
            let baseMesh = MeshResource.generateCylinder(
                height: m(lamp.baseHeight),
                radius: m(lamp.baseDiameter / 2)
            )
            let base = ModelEntity(mesh: baseMesh, materials: [rattanBase()])
            base.position = SIMD3<Float>(
                m(cx),
                m(lamp.sitOnTopOfHeight + lamp.baseHeight / 2),
                m(sofaCZ)
            )
            root.addChild(base)
            
            // Neck
            let neckMesh = MeshResource.generateCylinder(
                height: m(3.0),
                radius: m(0.4)
            )
            let neck = ModelEntity(mesh: neckMesh, materials: [ironBlack()])
            neck.position = SIMD3<Float>(
                m(cx),
                m(lamp.sitOnTopOfHeight + lamp.baseHeight + 1.5),
                m(sofaCZ)
            )
            root.addChild(neck)
            
            // Shade (trapezoid approximated as a cylinder tapering isn't native;
            // use a single cylinder with average diameter for a first pass).
            let avgRadius = (lamp.shadeTopDiameter + lamp.shadeBottomDiameter) / 4
            let shadeMesh = MeshResource.generateCylinder(
                height: m(lamp.shadeHeight),
                radius: m(avgRadius)
            )
            let shade = ModelEntity(mesh: shadeMesh, materials: [lampShade()])
            shade.position = SIMD3<Float>(
                m(cx),
                m(lamp.sitOnTopOfHeight + lamp.baseHeight + 3.0 + lamp.shadeHeight / 2),
                m(sofaCZ)
            )
            root.addChild(shade)
            
            // Warm glow at the bottom of the shade
            let glowMesh = MeshResource.generateSphere(radius: m(1.0))
            let glow = ModelEntity(mesh: glowMesh, materials: [lampGlow()])
            glow.position = SIMD3<Float>(
                m(cx),
                m(lamp.sitOnTopOfHeight + lamp.baseHeight + 3.0),
                m(sofaCZ)
            )
            root.addChild(glow)
        }
        let sofaCZ = 6.0 + (plan.sofa?.depth ?? 36) / 2
        if let lamp = plan.leftLamp { drawLamp(lamp, sofaCZ: sofaCZ) }
        if let lamp = plan.rightLamp { drawLamp(lamp, sofaCZ: sofaCZ) }
        
        // Roman blinds
        for b in plan.blinds {
            let w = b.xRight - b.xLeft
            let h = b.yTop - b.yBottom
            let mesh = MeshResource.generateBox(
                width: m(w),
                height: m(h),
                depth: m(0.75)
            )
            let blind = ModelEntity(mesh: mesh, materials: [linenCream()])
            let cx = (b.xLeft + b.xRight) / 2
            let cy = (b.yTop + b.yBottom) / 2
            blind.position = SIMD3<Float>(
                m(wx(cx)),
                m(cy),
                m(b.mountDepth)
            )
            root.addChild(blind)
        }
        
        // Curtain rod
        for rod in plan.curtainRods {
            let length = rod.xRight - rod.xLeft
            let mesh = MeshResource.generateCylinder(
                height: m(length),
                radius: m(rod.diameter / 2)
            )
            let entity = ModelEntity(mesh: mesh, materials: [ironBlack()])
            let cx = (rod.xLeft + rod.xRight) / 2
            entity.position = SIMD3<Float>(
                m(wx(cx)),
                m(rod.y),
                m(rod.mountDepth)
            )
            // Rotate 90 degrees to lie horizontal along X
            entity.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
            root.addChild(entity)
            
            // Finials
            for finialX in [rod.xLeft, rod.xRight] {
                let fMesh = MeshResource.generateSphere(radius: m(rod.diameter))
                let fin = ModelEntity(mesh: fMesh, materials: [ironBlack()])
                fin.position = SIMD3<Float>(
                    m(wx(finialX)),
                    m(rod.y),
                    m(rod.mountDepth)
                )
                root.addChild(fin)
            }
        }
        
        // Curtain panels
        for panel in plan.curtainPanels {
            let h = panel.topY - panel.bottomY
            let mesh = MeshResource.generateBox(
                width: m(panel.width),
                height: m(h),
                depth: m(1.0)
            )
            let entity = ModelEntity(mesh: mesh, materials: [linenIvory()])
            let cy = (panel.topY + panel.bottomY) / 2
            entity.position = SIMD3<Float>(
                m(wx(panel.centerX)),
                m(cy),
                m(panel.mountDepth)
            )
            root.addChild(entity)
        }
    }
}

// MARK: - Wall + Furniture combined preview view

struct WallFurnitureRealityPreview: View {
    let wall: LockedWall
    let defaults: RoomDefaults
    
    @State private var showFurniture: Bool = true
    @State private var faceOnTrigger: Int = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $showFurniture) {
                    Text("Furniture")
                }
                .toggleStyle(.switch)
                Spacer()
                Button {
                    faceOnTrigger &+= 1
                } label: {
                    Label("Face On", systemImage: "square.on.square")
                        .font(.callout)
                }
            }
            .padding(.horizontal, 4)
            
            RealityView { content in
                // Build the wall scene (structural)
                let scene = WallSceneBuilder.build(wall: wall, defaults: defaults)
                scene.root.name = "wallRoot"
                scene.cameraAnchor.name = "cameraAnchor"
                content.add(scene.root)
                content.add(scene.cameraAnchor)
                content.add(scene.lightingAnchor)
                
                // Add furniture layer under a named container
                let furnitureContainer = Entity()
                furnitureContainer.name = "furnitureContainer"
                scene.root.addChild(furnitureContainer)
                if showFurniture {
                    let plan = WallFurniturePlan.derive(from: wall, defaults: defaults)
                    WallFurnitureSceneBuilder.add(plan: plan,
                                                  to: furnitureContainer,
                                                  wallWidth: wall.totalWidth)
                }
                
                // Face-on camera
                positionCamera(scene.cameraAnchor, for: wall)
            } update: { content in
                // Toggle furniture visibility by clearing and rebuilding the
                // furniture container. Wall structure and camera stay put.
                if let root = content.entities.first(where: { $0.name == "wallRoot" }),
                   let container = root.children.first(where: { $0.name == "furnitureContainer" }) {
                    container.children.removeAll()
                    if showFurniture {
                        let plan = WallFurniturePlan.derive(from: wall, defaults: defaults)
                        WallFurnitureSceneBuilder.add(plan: plan,
                                                      to: container,
                                                      wallWidth: wall.totalWidth)
                    }
                }
                if let camAnchor = content.entities.first(where: { $0.name == "cameraAnchor" }) {
                    positionCamera(camAnchor, for: wall)
                }
                _ = faceOnTrigger
            }
        }
        .padding()
    }
    
    private func positionCamera(_ anchor: Entity, for wall: LockedWall) {
        // Face-on: camera on wall centerline, at seated eye level,
        // pulled back proportional to wall width so the whole wall fits.
        let wallW = wall.totalWidth
        let eyeInches: Double = 60          // 5 ft seated eye level
        // Distance = wallW / (2 * tan(halfFov)) with 50 degree FoV
        let halfFov = 25.0 * .pi / 180
        let distanceInches = (wallW / 2) / tan(halfFov) + 12
        let m = WallFurnitureSceneBuilder.m
        anchor.position = SIMD3<Float>(
            0,
            m(eyeInches),
            m(distanceInches)
        )
        let target = SIMD3<Float>(0, m(eyeInches), 0)
        anchor.look(at: target, from: anchor.position, relativeTo: nil)
    }
}
