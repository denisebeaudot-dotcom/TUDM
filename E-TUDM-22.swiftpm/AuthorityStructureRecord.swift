import Foundation

struct AuthorityStructureRecord: Identifiable {

    let id = UUID()

    let code: String

    var columns: [AuthorityColumn]
    var beams: [AuthorityBeam]

    init(
        code: String,
        columns: [AuthorityColumn] = [],
        beams: [AuthorityBeam] = []
    ) {
        self.code = code
        self.columns = columns
        self.beams = beams
    }
}
