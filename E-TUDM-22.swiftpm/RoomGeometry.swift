import Foundation

struct RoomGeometry {

    var records: [AuthorityGeometryRecord]

    func geometry(for code: String) -> AuthorityGeometryRecord? {
        records.first { $0.code == code }
    }
}
