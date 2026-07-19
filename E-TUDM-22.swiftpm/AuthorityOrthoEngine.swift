import SwiftUI
import CryptoKit

struct AuthorityOrthoValidationResult {
    var errors: [String]
    var isValid: Bool { errors.isEmpty }
}

enum AuthorityOrthoEngine {

    static func validate(_ wall: StoredWallAuthority) -> AuthorityOrthoValidationResult {
        var errors: [String] = []

        guard let wallWidth = Double(wall.width), wallWidth > 0 else {
            errors.append("Wall width is missing or invalid.")
            return AuthorityOrthoValidationResult(errors: errors)
        }

        guard let wallHeight = Double(wall.height), wallHeight > 0 else {
            errors.append("Wall height is missing or invalid.")
            return AuthorityOrthoValidationResult(errors: errors)
        }

        for (index, column) in wall.columns.enumerated() {
            if Double(column.startX) == nil { errors.append("Column \(index + 1) needs Start X.") }
            if Double(column.bottomAFF) == nil { errors.append("Column \(index + 1) needs Bottom AFF.") }
            if Double(column.width) == nil { errors.append("Column \(index + 1) needs Width.") }
            if Double(column.height) == nil { errors.append("Column \(index + 1) needs Height.") }
        }

        for (index, opening) in wall.openings.enumerated() {
            if Double(opening.startX) == nil { errors.append("Opening \(index + 1) needs Start X.") }
            if Double(opening.bottomAFF) == nil { errors.append("Opening \(index + 1) needs Bottom AFF.") }
            if Double(opening.width) == nil { errors.append("Opening \(index + 1) needs Width.") }
            if Double(opening.height) == nil { errors.append("Opening \(index + 1) needs Height.") }
        }

        for (index, beam) in wall.beams.enumerated() {
            if Double(beam.startX) == nil { errors.append("Beam \(index + 1) needs Start X.") }
            if Double(beam.endX) == nil { errors.append("Beam \(index + 1) needs End X.") }
            if Double(beam.undersideHeight) == nil { errors.append("Beam \(index + 1) needs Underside Height AFF.") }
            if Double(beam.height) == nil { errors.append("Beam \(index + 1) needs Height / Depth.") }
        }

        for (index, builtIn) in wall.builtIns.enumerated() {
            if Double(builtIn.startX) == nil { errors.append("Built-in \(index + 1) needs Start X.") }
            if Double(builtIn.bottomAFF) == nil { errors.append("Built-in \(index + 1) needs Bottom AFF.") }
            if Double(builtIn.width) == nil { errors.append("Built-in \(index + 1) needs Width.") }
            if Double(builtIn.height) == nil { errors.append("Built-in \(index + 1) needs Height.") }
        }

        if let maxColumn = wall.columns.compactMap({ column -> Double? in
            guard let x = Double(column.startX), let width = Double(column.width) else { return nil }
            return x + width
        }).max(), maxColumn > wallWidth {
            errors.append("A column extends beyond the wall width.")
        }

        if let maxOpening = wall.openings.compactMap({ opening -> Double? in
            guard let x = Double(opening.startX), let width = Double(opening.width) else { return nil }
            return x + width
        }).max(), maxOpening > wallWidth {
            errors.append("An opening extends beyond the wall width.")
        }

        if let maxBuiltIn = wall.builtIns.compactMap({ builtIn -> Double? in
            guard let x = Double(builtIn.startX), let width = Double(builtIn.width) else { return nil }
            return x + width
        }).max(), maxBuiltIn > wallWidth {
            errors.append("A built-in extends beyond the wall width.")
        }

        return AuthorityOrthoValidationResult(errors: errors)
    }

    static func checksum(for wall: StoredWallAuthority) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(wall)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    @MainActor
    static func renderPNG(
        wall: StoredWallAuthority,
        projectID: UUID,
        roomCode: String
    ) throws -> String {
        let view = OrthographicAuthorityBoard(wall: wall)
            .frame(width: 1800, height: 1200)
            .background(Color(red: 0.95, green: 0.93, blue: 0.89))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1

        guard let image = renderer.uiImage,
              let data = image.pngData() else {
            throw RenderError.imageCreationFailed
        }

        let filename = "\(projectID.uuidString)_\(roomCode)_\(wall.wallCode)_ORTHO_AUTHORITY.png"
        let url = documentsDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return filename
    }

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    enum RenderError: LocalizedError {
        case imageCreationFailed

        var errorDescription: String? {
            "The deterministic orthographic image could not be created."
        }
    }
}

struct OrthographicAuthorityBoard: View {

    let wall: StoredWallAuthority

    private var wallWidth: Double { Double(wall.width) ?? 1 }
    private var wallHeight: Double { Double(wall.height) ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(wall.wallCode) — \(wall.wallName)")
                    .font(.system(size: 34, weight: .bold))
                Text("DETERMINISTIC ORTHOGRAPHIC AUTHORITY — FLAT ELEVATION — NO PERSPECTIVE")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                let inset: CGFloat = 90
                let availableWidth = max(proxy.size.width - inset * 2, 1)
                let availableHeight = max(proxy.size.height - 190, 1)
                let scale = min(
                    availableWidth / CGFloat(wallWidth),
                    availableHeight / CGFloat(wallHeight)
                )
                let originX = inset
                let originY = proxy.size.height - 90

                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.white)
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                        .frame(
                            width: CGFloat(wallWidth) * scale,
                            height: CGFloat(wallHeight) * scale
                        )
                        .position(
                            x: originX + CGFloat(wallWidth) * scale / 2,
                            y: originY - CGFloat(wallHeight) * scale / 2
                        )

                    ForEach(wall.columns) { column in
                        elementRectangle(
                            x: Double(column.startX) ?? 0,
                            y: Double(column.bottomAFF) ?? 0,
                            width: Double(column.width) ?? 0,
                            height: Double(column.height) ?? 0,
                            scale: scale,
                            originX: originX,
                            originY: originY,
                            fill: Color.gray.opacity(0.65),
                            label: column.name.isEmpty ? "COLUMN" : column.name
                        )
                    }

                    ForEach(wall.openings) { opening in
                        elementRectangle(
                            x: Double(opening.startX) ?? 0,
                            y: Double(opening.bottomAFF) ?? 0,
                            width: Double(opening.width) ?? 0,
                            height: Double(opening.height) ?? 0,
                            scale: scale,
                            originX: originX,
                            originY: originY,
                            fill: Color.blue.opacity(0.12),
                            label: opening.name.isEmpty ? opening.type : opening.name,
                            dashed: true
                        )
                    }

                    ForEach(wall.beams) { beam in
                        let x0 = Double(beam.startX) ?? 0
                        let x1 = Double(beam.endX) ?? x0
                        let underside = Double(beam.undersideHeight) ?? 0
                        let height = Double(beam.height) ?? 0

                        elementRectangle(
                            x: x0,
                            y: underside,
                            width: max(x1 - x0, 0),
                            height: height,
                            scale: scale,
                            originX: originX,
                            originY: originY,
                            fill: Color.black.opacity(0.78),
                            label: beam.name.isEmpty ? "BEAM" : beam.name
                        )
                    }

                    ForEach(wall.builtIns) { builtIn in
                        elementRectangle(
                            x: Double(builtIn.startX) ?? 0,
                            y: Double(builtIn.bottomAFF) ?? 0,
                            width: Double(builtIn.width) ?? 0,
                            height: Double(builtIn.height) ?? 0,
                            scale: scale,
                            originX: originX,
                            originY: originY,
                            fill: Color.orange.opacity(0.32),
                            label: builtIn.name.isEmpty ? builtIn.type : builtIn.name
                        )
                    }

                    Path { path in
                        path.move(to: CGPoint(x: originX, y: originY + 28))
                        path.addLine(to: CGPoint(x: originX + CGFloat(wallWidth) * scale, y: originY + 28))
                    }
                    .stroke(Color.blue, lineWidth: 2)

                    Text("\(format(wallWidth)) in OVERALL")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.blue)
                        .position(
                            x: originX + CGFloat(wallWidth) * scale / 2,
                            y: originY + 52
                        )
                }
            }

            HStack {
                Text("STATUS: \(wall.isApproved ? "APPROVED / LOCKED" : "WORKING")")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("CHECKSUM: \(wall.approvedChecksum.isEmpty ? "NOT APPROVED" : String(wall.approvedChecksum.prefix(20)))")
                    .font(.system(size: 13, design: .monospaced))
            }
        }
        .padding(40)
    }

    @ViewBuilder
    private func elementRectangle(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        scale: CGFloat,
        originX: CGFloat,
        originY: CGFloat,
        fill: Color,
        label: String,
        dashed: Bool = false
    ) -> some View {
        let rectWidth = CGFloat(width) * scale
        let rectHeight = CGFloat(height) * scale
        let centerX = originX + CGFloat(x) * scale + rectWidth / 2
        let centerY = originY - CGFloat(y) * scale - rectHeight / 2

        Rectangle()
            .fill(fill)
            .overlay(
                Rectangle()
                    .stroke(
                        Color.black,
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: dashed ? [10, 6] : []
                        )
                    )
            )
            .frame(width: rectWidth, height: rectHeight)
            .position(x: centerX, y: centerY)
            .overlay(
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .position(x: centerX, y: centerY)
            )
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

struct OrthographicAuthorityWorkspace: View {

    let wall: StoredWallAuthority

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            OrthographicAuthorityBoard(wall: wall)
                .frame(width: 1100, height: 760)
                .padding()
        }
        .navigationTitle("\(wall.wallCode) Ortho Authority")
        .navigationBarTitleDisplayMode(.inline)
    }
}
