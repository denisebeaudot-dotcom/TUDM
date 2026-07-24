import SwiftUI

// MARK: - Drafts

struct ProjectDraft: Hashable {
    var name: String = ""
    var clientName: String = ""
    var location: String = ""
    var notes: String = ""
    
    init() {}
    
    init(project: Project) {
        self.name = project.name
        self.clientName = project.clientName
        self.location = project.location
        self.notes = project.notes
    }
}

struct RoomDraft: Hashable {
    var name: String = ""
    var notes: String = ""
    var defaults: RoomDefaults = .rgrstDefaults
    
    init() {}
    
    init(room: Room) {
        self.name = room.name
        self.notes = room.notes
        self.defaults = room.defaults
    }
}

struct WallDraft: Hashable {
    var name: String = ""
    var totalWidth: Double = 246
    var ruleSet: String = "RGRST"
    var notes: String = ""
    var useSeedSegments: Bool = false
    var usesOverrides: Bool = false
    var overrides: RoomDefaults = .rgrstDefaults
    var chainString: String = ""
    var verticalChainString: String = ""
    var generatedSegments: [WallSegment] = []
    
    init() {}
    
    init(wall: WallSpec, roomDefaults: RoomDefaults) {
        self.name = wall.name
        self.totalWidth = wall.totalWidth
        self.ruleSet = wall.ruleSet
        self.notes = wall.notes
        self.useSeedSegments = false
        self.usesOverrides = wall.usesOverrides
        self.overrides = wall.overrides ?? roomDefaults
        self.chainString = wall.chainString
        self.verticalChainString = wall.verticalChainString
        self.generatedSegments = wall.segments
    }
    
    var resolvedSegments: [WallSegment] {
        if !generatedSegments.isEmpty { return generatedSegments }
        if useSeedSegments { return WallSegment.wallOneSeedSegments }
        if !chainString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return WallSegment.parseChain(chainString)
        }
        return []
    }
}

// MARK: - Beam Range Helpers

enum BeamRangeAFFHelper {
    static func parseBottom(_ raw: String) -> Double {
        let firstToken = raw
            .split(whereSeparator: { $0 == "-" || $0 == " " || $0 == "\u{2013}" })
            .first
            .map(String.init) ?? ""
        let cleaned = firstToken
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned) ?? 0
    }
    
    static func format(bottom: Double, beamHeight: Double) -> String {
        let b = max(0, bottom)
        let t = b + max(0, beamHeight)
        return String(format: "%.2f-%.2f", b, t)
    }
}

// MARK: - Project Form

struct ProjectFormView: View {
    enum Mode {
        case create
        case edit(Project)
        
        var title: String {
            switch self {
            case .create: return "New Project"
            case .edit: return "Edit Project"
            }
        }
    }
    
    let mode: Mode
    let onSave: (ProjectDraft) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProjectDraft
    
    init(mode: Mode, onSave: @escaping (ProjectDraft) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        switch mode {
        case .create:
            _draft = State(initialValue: ProjectDraft())
        case .edit(let project):
            _draft = State(initialValue: ProjectDraft(project: project))
        }
    }
    
    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project Name", text: $draft.name)
                    TextField("Client Name", text: $draft.clientName)
                    TextField("Location", text: $draft.location)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Room Form

struct RoomFormView: View {
    enum Mode {
        case create(projectID: UUID)
        case edit(projectID: UUID, room: Room)
        
        var title: String {
            switch self {
            case .create: return "New Room"
            case .edit: return "Edit Room"
            }
        }
    }
    
    let mode: Mode
    let onSave: (RoomDraft) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RoomDraft
    
    init(mode: Mode, onSave: @escaping (RoomDraft) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        switch mode {
        case .create:
            _draft = State(initialValue: RoomDraft())
        case .edit(_, let room):
            _draft = State(initialValue: RoomDraft(room: room))
        }
    }
    
    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var beamBottomBinding: Binding<Double> {
        Binding(
            get: { BeamRangeAFFHelper.parseBottom(draft.defaults.beamRangeAFF) },
            set: { newBottom in
                draft.defaults.beamRangeAFF = BeamRangeAFFHelper.format(
                    bottom: newBottom,
                    beamHeight: draft.defaults.beamHeight
                )
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Room") {
                    TextField("Room Name", text: $draft.name)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section("Defaults") {
                    StepperFieldRow(title: "Ceiling Height", value: $draft.defaults.ceilingHeight, step: 1)
                    StepperFieldRow(title: "Crown Height", value: $draft.defaults.crownHeight, step: 0.5)
                    StepperFieldRow(title: "Baseboard Height", value: $draft.defaults.baseboardHeight, step: 0.5)
                    StepperFieldRow(title: "Beam Height", value: $draft.defaults.beamHeight, step: 1)
                    
                    StepperFieldRow(title: "Beam Bottom AFF", value: beamBottomBinding, step: 1)
                    
                    LabeledContent("Beam Range AFF", value: draft.defaults.beamRangeAFF.isEmpty ? "—" : draft.defaults.beamRangeAFF)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    StepperFieldRow(title: "Column Width", value: $draft.defaults.columnWidth, step: 0.5)
                    StepperFieldRow(title: "Column Depth", value: $draft.defaults.columnDepth, step: 0.5)
                    StepperFieldRow(title: "Column Height", value: $draft.defaults.columnHeight, step: 1)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Room Defaults Form

struct RoomDefaultsFormView: View {
    let initialDefaults: RoomDefaults
    let onSave: (RoomDefaults) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var defaults: RoomDefaults
    
    init(initialDefaults: RoomDefaults, onSave: @escaping (RoomDefaults) -> Void) {
        self.initialDefaults = initialDefaults
        self.onSave = onSave
        _defaults = State(initialValue: initialDefaults)
    }
    
    private var beamBottomBinding: Binding<Double> {
        Binding(
            get: { BeamRangeAFFHelper.parseBottom(defaults.beamRangeAFF) },
            set: { newBottom in
                defaults.beamRangeAFF = BeamRangeAFFHelper.format(
                    bottom: newBottom,
                    beamHeight: defaults.beamHeight
                )
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Structure Defaults") {
                    StepperFieldRow(title: "Ceiling Height", value: $defaults.ceilingHeight, step: 1)
                    StepperFieldRow(title: "Crown Height", value: $defaults.crownHeight, step: 0.5)
                    StepperFieldRow(title: "Baseboard Height", value: $defaults.baseboardHeight, step: 0.5)
                    StepperFieldRow(title: "Beam Height", value: $defaults.beamHeight, step: 1)
                    
                    StepperFieldRow(title: "Beam Bottom AFF", value: beamBottomBinding, step: 1)
                    
                    LabeledContent("Beam Range AFF", value: defaults.beamRangeAFF.isEmpty ? "—" : defaults.beamRangeAFF)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    StepperFieldRow(title: "Column Width", value: $defaults.columnWidth, step: 0.5)
                    StepperFieldRow(title: "Column Depth", value: $defaults.columnDepth, step: 0.5)
                    StepperFieldRow(title: "Column Height", value: $defaults.columnHeight, step: 1)
                }
            }
            .navigationTitle("Edit Defaults")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(defaults)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Stepper Field Row (default numeric input for all forms)

struct StepperFieldRow: View {
    let title: String
    @Binding var value: Double
    var step: Double = 1
    var minimum: Double = 0
    var maximum: Double = 9999
    
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
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onAppear { syncFromValue() }
                .onChange(of: value) { _, _ in
                    if !isFocused { syncFromValue() }
                }
                .onChange(of: textValue) { _, _ in
                    commitTextLive()
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
                    .font(.title2)
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
    
    private func commitTextLive() {
        let cleaned = textValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let parsed = Double(cleaned) {
            value = min(maximum, max(minimum, parsed))
        }
    }
}
