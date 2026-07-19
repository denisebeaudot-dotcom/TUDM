import Foundation

/// Defines the ordered structural sequence for a wall,
/// or any other linear architectural path.
///
/// Examples:
///
/// W1:
/// C1 -> Bookcase -> C2 -> Window -> C3 -> Bookcase -> C4
///
/// W2:
/// C4 -> Wall -> Door -> Wall -> C5
///
/// W3:
/// C5 -> Wall -> C6 -> Opening -> C7 -> Wall -> C8 -> C9
///
/// W4:
/// C10 -> Brick -> TV Wall -> C1
///
struct StructuralChain: Hashable {
    
    /// Unique identifier.
    let code: String
    
    /// Human-readable name.
    let name: String
    
    /// Ordered list of structural nodes.
    private(set) var nodes: [StructuralNode]
    
    init(
        code: String,
        name: String,
        nodes: [StructuralNode] = []
    ) {
        self.code = code
        self.name = name
        self.nodes = nodes
    }
    
    // MARK: - Editing
    
    mutating func append(
        _ node: StructuralNode
    ) {
        nodes.append(node)
    }
    
    mutating func insert(
        _ node: StructuralNode,
        at index: Int
    ) {
        nodes.insert(node, at: index)
    }
    
    mutating func remove(
        code: String
    ) {
        nodes.removeAll {
            $0.code == code
        }
    }
    
    // MARK: - Lookup
    
    func node(
        code: String
    ) -> StructuralNode? {
        
        nodes.first {
            $0.code == code
        }
    }
    
    func contains(
        code: String
    ) -> Bool {
        
        node(code: code) != nil
    }
    
    // MARK: - Navigation
    
    func previous(
        to code: String
    ) -> StructuralNode? {
        
        guard
            let index = nodes.firstIndex(where: { $0.code == code }),
            index > 0
        else {
            return nil
        }
        
        return nodes[index - 1]
    }
    
    func next(
        after code: String
    ) -> StructuralNode? {
        
        guard
            let index = nodes.firstIndex(where: { $0.code == code }),
            index < nodes.count - 1
        else {
            return nil
        }
        
        return nodes[index + 1]
    }
}
