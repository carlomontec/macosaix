import SwiftUI
import AppKit
import MacOSaiXCore

public struct TileDetailPopover: View {
    let tile: MacOSaiXTile
    let onClose: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tile (\(tile.geometry.gridX), \(tile.geometry.gridY))")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if let imageURL = tile.bestImageURL {
                if let nsImg = NSImage(contentsOf: imageURL) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240, maxHeight: 180)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(imageURL.lastPathComponent)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    let matchPct = max(0, min(100, Int((1.0 - tile.bestScore) * 100)))
                    Text("Match Quality: \(matchPct)%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([imageURL])
                    }
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            } else {
                Text("No photo matched to this tile yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(width: 260)
    }
}
