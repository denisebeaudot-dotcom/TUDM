import Foundation

struct AuthorityGeometryRecord: Identifiable {

    let id = UUID()

    let code: String

    var width: Double
    var height: Double
    var ceilingHeight: Double
    var beamHeight: Double
}
