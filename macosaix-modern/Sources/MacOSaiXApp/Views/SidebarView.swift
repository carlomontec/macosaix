import SwiftUI
import AppKit
import MacOSaiXCore

public struct SidebarView: View {
    @EnvironmentObject private var viewModel: MosaicViewModel
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Section 1: Target Image
                GroupBox(label: Label("Original Image", systemImage: "photo")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TargetImageWell()
                    }
                    .padding(.top, 4)
                }
                
                // Section 2: Tile Shapes
                GroupBox(label: Label("Tile Shapes", systemImage: "square.grid.2x2")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Shape", selection: $viewModel.shapeType) {
                            Text("Square").tag(MacOSaiXShapeType.rectangular)
                            Text("Hexagon").tag(MacOSaiXShapeType.hexagonal)
                            Text("Puzzle").tag(MacOSaiXShapeType.puzzle)
                        }
                        .pickerStyle(.segmented)
                        .disabled(viewModel.isRunning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tiles Across:")
                                Spacer()
                                Text("\(viewModel.tilesAcross)")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            Slider(value: Binding(
                                get: { Double(viewModel.tilesAcross) },
                                set: { viewModel.tilesAcross = Int($0) }
                            ), in: 10...80, step: 2)
                            .disabled(viewModel.isRunning)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tiles Down:")
                                Spacer()
                                Text("\(viewModel.tilesDown)")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            Slider(value: Binding(
                                get: { Double(viewModel.tilesDown) },
                                set: { viewModel.tilesDown = Int($0) }
                            ), in: 10...60, step: 2)
                            .disabled(viewModel.isRunning)
                        }
                        
                        if viewModel.shapeType == .puzzle {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Puzzle Curviness:")
                                    Spacer()
                                    Text(String(format: "%.1f", viewModel.curviness))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                .font(.caption)
                                Slider(value: $viewModel.curviness, in: 0.0...1.0, step: 0.1)
                                .disabled(viewModel.isRunning)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Piece Cutlines:")
                                Spacer()
                                Text(viewModel.strokeWidth > 0 ? String(format: "%.1f px", viewModel.strokeWidth) : "Off")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            Slider(value: $viewModel.strokeWidth, in: 0.0...2.0, step: 0.25)
                        }
                        
                        HStack {
                            Text("Total Tiles:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.totalTilesCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Section 3: Photo Sources
                GroupBox(label: Label("Photo Sources", systemImage: "folder")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.sourceFolders.isEmpty {
                            Text("No folders added yet.\nDrag & drop folders here or click + Add Folder.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(viewModel.sourceFolders, id: \.self) { folder in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                    Text(folder.lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button(action: {
                                        viewModel.removeSourceFolder(folder)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        HStack {
                            Button("+ Add Folder...") {
                                chooseSourceFolder()
                            }
                            .controlSize(.small)
                            .disabled(viewModel.isRunning)
                            
                            Spacer()
                            
                            if !viewModel.foundImageURLs.isEmpty {
                                Text("\(viewModel.foundImageURLs.count) photos")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !viewModel.formatBreakdownText.isEmpty {
                            Text(viewModel.formatBreakdownText)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.foundImageURLs.isEmpty && viewModel.totalTilesCount > 0 && viewModel.foundImageURLs.count < viewModel.totalTilesCount {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Tip: You have fewer photos (\(viewModel.foundImageURLs.count)) than tiles (\(viewModel.totalTilesCount)). For best results, set Max Reuse to Unlimited and Blend to 15–25%.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    .padding(.top, 4)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(viewModel.isSourcesDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.isSourcesDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                )
                .onDrop(of: [.fileURL], isTargeted: $viewModel.isSourcesDropTargeted) { providers in
                    handleDroppedSources(providers)
                    return true
                }
                
                // Section 4: Image Usage Constraints
                GroupBox(label: Label("Placement Rules", systemImage: "slider.horizontal.3")) {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Max Reuse:")
                                Spacer()
                                Text(viewModel.maxReuse == 0 ? "Unlimited" : "\(viewModel.maxReuse)×")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            Slider(value: Binding(
                                get: { Double(viewModel.maxReuse) },
                                set: { viewModel.maxReuse = Int($0) }
                            ), in: 0...10, step: 1)
                            .disabled(viewModel.isRunning)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Min Distance:")
                                Spacer()
                                Text("\(viewModel.minDistance) tiles")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            Slider(value: Binding(
                                get: { Double(viewModel.minDistance) },
                                set: { viewModel.minDistance = Int($0) }
                            ), in: 0...6, step: 1)
                            .disabled(viewModel.isRunning)
                        }
                        
                        Picker("Metric", selection: $viewModel.colorMetric) {
                            Text("Riemersma (Eye)").tag(MacOSaiXColorMetric.riemersma)
                            Text("RGB Distance").tag(MacOSaiXColorMetric.RGB)
                        }
                        .pickerStyle(.menu)
                        .font(.caption)
                        .disabled(viewModel.isRunning)
                    }
                    .padding(.top, 4)
                }
                
                // Section 5: Memory Safety Badge
                HStack {
                    Image(systemName: viewModel.isMemorySafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.isMemorySafe ? .green : .orange)
                    Text("RAM Footprint: ~\(viewModel.estimatedRAMText)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.isMemorySafe ? "Safe" : "Caution")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.isMemorySafe ? .green : .orange)
                }
                .padding(.horizontal, 4)
            }
            .padding()
        }
    }
    
    private func chooseSourceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Add Photos"
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                viewModel.addSourceFolder(url)
            }
        }
    }
    
    private func handleDroppedSources(_ providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let fileURL = url else { return }
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                    DispatchQueue.main.async {
                        if isDir.boolValue {
                            viewModel.addSourceFolder(fileURL)
                        } else {
                            // If an image file was dropped, add its containing folder
                            let folder = fileURL.deletingLastPathComponent()
                            viewModel.addSourceFolder(folder)
                        }
                    }
                }
            }
        }
    }
}
