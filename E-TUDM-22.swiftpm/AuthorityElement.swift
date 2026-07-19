import Foundation

/// Every object that participates in the
/// Authority Engine conforms to this protocol.
///
/// The protocol deliberately contains only
/// identity information.
///
/// Geometry, dimensions and metadata remain
/// in their own authority records.
protocol AuthorityElement {
    
    /// Globally unique authority code.
    ///
    /// Examples:
    /// FR
    /// W1
    /// C4
    /// B2
    /// W2-DOOR-1
    /// SOFA-1
    var code: String { get }
    
    /// Architectural classification.
    var authorityType: AuthorityType { get }
    
}
