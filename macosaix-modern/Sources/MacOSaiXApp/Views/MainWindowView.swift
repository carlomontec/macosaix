import SwiftUI
import AppKit
import MacOSaiXCore
import MacOSaiXKit

public struct MainWindowView: View {
    @EnvironmentObject private var viewModel: MosaicViewModel
    
    public init() {}
    
    public var body: some View {
        HSplitView {
            SidebarView()
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
            
            MosaicCanvasView()
                .frame(minWidth: 500, minHeight: 450)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Play / Pause matching
                Button(action: {
                    viewModel.toggleMatching()
                }) {
                    Label(
                        viewModel.isRunning ? (viewModel.isPaused ? "Resume" : "Pause") : "Start",
                        systemImage: viewModel.isRunning ? (viewModel.isPaused ? "play.fill" : "pause.fill") : "play.fill"
                    )
                }
                .disabled(!viewModel.canStart && !viewModel.isRunning)
                .keyboardShortcut("r", modifiers: [.command])
                
                if viewModel.isRunning {
                    Button(action: {
                        viewModel.stopMatching()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .keyboardShortcut(".", modifiers: [.command])
                }
                
                Spacer()
                
                // Status & Progress indicator
                HStack(spacing: 8) {
                    if (viewModel.isRunning && !viewModel.isPaused) || viewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: 280)
                .layoutPriority(0)
                
                Spacer()
                
                // Classic "Blend with Original" Slider
                HStack(spacing: 6) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Blend:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $viewModel.blendOpacity, in: 0.0...1.0)
                        .frame(width: 85)
                }
                .disabled(viewModel.targetCGImage == nil)
                .layoutPriority(2)
                
                Divider()
                
                // Export Button
                Button(action: {
                    viewModel.isExportSheetPresented = true
                }) {
                    Label("Export...", systemImage: "square.and.arrow.up")
                }
                .disabled(!viewModel.hasCompletedTiles)
                .keyboardShortcut("e", modifiers: [.command])
                
                // About Button
                Button(action: {
                    viewModel.isAboutPresented = true
                }) {
                    Image(systemName: "info.circle")
                }
                .help("About MacOSaiX Remake")
            }
        }
        .sheet(isPresented: $viewModel.isExportSheetPresented) {
            ExportSheetView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.isAboutPresented) {
            AboutView()
        }
        .popover(item: $viewModel.selectedTile) { tile in
            TileDetailPopover(tile: tile) {
                viewModel.selectedTile = nil
            }
        }
    }
}

// Extension to allow MacOSaiXTile in .popover(item:)
extension MacOSaiXTile: @retroactive Identifiable {
    public var id: Int {
        return self.geometry.tileIndex
    }
}
