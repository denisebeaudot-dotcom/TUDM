import Foundation

struct EditableOpening: Identifiable, Codable {

    var id = UUID()

    var name = ""
    var type = "Window"

    var width = ""
    var height = ""
    var bottomAFF = "0"
    var startX = ""
    var notes = ""

    var placement = "Centered"
    var referenceStructureStart = ""
    var referenceStructureEnd = ""
    var offsetDirection = "None"
    var offsetDistance = ""

    var structureAboveType = "None"
    var structureAboveHeight = ""
    var structureAboveProjection = ""
    var structureAboveNotes = ""

    var structureBelowType = "None"
    var structureBelowHeight = ""
    var structureBelowDepth = ""
    var structureBelowNotes = ""

    var windowType = "Picture Window"
    var windowAssembly = "Single Section"
    var sectionCount = 1

    var leftSectionWidth = ""
    var centerSectionWidth = ""
    var rightSectionWidth = ""

    var mullionCount = 0
    var mullionWidth = ""
    var muntinPattern = ""

    var sillHeight = ""
    var sillDepth = ""

    var casingWidth = ""
    var returnDepth = ""
    var headerHeight = ""
    var crownMoldingHeight = ""
    var trimFinish = ""

    var doorType = "Single Door"
    var doorLeafWidth = ""
    var doorLeafHeight = ""
    var doorCasingWidth = ""
    var doorHeaderHeight = ""
    var doorHingeSide = "Left"
    var doorSwingDirection = "Into Room"
    var doorSwingAngle = ""

    var stepCount = 0
    var stepDirection = "Up"
    var riserHeight = ""
    var treadDepth = ""
    var firstStepInset = ""

    private enum CodingKeys: String, CodingKey {
        case id, name, type, width, height, bottomAFF, startX, notes
        case placement, referenceStructureStart, referenceStructureEnd
        case offsetDirection, offsetDistance
        case structureAboveType, structureAboveHeight
        case structureAboveProjection, structureAboveNotes
        case structureBelowType, structureBelowHeight
        case structureBelowDepth, structureBelowNotes
        case windowType, windowAssembly, sectionCount
        case leftSectionWidth, centerSectionWidth, rightSectionWidth
        case mullionCount, mullionWidth, muntinPattern
        case sillHeight, sillDepth, casingWidth, returnDepth
        case headerHeight, crownMoldingHeight, trimFinish
        case doorType, doorLeafWidth, doorLeafHeight
        case doorCasingWidth, doorHeaderHeight
        case doorHingeSide, doorSwingDirection, doorSwingAngle
        case stepCount, stepDirection, riserHeight, treadDepth
        case firstStepInset
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Window"
        width = try container.decodeIfPresent(String.self, forKey: .width) ?? ""
        height = try container.decodeIfPresent(String.self, forKey: .height) ?? ""
        bottomAFF = try container.decodeIfPresent(String.self, forKey: .bottomAFF) ?? "0"
        startX = try container.decodeIfPresent(String.self, forKey: .startX) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""

        placement = try container.decodeIfPresent(String.self, forKey: .placement) ?? "Centered"
        referenceStructureStart = try container.decodeIfPresent(String.self, forKey: .referenceStructureStart) ?? ""
        referenceStructureEnd = try container.decodeIfPresent(String.self, forKey: .referenceStructureEnd) ?? ""
        offsetDirection = try container.decodeIfPresent(String.self, forKey: .offsetDirection) ?? "None"
        offsetDistance = try container.decodeIfPresent(String.self, forKey: .offsetDistance) ?? ""

        structureAboveType = try container.decodeIfPresent(String.self, forKey: .structureAboveType) ?? "None"
        structureAboveHeight = try container.decodeIfPresent(String.self, forKey: .structureAboveHeight) ?? ""
        structureAboveProjection = try container.decodeIfPresent(String.self, forKey: .structureAboveProjection) ?? ""
        structureAboveNotes = try container.decodeIfPresent(String.self, forKey: .structureAboveNotes) ?? ""

        structureBelowType = try container.decodeIfPresent(String.self, forKey: .structureBelowType) ?? "None"
        structureBelowHeight = try container.decodeIfPresent(String.self, forKey: .structureBelowHeight) ?? ""
        structureBelowDepth = try container.decodeIfPresent(String.self, forKey: .structureBelowDepth) ?? ""
        structureBelowNotes = try container.decodeIfPresent(String.self, forKey: .structureBelowNotes) ?? ""

        windowType = try container.decodeIfPresent(String.self, forKey: .windowType) ?? "Picture Window"
        windowAssembly = try container.decodeIfPresent(String.self, forKey: .windowAssembly) ?? "Single Section"
        sectionCount = try container.decodeIfPresent(Int.self, forKey: .sectionCount) ?? 1
        leftSectionWidth = try container.decodeIfPresent(String.self, forKey: .leftSectionWidth) ?? ""
        centerSectionWidth = try container.decodeIfPresent(String.self, forKey: .centerSectionWidth) ?? ""
        rightSectionWidth = try container.decodeIfPresent(String.self, forKey: .rightSectionWidth) ?? ""
        mullionCount = try container.decodeIfPresent(Int.self, forKey: .mullionCount) ?? 0
        mullionWidth = try container.decodeIfPresent(String.self, forKey: .mullionWidth) ?? ""
        muntinPattern = try container.decodeIfPresent(String.self, forKey: .muntinPattern) ?? ""
        sillHeight = try container.decodeIfPresent(String.self, forKey: .sillHeight) ?? ""
        sillDepth = try container.decodeIfPresent(String.self, forKey: .sillDepth) ?? ""
        casingWidth = try container.decodeIfPresent(String.self, forKey: .casingWidth) ?? ""
        returnDepth = try container.decodeIfPresent(String.self, forKey: .returnDepth) ?? ""
        headerHeight = try container.decodeIfPresent(String.self, forKey: .headerHeight) ?? ""
        crownMoldingHeight = try container.decodeIfPresent(String.self, forKey: .crownMoldingHeight) ?? ""
        trimFinish = try container.decodeIfPresent(String.self, forKey: .trimFinish) ?? ""

        doorType = try container.decodeIfPresent(String.self, forKey: .doorType) ?? "Single Door"
        doorLeafWidth = try container.decodeIfPresent(String.self, forKey: .doorLeafWidth) ?? ""
        doorLeafHeight = try container.decodeIfPresent(String.self, forKey: .doorLeafHeight) ?? ""
        doorCasingWidth = try container.decodeIfPresent(String.self, forKey: .doorCasingWidth) ?? ""
        doorHeaderHeight = try container.decodeIfPresent(String.self, forKey: .doorHeaderHeight) ?? ""
        doorHingeSide = try container.decodeIfPresent(String.self, forKey: .doorHingeSide) ?? "Left"
        doorSwingDirection = try container.decodeIfPresent(String.self, forKey: .doorSwingDirection) ?? "Into Room"
        doorSwingAngle = try container.decodeIfPresent(String.self, forKey: .doorSwingAngle) ?? ""

        stepCount = try container.decodeIfPresent(Int.self, forKey: .stepCount) ?? 0
        stepDirection = try container.decodeIfPresent(String.self, forKey: .stepDirection) ?? "Up"
        riserHeight = try container.decodeIfPresent(String.self, forKey: .riserHeight) ?? ""
        treadDepth = try container.decodeIfPresent(String.self, forKey: .treadDepth) ?? ""
        firstStepInset = try container.decodeIfPresent(String.self, forKey: .firstStepInset) ?? ""
    }
}

struct StoredColumnAuthority: Identifiable, Codable {

    var id = UUID()
    var name = ""
    var startX = ""
    var bottomAFF = "0"
    var width = ""
    var depth = ""
    var height = ""
    var finish = ""
}

struct StoredBeamAuthority: Identifiable, Codable {

    var id = UUID()
    var name = ""
    var type = "Perimeter Beam"
    var width = ""
    var height = ""
    var undersideHeight = ""
    var projection = ""
    var startPoint = ""
    var endPoint = ""
    var startX = ""
    var endX = ""
    var startColumn = ""
    var endColumn = ""
    var finish = ""
    var crownRelationship = "None"
    var decorativeConstraintNotes = ""

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case width
        case height
        case undersideHeight
        case projection
        case startPoint
        case endPoint
        case startX
        case endX
        case startColumn
        case endColumn
        case finish
        case crownRelationship
        case decorativeConstraintNotes
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        type: String = "Perimeter Beam",
        width: String = "",
        height: String = "",
        undersideHeight: String = "",
        projection: String = "",
        startPoint: String = "",
        endPoint: String = "",
        startX: String = "",
        endX: String = "",
        startColumn: String = "",
        endColumn: String = "",
        finish: String = "",
        crownRelationship: String = "None",
        decorativeConstraintNotes: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.width = width
        self.height = height
        self.undersideHeight = undersideHeight
        self.projection = projection
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startX = startX
        self.endX = endX
        self.startColumn = startColumn
        self.endColumn = endColumn
        self.finish = finish
        self.crownRelationship = crownRelationship
        self.decorativeConstraintNotes = decorativeConstraintNotes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Perimeter Beam"
        width = try container.decodeIfPresent(String.self, forKey: .width) ?? ""
        height = try container.decodeIfPresent(String.self, forKey: .height) ?? ""
        undersideHeight = try container.decodeIfPresent(String.self, forKey: .undersideHeight) ?? ""
        projection = try container.decodeIfPresent(String.self, forKey: .projection) ?? ""
        startPoint = try container.decodeIfPresent(String.self, forKey: .startPoint) ?? ""
        endPoint = try container.decodeIfPresent(String.self, forKey: .endPoint) ?? ""
        startX = try container.decodeIfPresent(String.self, forKey: .startX) ?? ""
        endX = try container.decodeIfPresent(String.self, forKey: .endX) ?? ""
        startColumn = try container.decodeIfPresent(String.self, forKey: .startColumn) ?? ""
        endColumn = try container.decodeIfPresent(String.self, forKey: .endColumn) ?? ""
        finish = try container.decodeIfPresent(String.self, forKey: .finish) ?? ""
        crownRelationship = try container.decodeIfPresent(String.self, forKey: .crownRelationship) ?? "None"
        decorativeConstraintNotes = try container.decodeIfPresent(String.self, forKey: .decorativeConstraintNotes) ?? ""
    }
}


struct StoredBuiltInAuthority: Identifiable, Codable {

    var id = UUID()
    var name = ""
    var type = "Bookcase"

    var startX = ""
    var bottomAFF = "0"
    var width = ""
    var height = ""
    var depth = ""

    var bayCount = 0
    var shelfCount = 0
    var openClosedStyle = "Open"

    var placement = "Custom"
    var referenceStructureStart = ""
    var referenceStructureEnd = ""
    var offsetDirection = "None"
    var offsetDistance = ""

    var finish = ""
    var notes = ""
}

struct StoredWallAuthority: Codable {

    var wallCode: String
    var wallName = ""

    var width = ""
    var height = ""
    var ceilingHeight = ""
    var beamHeight = ""

    var crownMoldingHeight = ""
    var crownMoldingNotes = ""
    var baseboardHeight = ""
    var baseboardNotes = ""

    var openings: [EditableOpening] = []
    var columns: [StoredColumnAuthority] = []
    var beams: [StoredBeamAuthority] = []
    var builtIns: [StoredBuiltInAuthority] = []

    var isApproved = false
    var approvedChecksum = ""
    var approvedUTC = ""
    var orthoImageFilename = ""

    init(
        wallCode: String,
        wallName: String = "",
        width: String = "",
        height: String = "",
        ceilingHeight: String = "",
        beamHeight: String = "",
        crownMoldingHeight: String = "",
        crownMoldingNotes: String = "",
        baseboardHeight: String = "",
        baseboardNotes: String = "",
        openings: [EditableOpening] = [],
        columns: [StoredColumnAuthority] = [],
        beams: [StoredBeamAuthority] = [],
        builtIns: [StoredBuiltInAuthority] = [],
        isApproved: Bool = false,
        approvedChecksum: String = "",
        approvedUTC: String = "",
        orthoImageFilename: String = ""
    ) {
        self.wallCode = wallCode
        self.wallName = wallName
        self.width = width
        self.height = height
        self.ceilingHeight = ceilingHeight
        self.beamHeight = beamHeight
        self.crownMoldingHeight = crownMoldingHeight
        self.crownMoldingNotes = crownMoldingNotes
        self.baseboardHeight = baseboardHeight
        self.baseboardNotes = baseboardNotes
        self.openings = openings
        self.columns = columns
        self.beams = beams
        self.builtIns = builtIns
        self.isApproved = isApproved
        self.approvedChecksum = approvedChecksum
        self.approvedUTC = approvedUTC
        self.orthoImageFilename = orthoImageFilename
    }

    private enum CodingKeys: String, CodingKey {
        case wallCode
        case wallName
        case width
        case height
        case ceilingHeight
        case beamHeight
        case crownMoldingHeight
        case crownMoldingNotes
        case baseboardHeight
        case baseboardNotes
        case openings
        case columns
        case beams
        case builtIns
        case isApproved
        case approvedChecksum
        case approvedUTC
        case orthoImageFilename
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        wallCode = try container.decode(String.self, forKey: .wallCode)
        wallName = try container.decodeIfPresent(String.self, forKey: .wallName) ?? ""
        width = try container.decodeIfPresent(String.self, forKey: .width) ?? ""
        height = try container.decodeIfPresent(String.self, forKey: .height) ?? ""
        ceilingHeight = try container.decodeIfPresent(String.self, forKey: .ceilingHeight) ?? ""
        beamHeight = try container.decodeIfPresent(String.self, forKey: .beamHeight) ?? ""
        crownMoldingHeight = try container.decodeIfPresent(String.self, forKey: .crownMoldingHeight) ?? ""
        crownMoldingNotes = try container.decodeIfPresent(String.self, forKey: .crownMoldingNotes) ?? ""
        baseboardHeight = try container.decodeIfPresent(String.self, forKey: .baseboardHeight) ?? ""
        baseboardNotes = try container.decodeIfPresent(String.self, forKey: .baseboardNotes) ?? ""
        openings = try container.decodeIfPresent([EditableOpening].self, forKey: .openings) ?? []
        columns = try container.decodeIfPresent([StoredColumnAuthority].self, forKey: .columns) ?? []
        beams = try container.decodeIfPresent([StoredBeamAuthority].self, forKey: .beams) ?? []
        builtIns = try container.decodeIfPresent([StoredBuiltInAuthority].self, forKey: .builtIns) ?? []
        isApproved = try container.decodeIfPresent(Bool.self, forKey: .isApproved) ?? false
        approvedChecksum = try container.decodeIfPresent(String.self, forKey: .approvedChecksum) ?? ""
        approvedUTC = try container.decodeIfPresent(String.self, forKey: .approvedUTC) ?? ""
        orthoImageFilename = try container.decodeIfPresent(String.self, forKey: .orthoImageFilename) ?? ""
    }
}

struct StoredRoomDefaults: Codable {

    var wallHeight = ""
    var ceilingHeight = ""
    var beamUndersideHeight = ""

    var crownMoldingHeight = ""
    var crownMoldingNotes = ""

    var baseboardHeight = ""
    var baseboardNotes = ""

    var columnWidth = ""
    var columnDepth = ""
    var columnHeight = ""
    var columnFinish = ""

    var beamType = "Perimeter Beam"
    var beamWidth = ""
    var beamHeight = ""
    var beamUnderside = ""
    var beamProjection = ""
    var beamFinish = ""
    var beamCrownRelationship = "None"

    private enum CodingKeys: String, CodingKey {
        case wallHeight
        case ceilingHeight
        case beamUndersideHeight
        case crownMoldingHeight
        case crownMoldingNotes
        case baseboardHeight
        case baseboardNotes
        case columnWidth
        case columnDepth
        case columnHeight
        case columnFinish
        case beamType
        case beamWidth
        case beamHeight
        case beamUnderside
        case beamProjection
        case beamFinish
        case beamCrownRelationship
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        wallHeight = try container.decodeIfPresent(String.self, forKey: .wallHeight) ?? ""
        ceilingHeight = try container.decodeIfPresent(String.self, forKey: .ceilingHeight) ?? ""
        beamUndersideHeight = try container.decodeIfPresent(String.self, forKey: .beamUndersideHeight) ?? ""
        crownMoldingHeight = try container.decodeIfPresent(String.self, forKey: .crownMoldingHeight) ?? ""
        crownMoldingNotes = try container.decodeIfPresent(String.self, forKey: .crownMoldingNotes) ?? ""
        baseboardHeight = try container.decodeIfPresent(String.self, forKey: .baseboardHeight) ?? ""
        baseboardNotes = try container.decodeIfPresent(String.self, forKey: .baseboardNotes) ?? ""
        columnWidth = try container.decodeIfPresent(String.self, forKey: .columnWidth) ?? ""
        columnDepth = try container.decodeIfPresent(String.self, forKey: .columnDepth) ?? ""
        columnHeight = try container.decodeIfPresent(String.self, forKey: .columnHeight) ?? ""
        columnFinish = try container.decodeIfPresent(String.self, forKey: .columnFinish) ?? ""
        beamType = try container.decodeIfPresent(String.self, forKey: .beamType) ?? "Perimeter Beam"
        beamWidth = try container.decodeIfPresent(String.self, forKey: .beamWidth) ?? ""
        beamHeight = try container.decodeIfPresent(String.self, forKey: .beamHeight) ?? ""
        beamUnderside = try container.decodeIfPresent(String.self, forKey: .beamUnderside) ?? ""
        beamProjection = try container.decodeIfPresent(String.self, forKey: .beamProjection) ?? ""
        beamFinish = try container.decodeIfPresent(String.self, forKey: .beamFinish) ?? ""
        beamCrownRelationship = try container.decodeIfPresent(String.self, forKey: .beamCrownRelationship) ?? "None"
    }
}

struct StoredRoomAuthority: Codable {

    var roomCode: String
    var defaults = StoredRoomDefaults()
    var walls: [StoredWallAuthority] = []

    init(
        roomCode: String,
        defaults: StoredRoomDefaults = StoredRoomDefaults(),
        walls: [StoredWallAuthority] = []
    ) {
        self.roomCode = roomCode
        self.defaults = defaults
        self.walls = walls
    }

    private enum CodingKeys: String, CodingKey {
        case roomCode
        case defaults
        case walls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        roomCode = try container.decode(String.self, forKey: .roomCode)
        defaults = try container.decodeIfPresent(
            StoredRoomDefaults.self,
            forKey: .defaults
        ) ?? StoredRoomDefaults()
        walls = try container.decodeIfPresent(
            [StoredWallAuthority].self,
            forKey: .walls
        ) ?? []
    }
}

struct StoredProjectAuthority: Codable, Identifiable {

    var id: UUID
    var name: String
    var selectedRoomCode: String
    var rooms: [StoredRoomAuthority] = []
}

struct AuthorityDataFile: Codable {

    var version = 5
    var projects: [StoredProjectAuthority] = []
}

enum AuthorityJSONStore {

    enum SaveError: LocalizedError {

        case verificationFailed

        var errorDescription: String? {

            switch self {

            case .verificationFailed:
                return "The JSON file was written, but the saved data could not be verified."
            }
        }
    }

    static let filename = "project-authority.json"

    static var fileURL: URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    static func loadFile() -> AuthorityDataFile {

        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? decoder.decode(
                AuthorityDataFile.self,
                from: data
            )
        else {
            return AuthorityDataFile()
        }

        return decoded
    }

    static func saveFile(
        _ file: AuthorityDataFile
    ) throws {

        let expectedData = try encoder.encode(file)

        try expectedData.write(
            to: fileURL,
            options: .atomic
        )

        let writtenData = try Data(
            contentsOf: fileURL
        )

        let verifiedFile = try decoder.decode(
            AuthorityDataFile.self,
            from: writtenData
        )

        let verifiedData = try encoder.encode(
            verifiedFile
        )

        guard verifiedData == expectedData else {
            throw SaveError.verificationFailed
        }
    }

    static func projects() -> [Project] {

        loadFile().projects.map { stored in

            Project(
                id: stored.id,
                name: stored.name,
                rooms: AuthorityDatabase.rooms,
                selectedRoomCode: stored.selectedRoomCode
            )
        }
    }

    static func registerProject(
        _ project: Project
    ) {

        var file = loadFile()

        if let index = file.projects.firstIndex(
            where: { $0.id == project.id }
        ) {

            file.projects[index].name = project.name
            file.projects[index].selectedRoomCode = project.selectedRoomCode

        } else {

            file.projects.append(
                StoredProjectAuthority(
                    id: project.id,
                    name: project.name,
                    selectedRoomCode: project.selectedRoomCode
                )
            )
        }

        do {
            try saveFile(file)
        } catch {
            print("Project registration save failed: \(error)")
        }
    }

    static func loadRoomDefaults(
        projectID: UUID,
        roomCode: String
    ) -> StoredRoomDefaults {

        loadFile().projects
            .first { $0.id == projectID }?
            .rooms
            .first { $0.roomCode == roomCode }?
            .defaults
            ?? StoredRoomDefaults()
    }

    static func saveRoomDefaults(
        _ defaults: StoredRoomDefaults,
        project: Project,
        roomCode: String
    ) throws {

        var file = loadFile()

        let projectIndex: Int

        if let existingProjectIndex = file.projects.firstIndex(
            where: { $0.id == project.id }
        ) {
            projectIndex = existingProjectIndex
        } else {
            file.projects.append(
                StoredProjectAuthority(
                    id: project.id,
                    name: project.name,
                    selectedRoomCode: project.selectedRoomCode
                )
            )
            projectIndex = file.projects.count - 1
        }

        let roomIndex: Int

        if let existingRoomIndex = file.projects[projectIndex].rooms.firstIndex(
            where: { $0.roomCode == roomCode }
        ) {
            roomIndex = existingRoomIndex
        } else {
            file.projects[projectIndex].rooms.append(
                StoredRoomAuthority(
                    roomCode: roomCode
                )
            )
            roomIndex = file.projects[projectIndex].rooms.count - 1
        }

        file.projects[projectIndex].rooms[roomIndex].defaults = defaults
        file.projects[projectIndex].name = project.name
        file.projects[projectIndex].selectedRoomCode = project.selectedRoomCode
        file.version = 3

        try saveFile(file)
    }

    static func loadWall(
        projectID: UUID,
        roomCode: String,
        wallCode: String
    ) -> StoredWallAuthority {

        let file = loadFile()

        return file.projects
            .first { $0.id == projectID }?
            .rooms
            .first { $0.roomCode == roomCode }?
            .walls
            .first { $0.wallCode == wallCode }
            ?? StoredWallAuthority(
                wallCode: wallCode
            )
    }

    static func effectiveWall(
        project: Project,
        room: Room,
        wallRecord: AuthorityRecord
    ) -> StoredWallAuthority {

        let stored = loadWall(
            projectID: project.id,
            roomCode: room.code,
            wallCode: wallRecord.code
        )

        let defaults = loadRoomDefaults(
            projectID: project.id,
            roomCode: room.code
        )

        let geometry = room.authority.geometryRecord(
            code: wallRecord.code
        )

        let structure = room.authority.structureRecord(
            code: wallRecord.code
        )

        let sourceColumns: [StoredColumnAuthority]

        if stored.columns.isEmpty {
            sourceColumns = structure?.columns.map(storedColumn) ?? []
        } else {
            sourceColumns = stored.columns
        }

        let columns = sourceColumns.map { column in
            var updated = column

            if updated.width.isEmpty, !defaults.columnWidth.isEmpty {
                updated.width = defaults.columnWidth
            }

            if updated.depth.isEmpty, !defaults.columnDepth.isEmpty {
                updated.depth = defaults.columnDepth
            }

            if updated.height.isEmpty, !defaults.columnHeight.isEmpty {
                updated.height = defaults.columnHeight
            }

            if updated.finish.isEmpty, !defaults.columnFinish.isEmpty {
                updated.finish = defaults.columnFinish
            }

            return updated
        }

        return StoredWallAuthority(
            wallCode: wallRecord.code,
            wallName: stored.wallName.isEmpty ? wallRecord.name : stored.wallName,
            width: stored.width.isEmpty ? numberString(geometry?.width) : stored.width,
            height: stored.height.isEmpty
                ? firstNonEmpty(defaults.wallHeight, numberString(geometry?.height))
                : stored.height,
            ceilingHeight: stored.ceilingHeight.isEmpty
                ? firstNonEmpty(defaults.ceilingHeight, numberString(geometry?.ceilingHeight))
                : stored.ceilingHeight,
            beamHeight: stored.beamHeight.isEmpty
                ? firstNonEmpty(defaults.beamUndersideHeight, numberString(geometry?.beamHeight))
                : stored.beamHeight,
            crownMoldingHeight: stored.crownMoldingHeight.isEmpty
                ? defaults.crownMoldingHeight
                : stored.crownMoldingHeight,
            crownMoldingNotes: stored.crownMoldingNotes.isEmpty
                ? defaults.crownMoldingNotes
                : stored.crownMoldingNotes,
            baseboardHeight: stored.baseboardHeight.isEmpty
                ? defaults.baseboardHeight
                : stored.baseboardHeight,
            baseboardNotes: stored.baseboardNotes.isEmpty
                ? defaults.baseboardNotes
                : stored.baseboardNotes,
            openings: stored.openings,
            columns: columns,
            beams: effectiveBeams(
                stored: stored.beams,
                source: structure?.beams.map(storedBeam) ?? [],
                defaults: defaults
            ),
            builtIns: stored.builtIns,
            isApproved: stored.isApproved,
            approvedChecksum: stored.approvedChecksum,
            approvedUTC: stored.approvedUTC,
            orthoImageFilename: stored.orthoImageFilename
        )
    }

    static func effectiveGeometry(
        project: Project,
        room: Room,
        wallRecord: AuthorityRecord
    ) -> AuthorityGeometryRecord? {

        let wall = effectiveWall(
            project: project,
            room: room,
            wallRecord: wallRecord
        )

        guard
            let width = Double(wall.width),
            let height = Double(wall.height),
            let ceilingHeight = Double(wall.ceilingHeight),
            let beamHeight = Double(wall.beamHeight)
        else {
            return room.authority.geometryRecord(code: wallRecord.code)
        }

        return AuthorityGeometryRecord(
            code: wallRecord.code,
            width: width,
            height: height,
            ceilingHeight: ceilingHeight,
            beamHeight: beamHeight
        )
    }

    static func allColumns(
        project: Project,
        room: Room
    ) -> [StoredColumnAuthority] {

        room.authority.records.flatMap { wallRecord in
            effectiveWall(
                project: project,
                room: room,
                wallRecord: wallRecord
            ).columns
        }
    }

    static func allBeams(
        project: Project,
        room: Room
    ) -> [StoredBeamAuthority] {

        room.authority.records.flatMap { wallRecord in
            effectiveWall(
                project: project,
                room: room,
                wallRecord: wallRecord
            ).beams
        }
    }

    static func totalOpeningCount(
        project: Project,
        room: Room
    ) -> Int {

        room.authority.records.reduce(0) { total, wallRecord in
            total + loadWall(
                projectID: project.id,
                roomCode: room.code,
                wallCode: wallRecord.code
            ).openings.count
        }
    }

    static func saveWall(
        _ wall: StoredWallAuthority,
        project: Project,
        roomCode: String
    ) throws {

        var file = loadFile()

        let projectIndex: Int

        if let existingProjectIndex = file.projects.firstIndex(
            where: { $0.id == project.id }
        ) {
            projectIndex = existingProjectIndex
        } else {
            file.projects.append(
                StoredProjectAuthority(
                    id: project.id,
                    name: project.name,
                    selectedRoomCode: project.selectedRoomCode
                )
            )
            projectIndex = file.projects.count - 1
        }

        let roomIndex: Int

        if let existingRoomIndex = file.projects[projectIndex].rooms.firstIndex(
            where: { $0.roomCode == roomCode }
        ) {
            roomIndex = existingRoomIndex
        } else {
            file.projects[projectIndex].rooms.append(
                StoredRoomAuthority(
                    roomCode: roomCode
                )
            )
            roomIndex = file.projects[projectIndex].rooms.count - 1
        }

        if let wallIndex = file.projects[projectIndex]
            .rooms[roomIndex]
            .walls
            .firstIndex(where: { $0.wallCode == wall.wallCode }) {

            file.projects[projectIndex]
                .rooms[roomIndex]
                .walls[wallIndex] = wall

        } else {

            file.projects[projectIndex]
                .rooms[roomIndex]
                .walls
                .append(wall)
        }

        file.projects[projectIndex].name = project.name
        file.projects[projectIndex].selectedRoomCode = project.selectedRoomCode
        file.version = 3

        try saveFile(file)
    }

    static func exportData() -> Data {

        (try? encoder.encode(loadFile())) ?? Data()
    }

    static func importData(
        _ data: Data
    ) throws {

        let decoded = try decoder.decode(
            AuthorityDataFile.self,
            from: data
        )

        try saveFile(decoded)
    }

    private static func effectiveBeams(
        stored: [StoredBeamAuthority],
        source: [StoredBeamAuthority],
        defaults: StoredRoomDefaults
    ) -> [StoredBeamAuthority] {

        let base = stored.isEmpty ? source : stored

        return base.map { beam in
            var updated = beam

            if updated.type.isEmpty {
                updated.type = defaults.beamType
            }

            if updated.width.isEmpty {
                updated.width = defaults.beamWidth
            }

            if updated.height.isEmpty {
                updated.height = defaults.beamHeight
            }

            if updated.undersideHeight.isEmpty {
                updated.undersideHeight = firstNonEmpty(
                    defaults.beamUnderside,
                    defaults.beamUndersideHeight
                )
            }

            if updated.projection.isEmpty {
                updated.projection = defaults.beamProjection
            }

            if updated.finish.isEmpty {
                updated.finish = defaults.beamFinish
            }

            if updated.crownRelationship.isEmpty || updated.crownRelationship == "None" {
                updated.crownRelationship = defaults.beamCrownRelationship
            }

            return updated
        }
    }

    private static func storedColumn(
        _ column: AuthorityColumn
    ) -> StoredColumnAuthority {

        StoredColumnAuthority(
            name: column.name,
            width: numberString(column.width),
            depth: numberString(column.depth),
            height: numberString(column.height),
            finish: column.finish
        )
    }

    private static func storedBeam(
        _ beam: AuthorityBeam
    ) -> StoredBeamAuthority {

        StoredBeamAuthority(
            name: beam.name,
            type: "Perimeter Beam",
            width: numberString(beam.width),
            height: numberString(beam.height),
            undersideHeight: numberString(beam.undersideHeight),
            startColumn: beam.startColumn,
            endColumn: beam.endColumn,
            finish: beam.finish
        )
    }

    private static func firstNonEmpty(
        _ preferred: String,
        _ fallback: String
    ) -> String {

        preferred.isEmpty ? fallback : preferred
    }

    private static func numberString(
        _ value: Double?
    ) -> String {

        guard let value else {
            return ""
        }

        return value.formatted(
            .number.precision(.fractionLength(0...2))
        )
    }

    private static var documentsDirectory: URL {

        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    private static var encoder: JSONEncoder {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        return encoder
    }

    private static var decoder: JSONDecoder {
        JSONDecoder()
    }
}
