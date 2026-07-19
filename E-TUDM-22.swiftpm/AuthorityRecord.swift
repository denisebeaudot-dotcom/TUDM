import Foundation

struct AuthorityRecord: Identifiable {

    let id = UUID()

    var code: String
    var name: String
    var type: AuthorityType
    var status: AuthorityStatus
}
