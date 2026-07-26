import SwiftUI
import UIKit
import PhotosUI

// MARK: - Photoreal Renders section
//
// Drops into WallFormView below the elevation preview. Shows the
// active preset, offers a one-tap Render action that packages the
// reference PNG + prompt JSON, and lists render history for the
// wall with import + canonical-pin controls.

struct WallPhotorealSection: View {
    let wall: LockedWall
    let defaults: RoomDefaults
    
    @State private var presets: [PhotorealPreset] = PhotorealPresetLibrary.load()
    @State private var selectedPresetID: UUID = PhotorealPresetLibrary.bohoMorningEditorial.id
    @State private var history: [RenderHistoryRecord] = []
    @State private var packageResult: WallPhotorealRenderer.PackageResult?
    @State private var showShare: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var importTargetRecordID: UUID?
    @State private var importImage: PhotosPickerItem?
    @State private var statusMessage: String = ""
    
    private var selectedPreset: PhotorealPreset {
        presets.first(where: { $0.id == selectedPresetID }) ?? PhotorealPresetLibrary.bohoMorningEditorial
    }
    
    var body: some View {
        Section("Photoreal Renders") {
            // Preset picker
            HStack {
                Text("Preset")
                Spacer()
                Menu {
                    ForEach(presets) { p in
                        Button {
                            selectedPresetID = p.id
                        } label: {
                            HStack {
                                Text(p.name)
                                if p.id == selectedPresetID {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPreset.name)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Render button
            Button {
                packageAndShare()
            } label: {
                Label("Render Photoreal (Package + Share)", systemImage: "wand.and.stars")
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Canonical preview
            if let canonical = history.first(where: { $0.isCanonical }),
               let img = WallPhotorealRenderer.loadFinishedImage(for: canonical) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canonical Render")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // History list
            if history.isEmpty {
                Text("No renders yet. Tap Render Photoreal to create the first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history) { record in
                    RenderHistoryRow(
                        record: record,
                        onImport: { importForRecord(record) },
                        onPin: { pinCanonical(record) },
                        onDelete: { deleteRecord(record) }
                    )
                }
            }
        }
        .onAppear {
            history = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
        }
        .sheet(isPresented: $showShare) {
            if let pkg = packageResult {
                let items: [Any] = {
                    var arr: [Any] = [pkg.promptJSONURL]
                    if let ref = pkg.referenceImageURL { arr.insert(ref, at: 0) }
                    return arr
                }()
                ShareSheet(items: items)
            }
        }
        .photosPicker(isPresented: $showImportPicker,
                      selection: $importImage,
                      matching: .images)
        .onChange(of: importImage) { _, newValue in
            guard let newValue,
                  let recordID = importTargetRecordID else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    WallPhotorealRenderer.importFinishedImage(
                        img,
                        recordID: recordID,
                        wallID: wall.id.uuidString,
                        pinAsCanonical: true
                    )
                    await MainActor.run {
                        history = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
                        statusMessage = "Finished image imported and pinned as canonical."
                    }
                }
                importImage = nil
                importTargetRecordID = nil
            }
        }
    }
    
    private func packageAndShare() {
        statusMessage = "Packaging render request..."
        Task { @MainActor in
            let preset = selectedPreset
            if let result = WallPhotorealRenderer.packageRequest(
                wall: wall,
                defaults: defaults,
                preset: preset,
                referenceImage: nil,
                note: ""
            ) {
                packageResult = result
                history = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
                statusMessage = "Ready. Prompt JSON is being shared. Also export the Furnished view via Export Render Frame to Photos and attach both to your Perplexity session. Then Import the finished PNG below."
                showShare = true
            } else {
                statusMessage = "Could not package the render. Try again."
            }
        }
    }
    
    private func importForRecord(_ record: RenderHistoryRecord) {
        importTargetRecordID = record.id
        showImportPicker = true
    }
    
    private func pinCanonical(_ record: RenderHistoryRecord) {
        WallPhotorealRenderer.setCanonical(recordID: record.id, wallID: wall.id.uuidString)
        history = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
    }
    
    private func deleteRecord(_ record: RenderHistoryRecord) {
        var records = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
        records.removeAll { $0.id == record.id }
        WallPhotorealRenderer.saveHistory(records, wallID: wall.id.uuidString)
        history = records
    }
}

// MARK: - History row

private struct RenderHistoryRow: View {
    let record: RenderHistoryRecord
    let onImport: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.presetName)
                    .font(.subheadline)
                if record.isCanonical {
                    Text("CANONICAL")
                        .font(.caption2).bold()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green))
                }
                Spacer()
                Text(record.createdAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                if let ref = WallPhotorealRenderer.loadReferenceImage(for: record) {
                    Image(uiImage: ref)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if let finished = WallPhotorealRenderer.loadFinishedImage(for: record) {
                    Image(uiImage: finished)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("No finished PNG yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Button("Import Finished") {
                    onImport()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                
                if record.finishedImageFilename != nil, !record.isCanonical {
                    Button("Set Canonical") {
                        onPin()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share sheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
