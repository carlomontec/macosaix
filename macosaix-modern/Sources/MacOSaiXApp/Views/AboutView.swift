import SwiftUI
import AppKit

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // App Icon
            if let iconImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: iconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            
            // Header
            VStack(spacing: 4) {
                Text("MacOSaiX Remake")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Apple Silicon Native • Classic Revival")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Description & Credits
            VStack(alignment: .leading, spacing: 14) {
                Text("A modern Apple Silicon revival of Frank M. Midgley's classic Mac OS X photomosaic software.")
                    .font(.callout)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original Software:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Created by Frank M. Midgley (2002–2009). MacOSaiX was the premier open-source photomosaic creator for classic Mac OS X.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("About this Remake:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("This project modernizes the original application to run natively on 64-bit Apple Silicon and modern macOS while preserving the classic feature set, mathematics, and user experience.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Footer & Link
            HStack {
                Button(action: {
                    if let url = URL(string: "https://github.com/carlomontec/MacOSaiX_Remake") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Repository", systemImage: "link")
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
        }
        .padding(26)
        .frame(width: 440)
    }
}
