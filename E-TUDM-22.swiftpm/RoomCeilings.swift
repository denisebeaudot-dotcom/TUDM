import Foundation

struct RoomCeilings {
    
    var records: [AuthorityCeilingRecord]
    
    func ceiling(
        for code: String
    ) -> AuthorityCeilingRecord? {
        
        records.first {
            $0.code == code
        }
    }
    
    var allCeilings: [AuthorityCeilingRecord] {
        records
    }
}
