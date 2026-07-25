import Foundation

// MARK: - Manifest TXT Writer
//
// Produces a compact, human-readable text file that captures the current
// structural state of every wall in every room in every project. The file is
// designed so a person or an external AI (Perplexity) can read it top-to-bottom
// and know the exact numbers the app is currently holding.
//
// One file per app state: wall_manifests.txt. Overwritten on every save.
//
// Output shape (example):
//
// === TUDM Wall Manifests ===
// Generated: 2026-07-24 22:53:14 -0400
//
// Project: Cantley House
//   Room: Living Room
//     Room defaults: ceiling 96.00in, crown 6.00in, baseboard 8.00in, beam 12.00in at 84-96 AFF, columns 8.00w x 9.25d x 88.00h
//     Beams:
//       - Beam 1: 10.00in tall at 84.00-94.00 AFF, front
//     Wall: Wall 1
//       Total width: 246.00in
//       Chain: C SH C WS W WS C SH C
//       Segments (left to right):
//         1. C1  column    8.00w
//         2. SH1 bookcase  43.00w   5 shelves, 12.00in deep, floor-to-ceiling
//         3. C2  column    8.00w
//         4. WS1 wallspace 12.75w
//         5. W1  window    106.00w x 48.00h  sill 24.00 AFF  panels 1  style picture
//         6. WS2 wallspace 12.75w
//         7. C3  column    8.00w
//         8. SH2 bookcase  39.50w   5 shelves, 12.00in deep, floor-to-ceiling
//         9. C4  column    8.00w
//       Segment sum: 246.00in
//       Matches wall width: yes
//
// Numbers use two decimals to match the app's numeric display convention.

enum ManifestTxtWriter {
    
    static let filename = "wall_manifests.txt"
    
    static func build(projects: [Project]) -> String {
        var lines: [String] = []
        lines.append("=== TUDM Wall Manifests ===")
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss xxxx"
        lines.append("Generated: \(fmt.string(from: Date()))")
        lines.append("")
        
        if projects.isEmpty {
            lines.append("(No projects. Add one in the app to populate this file.)")
            return lines.joined(separator: "\n")
        }
        
        for project in projects {
            lines.append("Project: \(project.name.isEmpty ? "(unnamed)" : project.name)")
            if !project.clientName.trimmed.isEmpty {
                lines.append("  Client: \(project.clientName)")
            }
            if !project.location.trimmed.isEmpty {
                lines.append("  Location: \(project.location)")
            }
            if project.rooms.isEmpty {
                lines.append("  (no rooms)")
                lines.append("")
                continue
            }
            for room in project.rooms {
                lines.append("  Room: \(room.name.isEmpty ? "(unnamed)" : room.name)")
                lines.append(indent(2, roomDefaultsLine(room.defaults)))
                if !room.beams.isEmpty {
                    lines.append("    Beams:")
                    for (i, beam) in room.beams.enumerated() {
                        lines.append("      - Beam \(i + 1): \(beamLine(beam))")
                    }
                }
                if room.wallSpecs.isEmpty {
                    lines.append("    (no walls)")
                    continue
                }
                for wall in room.wallSpecs {
                    lines.append("    Wall: \(wall.name.isEmpty ? "(unnamed)" : wall.name)")
                    lines.append("      Total width: \(fmtIn(wall.totalWidth))")
                    if !wall.chainString.trimmed.isEmpty {
                        lines.append("      Chain: \(wall.chainString)")
                    }
                    if !wall.verticalChainString.trimmed.isEmpty {
                        lines.append("      Vertical chain: \(wall.verticalChainString)")
                    }
                    lines.append("      Segments (left to right):")
                    let segs = wall.segments.isEmpty ? WallSegment.parseChain(wall.chainString) : wall.segments
                    if segs.isEmpty {
                        lines.append("        (no segments)")
                    } else {
                        var sum = 0.0
                        for (i, s) in segs.enumerated() {
                            let n = i + 1
                            lines.append("        \(n). \(segmentLine(s))")
                            sum += segmentEffectiveWidth(s)
                        }
                        lines.append("      Segment sum: \(fmtIn(sum))")
                        let matches = abs(sum - wall.totalWidth) < 0.005
                        lines.append("      Matches wall width: \(matches ? "yes" : "no (delta \(fmtIn(sum - wall.totalWidth)))")")
                    }
                    if !wall.notes.trimmed.isEmpty {
                        lines.append("      Notes: \(wall.notes)")
                    }
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Line builders
    
    private static func roomDefaultsLine(_ d: RoomDefaults) -> String {
        "Room defaults: ceiling \(fmtIn(d.ceilingHeight)), crown \(fmtIn(d.crownHeight)), baseboard \(fmtIn(d.baseboardHeight)), beam \(fmtIn(d.beamHeight)) at \(d.beamRangeAFF) AFF, columns \(fmt2(d.columnWidth))w x \(fmt2(d.columnDepth))d x \(fmt2(d.columnHeight))h"
    }
    
    private static func beamLine(_ b: RoomBeam) -> String {
        var parts: [String] = []
        if !b.label.trimmed.isEmpty { parts.append(b.label) }
        parts.append("\(fmtIn(b.height)) tall")
        parts.append("\(fmtIn(b.thickness)) thick")
        parts.append(b.position.rawValue)
        return parts.joined(separator: ", ")
    }
    
    private static func segmentLine(_ s: WallSegment) -> String {
        let label = s.label.isEmpty ? s.kind.rawValue : s.label
        let paddedLabel = pad(label, width: 4)
        let paddedKind = pad(s.kind.rawValue, width: 9)
        var body = "\(paddedLabel) \(paddedKind) "
        
        switch s.kind {
        case .column, .wallSpace:
            body += "\(fmt2(s.width))w"
        case .bookcase:
            body += "\(fmt2(s.width))w"
            let shelves = s.shelfCount.map { "\($0) shelves" } ?? "shelves not set"
            let depth = s.shelfDepth.map { "\(fmt2($0))in deep" } ?? "depth not set"
            let ftc = (s.isFloorToCeiling ?? false) ? "floor-to-ceiling" : "not floor-to-ceiling"
            body += "   \(shelves), \(depth), \(ftc)"
        case .windowUnit, .door, .opening:
            if let opening = s.opening {
                body += "\(fmt2(opening.openingWidth))w x \(fmt2(opening.openingHeight))h"
                if opening.category == .window {
                    body += "  sill \(fmt2(opening.sillOrBottomAFF)) AFF"
                } else {
                    body += "  bottom \(fmt2(opening.sillOrBottomAFF)) AFF"
                }
                body += "  panels \(opening.panelCount)"
                if let ws = opening.windowStyle {
                    body += "  style \(ws.rawValue)"
                }
                if let ds = opening.doorStyle {
                    body += "  style \(ds.rawValue)"
                }
            } else {
                body += "\(fmt2(s.width))w  (no opening spec)"
            }
        default:
            body += "\(fmt2(s.width))w"
        }
        return body
    }
    
    /// A segment's effective width for chain-sum purposes: openings use their opening width when set.
    private static func segmentEffectiveWidth(_ s: WallSegment) -> Double {
        if let opening = s.opening, s.width == 0 {
            return opening.openingWidth
        }
        return s.width
    }
    
    // MARK: - Formatters
    
    private static func fmtIn(_ v: Double) -> String {
        String(format: "%.2fin", v)
    }
    
    private static func fmt2(_ v: Double) -> String {
        String(format: "%.2f", v)
    }
    
    private static func pad(_ s: String, width: Int) -> String {
        if s.count >= width { return s }
        return s + String(repeating: " ", count: width - s.count)
    }
    
    private static func indent(_ n: Int, _ line: String) -> String {
        String(repeating: " ", count: n * 2) + line
    }
}

