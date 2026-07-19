import SwiftUI

struct ProjectCreateScreen: View {
    
    @Environment(AppState.self)
    private var appState
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var projectName = ""
    
    @State
    private var showDuplicateAlert = false
    
    @State
    private var duplicateName = ""
    
    var trimmedName: String {
        projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        
        Form {
            
            Section("Project") {
                
                TextField("Project Name", text: $projectName)
                    .textInputAutocapitalization(.words)
            }
            
            Button("Create Project") {
                
                createProject()
                
            }
            .buttonStyle(.borderedProminent)
            .disabled(trimmedName.isEmpty)
        }
        .navigationTitle("New Project")
        .alert("Project Already Exists",
               isPresented: $showDuplicateAlert) {
            
            Button("Create \"\(duplicateName) (2)\"") {
                
                createDuplicateVersion()
            }
            
            Button("Cancel", role: .cancel) { }
            
        } message: {
            
            Text("""
A project named "\(duplicateName)" already exists.

Choose a different name or create "\(duplicateName) (2)".
""")
        }
    }
    
    // MARK: - Create
    
    private func createProject() {
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let exists = appState.projects.contains {
            $0.name.compare(
                trimmedName,
                options: .caseInsensitive
            ) == .orderedSame
        }
        
        if exists {
            
            duplicateName = trimmedName
            showDuplicateAlert = true
            return
        }
        
        addProject(named: trimmedName)
    }
    
    private func createDuplicateVersion() {
        
        var candidate = "\(duplicateName) (2)"
        var number = 2
        
        while appState.projects.contains(where: {
            
            $0.name.compare(
                candidate,
                options: .caseInsensitive
            ) == .orderedSame
            
        }) {
            
            number += 1
            candidate = "\(duplicateName) (\(number))"
        }
        
        addProject(named: candidate)
    }
    
    private func addProject(named name: String) {
        
        appState.addProject(
            
            Project(
                
                name: name,
                
                rooms: AuthorityDatabase.rooms,
                
                selectedRoomCode: AuthorityDatabase.familyRoom.code
            )
        )
        
        dismiss()
    }
}
