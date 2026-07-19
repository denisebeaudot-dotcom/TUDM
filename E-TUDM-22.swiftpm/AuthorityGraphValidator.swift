import Foundation

struct AuthorityGraphValidator {
    
    static func validate(
        _ graph: AuthorityGraph
    ) -> [AuthorityValidationIssue] {
        
        var issues: [AuthorityValidationIssue] = []
        
        issues.append(
            contentsOf: validateWalls(graph)
        )
        
        issues.append(
            contentsOf: validateDuplicateNodes(graph)
        )
        
        issues.append(
            contentsOf: validateEmptyChains(graph)
        )
        
        return issues
    }
    
}

// MARK: - Private

private extension AuthorityGraphValidator {
    
    static func validateWalls(
        _ graph: AuthorityGraph
    ) -> [AuthorityValidationIssue] {
        
        var issues: [AuthorityValidationIssue] = []
        
        for wall in graph.allWalls {
            
            if wall.chain.nodes.isEmpty {
                
                issues.append(
                    
                    AuthorityValidationIssue(
                        
                        severity: .warning,
                        
                        code: "EMPTY_WALL",
                        
                        message: "Wall \(wall.code) contains no structural nodes."
                        
                    )
                    
                )
                
            }
            
        }
        
        return issues
        
    }
    
    static func validateDuplicateNodes(
        _ graph: AuthorityGraph
    ) -> [AuthorityValidationIssue] {
        
        var issues: [AuthorityValidationIssue] = []
        
        var seen = Set<String>()
        
        for wall in graph.allWalls {
            
            for node in wall.chain.nodes {
                
                if seen.contains(node.code) {
                    
                    issues.append(
                        
                        AuthorityValidationIssue(
                            
                            severity: .error,
                            
                            code: "DUPLICATE_NODE",
                            
                            message: "Duplicate node '\(node.code)' detected."
                            
                        )
                        
                    )
                    
                }
                
                seen.insert(node.code)
                
            }
            
        }
        
        return issues
        
    }
    
    static func validateEmptyChains(
        _ graph: AuthorityGraph
    ) -> [AuthorityValidationIssue] {
        
        var issues: [AuthorityValidationIssue] = []
        
        for wall in graph.allWalls {
            
            if wall.chain.nodes.isEmpty {
                
                issues.append(
                    
                    AuthorityValidationIssue(
                        
                        severity: .info,
                        
                        code: "NO_CHAIN",
                        
                        message: "No structural chain defined for \(wall.code)."
                        
                    )
                    
                )
                
            }
            
        }
        
        return issues
        
    }
    
}
