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
    @State private var selectedPresetID: UUID = PhotorealPresetLibrary.bohoMorningEditorialSignature.id
    @State private var renderSpeed: RenderSpeed = .draft
    @State private var history: [RenderHistoryRecord] = []
    @State private var previewResult: WallPhotorealRenderer.PreviewResult?
    @State private var isSnapshotting: Bool = false
    @State private var packageResult: WallPhotorealRenderer.PackageResult?
    @State private var showShare: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var importTargetRecordID: UUID?
    @State private var importImage: PhotosPickerItem?
    @State private var statusMessage: String = ""
    
    private var selectedPreset: PhotorealPreset {
        presets.first(where: { $0.id == selectedPresetID }) ?? PhotorealPresetLibrary.bohoMorningEditorialSignature
    }
    
    var body: some View {
        Section("Photoreal Renders") {
            // Preset picker (grouped by style family)
            HStack {
                Text("Style")
                Spacer()
                Menu {
                    // Group presets by family. Presets without a family
                    // fall into an Other section.
                    let grouped = Dictionary(grouping: presets, by: { $0.styleFamily?.rawValue ?? "Other" })
                    let familyOrder = grouped.keys.sorted()
                    ForEach(familyOrder, id: \.self) { family in
                        Section(family) {
                            ForEach(grouped[family] ?? []) { p in
                                Button {
                                    selectedPresetID = p.id
                                    previewResult = nil
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
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(selectedPreset.name)
                                .foregroundStyle(.primary)
                            if let fam = selectedPreset.styleFamily?.rawValue {
                                Text(fam)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Speed picker — controls which image model is used.
            HStack {
                Text("Speed")
                Spacer()
                Picker("Speed", selection: $renderSpeed) {
                    ForEach(RenderSpeed.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }
            
            // Render / preview button
            Button {
                runPreview()
            } label: {
                HStack {
                    if isSnapshotting {
                        ProgressView()
                            .controlSize(.small)
                        Text("Snapshotting Furnished view...")
                    } else {
                        Label("Preview Photoreal Snapshot", systemImage: "wand.and.stars")
                    }
                }
            }
            .disabled(isSnapshotting)
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Inline preview of the pending snapshot
            if let preview = previewResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snapshot Preview")
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                    
                    if let img = preview.referenceImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Snapshot failed. You can still share the prompt JSON, then export the Furnished view manually.")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
                    }
                    
                    Text(preview.preset.name + " v\(preview.preset.version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    // Prompt inspector: what is actually being sent
                    DisclosureGroup("Structural Summary") {
                        Text(preview.structuralSummary)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                    }
                    .font(.caption)
                    
                    DisclosureGroup("Full Composed Prompt") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(preview.fullPrompt)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
                            Button {
                                UIPasteboard.general.string = preview.fullPrompt
                                statusMessage = "Prompt copied to clipboard."
                            } label: {
                                Label("Copy Prompt", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .font(.caption)
                    
                    HStack {
                        Button {
                            commitAndShare()
                        } label: {
                            Label("Share + Save to History", systemImage: "square.and.arrow.up")
                                .font(.callout)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(role: .destructive) {
                            previewResult = nil
                            statusMessage = "Preview discarded."
                        } label: {
                            Label("Discard", systemImage: "xmark")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button {
                            runPreview()
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSnapshotting)
                    }
                }
                .padding(.vertical, 4)
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
    
    private func runPreview() {
        statusMessage = ""
        isSnapshotting = true
        let preset = selectedPreset
        Task { @MainActor in
            let preview = await WallPhotorealRenderer.previewRequest(
                wall: wall,
                defaults: defaults,
                preset: preset,
                speed: renderSpeed,
                autoSnapshot: true
            )
            isSnapshotting = false
            if let preview {
                previewResult = preview
                if preview.referenceImage != nil {
                    statusMessage = "Snapshot captured. Review below, then Share + Save."
                } else {
                    statusMessage = "Snapshot could not be captured. Prompt JSON is still available."
                }
            } else {
                statusMessage = "Preview failed. Try again."
            }
        }
    }
    
    private func commitAndShare() {
        guard let preview = previewResult else { return }
        statusMessage = "Saving to history..."
        Task { @MainActor in
            if let result = await WallPhotorealRenderer.packageRequest(
                wall: wall,
                defaults: defaults,
                preset: preview.preset,
                speed: renderSpeed,
                referenceImage: preview.referenceImage,
                autoSnapshot: false,
                note: ""
            ) {
                packageResult = result
                history = WallPhotorealRenderer.loadHistory(wallID: wall.id.uuidString)
                previewResult = nil
                statusMessage = result.referenceImageURL != nil
                    ? "Saved to history. Sharing reference PNG and prompt JSON."
                    : "Saved to history. Sharing prompt JSON only."
                showShare = true
            } else {
                statusMessage = "Could not save. Try again."
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

// Uses the top-level ShareSheet defined in InteriorAuthorityWorksheet.swift.
