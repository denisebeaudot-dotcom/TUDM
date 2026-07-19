import Foundation

/// Represents one wall within the room topology.
///
/// A WallTopology owns exactly one StructuralChain.
///
/// Geometry, openings, columns, beams, etc.
/// remain in the Authority system.
///
/// This object simply connects the Authority
/// to the Structural Chain.
struct WallTopology: Hashable {
    
    /// Wall code.
    ///
    /// Example:
    /// W1
    /// W2
    /// W3
    /// W4
    let code: String
    
    /// Friendly wall name.
    let name: String
    
    /// Ordered structural chain.
    var chain: StructuralChain
    
    init(
        code: String,
        name: String,
        chain: StructuralChain = StructuralChain(
            code: "",
            name: ""
        )
    ) {
        
        self.code = code
        self.name = name
        
        if chain.code.isEmpty {
            
            self.chain = StructuralChain(
                code: code,
                name: "\(name) Chain"
            )
            
        } else {
            
            self.chain = chain
        }
    }
    
    // MARK: Convenience
    
    mutating func addNode(
        _ node: StructuralNode
    ) {
        
        chain.append(node)
    }
    
    func containsNode(
        code: String
    ) -> Bool {
        
        chain.contains(
            code: code
        )
    }
    
    func node(
        code: String
    ) -> StructuralNode? {
        
        chain.node(
            code: code
        )
    }
    
    func previousNode(
        before code: String
    ) -> StructuralNode? {
        
        chain.previous(
            to: code
        )
    }
    
    func nextNode(
        after code: String
    ) -> StructuralNode? {
        
        chain.next(
            after: code
        )
    }
}
