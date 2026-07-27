import SwiftUI

// MARK: - DesignPhase
//
// Twelve-phase interior design workflow, grouped into four blocks.
// Order and grouping match the process Denise laid out:
//
//   GROUNDWORK
//     1. Client's Needs
//     2. Site Study
//     3. Furniture (Needs, Circulation, Arrangement — combined here)
//     4. Lighting
//   DESIGN
//     5. Style
//     6. Mood
//     7. Palette
//   WORKBOARDS
//     8. Mood Board
//     9. Elevations
//    10. Materials
//   EXECUTION
//    11. DIY Plan
//    12. Source List
//
// Some phases route to already-built screens (Client's Needs → PersonaPickerView,
// Style → StylePickerView). Everything else opens PhasePlaceholderView which
// shows the phase description plus a free-text notes field saved on the Project.

enum DesignPhaseBlock: String, CaseIterable, Identifiable {
    case groundwork = "Groundwork"
    case design     = "Design"
    case workboards = "Workboards"
    case execution  = "Execution"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .groundwork: return "square.stack.3d.up"
        case .design:     return "paintpalette"
        case .workboards: return "rectangle.on.rectangle"
        case .execution:  return "checkmark.seal"
        }
    }
}

enum DesignPhase: String, CaseIterable, Identifiable, Hashable {
    // Groundwork
    case clientsNeeds       = "clients_needs"
    case siteStudy          = "site_study"
    case furniture          = "furniture"
    case lighting           = "lighting"
    // Design
    case style              = "style"
    case mood               = "mood"
    case palette            = "palette"
    // Workboards
    case moodBoard          = "mood_board"
    case elevations         = "elevations"
    case materials          = "materials"
    // Execution
    case diyPlan            = "diy_plan"
    case sourceList         = "source_list"
    
    var id: String { rawValue }
    
    var block: DesignPhaseBlock {
        switch self {
        case .clientsNeeds, .siteStudy, .furniture, .lighting:
            return .groundwork
        case .style, .mood, .palette:
            return .design
        case .moodBoard, .elevations, .materials:
            return .workboards
        case .diyPlan, .sourceList:
            return .execution
        }
    }
    
    var number: Int {
        switch self {
        case .clientsNeeds: return 1
        case .siteStudy:    return 2
        case .furniture:    return 3
        case .lighting:     return 4
        case .style:        return 5
        case .mood:         return 6
        case .palette:      return 7
        case .moodBoard:    return 8
        case .elevations:   return 9
        case .materials:    return 10
        case .diyPlan:      return 11
        case .sourceList:   return 12
        }
    }
    
    var title: String {
        switch self {
        case .clientsNeeds: return "Client's Needs"
        case .siteStudy:    return "Site Study"
        case .furniture:    return "Furniture"
        case .lighting:     return "Lighting"
        case .style:        return "Style"
        case .mood:         return "Mood"
        case .palette:      return "Palette"
        case .moodBoard:    return "Mood Board"
        case .elevations:   return "Elevations"
        case .materials:    return "Materials"
        case .diyPlan:      return "DIY Plan"
        case .sourceList:   return "Source List"
        }
    }
    
    var subtitle: String {
        switch self {
        case .clientsNeeds:
            return "Persona, household size, activities, desired emotional read."
        case .siteStudy:
            return "Chain elevations of every wall, floorplan, views, light levels."
        case .furniture:
            return "Needs vs activities, circulation, three placeholder arrangements."
        case .lighting:
            return "Lighting placement plan built from site study."
        case .style:
            return "Family + Muse + Moods + overrides."
        case .mood:
            return "Emotional tone the room should convey."
        case .palette:
            return "Primary, secondary, accent, neutral, wood, metal."
        case .moodBoard:
            return "Precedent images and atmosphere reference."
        case .elevations:
            return "Rendered elevations of each wall with materials."
        case .materials:
            return "Physical and digital material references."
        case .diyPlan:
            return "What the owner builds or installs themselves."
        case .sourceList:
            return "Where every piece and finish comes from."
        }
    }
    
    var longDescription: String {
        switch self {
        case .clientsNeeds:
            return """
                Define who lives or works in this room and what they want to do here. \
                For fantasy projects, invent a persona (archetype, era, traits, biography). \
                For real projects, capture actual users, household size, and every activity \
                the room must support. Finish by writing the emotional read the room should give.
                """
        case .siteStudy:
            return """
                Document the space as it actually is. Every wall gets a chain-dimensioned \
                elevation. Add floorplan and any other useful views (RCP, sections). \
                Note natural light levels through the day and existing electrical.
                """
        case .furniture:
            return """
                Three passes in order:
                
                1. Needs — walk through every activity from Client's Needs and verify each \
                   has furniture that supports it.
                
                2. Circulation — draw circulation paths, sightlines, and collision lines. \
                   Anchored to site study.
                
                3. Arrangement — three placeholder layouts, adhering strictly to \
                   arrangement rules. No detail styling yet.
                """
        case .lighting:
            return """
                Layer the lighting plan on the site study: ambient, task, accent, and \
                decorative. Note fixture locations, switching, and dimming needs.
                """
        case .style:
            return """
                Pick the aesthetic family, muse, and moods. Style is built from \
                Client's Needs — the persona and desired emotional read drive it.
                """
        case .mood:
            return """
                What should this room feel like at 7am, at 4pm, at 10pm? Capture \
                temperature, energy level, and register (formal, easy, austere, generous).
                """
        case .palette:
            return """
                Primary, secondary, accent, neutral, wood tone, and metal finish. \
                Anchored to Style but written out as a standalone reference for procurement.
                """
        case .moodBoard:
            return """
                Precedent images and atmosphere reference. Not a materials board — \
                the goal is to communicate feel, not spec sheets.
                """
        case .elevations:
            return """
                Rendered elevations of every wall, blending the locked structural \
                blueprint with the Style DNA and Persona through the photoreal pipeline.
                """
        case .materials:
            return """
                Physical swatches and digital reference for every finish, textile, and \
                hardware selection. One entry per material.
                """
        case .diyPlan:
            return """
                Anything the owner or contractor builds or installs themselves. \
                Sequence, dependencies, tools, materials.
                """
        case .sourceList:
            return """
                Where every piece and finish comes from. Vendor, SKU, price, lead time, \
                and status.
                """
        }
    }
    
    /// If the phase already has a built-out screen elsewhere in the app, describe it here.
    /// Otherwise nil means we route to the placeholder view.
    var routesTo: PhaseRoute {
        switch self {
        case .clientsNeeds: return .personaPicker
        case .style:        return .stylePicker
        default:            return .placeholder
        }
    }
}

enum PhaseRoute {
    case personaPicker
    case stylePicker
    case placeholder
}

// MARK: - DesignProcessView

struct DesignProcessView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    
    let projectID: UUID
    
    private var project: Project? {
        store.projects.first(where: { $0.id == projectID })
    }
    
    var body: some View {
        Group {
            if let project {
                List {
                    ForEach(DesignPhaseBlock.allCases) { block in
                        Section {
                            ForEach(DesignPhase.allCases.filter { $0.block == block }) { phase in
                                PhaseRow(
                                    project: project,
                                    projectID: projectID,
                                    phase: phase
                                )
                            }
                        } header: {
                            Label(block.rawValue.uppercased(), systemImage: block.iconName)
                                .font(.footnote.weight(.semibold))
                        }
                    }
                }
                .navigationTitle("Design Process")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            } else {
                ContentUnavailableView(
                    "Project Not Found",
                    systemImage: "questionmark.folder",
                    description: Text("This project no longer exists.")
                )
            }
        }
    }
}

// MARK: - PhaseRow

private struct PhaseRow: View {
    let project: Project
    let projectID: UUID
    let phase: DesignPhase
    
    private var storedNote: String {
        project.phaseNotes?[phase.rawValue] ?? ""
    }
    
    private var hasNote: Bool {
        !storedNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(String(format: "%02d", phase.number))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 26, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(phase.title)
                            .font(.headline)
                        
                        if phase.routesTo != .placeholder {
                            Text("live")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        
                        if hasNote {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(phase.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var destination: some View {
        switch phase.routesTo {
        case .personaPicker:
            PersonaPickerView()
                .navigationTitle(phase.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        case .stylePicker:
            StylePickerView()
                .navigationTitle(phase.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        case .placeholder:
            PhasePlaceholderView(projectID: projectID, phase: phase)
        }
    }
}

// MARK: - PhasePlaceholderView

struct PhasePlaceholderView: View {
    @Environment(InteriorAuthorityStore.self) private var store
    
    let projectID: UUID
    let phase: DesignPhase
    
    @State private var noteDraft: String = ""
    @State private var loaded: Bool = false
    
    private var project: Project? {
        store.projects.first(where: { $0.id == projectID })
    }
    
    var body: some View {
        Form {
            Section("About This Phase") {
                Text(phase.longDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Section("Status") {
                LabeledContent("Phase", value: "\(phase.number) of 12")
                LabeledContent("Block", value: phase.block.rawValue)
                LabeledContent("Screen", value: "Placeholder (notes only for now)")
            }
            
            Section("Notes") {
                TextEditor(text: $noteDraft)
                    .frame(minHeight: 180)
                    .textInputAutocapitalization(.sentences)
                
                HStack {
                    Button("Save Note") {
                        store.setPhaseNote(
                            projectID: projectID,
                            phaseKey: phase.rawValue,
                            note: noteDraft
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Clear", role: .destructive) {
                        noteDraft = ""
                        store.setPhaseNote(
                            projectID: projectID,
                            phaseKey: phase.rawValue,
                            note: ""
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(phase.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            guard !loaded else { return }
            noteDraft = project?.phaseNotes?[phase.rawValue] ?? ""
            loaded = true
        }
    }
}
