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
                
                Text("Version 3.0.0 (Apple Silicon Native)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Description & Credits
            VStack(alignment: .leading, spacing: 14) {
                Text("A modern Apple Silicon remake of the classic Mac OS X photomosaic creator.")
                    .font(.callout)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historical Origins:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Original concept, design, and algorithms created by Frank M. Midgley (2002–2007). Widely celebrated as the premier photomosaic creator on classic Mac OS X.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modern Remake:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Revived and rebuilt by Carlo Monjaraz-Tec (2026) using AI-assisted coding (paired with Google Antigravity). It preserves Frank Midgley's original cubic Bezier jigsaw puzzle mathematics, hexagonal tessellations, and Riemersma perceptual color metrics, upgraded with modern additions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        bulletPoint("Native Apple HEIC (.heic) photo decoding via ImageIO")
                        bulletPoint("Multi-threaded asynchronous constraint solver")
                        bulletPoint("Real-time RAM pre-flight safety guard")
                        bulletPoint("Modern SwiftUI interface with live progressive canvas")
                        bulletPoint("Ultra-high-resolution bounded-memory vector exporter")
                        bulletPoint("AI-assisted development & modern Apple Silicon architecture")
                    }
                    .padding(.top, 2)
                    .padding(.leading, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Footer & Link
            HStack {
                Button(action: {
                    if let url = URL(string: "https://github.com/carlomontec/macosaix") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Project", systemImage: "link")
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
        .frame(width: 480)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
