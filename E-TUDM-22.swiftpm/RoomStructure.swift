import Foundation

struct RoomStructure {

    var records: [AuthorityStructureRecord]

    func structure(for code: String) -> AuthorityStructureRecord? {
        records.first { $0.code == code }
    }

    var allColumns: [AuthorityColumn] {
        records.flatMap { $0.columns }
    }

    var allBeams: [AuthorityBeam] {
        records.flatMap { $0.beams }
    }
}
