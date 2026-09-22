import SwiftUI
import AppKit

@main
struct MacOSaiXApp: App {
    @StateObject private var viewModel = MosaicViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(viewModel)
                .frame(minWidth: 960, minHeight: 650)
                .navigationTitle(viewModel.currentProjectURL?.lastPathComponent ?? "MacOSaiX Remake")
                .onOpenURL { url in
                    if url.pathExtension.lowercased() == "macosaix" {
                        viewModel.openProject(from: url)
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacOSaiX Remake") {
                    viewModel.isAboutPresented = true
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    viewModel.newProject()
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Open Project...") {
                    viewModel.openProjectPrompt()
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Divider()
                
                Button("Save Project") {
                    viewModel.saveProject()
                }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(viewModel.targetCGImage == nil)
                
                Button("Save Project As...") {
                    viewModel.saveProjectAsPrompt()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(viewModel.targetCGImage == nil)
                
                Divider()
                
                Button("Export Mosaic...") {
                    viewModel.isExportSheetPresented = true
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(!viewModel.hasCompletedTiles)
            }
        }
    }
}
