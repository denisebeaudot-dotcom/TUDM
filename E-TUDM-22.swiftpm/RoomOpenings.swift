import Foundation

struct RoomOpenings {
    
    var records: [AuthorityOpeningRecord]
    
    func openings(
        for code: String
    ) -> [AuthorityOpening] {
        
        records
            .first { $0.code == code }?
            .openings ?? []
    }
    
    var allOpenings: [AuthorityOpening] {
        records.flatMap { $0.openings }
    }
}

struct AuthorityOpeningRecord: Identifiable {
    
    let id = UUID()
    
    let code: String
    var openings: [AuthorityOpening]
    
    init(
        code: String,
        openings: [AuthorityOpening] = []
    ) {
        self.code = code
        self.openings = openings
    }
}
