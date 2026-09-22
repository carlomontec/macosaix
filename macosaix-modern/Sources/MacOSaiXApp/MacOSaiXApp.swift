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
                .navigationTitle("MacOSaiX")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
