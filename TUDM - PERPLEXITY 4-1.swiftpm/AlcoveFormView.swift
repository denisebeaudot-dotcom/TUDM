// ============================================================
// DENISEBEAUDOT — BUILD MARKER — alcove bump-out + point C
// 2026-08-03 18:27 EDT   branch: alcove-bumpout-point-c
// If you cannot see this line at the very top, this file did
// not load or the paste was truncated.
// ============================================================

import SwiftUI

// MARK: - AlcoveDraft
//
// Working copy of a RoomAlcove used by the editor form. Mirrors the
// BeamDraft / WallDraft pattern: the draft holds every field the form
// touches, and `toAlcove(existingID:)` turns it back into a real
// RoomAlcove when Save is tapped.

struct AlcoveDraft: Hashable {
    var name: String = ""
    var notes: String = ""
    
    // Anchor
    var wallAID: UUID? = nil
    var wallBID: UUID? = nil
    var footprintA: Double = 0
    var footprintB: Double = 0
    var anchorAEnd: AlcoveCornerAnchor.WallEnd = .corner
    var anchorBEnd: AlcoveCornerAnchor.WallEnd = .corner
    
    // Plan points — back wall C (Step 7c).
    // When `backWallCIsAuto` is true the alcove stores nil for C and every
    // renderer falls back to the short leg, which is the plain rectangle.
    // Turning the toggle off promotes C to authored, measured geometry.
    var backWallCIsAuto: Bool = true
    var backWallC: Double = 0
    
    /// Recess into the room, or bump-out tacked onto the far side of a wall.
    var projection: AlcoveProjection = .inward
    
    /// Distance along the host wall from the anchor end to the start of the
    /// opening. Zero keeps the alcove in the corner.
    var openingOffset: Double = 0
    
    // Platform
    var platformHeight: Double = 12
    var platformShape: PlatformShape = .flatRectangular
    var platformMaterial: AlcoveMaterial = .redBrick
    
    // Columns
    var columnALabel: String = "Column A"
    var columnAWidth: Double = 8
    var columnADepth: Double = 9.25
    var columnAHeight: Double = 84
    var columnAMaterial: AlcoveMaterial = .redBrick
    var columnANotes: String = ""
    
    var columnBLabel: String = "Column B"
    var columnBWidth: Double = 8
    var columnBDepth: Double = 9.25
    var columnBHeight: Double = 84
    var columnBMaterial: AlcoveMaterial = .redBrick
    var columnBNotes: String = ""
    
    // Back element
    var backStyle: BackElementStyle = .concaveCurved
    var backHeight: Double = 84
    var backMaterial: AlcoveMaterial = .feedBrick
    var backNotes: String = ""
    
    // Payload
    var payloadKind: PayloadKind = .empty
    var wsModelName: String = ""
    var wsManufacturer: String = ""
    var wsStoveWidth: Double = 24
    var wsStoveDepth: Double = 22
    var wsStoveHeight: Double = 32
    var wsFlueDiameter: Double = 6
    var wsClearanceRating: String = ""
    var wsHearthExtension: Double = 16
    var wsNotes: String = ""
    
    // Lock
    var isLocked: Bool = false
    
    enum PayloadKind: String, CaseIterable, Hashable {
        case empty = "Empty"
        case woodStove = "Wood Stove"
    }
    
    init() {}
    
    init(alcove: RoomAlcove) {
        self.name = alcove.name
        self.notes = alcove.notes
        
        self.wallAID = alcove.anchor.wallA
        self.wallBID = alcove.anchor.wallB
        self.footprintA = alcove.anchor.footprintA
        self.footprintB = alcove.anchor.footprintB
        self.anchorAEnd = alcove.anchor.anchorA
        self.anchorBEnd = alcove.anchor.anchorB
        
        self.projection = alcove.anchor.projection
        self.openingOffset = alcove.anchor.openingOffset
        
        if let c = alcove.anchor.backWallC, c > 0 {
            self.backWallCIsAuto = false
            self.backWallC = c
        } else {
            self.backWallCIsAuto = true
            self.backWallC = max(alcove.anchor.footprintA, alcove.anchor.footprintB)
        }
        
        self.platformHeight = alcove.platform.height
        self.platformShape = alcove.platform.shape
        self.platformMaterial = alcove.platform.material
        
        self.columnALabel = alcove.columnA.label
        self.columnAWidth = alcove.columnA.width
        self.columnADepth = alcove.columnA.depth
        self.columnAHeight = alcove.columnA.height
        self.columnAMaterial = alcove.columnA.material
        self.columnANotes = alcove.columnA.notes
        
        self.columnBLabel = alcove.columnB.label
        self.columnBWidth = alcove.columnB.width
        self.columnBDepth = alcove.columnB.depth
        self.columnBHeight = alcove.columnB.height
        self.columnBMaterial = alcove.columnB.material
        self.columnBNotes = alcove.columnB.notes
        
        self.backStyle = alcove.back.style
        self.backHeight = alcove.back.height
        self.backMaterial = alcove.back.material
        self.backNotes = alcove.back.notes
        
        switch alcove.payload {
        case .empty:
            self.payloadKind = .empty
        case .woodStove(let spec):
            self.payloadKind = .woodStove
            self.wsModelName = spec.modelName
            self.wsManufacturer = spec.manufacturer
            self.wsStoveWidth = spec.stoveWidth
            self.wsStoveDepth = spec.stoveDepth
            self.wsStoveHeight = spec.stoveHeight
            self.wsFlueDiameter = spec.flueDiameter
            self.wsClearanceRating = spec.clearanceRating
            self.wsHearthExtension = spec.hearthExtension
            self.wsNotes = spec.notes
        }
        
        self.isLocked = alcove.isLocked
    }
    
    // MARK: Derived plan geometry
    
    /// C reads against the OPENING, so the long leg is the reference: C equal
    /// to the long leg squares point D off into a plain rectangle.
    var shortLegLength: Double { min(footprintA, footprintB) }
    var longLegLength: Double { max(footprintA, footprintB) }
    
    /// The C actually used for drawing, honouring the auto toggle.
    var resolvedBackWallC: Double {
        backWallCIsAuto ? longLegLength : backWallC
    }
    
    /// Live footprint preview for the form readout. Wall identity does not
    /// affect plan geometry, so placeholder ids are fine here — this value is
    /// never persisted.
    var planFootprintPreview: AlcovePlanFootprint? {
        guard footprintA > 0, footprintB > 0 else { return nil }
        let probe = AlcoveCornerAnchor(
            wallA: wallAID ?? UUID(),
            footprintA: footprintA,
            wallB: wallBID ?? UUID(),
            footprintB: footprintB,
            backWallC: backWallCIsAuto ? nil : backWallC,
            projection: projection,
            openingOffset: openingOffset,
            anchorA: anchorAEnd,
            anchorB: anchorBEnd
        )
        return probe.planFootprint
    }
    
    var isValid: Bool {
        // Both walls must be selected and distinct.
        guard let a = wallAID, let b = wallBID else { return false }
        if a == b { return false }
        // Footprints must be positive.
        if footprintA <= 0 || footprintB <= 0 { return false }
        // A declared back wall must be positive. It is allowed to exceed the
        // long leg — that is a back-widening recess, which is buildable and
        // only warrants a warning, not a block.
        if !backWallCIsAuto {
            if backWallC <= 0 { return false }
        }
        // Positive dimensions.
        if platformHeight < 0 { return false }
        if columnAWidth <= 0 || columnADepth <= 0 || columnAHeight <= 0 { return false }
        if columnBWidth <= 0 || columnBDepth <= 0 || columnBHeight <= 0 { return false }
        if backHeight <= 0 { return false }
        return true
    }
    
    func toAlcove(existingID: UUID? = nil) -> RoomAlcove? {
        guard let wallA = wallAID, let wallB = wallBID else { return nil }
        
        let anchor = AlcoveCornerAnchor(
            wallA: wallA,
            footprintA: footprintA,
            wallB: wallB,
            footprintB: footprintB,
            backWallC: backWallCIsAuto ? nil : backWallC,
            projection: projection,
            openingOffset: openingOffset,
            anchorA: anchorAEnd,
            anchorB: anchorBEnd
        )
        
        let platform = AlcovePlatform(
            height: platformHeight,
            shape: platformShape,
            material: platformMaterial
        )
        
        let colA = AlcoveColumnSpec(
            label: columnALabel,
            width: columnAWidth,
            depth: columnADepth,
            height: columnAHeight,
            material: columnAMaterial,
            notes: columnANotes
        )
        
        let colB = AlcoveColumnSpec(
            label: columnBLabel,
            width: columnBWidth,
            depth: columnBDepth,
            height: columnBHeight,
            material: columnBMaterial,
            notes: columnBNotes
        )
        
        let back = AlcoveBackSpec(
            style: backStyle,
            height: backHeight,
            material: backMaterial,
            notes: backNotes
        )
        
        let payload: AlcovePayload
        switch payloadKind {
        case .empty:
            payload = .empty
        case .woodStove:
            let spec = WoodStoveSpec(
                modelName: wsModelName,
                manufacturer: wsManufacturer,
                stoveWidth: wsStoveWidth,
                stoveDepth: wsStoveDepth,
                stoveHeight: wsStoveHeight,
                flueDiameter: wsFlueDiameter,
                clearanceRating: wsClearanceRating,
                hearthExtension: wsHearthExtension,
                notes: wsNotes
            )
            payload = .woodStove(spec)
        }
        
        return RoomAlcove(
            id: existingID ?? UUID(),
            name: name,
            notes: notes,
            anchor: anchor,
            platform: platform,
            columnA: colA,
            columnB: colB,
            back: back,
            payload: payload,
            isLocked: isLocked
        )
    }
}

// MARK: - AlcoveFormView

struct AlcoveFormView: View {
    enum Mode {
        case create
        case edit(RoomAlcove)
        
        var title: String {
            switch self {
            case .create: return "New Alcove"
            case .edit: return "Edit Alcove"
            }
        }
        
        var existingID: UUID? {
            switch self {
            case .create: return nil
            case .edit(let a): return a.id
            }
        }
        
        var wasLockedAtOpen: Bool {
            switch self {
            case .create: return false
            case .edit(let a): return a.isLocked
            }
        }
    }
    
    let mode: Mode
    let availableWalls: [WallSpec]
    let onSave: (RoomAlcove) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AlcoveDraft
    
    init(mode: Mode, availableWalls: [WallSpec], onSave: @escaping (RoomAlcove) -> Void) {
        self.mode = mode
        self.availableWalls = availableWalls
        self.onSave = onSave
        
        switch mode {
        case .create:
            _draft = State(initialValue: AlcoveDraft())
        case .edit(let alcove):
            _draft = State(initialValue: AlcoveDraft(alcove: alcove))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alcove") {
                    TextField("Name (e.g. Wood Stove Corner)", text: $draft.name)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...4)
                    Toggle("Locked", isOn: $draft.isLocked)
                }
                
                Section {
                    if availableWalls.count < 2 {
                        Text("Add at least two walls to this room before creating a corner alcove.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Wall A", selection: $draft.wallAID) {
                            Text("Select wall").tag(UUID?.none)
                            ForEach(availableWalls) { wall in
                                Text(wallDisplayName(wall)).tag(UUID?.some(wall.id))
                            }
                        }
                        
                        Picker("Wall A End", selection: $draft.anchorAEnd) {
                            Text("Origin (station 0)").tag(AlcoveCornerAnchor.WallEnd.origin)
                            Text("Corner (far end)").tag(AlcoveCornerAnchor.WallEnd.corner)
                        }
                        .pickerStyle(.segmented)
                        
                        StepperFieldRow(title: "Footprint on Wall A", value: $draft.footprintA, step: 0.25)
                        
                        Picker("Wall B", selection: $draft.wallBID) {
                            Text("Select wall").tag(UUID?.none)
                            ForEach(availableWalls) { wall in
                                Text(wallDisplayName(wall)).tag(UUID?.some(wall.id))
                            }
                        }
                        
                        Picker("Wall B End", selection: $draft.anchorBEnd) {
                            Text("Origin (station 0)").tag(AlcoveCornerAnchor.WallEnd.origin)
                            Text("Corner (far end)").tag(AlcoveCornerAnchor.WallEnd.corner)
                        }
                        .pickerStyle(.segmented)
                        
                        StepperFieldRow(title: "Footprint on Wall B", value: $draft.footprintB, step: 0.25)
                        
                        if let footprintIssue = footprintIssueText {
                            Text(footprintIssue)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Anchor")
                } footer: {
                    Text("Corner alcoves span two walls at their shared corner. Footprint is measured from the anchor end along each wall.")
                }
                
                Section {
                    Picker("Projection", selection: $draft.projection) {
                        ForEach(AlcoveProjection.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    
                    if draft.projection.isBumpOut {
                        StepperFieldRow(
                            title: "Offset along host wall",
                            value: $draft.openingOffset,
                            step: 1
                        )
                    }
                    
                    Toggle("Derive C from long leg", isOn: $draft.backWallCIsAuto)
                    
                    if !draft.backWallCIsAuto {
                        StepperFieldRow(title: "Back Wall C", value: $draft.backWallC, step: 0.25)
                        
                        if let issue = backWallIssueText {
                            Text(issue)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    planPointsReadout
                } header: {
                    Text("Plan Points \u{2014} A / B / C")
                } footer: {
                    Text("Projection sets which side of the walls the body sits on. A recess eats into the room; a bump-out is tacked onto the far side of the host wall, adds floor area, and removes that wall's segment across the opening \u{2014} the room outline becomes an L.\n\nC is the back wall. It starts at the endpoint of the shorter leg and runs parallel to the longer leg's wall, so C reads against the opening. Its far end is the derived point D, which closes back onto the longer leg. The footprint is O \u{2192} A \u{2192} D \u{2192} B.\n\nOffset slides a bump-out along its host wall; zero keeps it in the corner. For a bump-out the Back Element style shapes the outside envelope \u{2014} Flat gives a square box, Convex a bow, Mitered a canted bay. For a recess it stays a feature drawn inside the footprint, unchanged.")
                }
                
                Section("Platform") {
                    StepperFieldRow(title: "Height", value: $draft.platformHeight, step: 1)
                    Picker("Shape", selection: $draft.platformShape) {
                        ForEach(PlatformShape.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    Picker("Material", selection: $draft.platformMaterial) {
                        ForEach(AlcoveMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                }
                
                Section("Column A") {
                    TextField("Label", text: $draft.columnALabel)
                    StepperFieldRow(title: "Width", value: $draft.columnAWidth, step: 0.25)
                    StepperFieldRow(title: "Depth", value: $draft.columnADepth, step: 0.25)
                    StepperFieldRow(title: "Height", value: $draft.columnAHeight, step: 1)
                    Picker("Material", selection: $draft.columnAMaterial) {
                        ForEach(AlcoveMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    TextField("Notes", text: $draft.columnANotes, axis: .vertical)
                        .lineLimit(1...3)
                }
                
                Section("Column B") {
                    TextField("Label", text: $draft.columnBLabel)
                    StepperFieldRow(title: "Width", value: $draft.columnBWidth, step: 0.25)
                    StepperFieldRow(title: "Depth", value: $draft.columnBDepth, step: 0.25)
                    StepperFieldRow(title: "Height", value: $draft.columnBHeight, step: 1)
                    Picker("Material", selection: $draft.columnBMaterial) {
                        ForEach(AlcoveMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    TextField("Notes", text: $draft.columnBNotes, axis: .vertical)
                        .lineLimit(1...3)
                }
                
                Section {
                    Picker("Style", selection: $draft.backStyle) {
                        ForEach(BackElementStyle.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    StepperFieldRow(title: "Height", value: $draft.backHeight, step: 1)
                    Picker("Material", selection: $draft.backMaterial) {
                        ForEach(AlcoveMaterial.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    TextField("Notes", text: $draft.backNotes, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Text("Back Element")
                } footer: {
                    Text("The back surface between the two flanking columns. In v1 only Concave Curved is rendered; the other styles are stored but not painted yet.")
                }
                
                Section("Payload") {
                    Picker("Payload", selection: $draft.payloadKind) {
                        ForEach(AlcoveDraft.PayloadKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if draft.payloadKind == .woodStove {
                    Section("Wood Stove") {
                        TextField("Manufacturer", text: $draft.wsManufacturer)
                        TextField("Model", text: $draft.wsModelName)
                        StepperFieldRow(title: "Stove Width", value: $draft.wsStoveWidth, step: 0.5)
                        StepperFieldRow(title: "Stove Depth", value: $draft.wsStoveDepth, step: 0.5)
                        StepperFieldRow(title: "Stove Height", value: $draft.wsStoveHeight, step: 0.5)
                        StepperFieldRow(title: "Flue Diameter", value: $draft.wsFlueDiameter, step: 0.5)
                        StepperFieldRow(title: "Hearth Extension", value: $draft.wsHearthExtension, step: 0.5)
                        TextField("Clearance Rating", text: $draft.wsClearanceRating)
                        TextField("Notes", text: $draft.wsNotes, axis: .vertical)
                            .lineLimit(1...4)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        if let alcove = draft.toAlcove(existingID: mode.existingID) {
                            onSave(alcove)
                            dismiss()
                        }
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }
    
    // MARK: Plan points readout
    
    /// Live derived geometry. Everything here recomputes from the two legs plus
    /// C, so the user can see D move before committing anything to the model.
    @ViewBuilder
    private var planPointsReadout: some View {
        if let fp = draft.planFootprintPreview {
            VStack(alignment: .leading, spacing: 6) {
                pointRow("O", fp.pointO, note: "shared corner")
                pointRow("A", fp.pointA, note: "wall A leg")
                pointRow("B", fp.pointB, note: "wall B leg")
                pointRow("D", fp.pointD, note: "derived")
                
                Divider().padding(.vertical, 2)
                
                LabeledContent("Back wall C") {
                    Text("\(inches(fp.backWallC)) \u{00B7} from point \(fp.shortLegLabel)")
                        .monospacedDigit()
                }
                LabeledContent("Closing face") {
                    Text(inches(fp.closingFaceLength))
                        .monospacedDigit()
                }
                if !fp.isRectangular {
                    LabeledContent("Cant") {
                        Text(String(format: "%.1f\u{00B0}", fp.closingFaceCantDegrees))
                            .monospacedDigit()
                    }
                }
                LabeledContent(fp.projection.isBumpOut ? "Floor area added" : "Floor area removed") {
                    Text(String(format: "%.2f sq ft", fp.area / 144))
                        .monospacedDigit()
                }
                
                if fp.projection.isBumpOut {
                    LabeledContent("Back wall shape") {
                        Text(draft.backStyle.rawValue)
                    }
                    LabeledContent("Sits") {
                        Text(fp.isFloating
                             ? "Mid-wall, \(inches(fp.openingOffset)) from anchor"
                             : "At the shared corner")
                    }
                    LabeledContent("Wall removed") {
                        Text(inches(fp.removedWallWidth))
                            .monospacedDigit()
                    }
                    if let returns = fp.sideReturns {
                        LabeledContent("Side returns") {
                            Text("\(inches(returns.first)) + \(inches(returns.second))")
                                .monospacedDigit()
                        }
                    }
                }
                
                Text(planVerdict(fp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .font(.footnote)
        } else {
            Text("Enter both wall footprints to resolve the plan points.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Plain-language verdict on the resolved footprint shape.
    private func planVerdict(_ fp: AlcovePlanFootprint) -> String {
        if fp.isRectangular {
            return fp.projection.isBumpOut
                ? "Rectangular bump-out \u{2014} the room outline becomes an L."
                : "Rectangular recess \u{2014} D squares off against the long leg."
        }
        if fp.widensTowardBack {
            return "Recess widens toward the back \u{2014} C runs past point \(fp.longLegLabel)."
        }
        return "L / splayed footprint \u{2014} face D to \(fp.longLegLabel) cants."
    }
    
    private func pointRow(_ label: String, _ point: CGPoint, note: String) -> some View {
        LabeledContent(label) {
            Text("(\(inches(Double(point.x))), \(inches(Double(point.y))))  \(note)")
                .monospacedDigit()
        }
    }
    
    private func inches(_ value: Double) -> String {
        String(format: "%.2f\u{201D}", value)
    }
    
    /// Inline warning when a declared C cannot physically close. Save is
    /// blocked by `draft.isValid` in this case, unlike the footprint warnings
    /// which only advise.
    private var backWallIssueText: String? {
        guard !draft.backWallCIsAuto else { return nil }
        if draft.backWallC <= 0 {
            return "Back wall C must be greater than 0."
        }
        if draft.backWallC > draft.longLegLength + 0.01 {
            let over = draft.backWallC - draft.longLegLength
            return "Back wall C is \(inches(over)) wider than the opening (\(inches(draft.longLegLength))). The recess undercuts the wall it sits in."
        }
        return nil
    }
    
    private var saveButtonTitle: String {
        switch mode {
        case .create: return "Add"
        case .edit: return "Update"
        }
    }
    
    private func wallDisplayName(_ wall: WallSpec) -> String {
        let name = wall.name.trimmed.isEmpty ? "Untitled Wall" : wall.name
        return "\(name) · \(String(format: "%.2f", wall.totalWidth))in"
    }
    
    /// If both walls are selected and either footprint exceeds its wall's
    /// total width, surface a warning inline. Save is still allowed because
    /// AlcoveValidation will catch this in the room's overall validation
    /// pass — the inline note just gives the user immediate feedback.
    private var footprintIssueText: String? {
        guard
            let aID = draft.wallAID,
            let bID = draft.wallBID,
            let wallA = availableWalls.first(where: { $0.id == aID }),
            let wallB = availableWalls.first(where: { $0.id == bID })
        else { return nil }
        
        var messages: [String] = []
        if draft.footprintA > wallA.totalWidth + 0.01 {
            let over = draft.footprintA - wallA.totalWidth
            messages.append("Footprint A exceeds Wall A total width by \(String(format: "%.2f", over))in.")
        }
        if draft.footprintB > wallB.totalWidth + 0.01 {
            let over = draft.footprintB - wallB.totalWidth
            messages.append("Footprint B exceeds Wall B total width by \(String(format: "%.2f", over))in.")
        }
        if aID == bID {
            messages.append("Wall A and Wall B must reference different walls for a corner alcove.")
        }
        return messages.isEmpty ? nil : messages.joined(separator: " ")
    }
}
