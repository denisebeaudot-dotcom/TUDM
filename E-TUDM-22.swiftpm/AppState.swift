import Observation

@Observable
final class AppState {

    var projects: [Project]

    init() {
        projects = AuthorityJSONStore.projects()
    }

    func addProject(
        _ project: Project
    ) {
        projects.append(project)
        AuthorityJSONStore.registerProject(project)
    }

    func reloadFromJSON() {
        projects = AuthorityJSONStore.projects()
    }
}
