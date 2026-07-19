import Foundation

struct Project: Identifiable {

    let id: UUID

    var name: String
    var rooms: [Room]
    var selectedRoomCode: String

    init(
        id: UUID = UUID(),
        name: String,
        rooms: [Room],
        selectedRoomCode: String
    ) {
        self.id = id
        self.name = name
        self.rooms = rooms
        self.selectedRoomCode = selectedRoomCode
    }

    var selectedRoom: Room? {
        rooms.first { $0.code == selectedRoomCode }
    }

    func selectingRoom(code: String) -> Project {
        var updatedProject = self
        updatedProject.selectedRoomCode = code
        return updatedProject
    }
}
