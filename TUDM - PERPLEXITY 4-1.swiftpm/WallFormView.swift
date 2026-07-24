import SwiftUI

// UUID isn't Identifiable by default; wrap it so we can use .sheet(item:)
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct WallFormView: View {
    enum Mode {
        case create(projectID: UUID, roomID: UUID, roomDefaults: RoomDefaults)
        case edit(projectID: UUID, roomID: UUID, roomDefaults: RoomDefaults, wall: WallSpec)
        
        var title: String {
            switch self {
            case .create: return "New Wall"
            case .edit: return "Edit Wall"
            }
        }
        
        var roomDefaults: RoomDefaults {
            switch self {
            case .create(_, _, let defaults):
                return defaults
            case .edit(_, _, let defaults, _):
                return defaults
            }
        }
    }
    
    let mode: Mode
    let onSave: (WallDraft) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var draft: WallDraft
    @State private var chainInput: String
    @State private var verticalChainInput: String
    @State private var editingSegmentID: UUID?
    @State private var editMode: EditMode = .inactive
    @State private var insertingAfterIndex: Int?
    @State private var showingInsertPicker = false
    @State private var isLegendExpanded: Bool = true
    @State private var previewMode: WallPreviewMode = .ortho
    
    enum WallPreviewMode: String, CaseIterable, Identifiable {
        case ortho = "Ortho"
        case threeD = "3D"
        var id: String { rawValue }
    }
    
    private enum Field: Hashable {
        case wallName
        case ruleSet
        case notes
        case chain
        case verticalChain
    }
    
    init(mode: Mode, onSave: @escaping (WallDraft) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        switch mode {
        case .create(_, _, let roomDefaults):
            var newDraft = WallDraft()
            newDraft.overrides = roomDefaults
            _draft = State(initialValue: newDraft)
            _chainInput = State(initialValue: newDraft.chainString)
            _verticalChainInput = State(initialValue: newDraft.verticalChainString)
            
        case .edit(_, _, let roomDefaults, let wall):
            let seededDraft = WallDraft(wall: wall, roomDefaults: roomDefaults)
            _draft = State(initialValue: seededDraft)
            _chainInput = State(initialValue: seededDraft.chainString)
            _verticalChainInput = State(initialValue: seededDraft.verticalChainString)
        }
    }
    
    private var cleanedChainInput: String {
        chainInput
            .uppercased()
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    private var cleanedVerticalChainInput: String {
        verticalChainInput
            .uppercased()
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    // MARK: Chain input bindings with live shorthand expansion
    
    private var chainInputBinding: Binding<String> {
        Binding(
            get: { chainInput },
            set: { newValue in
                chainInput = ChainShorthand.normalize(newValue, axis: .horizontal)
            }
        )
    }
    
    private var verticalChainInputBinding: Binding<String> {
        Binding(
            get: { verticalChainInput },
            set: { newValue in
                verticalChainInput = ChainShorthand.normalize(newValue, axis: .vertical)
            }
        )
    }
    
    private enum ChainAxis {
        case chain
        case verticalChain
    }
    
    private func insertToken(_ token: String, into axis: ChainAxis) {
        switch axis {
        case .chain:
            if chainInput.isEmpty || chainInput.hasSuffix(" ") {
                chainInput += token
            } else {
                chainInput += " \(token)"
            }
        case .verticalChain:
            if verticalChainInput.isEmpty || verticalChainInput.hasSuffix(" ") {
                verticalChainInput += token
            } else {
                verticalChainInput += " \(token)"
            }
        }
    }
    
    private var hasSegments: Bool {
        !draft.resolvedSegments.isEmpty
    }
    
    private var segmentSum: Double {
        draft.resolvedSegments.reduce(0) { $0 + $1.resolvedWidth }
    }
    
    private var matchesWallWidth: Bool {
        abs(segmentSum - draft.totalWidth) < 0.01
    }
    
    private var effectiveDefaults: RoomDefaults {
        draft.usesOverrides ? draft.overrides : mode.roomDefaults
    }
    
    private var previewWall: WallSpec {
        WallSpec(
            name: draft.name.isEmpty ? "Preview Wall" : draft.name,
            totalWidth: draft.totalWidth,
            ruleSet: draft.ruleSet,
            notes: draft.notes,
            chainString: draft.chainString,
            verticalChainString: draft.verticalChainString,
            segments: draft.resolvedSegments,
            usesOverrides: draft.usesOverrides,
            overrides: draft.usesOverrides ? draft.overrides : nil
        )
    }
    
    private var elevationLayout: WallElevationLayout {
        WallElevationBuilder.build(
            wall: previewWall,
            defaults: effectiveDefaults,
            verticalChain: draft.verticalChainString
        )
    }
    
    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        draft.totalWidth > 0 &&
        hasSegments
    }
    
    private var isEditingExistingWall: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private let insertableKinds: [SegmentKind] = [
        .wallSpace,
        .wall,
        .column,
        .bookcase,
        .shelf,
        .windowUnit,
        .door,
        .opening,
        .beam,
        .baseboard,
        .crown,
        .casing,
        .trim,
        .returnZone
    ]
    
    // Beam Range AFF stored as "<bottom>" or "<bottom>-<top>" string.
    // Parse the bottom value out for stepper display; rewrite as bottom-(bottom+beamHeight) on set.
    private var beamRangeBottomBinding: Binding<Double> {
        Binding(
            get: {
                let raw = effectiveDefaults.beamRangeAFF
                let firstToken = raw
                    .split(whereSeparator: { $0 == "-" || $0 == " " || $0 == "\u{2013}" })
                    .first
                    .map(String.init) ?? ""
                let cleaned = firstToken
                    .replacingOccurrences(of: "\"", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return Double(cleaned) ?? 0
            },
            set: { newBottom in
                draft.usesOverrides = true
                let bottom = max(0, newBottom)
                let top = bottom + effectiveDefaults.beamHeight
                draft.overrides.beamRangeAFF = String(format: "%.2f-%.2f", bottom, top)
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("Wall Info") {
                    TextField("Wall Name", text: $draft.name)
                        .focused($focusedField, equals: .wallName)
                    
                    StepperFieldRow(title: "Total Width", value: $draft.totalWidth, step: 1)
                    
                    TextField("Rule Set", text: $draft.ruleSet)
                        .focused($focusedField, equals: .ruleSet)
                    
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(3...6)
                }
                
                Section("Structure (Defaults)") {
                    Toggle("Use Wall Override Defaults", isOn: $draft.usesOverrides)
                    
                    StepperFieldRow(title: "Ceiling Height", value: overrideBinding(\.ceilingHeight), step: 1)
                    StepperFieldRow(title: "Crown Height", value: overrideBinding(\.crownHeight), step: 0.5)
                    StepperFieldRow(title: "Baseboard Height", value: overrideBinding(\.baseboardHeight), step: 0.5)
                    StepperFieldRow(title: "Beam Height", value: overrideBinding(\.beamHeight), step: 1)
                    
                    StepperFieldRow(title: "Beam Bottom AFF", value: beamRangeBottomBinding, step: 1)
                    
                    LabeledContent("Beam Range AFF", value: effectiveDefaults.beamRangeAFF.isEmpty ? "—" : effectiveDefaults.beamRangeAFF)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    StepperFieldRow(title: "Column Width", value: overrideBinding(\.columnWidth), step: 0.5)
                    StepperFieldRow(title: "Column Depth", value: overrideBinding(\.columnDepth), step: 0.5)
                    StepperFieldRow(title: "Column Height", value: overrideBinding(\.columnHeight), step: 1)
                    
                    Button("Reapply Defaults to All Segments") {
                        reapplyDefaultsToSegments()
                    }
                    .disabled(draft.generatedSegments.isEmpty && draft.resolvedSegments.isEmpty)
                    .font(.callout)
                }
                
                Section {
                    ArchitecturalLegendStrip(
                        axis: .horizontal,
                        isExpanded: $isLegendExpanded,
                        onInsertToken: { token in
                            insertToken(token, into: .chain)
                        }
                    )
                    
                    TextField("Chain String", text: chainInputBinding)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .chain)
                    
                    HStack {
                        Button("Apply Chain") {
                            applyChain()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cleanedChainInput.isEmpty)
                        
                        Spacer()
                        
                        Button("Apply Seed") {
                            applySeed()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if !draft.chainString.isEmpty {
                        Text("Applied: \(draft.chainString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Horizontal Chain")
                } footer: {
                    Text("Type shorthand and it auto-expands. d = DR, w = WIN, c = C, bc = BC, o = OP, fp = FP, n = NIC, s = SH, rz = RZ, ws = WS.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Section {
                    ArchitecturalLegendStrip(
                        axis: .vertical,
                        isExpanded: $isLegendExpanded,
                        onInsertToken: { token in
                            insertToken(token, into: .verticalChain)
                        }
                    )
                    
                    TextField("Vertical Chain", text: verticalChainInputBinding)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .verticalChain)
                    
                    HStack {
                        Button("Apply Vertical") {
                            applyVerticalChain()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cleanedVerticalChainInput.isEmpty)
                        
                        Spacer()
                        
                        Button("Default (BB WS BM CR)") {
                            verticalChainInput = "BB WS BM CR"
                            applyVerticalChain()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    
                    if !draft.verticalChainString.isEmpty {
                        Text("Applied: \(draft.verticalChainString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Vertical Chain")
                } footer: {
                    Text("Bottom-to-top stack. Shorthand: bb = BB, ws = WS, bm = BM, cr = CR, hdr = HDR, sl = SL.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Section {
                    if draft.generatedSegments.isEmpty && draft.chainString.isEmpty {
                        Text("No segments yet. Apply a chain, apply seed, or add manually.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(draft.generatedSegments.enumerated()), id: \.element.id) { index, segment in
                            segmentRow(index: index, segment: segment)
                        }
                        .onDelete { offsets in
                            draft.generatedSegments.remove(atOffsets: offsets)
                            draft.chainString = rebuildChainString()
                            chainInput = draft.chainString
                        }
                        .onMove { source, destination in
                            draft.generatedSegments.move(fromOffsets: source, toOffset: destination)
                            draft.chainString = rebuildChainString()
                            chainInput = draft.chainString
                        }
                    }
                    
                    Button {
                        insertingAfterIndex = draft.generatedSegments.count - 1
                        showingInsertPicker = true
                    } label: {
                        Label("Add Segment at End", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Segments")
                        Spacer()
                        EditButton()
                            .font(.caption)
                    }
                } footer: {
                    Text("Tap label to edit. Use inline stepper for quick width changes. Swipe left to delete. Tap Edit to reorder.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Section("Elevation Preview") {
                    Picker("View", selection: $previewMode) {
                        ForEach(WallPreviewMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch previewMode {
                    case .ortho:
                        ElevationPreviewCard(layout: elevationLayout)
                    case .threeD:
                        WallRealityPreview(wall: previewWall, defaults: effectiveDefaults)
                            .frame(minHeight: 320)
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    LabeledContent("Segment Sum", value: formatted(segmentSum))
                    LabeledContent("Matches Wall Width", value: matchesWallWidth ? "Yes" : "No")
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditingExistingWall ? "Update" : "Save") {
                        saveDraft()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(item: $editingSegmentID) { segmentID in
                NavigationStack {
                    if let index = draft.generatedSegments.firstIndex(where: { $0.id == segmentID }) {
                        SegmentDetailForm(segment: bindingForSegment(at: index))
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { editingSegmentID = nil }
                                        .fontWeight(.semibold)
                                }
                            }
                    } else {
                        ContentUnavailableView("Segment Missing", systemImage: "questionmark.square.dashed")
                    }
                }
                .interactiveDismissDisabled(true)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .confirmationDialog(
                "Insert Segment",
                isPresented: $showingInsertPicker,
                titleVisibility: .visible
            ) {
                ForEach(insertableKinds, id: \.self) { kind in
                    Button(kind.rawValue) {
                        insertSegment(kind: kind)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose a kind to insert.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func segmentRow(index: Int, segment: WallSegment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    editingSegmentID = segment.id
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(segment.label)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if segmentHasConfiguredDetails(segment) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            Text(segment.kind.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if isOpeningKind(segment.kind) {
                                HStack(spacing: 4) {
                                    Image(systemName: openingIconName(for: segment.kind))
                                        .font(.caption2)
                                    Text(openingDetailSummary(for: segment))
                                        .font(.caption2)
                                }
                                .foregroundStyle(.blue)
                                .padding(.top, 2)
                            }
                        }
                        Spacer(minLength: 0)
                        if isOpeningKind(segment.kind) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button {
                    insertingAfterIndex = index
                    showingInsertPicker = true
                } label: {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Insert segment after \(segment.label)")
            }
            
            InlineStepperRow(
                title: widthLabel(for: segment),
                value: widthBinding(for: index),
                step: widthStep(for: segment)
            )
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                insertingAfterIndex = max(-1, index - 1)
                showingInsertPicker = true
            } label: {
                Label("Insert Before", systemImage: "arrow.up.to.line")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if draft.generatedSegments.indices.contains(index) {
                    draft.generatedSegments.remove(at: index)
                    draft.chainString = rebuildChainString()
                    chainInput = draft.chainString
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                duplicateSegment(at: index)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            .tint(.indigo)
        }
    }
    
    private func widthLabel(for segment: WallSegment) -> String {
        segment.opening == nil ? "Width" : "Opening Width"
    }
    
    private func isOpeningKind(_ kind: SegmentKind) -> Bool {
        kind == .windowUnit || kind == .door || kind == .opening
    }
    
    private func openingIconName(for kind: SegmentKind) -> String {
        switch kind {
        case .windowUnit: return "window.horizontal"
        case .door: return "door.left.hand.closed"
        case .opening: return "rectangle.portrait"
        default: return "chevron.right"
        }
    }
    
    private func openingDetailSummary(for segment: WallSegment) -> String {
        guard let opening = segment.opening else {
            return "Configure Details"
        }
        
        var parts: [String] = []
        
        switch segment.kind {
        case .windowUnit:
            if let style = opening.windowStyle {
                parts.append(style.rawValue)
            }
            parts.append("\(opening.panelCount) panel\(opening.panelCount == 1 ? "" : "s")")
            parts.append("\(String(format: "%.2f", opening.openingWidth)) × \(String(format: "%.2f", opening.openingHeight))")
            
        case .door:
            if let style = opening.doorStyle {
                parts.append(style.rawValue)
            }
            if opening.handing != .none {
                parts.append(opening.handing.rawValue)
            }
            parts.append("\(String(format: "%.2f", opening.openingWidth)) × \(String(format: "%.2f", opening.openingHeight))")
            
        case .opening:
            parts.append("Cased Opening")
            parts.append("\(String(format: "%.2f", opening.openingWidth)) × \(String(format: "%.2f", opening.openingHeight))")
            
        default:
            return "Configure Details"
        }
        
        return parts.joined(separator: " · ") + " · Tap to edit"
    }
    
    private func segmentHasConfiguredDetails(_ segment: WallSegment) -> Bool {
        guard isOpeningKind(segment.kind), let opening = segment.opening else { return false }
        // "Configured" means: dimensions set beyond defaults, or notes filled, or panels array populated,
        // or manufacturer/model present, or non-default style.
        if !opening.notes.trimmed.isEmpty { return true }
        if !opening.panels.isEmpty { return true }
        if !opening.manufacturer.trimmed.isEmpty { return true }
        if !opening.modelNumber.trimmed.isEmpty { return true }
        if opening.mullionsVertical > 0 || opening.mullionsHorizontal > 0 { return true }
        if opening.muntinsRows > 0 || opening.muntinsCols > 0 { return true }
        if opening.panelCount > 1 { return true }
        return false
    }
    
    private func widthStep(for segment: WallSegment) -> Double {
        switch segment.kind {
        case .baseboard, .crown, .casing, .trim: return 0.5
        default: return 1
        }
    }
    
    private func widthBinding(for index: Int) -> Binding<Double> {
        Binding(
            get: {
                guard draft.generatedSegments.indices.contains(index) else { return 0 }
                let segment = draft.generatedSegments[index]
                if let opening = segment.opening {
                    return opening.openingWidth
                }
                return segment.width
            },
            set: { newValue in
                guard draft.generatedSegments.indices.contains(index) else { return }
                if draft.generatedSegments[index].opening != nil {
                    draft.generatedSegments[index].opening?.openingWidth = max(0, newValue)
                } else {
                    draft.generatedSegments[index].width = max(0, newValue)
                }
            }
        )
    }
    
    private func overrideBinding(_ keyPath: WritableKeyPath<RoomDefaults, Double>) -> Binding<Double> {
        Binding(
            get: { effectiveDefaults[keyPath: keyPath] },
            set: { newValue in
                draft.usesOverrides = true
                draft.overrides[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func overrideTextBinding(_ keyPath: WritableKeyPath<RoomDefaults, String>) -> Binding<String> {
        Binding(
            get: { effectiveDefaults[keyPath: keyPath] },
            set: { newValue in
                draft.usesOverrides = true
                draft.overrides[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func bindingForSegment(at index: Int) -> Binding<WallSegment> {
        Binding(
            get: { draft.generatedSegments[index] },
            set: { draft.generatedSegments[index] = $0 }
        )
    }
    
    private func insertSegment(kind: SegmentKind) {
        var newSegment = WallSegment(
            label: defaultLabel(for: kind, index: draft.generatedSegments.count),
            width: defaultWidth(for: kind),
            kind: kind,
            note: ""
        )
        applyDefaults(to: &newSegment)
        
        let raw = insertingAfterIndex ?? (draft.generatedSegments.count - 1)
        let insertIndex = min(max(raw + 1, 0), draft.generatedSegments.count)
        draft.generatedSegments.insert(newSegment, at: insertIndex)
        insertingAfterIndex = nil
        
        draft.chainString = rebuildChainString()
        chainInput = draft.chainString
    }
    
    private func duplicateSegment(at index: Int) {
        guard draft.generatedSegments.indices.contains(index) else { return }
        let source = draft.generatedSegments[index]
        var copy = WallSegment(
            label: source.label + " COPY",
            width: source.width,
            kind: source.kind,
            note: source.note
        )
        copy.opening = source.opening
        copy.shelfCount = source.shelfCount
        copy.shelfDepth = source.shelfDepth
        copy.shelfThickness = source.shelfThickness
        copy.shelfSpacedEvenly = source.shelfSpacedEvenly
        copy.isFloorToCeiling = source.isFloorToCeiling
        copy.isSharedCorner = source.isSharedCorner
        copy.beamPosition = source.beamPosition
        copy.wallVariant = source.wallVariant
        copy.kneeWallHeight = source.kneeWallHeight
        copy.cathedralPeakHeight = source.cathedralPeakHeight
        copy.cathedralPeakOffset = source.cathedralPeakOffset
        copy.archRise = source.archRise
        
        draft.generatedSegments.insert(copy, at: index + 1)
        draft.chainString = rebuildChainString()
        chainInput = draft.chainString
    }
    
    private func defaultLabel(for kind: SegmentKind, index: Int) -> String {
        let prefix: String
        switch kind {
        case .wallSpace: prefix = "WS"
        case .wall: prefix = "W"
        case .column: prefix = "C"
        case .bookcase: prefix = "SH"
        case .shelf: prefix = "SF"
        case .windowUnit: prefix = "WIN"
        case .door: prefix = "DR"
        case .opening: prefix = "OP"
        case .beam: prefix = "BM"
        case .baseboard: prefix = "BB"
        case .crown: prefix = "CR"
        case .casing: prefix = "CS"
        case .trim: prefix = "TR"
        case .returnZone: prefix = "RZ"
        }
        return "\(prefix)\(index + 1)"
    }
    
    private func defaultWidth(for kind: SegmentKind) -> Double {
        let d = effectiveDefaults
        switch kind {
        case .column: return d.columnWidth
        case .beam: return 12
        case .windowUnit: return 48
        case .door: return 36
        case .opening: return 36
        case .bookcase: return 36
        case .shelf: return 24
        case .baseboard: return d.baseboardHeight
        case .crown: return d.crownHeight
        case .casing, .trim: return 4
        case .wallSpace, .wall, .returnZone: return 24
        }
    }
    
    private func rebuildChainString() -> String {
        draft.generatedSegments.map { chainToken(for: $0.kind) }.joined(separator: " ")
    }
    
    private func chainToken(for kind: SegmentKind) -> String {
        switch kind {
        case .wallSpace: return "WS"
        case .wall: return "W"
        case .column: return "C"
        case .bookcase: return "SH"
        case .shelf: return "SF"
        case .windowUnit: return "WIN"
        case .door: return "DR"
        case .opening: return "OP"
        case .beam: return "BM"
        case .baseboard: return "BB"
        case .crown: return "CR"
        case .casing: return "CS"
        case .trim: return "TR"
        case .returnZone: return "RZ"
        }
    }
    
    private func applyChain() {
        let normalized = cleanedChainInput
        guard !normalized.isEmpty else { return }
        
        draft.chainString = normalized
        var parsed = WallSegment.parseChain(normalized)
        for i in parsed.indices {
            applyDefaults(to: &parsed[i])
        }
        draft.generatedSegments = parsed
        chainInput = normalized
        focusedField = nil
    }
    
    private func applyVerticalChain() {
        let normalized = cleanedVerticalChainInput
        guard !normalized.isEmpty else { return }
        draft.verticalChainString = normalized
        verticalChainInput = normalized
        focusedField = nil
    }
    
    private func applySeed() {
        let seedChain = "C SH C WS W WS C SH C"
        chainInput = seedChain
        draft.chainString = seedChain
        var segs = WallSegment.wallOneSeedSegments
        for i in segs.indices {
            applyDefaults(to: &segs[i])
        }
        draft.generatedSegments = segs
    }
    
    private func reapplyDefaultsToSegments() {
        // If the wall was loaded from a saved WallSpec, its segments live in
        // draft.resolvedSegments — not generatedSegments. Hoist them in first.
        if draft.generatedSegments.isEmpty && !draft.resolvedSegments.isEmpty {
            draft.generatedSegments = draft.resolvedSegments
        }
        for i in draft.generatedSegments.indices {
            applyDefaults(to: &draft.generatedSegments[i])
        }
        draft.chainString = rebuildChainString()
        chainInput = draft.chainString
    }
    
    private func applyDefaults(to segment: inout WallSegment) {
        let d = effectiveDefaults
        
        switch segment.kind {
        case .column:
            segment.width = d.columnWidth
            
        case .beam:
            segment.width = d.beamHeight
            if segment.beamPosition == nil { segment.beamPosition = .onTopOfColumns }
            
        case .baseboard:
            segment.width = d.baseboardHeight
            
        case .crown:
            segment.width = d.crownHeight
            
        case .casing, .trim:
            if segment.width <= 0 { segment.width = 4 }
            
        case .bookcase:
            if segment.width <= 0 { segment.width = 36 }
            if segment.shelfCount == nil { segment.shelfCount = 5 }
            if segment.shelfDepth == nil { segment.shelfDepth = 12 }
            if segment.isFloorToCeiling == nil { segment.isFloorToCeiling = true }
            
        case .shelf:
            if segment.width <= 0 { segment.width = 24 }
            if segment.shelfCount == nil { segment.shelfCount = 1 }
            if segment.shelfDepth == nil { segment.shelfDepth = 10 }
            if segment.shelfThickness == nil { segment.shelfThickness = 1.5 }
            if segment.shelfSpacedEvenly == nil { segment.shelfSpacedEvenly = true }
            
        case .wall, .wallSpace, .returnZone:
            if segment.width <= 0 { segment.width = 24 }
            
        case .windowUnit:
            if segment.opening == nil {
                let openingH = max(d.ceilingHeight - d.baseboardHeight - d.crownHeight - 6, 36)
                let sill = max(d.baseboardHeight, 24)
                segment.opening = OpeningSpec(
                    category: .window,
                    windowStyle: .picture,
                    openingWidth: max(segment.width, 48),
                    openingHeight: openingH,
                    sillOrBottomAFF: sill,
                    casingLeft: 5,
                    casingRight: 5,
                    casingHead: 5,
                    wallSpaceAboveUnit: max(d.ceilingHeight - sill - openingH - d.crownHeight, 0),
                    panelCount: 1
                )
            }
            
        case .door:
            if segment.opening == nil {
                let openingH: Double = 80
                segment.opening = OpeningSpec(
                    category: .door,
                    windowStyle: nil,
                    doorStyle: .single,
                    openingWidth: max(segment.width, 36),
                    openingHeight: openingH,
                    sillOrBottomAFF: 0,
                    casingLeft: 5,
                    casingRight: 5,
                    casingHead: 5,
                    wallSpaceAboveUnit: max(d.ceilingHeight - openingH - d.crownHeight, 0),
                    panelCount: 1,
                    handing: .left
                )
            }
            
        case .opening:
            if segment.opening == nil {
                let openingH: Double = 80
                segment.opening = OpeningSpec(
                    category: .generic,
                    windowStyle: nil,
                    doorStyle: nil,
                    openingWidth: max(segment.width, 36),
                    openingHeight: openingH,
                    sillOrBottomAFF: 0,
                    casingLeft: 0,
                    casingRight: 0,
                    casingHead: 0,
                    wallSpaceAboveUnit: max(d.ceilingHeight - openingH - d.crownHeight, 0)
                )
            }
        }
    }
    
    private func saveDraft() {
        if !cleanedChainInput.isEmpty && draft.generatedSegments.isEmpty {
            applyChain()
        }
        
        if !cleanedVerticalChainInput.isEmpty {
            draft.verticalChainString = cleanedVerticalChainInput
        }
        
        if draft.generatedSegments.isEmpty {
            draft.generatedSegments = draft.resolvedSegments
        }
        
        onSave(draft)
        dismiss()
    }
    
    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

// MARK: - Architectural Legend

// MARK: - Architectural Legend Entry

struct ArchitecturalLegendEntry: Identifiable, Hashable {
    let id = UUID()
    let token: String
    let name: String
    let definition: String
    let axis: Axis
    
    enum Axis: String {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
        case both = "Both"
    }
}

// MARK: - Chain Shorthand Normalizer

enum ChainShorthand {
    enum Axis {
        case horizontal
        case vertical
    }
    
    /// Horizontal shorthand → canonical token
    private static let horizontalMap: [String: String] = [
        "WS": "WS",
        "W": "WS",
        "C": "C",
        "COL": "C",
        "BC": "BC",
        "BK": "BC",
        "SH": "SH",
        "S": "SH",
        "WIN": "WIN",
        "WN": "WIN",
        "DR": "DR",
        "D": "DR",
        "DOOR": "DR",
        "OP": "OP",
        "O": "OP",
        "FP": "FP",
        "F": "FP",
        "NIC": "NIC",
        "N": "NIC",
        "RZ": "RZ",
        "R": "RZ"
    ]
    
    /// Vertical shorthand → canonical token
    private static let verticalMap: [String: String] = [
        "BB": "BB",
        "B": "BB",
        "BASE": "BB",
        "WS": "WS",
        "W": "WS",
        "BM": "BM",
        "BEAM": "BM",
        "CR": "CR",
        "C": "CR",
        "CROWN": "CR",
        "HDR": "HDR",
        "HD": "HDR",
        "HEAD": "HDR",
        "SL": "SL",
        "SILL": "SL",
        "CLG": "CLG",
        "CEIL": "CLG",
        "FLR": "FLR",
        "FLOOR": "FLR"
    ]
    
    /// Normalize a raw chain string against the given axis.
    /// - Splits on spaces and commas.
    /// - Uppercases each token.
    /// - Expands to canonical token if in the shorthand map.
    /// - Preserves a trailing space so the user can keep typing without the cursor snapping.
    static func normalize(_ raw: String, axis: Axis) -> String {
        let map = (axis == .horizontal) ? horizontalMap : verticalMap
        let trailingSpace = raw.hasSuffix(" ")
        let unified = raw.replacingOccurrences(of: ",", with: " ")
        let parts = unified.split(separator: " ", omittingEmptySubsequences: true)
        let normalized = parts.map { part -> String in
            let up = part.uppercased()
            return map[up] ?? up
        }
        var out = normalized.joined(separator: " ")
        if trailingSpace && !out.isEmpty {
            out += " "
        }
        return out
    }
}

// MARK: - Architectural Legend Strip (compact, non-blocking, tap-to-insert)

struct ArchitecturalLegendStrip: View {
    let axis: Axis
    @Binding var isExpanded: Bool
    var onInsertToken: (String) -> Void
    
    enum Axis {
        case horizontal
        case vertical
    }
    
    private static let horizontalEntries: [ArchitecturalLegendEntry] = [
        .init(token: "BC",  name: "Bookcase",    definition: "Built-in bookcase or cabinetry.", axis: .horizontal),
        .init(token: "C",   name: "Column",      definition: "Vertical structural column.", axis: .horizontal),
        .init(token: "DR",  name: "Door",        definition: "Door opening.", axis: .horizontal),
        .init(token: "FP",  name: "Fireplace",   definition: "Fireplace, mantel, or surround.", axis: .horizontal),
        .init(token: "NIC", name: "Niche",       definition: "Recessed wall niche or alcove.", axis: .horizontal),
        .init(token: "OP",  name: "Opening",     definition: "Cased opening, no door.", axis: .horizontal),
        .init(token: "RZ",  name: "Return Zone", definition: "Inside corner or return.", axis: .horizontal),
        .init(token: "SH",  name: "Shelf",       definition: "Shelving unit.", axis: .horizontal),
        .init(token: "WIN", name: "Window",      definition: "Window opening.", axis: .horizontal),
        .init(token: "WS",  name: "Wall Space",  definition: "Blank drywall run between elements.", axis: .horizontal)
    ]
    
    private static let verticalEntries: [ArchitecturalLegendEntry] = [
        .init(token: "BB",  name: "Baseboard",   definition: "Floor-line trim band.", axis: .vertical),
        .init(token: "BM",  name: "Beam",        definition: "Horizontal beam band.", axis: .vertical),
        .init(token: "CLG", name: "Ceiling",     definition: "Ceiling reference line.", axis: .vertical),
        .init(token: "CR",  name: "Crown",       definition: "Ceiling-line crown molding.", axis: .vertical),
        .init(token: "FLR", name: "Floor",       definition: "Floor reference line.", axis: .vertical),
        .init(token: "HDR", name: "Header",      definition: "Top framing of an opening.", axis: .vertical),
        .init(token: "SL",  name: "Sill",        definition: "Bottom framing of a window.", axis: .vertical),
        .init(token: "WS",  name: "Wall Space",  definition: "Blank vertical stretch of wall.", axis: .vertical)
    ]
    
    private var entries: [ArchitecturalLegendEntry] {
        switch axis {
        case .horizontal: return Self.horizontalEntries
        case .vertical:   return Self.verticalEntries
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(axisTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entries) { entry in
                            Button {
                                onInsertToken(entry.token)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(entry.token)
                                        .font(.caption.weight(.bold).monospaced())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(tokenColor(for: entry.token))
                                        )
                                    Text(entry.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Insert \(entry.name)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var axisTitle: String {
        switch axis {
        case .horizontal: return "Horizontal Legend — tap to insert"
        case .vertical:   return "Vertical Legend — tap to insert"
        }
    }
    
    private func tokenColor(for token: String) -> Color {
        switch token {
        case "WS":  return .gray
        case "C":   return .blue
        case "BC":  return .brown
        case "SH":  return .brown
        case "WIN": return .teal
        case "DR":  return .green
        case "OP":  return .mint
        case "FP":  return .red
        case "NIC": return .indigo
        case "RZ":  return .gray
        case "BB":  return .brown
        case "BM":  return .orange
        case "CR":  return .purple
        case "HDR": return .orange
        case "SL":  return .teal
        case "CLG": return .purple
        case "FLR": return .brown
        default:    return .secondary
        }
    }
}

// MARK: - Inline Stepper Row

struct InlineStepperRow: View {
    let title: String
    @Binding var value: Double
    var step: Double = 1
    var minimum: Double = 0
    var maximum: Double = 9999
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 4)
            
            Button {
                commitText()
                value = max(minimum, value - step)
                syncFromValue()
            } label: {
                Image(systemName: "minus.square.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease \(title)")
            
            TextField(title, text: $textValue)
                .multilineTextAlignment(.center)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .frame(width: 74)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onAppear { syncFromValue() }
                .onChange(of: value) { _, _ in
                    if !isFocused { syncFromValue() }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commitText() }
                }
            
            Button {
                commitText()
                value = min(maximum, value + step)
                syncFromValue()
            } label: {
                Image(systemName: "plus.square.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase \(title)")
        }
    }
    
    private func syncFromValue() {
        textValue = String(format: "%.2f", value)
    }
    
    private func commitText() {
        let cleaned = textValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let parsed = Double(cleaned) {
            value = min(maximum, max(minimum, parsed))
        }
        
        syncFromValue()
    }
}

// MARK: - Segment Detail Form (window / door / opening editor)

struct SegmentDetailForm: View {
    @Binding var segment: WallSegment
    
    private var isOpeningSegment: Bool {
        segment.kind == .windowUnit || segment.kind == .door || segment.kind == .opening
    }
    
    private var isWindow: Bool { segment.kind == .windowUnit }
    private var isDoor: Bool { segment.kind == .door }
    
    var body: some View {
        Form {
            
            if isOpeningSegment {
                Section {
                    OpeningElevationView(segment: segment)
                        .frame(height: 240)
                        .padding(.vertical, 4)
                } header: {
                    Text("Live Preview")
                } footer: {
                    Text("Deterministic orthographic view. Updates as you edit dimensions, panels, mullions, and muntins below.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section {
                TextField("Label", text: $segment.label)
                
                Picker("Kind", selection: $segment.kind) {
                    ForEach(SegmentKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .onChange(of: segment.kind) { _, newValue in
                    handleKindChange(newValue)
                }
                
                TextField("Note", text: $segment.note, axis: .vertical)
                    .lineLimit(2...5)
            } header: {
                Text("Segment")
            } footer: {
                Text("Segment width is edited on the main wall list, not here. This screen holds detail-only information.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if segment.kind == .column {
                Section {
                    Toggle("Shared Corner", isOn: sharedCornerBinding)
                } header: {
                    Text("Column")
                } footer: {
                    Text("Turn on when this column sits at a room corner and is shared with the adjacent wall. Used for cross-wall numbering in the future floorplan view.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if segment.kind == .bookcase {
                Section("Bookcase") {
                    StepperIntFieldRow(title: "Shelf Count", value: shelfCountBinding, step: 1, minimum: 1, maximum: 12)
                    StepperFieldRow(title: "Shelf Depth", value: shelfDepthBinding, step: 0.5)
                    Toggle("Floor to Ceiling", isOn: floorToCeilingBinding)
                }
            }
            
            if segment.kind == .shelf {
                Section {
                    StepperFieldRow(title: "Shelf Width", value: shelfWidthBinding, step: 1)
                    StepperFieldRow(title: "Shelf Depth", value: shelfDepthBinding, step: 0.5)
                    StepperFieldRow(title: "Shelf Thickness", value: shelfThicknessBinding, step: 0.25)
                    StepperIntFieldRow(title: "Shelf Count", value: shelfCountBinding, step: 1, minimum: 1, maximum: 20)
                    if shelfCountBinding.wrappedValue > 1 {
                        Toggle("Spaced Evenly", isOn: shelfSpacedEvenlyBinding)
                    }
                } header: {
                    Text("Shelf")
                } footer: {
                    Text("Shelf Width sets this segment's width on the wall. When Shelf Count is greater than 1, Spaced Evenly distributes shelves vertically across the wall height.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if segment.kind == .beam {
                Section {
                    Picker("Position", selection: beamPositionBinding) {
                        ForEach(BeamPosition.allCases, id: \.self) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                } header: {
                    Text("Beam")
                } footer: {
                    Text("On Top of Columns: beam rests on the columns and extends past their outer faces. Wedged Between: beam ends flush against two verticals. Ceiling Hung: beam is a ceiling drop / soffit with no supporting columns.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if segment.kind == .wall || segment.kind == .wallSpace {
                Section {
                    Picker("Variant", selection: wallVariantBinding) {
                        ForEach(WallVariant.allCases, id: \.self) { v in
                            Text(v.rawValue).tag(v)
                        }
                    }
                    
                    if wallVariantBinding.wrappedValue == .kneeWall {
                        StepperFieldRow(title: "Knee Wall Height", value: kneeWallHeightBinding, step: 1)
                    }
                    
                    if wallVariantBinding.wrappedValue == .cathedral {
                        StepperFieldRow(title: "Peak Height", value: cathedralPeakHeightBinding, step: 1)
                        StepperFieldRow(title: "Peak Offset From Left", value: cathedralPeakOffsetBinding, step: 1)
                    }
                    
                    if wallVariantBinding.wrappedValue == .archedPartition {
                        StepperFieldRow(title: "Arch Rise", value: archRiseBinding, step: 0.5)
                    }
                } header: {
                    Text("Wall Variant")
                } footer: {
                    Text("Full Wall: floor-to-ceiling standard wall. Knee / Half Wall: capped at Knee Wall Height AFF. Cathedral: single peak defined by peak height and horizontal offset from left. Arched Partition: half-round or elliptical head, Arch Rise is the vertical distance from spring line to peak. Pass-Through: framed opening with no fill. Custom: use the Note field.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if isOpeningSegment {
                Section("Opening Type") {
                    Picker("Category", selection: openingCategoryBinding) {
                        ForEach(OpeningCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .onChange(of: openingCategoryBinding.wrappedValue) { _, _ in
                        normalizeOpening()
                    }
                    
                    if openingCategoryBinding.wrappedValue == .window {
                        Picker("Window Style", selection: windowStyleBinding) {
                            ForEach(WindowStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(Optional(style))
                            }
                        }
                    }
                    
                    if openingCategoryBinding.wrappedValue == .door {
                        Picker("Door Style", selection: doorStyleBinding) {
                            ForEach(DoorStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(Optional(style))
                            }
                        }
                        
                        Picker("Handing", selection: handingBinding) {
                            ForEach(OpeningHanding.allCases, id: \.self) { handing in
                                Text(handing.rawValue).tag(handing)
                            }
                        }
                    }
                }
                
                Section("Opening Dimensions") {
                    StepperFieldRow(title: "Opening Width", value: openingWidthBinding, step: 1)
                    StepperFieldRow(title: "Opening Height", value: openingHeightBinding, step: 1)
                    StepperFieldRow(title: "Bottom / Sill AFF", value: openingBottomBinding, step: 1)
                    if isDoor {
                        StepperFieldRow(title: "Threshold Height", value: thresholdHeightBinding, step: 0.25)
                    }
                    StepperFieldRow(title: "Projection Depth", value: projectionDepthBinding, step: 0.5)
                }
                
                Section {
                    StepperIntFieldRow(title: "Panel Count", value: panelCountBinding, step: 1, minimum: 1, maximum: 12)
                        .onChange(of: panelCountBinding.wrappedValue) { _, _ in
                            syncPanelsArray()
                        }
                    StepperFieldRow(title: "Mullion Width", value: mullionWidthBinding, step: 0.25)
                } header: {
                    Text("Panels")
                } footer: {
                    Text("Enter each panel's width in inches below. Mullions between panels are configured in the Mullions Between Panels section.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                if panelCountBinding.wrappedValue >= 1 && (isWindow || segment.kind == .opening) {
                    Section {
                        LabeledContent("Available Panel Width", value: formatted(availablePanelWidth))
                        LabeledContent("Sum of Widths", value: formatted(sumOfShares))
                        HStack {
                            Button {
                                distributePanelsEqually()
                            } label: {
                                Label("Distribute Equally", systemImage: "equal.circle")
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                resetPanels()
                            } label: {
                                Label("Reset Panels", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        let panelIndices = Array(0..<(segment.opening?.panels.count ?? 0))
                        ForEach(panelIndices, id: \.self) { panelIndex in
                            PanelEditorRow(
                                index: panelIndex,
                                panel: panelBinding(at: panelIndex),
                                resolvedInches: resolvedPanelInches(at: panelIndex)
                            )
                        }
                    } header: {
                        Text("Per-Panel Configuration")
                    } footer: {
                        Text("Enter each panel's Width in inches. Sum should equal Available Panel Width. Use Distribute Equally to auto-split.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .onAppear {
                        syncPanelsArray()
                    }
                }
                
                if panelCountBinding.wrappedValue >= 2 && (isWindow || segment.kind == .opening) {
                    Section {
                        let seamCount = max(0, panelCountBinding.wrappedValue - 1)
                        ForEach(0..<seamCount, id: \.self) { seamIndex in
                            MullionSeamRow(
                                seamIndex: seamIndex,
                                panelLabelLeft: panelLabel(at: seamIndex),
                                panelLabelRight: panelLabel(at: seamIndex + 1),
                                isOn: seamBinding(at: seamIndex)
                            )
                        }
                    } header: {
                        Text("Mullions Between Panels")
                    } footer: {
                        Text("Turn a seam Off to remove the vertical divider between two panels while keeping them as separate units.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if isDoor {
                    Section {
                        LabeledContent("Leaf Configuration", value: leafConfigurationSummary)
                        LabeledContent("Rough Opening", value: "\(formatted(openingWidthBinding.wrappedValue)) × \(formatted(openingHeightBinding.wrappedValue))")
                    } header: {
                        Text("Door Summary")
                    } footer: {
                        Text("Leaf count is derived from Door Style. French = 2 leaves, Double = 2 leaves, Single/Pocket/Barn = 1 leaf. Adjust the style above to change leaf count.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if segment.kind == .opening {
                    Section {
                        Picker("Head Shape", selection: windowStyleBinding) {
                            Text("Square").tag(Optional(WindowStyle.picture))
                            Text("Arched").tag(Optional(WindowStyle.arched))
                            Text("Transom Top").tag(Optional(WindowStyle.transom))
                            Text("Custom").tag(Optional(WindowStyle.custom))
                        }
                    } header: {
                        Text("Opening Shape")
                    } footer: {
                        Text("Cased openings can be square, arched, or transom-topped.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if isWindow || segment.kind == .opening {
                    Section {
                        StepperIntFieldRow(title: "Muntin Rows", value: muntinsRowsBinding, step: 1, minimum: 0, maximum: 20)
                        StepperIntFieldRow(title: "Muntin Cols", value: muntinsColsBinding, step: 1, minimum: 0, maximum: 20)
                        StepperFieldRow(title: "Muntin Width", value: muntinWidthBinding, step: 0.125)
                    } header: {
                        Text("Muntins (Grid Inside Each Lite)")
                    } footer: {
                        Text("Rows × Cols defines the divided-lite pattern inside every panel. Set both to 0 for a single clear pane.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Section("Casing") {
                    StepperFieldRow(title: "Left Casing", value: casingLeftBinding, step: 0.25)
                    StepperFieldRow(title: "Right Casing", value: casingRightBinding, step: 0.25)
                    StepperFieldRow(title: "Head Casing", value: casingHeadBinding, step: 0.25)
                    StepperFieldRow(title: "Bottom Casing", value: casingBottomBinding, step: 0.25)
                    StepperFieldRow(title: "Casing Face Width", value: casingWidthBinding, step: 0.25)
                    Toggle("Top Casing Is Crown", isOn: topCasingIsCrownBinding)
                    StepperFieldRow(title: "Wall Space Above Unit", value: wallSpaceAboveUnitBinding, step: 0.5)
                }
                
                Section("Frame & Material") {
                    StepperFieldRow(title: "Frame Width", value: frameWidthBinding, step: 0.25)
                    StepperFieldRow(title: "Jamb Depth", value: jambDepthBinding, step: 0.25)
                    
                    if isWindow {
                        Picker("Frame Material", selection: frameMaterialBinding) {
                            ForEach(WindowFrameMaterial.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        
                        Picker("Glazing", selection: glazingBinding) {
                            ForEach(WindowGlazing.allCases, id: \.self) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                    }
                }
                
                if isWindow {
                    Section("Sill, Stool & Apron") {
                        StepperFieldRow(title: "Sill Projection (Ext.)", value: sillProjectionBinding, step: 0.25)
                        StepperFieldRow(title: "Interior Stool Projection", value: interiorStoolProjectionBinding, step: 0.25)
                        StepperFieldRow(title: "Apron Height", value: apronHeightBinding, step: 0.25)
                    }
                    
                    Section("Performance & Metadata") {
                        Toggle("Egress Window", isOn: isEgressBinding)
                        Toggle("Has Screens", isOn: hasScreensBinding)
                        StepperFieldRow(title: "U-Factor", value: uFactorBinding, step: 0.01, minimum: 0, maximum: 5)
                        StepperFieldRow(title: "SHGC", value: shgcBinding, step: 0.01, minimum: 0, maximum: 1)
                        TextField("Manufacturer", text: manufacturerBinding)
                        TextField("Model Number", text: modelNumberBinding)
                    }
                }
                
                Section("Notes") {
                    TextField("Opening notes", text: openingNotesBinding, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section("Computed") {
                    LabeledContent("Resolved Segment Width", value: formatted(segment.resolvedWidth))
                    LabeledContent("Top of Unit AFF", value: formatted(openingTopBinding.wrappedValue))
                    if isWindow, let opening = segment.opening {
                        LabeledContent("Lites per Panel", value: liteCount(rows: opening.muntinsRows, cols: opening.muntinsCols))
                        LabeledContent("Total Lites", value: "\(max(opening.panelCount, 1) * max(1, opening.muntinsRows == 0 ? 1 : opening.muntinsRows) * max(1, opening.muntinsCols == 0 ? 1 : opening.muntinsCols))")
                    }
                }
            } else {
                Section("Computed") {
                    LabeledContent("Resolved Segment Width", value: formatted(segment.resolvedWidth))
                }
            }
        }
        .navigationTitle(segment.label.isEmpty ? "Segment" : segment.label)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            handleKindChange(segment.kind)
        }
    }
    
    private func liteCount(rows: Int, cols: Int) -> String {
        let r = max(1, rows == 0 ? 1 : rows)
        let c = max(1, cols == 0 ? 1 : cols)
        return "\(r) × \(c) = \(r * c)"
    }
    
    private func handleKindChange(_ kind: SegmentKind) {
        switch kind {
        case .windowUnit:
            if segment.opening == nil {
                segment.opening = OpeningSpec(
                    category: .window,
                    windowStyle: .picture,
                    openingWidth: 96,
                    openingHeight: 60,
                    sillOrBottomAFF: 24,
                    casingLeft: 5,
                    casingRight: 5,
                    casingHead: 5,
                    wallSpaceAboveUnit: 3,
                    panelCount: 1
                )
            }
            segment.opening?.category = .window
            if segment.opening?.windowStyle == nil {
                segment.opening?.windowStyle = .picture
            }
            
        case .door:
            if segment.opening == nil {
                segment.opening = OpeningSpec(
                    category: .door,
                    windowStyle: nil,
                    doorStyle: .single,
                    openingWidth: 36,
                    openingHeight: 80,
                    sillOrBottomAFF: 0,
                    casingLeft: 5,
                    casingRight: 5,
                    casingHead: 5,
                    panelCount: 1,
                    handing: .left
                )
            }
            segment.opening?.category = .door
            if segment.opening?.doorStyle == nil {
                segment.opening?.doorStyle = .single
            }
            
        case .opening:
            if segment.opening == nil {
                segment.opening = OpeningSpec(
                    category: .generic,
                    windowStyle: nil,
                    doorStyle: nil,
                    openingWidth: 36,
                    openingHeight: 80,
                    sillOrBottomAFF: 0,
                    casingLeft: 0,
                    casingRight: 0,
                    casingHead: 0
                )
            }
            segment.opening?.category = .generic
            
        default:
            segment.opening = nil
        }
    }
    
    private func normalizeOpening() {
        guard segment.opening != nil else { return }
        
        switch openingCategoryBinding.wrappedValue {
        case .window:
            segment.kind = .windowUnit
            segment.opening?.doorStyle = nil
            if segment.opening?.windowStyle == nil {
                segment.opening?.windowStyle = .picture
            }
            
        case .door:
            segment.kind = .door
            segment.opening?.windowStyle = nil
            if segment.opening?.doorStyle == nil {
                segment.opening?.doorStyle = .single
            }
            
        case .generic:
            segment.kind = .opening
            segment.opening?.windowStyle = nil
            segment.opening?.doorStyle = nil
        }
    }
    
    private var shelfCountBinding: Binding<Int> {
        Binding(
            get: { segment.shelfCount ?? 5 },
            set: { segment.shelfCount = $0 }
        )
    }
    
    private var floorToCeilingBinding: Binding<Bool> {
        Binding(
            get: { segment.isFloorToCeiling ?? true },
            set: { segment.isFloorToCeiling = $0 }
        )
    }
    
    private var shelfDepthBinding: Binding<Double> {
        Binding(
            get: { segment.shelfDepth ?? 12 },
            set: { segment.shelfDepth = $0 }
        )
    }
    
    private var shelfThicknessBinding: Binding<Double> {
        Binding(
            get: { segment.shelfThickness ?? 1.5 },
            set: { segment.shelfThickness = $0 }
        )
    }
    
    private var sharedCornerBinding: Binding<Bool> {
        Binding(
            get: { segment.isSharedCorner ?? false },
            set: { segment.isSharedCorner = $0 }
        )
    }
    
    private var shelfWidthBinding: Binding<Double> {
        Binding(
            get: { segment.width },
            set: { segment.width = $0 }
        )
    }
    
    private var shelfSpacedEvenlyBinding: Binding<Bool> {
        Binding(
            get: { segment.shelfSpacedEvenly ?? true },
            set: { segment.shelfSpacedEvenly = $0 }
        )
    }
    
    private var beamPositionBinding: Binding<BeamPosition> {
        Binding(
            get: { segment.beamPosition ?? .onTopOfColumns },
            set: { segment.beamPosition = $0 }
        )
    }
    
    private var wallVariantBinding: Binding<WallVariant> {
        Binding(
            get: { segment.wallVariant ?? .full },
            set: { segment.wallVariant = $0 }
        )
    }
    
    private var kneeWallHeightBinding: Binding<Double> {
        Binding(
            get: { segment.kneeWallHeight ?? 42 },
            set: { segment.kneeWallHeight = $0 }
        )
    }
    
    private var cathedralPeakHeightBinding: Binding<Double> {
        Binding(
            get: { segment.cathedralPeakHeight ?? 120 },
            set: { segment.cathedralPeakHeight = $0 }
        )
    }
    
    private var cathedralPeakOffsetBinding: Binding<Double> {
        Binding(
            get: { segment.cathedralPeakOffset ?? (segment.width / 2) },
            set: { segment.cathedralPeakOffset = $0 }
        )
    }
    
    private var archRiseBinding: Binding<Double> {
        Binding(
            get: { segment.archRise ?? 24 },
            set: { segment.archRise = $0 }
        )
    }
    
    private func openingDoubleBinding(_ keyPath: WritableKeyPath<OpeningSpec, Double>, fallback: Double = 0) -> Binding<Double> {
        Binding(
            get: { segment.opening?[keyPath: keyPath] ?? fallback },
            set: { newValue in
                if segment.opening == nil { handleKindChange(segment.kind) }
                segment.opening?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func openingIntBinding(_ keyPath: WritableKeyPath<OpeningSpec, Int>, fallback: Int = 0) -> Binding<Int> {
        Binding(
            get: { segment.opening?[keyPath: keyPath] ?? fallback },
            set: { newValue in
                if segment.opening == nil { handleKindChange(segment.kind) }
                segment.opening?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func openingBoolBinding(_ keyPath: WritableKeyPath<OpeningSpec, Bool>) -> Binding<Bool> {
        Binding(
            get: { segment.opening?[keyPath: keyPath] ?? false },
            set: { newValue in
                if segment.opening == nil { handleKindChange(segment.kind) }
                segment.opening?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func openingStringBinding(_ keyPath: WritableKeyPath<OpeningSpec, String>) -> Binding<String> {
        Binding(
            get: { segment.opening?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if segment.opening == nil { handleKindChange(segment.kind) }
                segment.opening?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private var openingCategoryBinding: Binding<OpeningCategory> {
        Binding(
            get: { segment.opening?.category ?? .window },
            set: {
                if segment.opening == nil { handleKindChange(.windowUnit) }
                segment.opening?.category = $0
            }
        )
    }
    
    private var windowStyleBinding: Binding<WindowStyle?> {
        Binding(
            get: { segment.opening?.windowStyle ?? .picture },
            set: {
                if segment.opening == nil { handleKindChange(.windowUnit) }
                segment.opening?.windowStyle = $0
            }
        )
    }
    
    private var doorStyleBinding: Binding<DoorStyle?> {
        Binding(
            get: { segment.opening?.doorStyle ?? .single },
            set: {
                if segment.opening == nil { handleKindChange(.door) }
                segment.opening?.doorStyle = $0
            }
        )
    }
    
    private var handingBinding: Binding<OpeningHanding> {
        Binding(
            get: { segment.opening?.handing ?? .none },
            set: {
                if segment.opening == nil { handleKindChange(.door) }
                segment.opening?.handing = $0
            }
        )
    }
    
    private var frameMaterialBinding: Binding<WindowFrameMaterial> {
        Binding(
            get: { segment.opening?.frameMaterial ?? .wood },
            set: {
                if segment.opening == nil { handleKindChange(.windowUnit) }
                segment.opening?.frameMaterial = $0
            }
        )
    }
    
    private var glazingBinding: Binding<WindowGlazing> {
        Binding(
            get: { segment.opening?.glazing ?? .double },
            set: {
                if segment.opening == nil { handleKindChange(.windowUnit) }
                segment.opening?.glazing = $0
            }
        )
    }
    
    private var openingWidthBinding: Binding<Double> { openingDoubleBinding(\.openingWidth) }
    private var openingHeightBinding: Binding<Double> { openingDoubleBinding(\.openingHeight) }
    private var openingBottomBinding: Binding<Double> { openingDoubleBinding(\.sillOrBottomAFF) }
    private var thresholdHeightBinding: Binding<Double> { openingDoubleBinding(\.thresholdHeight) }
    private var projectionDepthBinding: Binding<Double> { openingDoubleBinding(\.projectionDepth) }
    
    private var casingLeftBinding: Binding<Double> { openingDoubleBinding(\.casingLeft) }
    private var casingRightBinding: Binding<Double> { openingDoubleBinding(\.casingRight) }
    private var casingHeadBinding: Binding<Double> { openingDoubleBinding(\.casingHead) }
    private var casingBottomBinding: Binding<Double> { openingDoubleBinding(\.casingBottom, fallback: 3) }
    private var casingWidthBinding: Binding<Double> { openingDoubleBinding(\.casingWidth) }
    private var topCasingIsCrownBinding: Binding<Bool> { openingBoolBinding(\.topCasingIsCrown) }
    private var wallSpaceAboveUnitBinding: Binding<Double> { openingDoubleBinding(\.wallSpaceAboveUnit) }
    
    private var panelCountBinding: Binding<Int> { openingIntBinding(\.panelCount, fallback: 1) }
    private var mullionsVerticalBinding: Binding<Int> { openingIntBinding(\.mullionsVertical) }
    private var mullionsHorizontalBinding: Binding<Int> { openingIntBinding(\.mullionsHorizontal) }
    private var mullionWidthBinding: Binding<Double> { openingDoubleBinding(\.mullionWidth) }
    
    private var mullionLayoutPresetBinding: Binding<MullionLayoutPreset> {
        Binding(
            get: { segment.opening?.mullionLayoutPreset ?? .grid },
            set: { newValue in
                guard var opening = segment.opening else { return }
                opening.mullionLayoutPreset = newValue
                segment.opening = opening
            }
        )
    }
    
    private func applyMullionLayoutPreset(_ preset: MullionLayoutPreset) {
        guard var opening = segment.opening else { return }
        switch preset {
        case .grid:
            // Auto-set vertical mullions to (panels - 1), horizontal to 0
            opening.mullionsVertical = max(0, opening.panelCount - 1)
        case .none:
            opening.mullionsVertical = 0
            opening.mullionsHorizontal = 0
        case .custom:
            // Leave user-set values alone
            break
        }
        opening.mullionLayoutPreset = preset
        segment.opening = opening
    }
    
    private var muntinsRowsBinding: Binding<Int> { openingIntBinding(\.muntinsRows) }
    private var muntinsColsBinding: Binding<Int> { openingIntBinding(\.muntinsCols) }
    private var muntinWidthBinding: Binding<Double> { openingDoubleBinding(\.muntinWidth) }
    
    private var frameWidthBinding: Binding<Double> { openingDoubleBinding(\.frameWidth) }
    private var jambDepthBinding: Binding<Double> { openingDoubleBinding(\.jambDepth) }
    private var sillProjectionBinding: Binding<Double> { openingDoubleBinding(\.sillProjection) }
    private var interiorStoolProjectionBinding: Binding<Double> { openingDoubleBinding(\.interiorStoolProjection) }
    private var apronHeightBinding: Binding<Double> { openingDoubleBinding(\.apronHeight) }
    
    private var isEgressBinding: Binding<Bool> { openingBoolBinding(\.isEgress) }
    private var hasScreensBinding: Binding<Bool> { openingBoolBinding(\.hasScreens) }
    private var uFactorBinding: Binding<Double> { openingDoubleBinding(\.uFactor) }
    private var shgcBinding: Binding<Double> { openingDoubleBinding(\.shgc) }
    private var manufacturerBinding: Binding<String> { openingStringBinding(\.manufacturer) }
    private var modelNumberBinding: Binding<String> { openingStringBinding(\.modelNumber) }
    
    private var openingTopBinding: Binding<Double> {
        Binding(
            get: {
                let opening = segment.opening
                return (opening?.sillOrBottomAFF ?? 0) + (opening?.openingHeight ?? 0)
            },
            set: { _ in }
        )
    }
    
    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
    
    // MARK: - Panels editor helpers
    
    private var openingNotesBinding: Binding<String> { openingStringBinding(\.notes) }
    
    private var availablePanelWidth: Double {
        guard let opening = segment.opening else { return 0 }
        let mullionSpace = Double(opening.mullionsVertical) * opening.mullionWidth
        return max(0, opening.openingWidth - mullionSpace)
    }
    
    private var sumOfShares: Double {
        guard let opening = segment.opening else { return 0 }
        return opening.panels.reduce(0) { $0 + $1.widthShare }
    }
    
    private var leafConfigurationSummary: String {
        guard let style = segment.opening?.doorStyle else { return "—" }
        switch style {
        case .single, .pocket, .barn, .cased, .sliding: return "1 leaf"
        case .double, .french: return "2 leaves"
        case .bifold: return "2–4 folding leaves"
        case .dutch: return "2 stacked leaves"
        }
    }
    
    private func panelLabel(at index: Int) -> String {
        guard let opening = segment.opening else { return "P\(index + 1)" }
        guard opening.panels.indices.contains(index) else { return "P\(index + 1)" }
        let label = opening.panels[index].label
        return label.isEmpty ? "P\(index + 1)" : label
    }
    
    private func seamBinding(at index: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard let opening = segment.opening else { return true }
                if opening.mullionSeams.indices.contains(index) {
                    return opening.mullionSeams[index]
                }
                return true
            },
            set: { newValue in
                guard var opening = segment.opening else { return }
                // Ensure seams array is sized correctly before writing
                let seamsTarget = max(0, opening.panelCount - 1)
                while opening.mullionSeams.count < seamsTarget {
                    opening.mullionSeams.append(true)
                }
                if opening.mullionSeams.count > seamsTarget {
                    opening.mullionSeams = Array(opening.mullionSeams.prefix(seamsTarget))
                }
                if opening.mullionSeams.indices.contains(index) {
                    opening.mullionSeams[index] = newValue
                }
                segment.opening = opening
            }
        )
    }
    
    private func syncPanelsArray() {
        guard var opening = segment.opening else { return }
        let target = max(1, opening.panelCount)
        
        if opening.panels.count != target {
            if opening.panels.count < target {
                let toAdd = target - opening.panels.count
                // Seed new panels with an even split of available width so widths read as inches out of the box.
                let evenWidth = availablePanelWidth / Double(target)
                for i in 0..<toAdd {
                    let existingCount = opening.panels.count
                    opening.panels.append(WindowPanel(
                        label: defaultPanelLabel(index: existingCount + i, total: target),
                        widthShare: evenWidth > 0 ? evenWidth : 1,
                        operation: .fixed,
                        hasMuntinGrid: true
                    ))
                }
            } else {
                opening.panels = Array(opening.panels.prefix(target))
            }
            // Relabel to keep labels sensible for the current total
            for i in 0..<opening.panels.count {
                if opening.panels[i].label.isEmpty {
                    opening.panels[i].label = defaultPanelLabel(index: i, total: opening.panels.count)
                }
            }
        }
        
        // Sync seams array to (panelCount - 1). Preserve existing seam values.
        // If the seams array is empty (legacy data), initialize from the old adjacency rule:
        // seam i is On only if both panel i and panel i+1 had hasMullions == true.
        let seamsTarget = max(0, target - 1)
        if opening.mullionSeams.isEmpty && seamsTarget > 0 {
            var initial: [Bool] = []
            for i in 0..<seamsTarget {
                if opening.panels.indices.contains(i) && opening.panels.indices.contains(i + 1) {
                    let a = opening.panels[i].hasMullions
                    let b = opening.panels[i + 1].hasMullions
                    initial.append(a && b)
                } else {
                    initial.append(true)
                }
            }
            opening.mullionSeams = initial
        } else if opening.mullionSeams.count < seamsTarget {
            let toAdd = seamsTarget - opening.mullionSeams.count
            opening.mullionSeams.append(contentsOf: Array(repeating: true, count: toAdd))
        } else if opening.mullionSeams.count > seamsTarget {
            opening.mullionSeams = Array(opening.mullionSeams.prefix(seamsTarget))
        }
        
        segment.opening = opening
    }
    
    private func defaultPanelLabel(index: Int, total: Int) -> String {
        switch total {
        case 1: return "P1"
        case 2: return index == 0 ? "L" : "R"
        case 3:
            switch index {
            case 0: return "L"
            case 1: return "C"
            default: return "R"
            }
        default: return "P\(index + 1)"
        }
    }
    
    private func distributePanelsEqually() {
        guard var opening = segment.opening else { return }
        let count = opening.panels.count
        guard count > 0 else { return }
        let each = availablePanelWidth / Double(count)
        for i in 0..<count {
            opening.panels[i].widthShare = each
        }
        segment.opening = opening
    }
    
    private func resetPanels() {
        guard var opening = segment.opening else { return }
        opening.panels = []
        segment.opening = opening
        syncPanelsArray()
    }
    
    private func panelBinding(at index: Int) -> Binding<WindowPanel> {
        Binding(
            get: {
                let panels = segment.opening?.panels ?? []
                if panels.indices.contains(index) {
                    return panels[index]
                }
                return WindowPanel()
            },
            set: { newValue in
                guard var opening = segment.opening else { return }
                if opening.panels.indices.contains(index) {
                    opening.panels[index] = newValue
                    segment.opening = opening
                }
            }
        )
    }
    
    private func resolvedPanelInches(at index: Int) -> Double {
        guard let opening = segment.opening else { return 0 }
        guard opening.panels.indices.contains(index) else { return 0 }
        let share = opening.panels[index].widthShare
        let total = sumOfShares
        guard total > 0 else { return 0 }
        return availablePanelWidth * (share / total)
    }
}

// MARK: - Mullion Seam Row

struct MullionSeamRow: View {
    let seamIndex: Int
    let panelLabelLeft: String
    let panelLabelRight: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Seam \(seamIndex + 1)")
                    .font(.callout.weight(.semibold))
                Text("Between \(panelLabelLeft) and \(panelLabelRight)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isOn.toggle()
            } label: {
                Text(isOn ? "Mullion On" : "Mullion Off")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isOn ? Color.purple : Color.gray)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Panel Editor Row (extracted subview to reduce type-checker load)

struct PanelEditorRow: View {
    let index: Int
    @Binding var panel: WindowPanel
    let resolvedInches: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Panel \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(String(format: "%.2f", resolvedInches))\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            StepperFieldRow(title: "Width (in)", value: $panel.widthShare, step: 1)
            
            Button {
                panel.hasMuntinGrid.toggle()
            } label: {
                Text(panel.hasMuntinGrid ? "Grid On" : "Grid Off")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(panel.hasMuntinGrid ? Color.green : Color.gray)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stepper Int Field Row

struct StepperIntFieldRow: View {
    let title: String
    @Binding var value: Int
    var step: Int = 1
    var minimum: Int = 0
    var maximum: Int = 999
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            
            Spacer()
            
            Button {
                commitText()
                value = max(minimum, value - step)
                syncFromValue()
            } label: {
                Image(systemName: "minus.square.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrease \(title)")
            
            TextField(title, text: $textValue)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onAppear { syncFromValue() }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commitText() }
                }
            
            Button {
                commitText()
                value = min(maximum, value + step)
                syncFromValue()
            } label: {
                Image(systemName: "plus.square.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Increase \(title)")
        }
    }
    
    private func syncFromValue() {
        textValue = String(value)
    }
    
    private func commitText() {
        let cleaned = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if let parsed = Int(cleaned) {
            value = min(maximum, max(minimum, parsed))
        }
        syncFromValue()
    }
}
