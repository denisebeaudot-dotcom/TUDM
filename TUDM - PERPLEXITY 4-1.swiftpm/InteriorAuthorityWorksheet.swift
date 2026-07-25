import SwiftUI
import UIKit
import PDFKit

// MARK: - Printable Worksheet
//
// Generates a US-Letter portrait PDF blank-form worksheet the user can print,
// fill out by hand, then transcribe into the app. Sections mirror the app's
// data model exactly so nothing has to be re-mapped when typing back in.
//
// Entry point:
//   let url = WorksheetRenderer.renderPDF(project: project, room: room)
//   present a share sheet with that URL
//
// Or use WorksheetButton() as a drop-in toolbar item — it wires up the
// share sheet automatically.

// MARK: - Renderer

enum WorksheetRenderer {
    
    /// US Letter portrait, 72 dpi
    static let pageSize = CGSize(width: 612, height: 792)
    
    static let marginX: CGFloat = 36
    static let marginTop: CGFloat = 36
    static let marginBottom: CGFloat = 36
    
    /// Renders a project + room worksheet to a PDF and returns the temp file URL.
    static func renderPDF(project: Project, room: Room) -> URL? {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let fileName = "Worksheet-\(sanitize(project.name.isEmpty ? "Project" : project.name))-\(sanitize(room.name.isEmpty ? "Room" : room.name)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: url) { ctx in
                var cursor = PageCursor(pageRect: pageRect, marginX: marginX, marginTop: marginTop, marginBottom: marginBottom)
                ctx.beginPage()
                
                drawHeader(project: project, room: room, cursor: &cursor)
                drawRoomInfo(project: project, room: room, cursor: &cursor)
                drawDefaults(defaults: room.defaults, cursor: &cursor)
                drawLegends(cursor: &cursor)
                
                for (index, wall) in room.wallSpecs.enumerated() {
                    ensureRoom(for: 260, cursor: &cursor, ctx: ctx)
                    drawWallBlock(wall: wall.locked, index: index, cursor: &cursor, ctx: ctx)
                }
                
                if room.wallSpecs.isEmpty {
                    // 3 blank wall blocks by default
                    for i in 0..<3 {
                        ensureRoom(for: 260, cursor: &cursor, ctx: ctx)
                        drawBlankWallBlock(index: i, cursor: &cursor, ctx: ctx)
                    }
                }
                
                drawFooter(project: project, room: room, cursor: cursor)
            }
            return url
        } catch {
            return nil
        }
    }
    
    // MARK: Drawing helpers
    
    private static func drawHeader(project: Project, room: Room, cursor: inout PageCursor) {
        let title = "INTERIOR AUTHORITY  ·  WALL WORKSHEET"
        drawText(title, at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .boldSystemFont(ofSize: 14), color: .label)
        cursor.advance(by: 20)
        
        let subtitle = "\(project.name.isEmpty ? "Untitled Project" : project.name)  ·  \(room.name.isEmpty ? "Untitled Room" : room.name)"
        drawText(subtitle, at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .systemFont(ofSize: 11), color: .secondaryLabel)
        cursor.advance(by: 14)
        
        drawHR(cursor: &cursor)
        cursor.advance(by: 8)
    }
    
    private static func drawRoomInfo(project: Project, room: Room, cursor: inout PageCursor) {
        drawSectionTitle("Project & Room", cursor: &cursor)
        
        let col1 = cursor.left
        let col2 = cursor.left + 260
        
        drawFieldLine(label: "Project", value: project.name, x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Client", value: project.clientName, x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Room", value: room.name, x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Location", value: project.location, x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Room Notes", value: room.notes, x: col1, y: cursor.y, width: pageSize.width - marginX * 2)
        cursor.advance(by: 26)
    }
    
    private static func drawDefaults(defaults: RoomDefaults, cursor: inout PageCursor) {
        drawSectionTitle("Room Defaults (Structure)", cursor: &cursor)
        
        let colW: CGFloat = (pageSize.width - marginX * 2) / 2
        let col1X = cursor.left
        let col2X = cursor.left + colW
        
        let items: [(String, String)] = [
            ("Ceiling Height", format(defaults.ceilingHeight)),
            ("Crown Height", format(defaults.crownHeight)),
            ("Baseboard Height", format(defaults.baseboardHeight)),
            ("Beam Height", format(defaults.beamHeight)),
            ("Beam Range AFF", defaults.beamRangeAFF),
            ("Column Width", format(defaults.columnWidth)),
            ("Column Depth", format(defaults.columnDepth)),
            ("Column Height", format(defaults.columnHeight))
        ]
        
        for (i, item) in items.enumerated() {
            let x = i.isMultiple(of: 2) ? col1X : col2X
            drawFieldLine(label: item.0, value: item.1, x: x, y: cursor.y, width: colW - 12)
            if !i.isMultiple(of: 2) {
                cursor.advance(by: 22)
            }
        }
        if items.count.isMultiple(of: 2) == false {
            cursor.advance(by: 22)
        }
        cursor.advance(by: 6)
    }
    
    private static func drawLegends(cursor: inout PageCursor) {
        drawSectionTitle("Chain Legend", cursor: &cursor)
        
        let horizontal = "H: BC=Bookcase  C=Column  DR=Door  FP=Fireplace  NIC=Niche  OP=Opening  RZ=Return  SH=Shelf  WIN=Window  WS=Wall Space"
        drawText(horizontal, at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .systemFont(ofSize: 8), color: .secondaryLabel)
        cursor.advance(by: 12)
        
        let vertical = "V: BB=Baseboard  BM=Beam  CLG=Ceiling  CR=Crown  FLR=Floor  HDR=Header  SL=Sill  WS=Wall Space"
        drawText(vertical, at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .systemFont(ofSize: 8), color: .secondaryLabel)
        cursor.advance(by: 16)
    }
    
    private static func drawWallBlock(wall: LockedWall, index: Int, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        drawSectionTitle("Wall \(index + 1) — \(wall.name.isEmpty ? "Unnamed" : wall.name)", cursor: &cursor)
        
        let col1 = cursor.left
        let col2 = cursor.left + 260
        drawFieldLine(label: "Wall Name", value: wall.name, x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Total Width", value: format(wall.totalWidth), x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Rule Set", value: wall.ruleSet, x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Notes", value: wall.notes, x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Horizontal Chain", value: wall.chainString, x: col1, y: cursor.y, width: pageSize.width - marginX * 2)
        cursor.advance(by: 22)
        drawFieldLine(label: "Vertical Chain", value: wall.verticalChainString, x: col1, y: cursor.y, width: pageSize.width - marginX * 2)
        cursor.advance(by: 22)
        
        drawSegmentTable(segments: wall.segments, cursor: &cursor, ctx: ctx)
        
        // Windows details block for any window unit in this wall
        let windowSegs = wall.segments.filter { $0.kind == .windowUnit && $0.opening?.category == .window }
        for seg in windowSegs {
            ensureRoom(for: 90, cursor: &cursor, ctx: ctx)
            drawWindowDetail(segment: seg, cursor: &cursor)
        }
        
        cursor.advance(by: 10)
    }
    
    private static func drawBlankWallBlock(index: Int, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        drawSectionTitle("Wall \(index + 1)", cursor: &cursor)
        
        let col1 = cursor.left
        let col2 = cursor.left + 260
        drawFieldLine(label: "Wall Name", value: "", x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Total Width", value: "", x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Rule Set", value: "", x: col1, y: cursor.y, width: 240)
        drawFieldLine(label: "Notes", value: "", x: col2, y: cursor.y, width: 240)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Horizontal Chain", value: "", x: col1, y: cursor.y, width: pageSize.width - marginX * 2)
        cursor.advance(by: 22)
        drawFieldLine(label: "Vertical Chain", value: "", x: col1, y: cursor.y, width: pageSize.width - marginX * 2)
        cursor.advance(by: 22)
        
        drawSegmentTable(segments: [], cursor: &cursor, ctx: ctx)
        cursor.advance(by: 10)
    }
    
    private static func drawSegmentTable(segments: [WallSegment], cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        drawText("Segments", at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .boldSystemFont(ofSize: 10), color: .label)
        cursor.advance(by: 14)
        
        let colX: [CGFloat] = [cursor.left, cursor.left + 30, cursor.left + 130, cursor.left + 230, cursor.left + 310]
        let colWidths: [CGFloat] = [30, 100, 100, 80, pageSize.width - marginX - colX[4]]
        let headers = ["#", "Kind", "Label", "Width", "Notes"]
        
        // Header row
        for (i, h) in headers.enumerated() {
            drawText(h, at: CGPoint(x: colX[i] + 2, y: cursor.y),
                     font: .boldSystemFont(ofSize: 9), color: .label)
        }
        cursor.advance(by: 14)
        drawHR(cursor: &cursor, color: .label)
        cursor.advance(by: 2)
        
        let rowCount = max(segments.count, 12)
        for i in 0..<rowCount {
            let seg = i < segments.count ? segments[i] : nil
            let rowY = cursor.y
            
            // #
            drawText("\(i + 1)", at: CGPoint(x: colX[0] + 2, y: rowY),
                     font: .systemFont(ofSize: 9), color: .secondaryLabel)
            // Kind
            drawText(seg?.kind.rawValue ?? "", at: CGPoint(x: colX[1] + 2, y: rowY),
                     font: .systemFont(ofSize: 9), color: .label)
            // Label
            drawText(seg?.label ?? "", at: CGPoint(x: colX[2] + 2, y: rowY),
                     font: .systemFont(ofSize: 9), color: .label)
            // Width
            let widthText = seg.map { format($0.resolvedWidth) } ?? ""
            drawText(widthText, at: CGPoint(x: colX[3] + 2, y: rowY),
                     font: .systemFont(ofSize: 9).monospacedDigits(), color: .label)
            // Notes
            drawText(seg?.note ?? "", at: CGPoint(x: colX[4] + 2, y: rowY),
                     font: .systemFont(ofSize: 9), color: .label,
                     maxWidth: colWidths[4] - 4)
            
            cursor.advance(by: 16)
            drawHR(cursor: &cursor, color: .quaternaryLabel)
            cursor.advance(by: 2)
            
            if cursor.y > cursor.pageBottom - 40 && i < rowCount - 1 {
                ctx.beginPage()
                cursor.reset()
                drawText("Segments (cont.)", at: CGPoint(x: cursor.left, y: cursor.y),
                         font: .boldSystemFont(ofSize: 10), color: .label)
                cursor.advance(by: 14)
            }
        }
    }
    
    private static func drawWindowDetail(segment: WallSegment, cursor: inout PageCursor) {
        guard let opening = segment.opening else { return }
        
        drawText("Window Detail — \(segment.label)",
                 at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .boldSystemFont(ofSize: 10), color: .label)
        cursor.advance(by: 14)
        
        let col1 = cursor.left
        let col2 = cursor.left + 190
        let col3 = cursor.left + 380
        
        drawFieldLine(label: "Style", value: opening.windowStyle?.rawValue ?? "", x: col1, y: cursor.y, width: 170)
        drawFieldLine(label: "Panels", value: "\(opening.panelCount)", x: col2, y: cursor.y, width: 170)
        drawFieldLine(label: "V Mullions", value: "\(opening.mullionsVertical)", x: col3, y: cursor.y, width: 160)
        cursor.advance(by: 22)
        
        drawFieldLine(label: "Opening W", value: format(opening.openingWidth), x: col1, y: cursor.y, width: 170)
        drawFieldLine(label: "Opening H", value: format(opening.openingHeight), x: col2, y: cursor.y, width: 170)
        drawFieldLine(label: "Sill AFF", value: format(opening.sillOrBottomAFF), x: col3, y: cursor.y, width: 160)
        cursor.advance(by: 22)
        
        // Per-panel table
        if opening.panelCount > 1 || !opening.panels.isEmpty {
            drawText("Per-Panel Widths & Operation",
                     at: CGPoint(x: cursor.left, y: cursor.y),
                     font: .boldSystemFont(ofSize: 9), color: .label)
            cursor.advance(by: 12)
            
            let pcolX: [CGFloat] = [cursor.left, cursor.left + 60, cursor.left + 140, cursor.left + 220, cursor.left + 320, cursor.left + 400]
            let headers = ["Panel", "Label", "Share", "Operation", "Muntin R×C", "Notes"]
            for (i, h) in headers.enumerated() {
                drawText(h, at: CGPoint(x: pcolX[i] + 2, y: cursor.y),
                         font: .boldSystemFont(ofSize: 8), color: .secondaryLabel)
            }
            cursor.advance(by: 12)
            drawHR(cursor: &cursor, color: .quaternaryLabel)
            cursor.advance(by: 2)
            
            let displayCount = max(opening.panelCount, opening.panels.count, 1)
            for i in 0..<displayCount {
                let panel = i < opening.panels.count ? opening.panels[i] : nil
                let rowY = cursor.y
                
                drawText("\(i + 1)", at: CGPoint(x: pcolX[0] + 2, y: rowY),
                         font: .systemFont(ofSize: 8), color: .secondaryLabel)
                drawText(panel?.label ?? "", at: CGPoint(x: pcolX[1] + 2, y: rowY),
                         font: .systemFont(ofSize: 8), color: .label)
                drawText(panel.map { format($0.widthShare) } ?? "",
                         at: CGPoint(x: pcolX[2] + 2, y: rowY),
                         font: .systemFont(ofSize: 8).monospacedDigits(), color: .label)
                drawText(panel?.operation.rawValue ?? "",
                         at: CGPoint(x: pcolX[3] + 2, y: rowY),
                         font: .systemFont(ofSize: 8), color: .label)
                let muntinText = panel.map { "\($0.muntinRows) × \($0.muntinCols)" } ?? ""
                drawText(muntinText, at: CGPoint(x: pcolX[4] + 2, y: rowY),
                         font: .systemFont(ofSize: 8).monospacedDigits(), color: .label)
                drawText("", at: CGPoint(x: pcolX[5] + 2, y: rowY),
                         font: .systemFont(ofSize: 8), color: .label)
                cursor.advance(by: 14)
                drawHR(cursor: &cursor, color: .quaternaryLabel)
                cursor.advance(by: 1)
            }
        }
        cursor.advance(by: 8)
    }
    
    private static func drawFooter(project: Project, room: Room, cursor: PageCursor) {
        let footerY = pageSize.height - 20
        let footer = "\(project.name) · \(room.name) · Generated by Interior Authority"
        drawText(footer, at: CGPoint(x: marginX, y: footerY),
                 font: .systemFont(ofSize: 7), color: .tertiaryLabel)
    }
    
    // MARK: Primitives
    
    private static func drawText(_ string: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat? = nil) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        
        let attributed = NSAttributedString(string: string, attributes: attrs)
        let rect: CGRect
        if let maxWidth {
            rect = CGRect(x: point.x, y: point.y, width: maxWidth, height: font.lineHeight + 2)
        } else {
            let size = attributed.boundingRect(with: CGSize(width: 1000, height: font.lineHeight * 2),
                                               options: [.usesLineFragmentOrigin], context: nil).size
            rect = CGRect(x: point.x, y: point.y, width: size.width + 2, height: size.height + 2)
        }
        attributed.draw(in: rect)
    }
    
    private static func drawSectionTitle(_ title: String, cursor: inout PageCursor) {
        drawText(title, at: CGPoint(x: cursor.left, y: cursor.y),
                 font: .boldSystemFont(ofSize: 11), color: .label)
        cursor.advance(by: 16)
        drawHR(cursor: &cursor, color: .separator)
        cursor.advance(by: 6)
    }
    
    private static func drawFieldLine(label: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        let labelText = "\(label):"
        let labelWidth: CGFloat = 90
        
        drawText(labelText, at: CGPoint(x: x, y: y),
                 font: .systemFont(ofSize: 9), color: .secondaryLabel)
        
        let lineY = y + 14
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x + labelWidth, y: lineY))
        path.addLine(to: CGPoint(x: x + width, y: lineY))
        UIColor.tertiaryLabel.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        
        if !value.isEmpty {
            drawText(value, at: CGPoint(x: x + labelWidth + 3, y: y),
                     font: .systemFont(ofSize: 10), color: .label,
                     maxWidth: width - labelWidth - 6)
        }
    }
    
    private static func drawHR(cursor: inout PageCursor, color: UIColor = .separator) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cursor.left, y: cursor.y))
        path.addLine(to: CGPoint(x: pageSize.width - marginX, y: cursor.y))
        color.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private static func ensureRoom(for height: CGFloat, cursor: inout PageCursor, ctx: UIGraphicsPDFRendererContext) {
        if cursor.y + height > cursor.pageBottom {
            ctx.beginPage()
            cursor.reset()
        }
    }
    
    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
    
    private static func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}

// MARK: - Page Cursor

private struct PageCursor {
    let pageRect: CGRect
    let marginX: CGFloat
    let marginTop: CGFloat
    let marginBottom: CGFloat
    var y: CGFloat
    
    init(pageRect: CGRect, marginX: CGFloat, marginTop: CGFloat, marginBottom: CGFloat) {
        self.pageRect = pageRect
        self.marginX = marginX
        self.marginTop = marginTop
        self.marginBottom = marginBottom
        self.y = marginTop
    }
    
    var left: CGFloat { marginX }
    var pageBottom: CGFloat { pageRect.height - marginBottom }
    
    mutating func advance(by dy: CGFloat) {
        y += dy
    }
    
    mutating func reset() {
        y = marginTop
    }
}

// MARK: - Font monospaced digits helper

private extension UIFont {
    func monospacedDigits() -> UIFont {
        let settings: [[UIFontDescriptor.FeatureKey: Any]] = [[
            .type: kNumberSpacingType,
            .selector: kMonospacedNumbersSelector
        ]]
        let descriptor = self.fontDescriptor.addingAttributes([.featureSettings: settings])
        return UIFont(descriptor: descriptor, size: self.pointSize)
    }
}

// MARK: - Worksheet Button (drop-in Toolbar item)
//
// Add this to your RoomDetailView toolbar:
//
//   .toolbar {
//       ToolbarItem(placement: .topBarTrailing) {
//           WorksheetButton(project: project, room: room)
//       }
//   }
//
// Or use it as a plain button in any Section.

struct WorksheetButton: View {
    let project: Project
    let room: Room
    
    @State private var pdfURL: URL?
    @State private var showingShareSheet = false
    @State private var showingError = false
    
    var body: some View {
        Button {
            generateAndShare()
        } label: {
            Label("Print Worksheet", systemImage: "printer.fill")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Could not generate worksheet", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func generateAndShare() {
        if let url = WorksheetRenderer.renderPDF(project: project, room: room) {
            pdfURL = url
            showingShareSheet = true
        } else {
            showingError = true
        }
    }
}

// MARK: - Worksheet Preview (opens PDF in-app before sharing)

struct WorksheetPreviewSheet: View {
    let project: Project
    let room: Room
    
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let url = pdfURL {
                    PDFPreviewView(url: url)
                } else {
                    ProgressView("Generating worksheet…")
                }
            }
            .navigationTitle("Worksheet Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(pdfURL == nil)
                }
            }
            .onAppear {
                if pdfURL == nil {
                    pdfURL = WorksheetRenderer.renderPDF(project: project, room: room)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

// MARK: - PDFKit Wrapper

struct PDFPreviewView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

// MARK: - iOS Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
