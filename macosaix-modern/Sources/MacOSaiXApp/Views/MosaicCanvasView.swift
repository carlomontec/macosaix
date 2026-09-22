import SwiftUI
import AppKit
import CoreGraphics
import ImageIO
import MacOSaiXCore
import MacOSaiXKit

public struct MosaicCanvasView: View {
    @EnvironmentObject private var viewModel: MosaicViewModel
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor.underPageBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
                
                if viewModel.targetCGImage != nil {
                    MosaicRepresentable(
                        canvasVersion: viewModel.canvasVersion,
                        engine: viewModel.engine,
                        targetImage: viewModel.targetCGImage,
                        blendOpacity: viewModel.blendOpacity,
                        strokeWidth: viewModel.strokeWidth,
                        onTileTapped: { tile in
                            viewModel.selectedTile = tile
                        }
                    )
                    .scaleEffect(viewModel.zoomScale)
                    .offset(viewModel.panOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { val in
                                viewModel.zoomScale = max(0.25, min(4.0, val))
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                viewModel.panOffset = val.translation
                            }
                            .onEnded { _ in
                                // retain offset
                            }
                    )
                    .padding(20)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 3)
                    
                    // Floating Controls Bar (Zoom + Blend)
                    VStack {
                        Spacer()
                        HStack(spacing: 14) {
                            // Zoom Section
                            HStack(spacing: 6) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        viewModel.zoomScale = max(0.25, viewModel.zoomScale - 0.25)
                                    }
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                                .help("Zoom Out")
                                
                                Slider(value: $viewModel.zoomScale, in: 0.25...4.0)
                                    .frame(width: 90)
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        viewModel.zoomScale = min(4.0, viewModel.zoomScale + 0.25)
                                    }
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                                .help("Zoom In")
                                
                                Text("\(Int(viewModel.zoomScale * 100))%")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                                    .frame(width: 36, alignment: .trailing)
                                
                                Button("Fit") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.zoomScale = 1.0
                                        viewModel.panOffset = .zero
                                    }
                                }
                                .controlSize(.small)
                                .buttonStyle(.bordered)
                                .help("Reset Zoom & Centering")
                            }
                            
                            Divider()
                                .frame(height: 16)
                            
                            // Blend Slider Section
                            HStack(spacing: 6) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Blend:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: $viewModel.blendOpacity, in: 0.0...1.0)
                                    .frame(width: 80)
                                Text("\(Int(viewModel.blendOpacity * 100))%")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                        .padding(.bottom, 16)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Mosaic Loaded")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Drag a picture into the sidebar or click 'Choose Picture...' to start.")
                            .font(.callout)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
        }
    }
}

private struct MosaicRepresentable: NSViewRepresentable {
    let canvasVersion: Int
    let engine: MosaicEngine?
    let targetImage: CGImage?
    let blendOpacity: Double
    let strokeWidth: Double
    let onTileTapped: (MacOSaiXTile) -> Void
    
    func makeNSView(context: Context) -> NSMosaicView {
        let view = NSMosaicView()
        view.onTileTapped = onTileTapped
        return view
    }
    
    func updateNSView(_ nsView: NSMosaicView, context: Context) {
        nsView.engine = engine
        nsView.targetImage = targetImage
        nsView.blendOpacity = blendOpacity
        nsView.strokeWidth = strokeWidth
        nsView.onTileTapped = onTileTapped
        nsView.needsDisplay = true
    }
}

private final class NSMosaicView: NSView {
    var engine: MosaicEngine?
    var targetImage: CGImage?
    var blendOpacity: Double = 0.0
    var strokeWidth: Double = 0.5
    var onTileTapped: ((MacOSaiXTile) -> Void)?
    
    override var isFlipped: Bool { true }
    
    override func mouseDown(with event: NSEvent) {
        guard let engine = self.engine else { return }
        let location = convert(event.locationInWindow, from: nil)
        
        let mSize = engine.mosaicSize
        guard mSize.width > 0, mSize.height > 0 else { return }
        let scale = min(bounds.width / mSize.width, bounds.height / mSize.height)
        let drawOriginX = (bounds.width - mSize.width * scale) / 2.0
        let drawOriginY = (bounds.height - mSize.height * scale) / 2.0
        
        // Convert to mosaic coordinates
        let mosaicPoint = CGPoint(
            x: (location.x - drawOriginX) / scale,
            y: (location.y - drawOriginY) / scale
        )
        
        // Find tapped tile
        for tile in engine.tiles {
            if tile.geometry.outline.contains(mosaicPoint) {
                onTileTapped?(tile)
                return
            }
        }
    }
    
    /// Draws an image right-side up inside a flipped NSView context
    private func drawUprightImage(_ image: CGImage, in rect: CGRect, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(image, in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        context.restoreGState()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let engine = self.engine,
              let target = self.targetImage else {
            return
        }
        
        let mSize = engine.mosaicSize
        guard mSize.width > 0, mSize.height > 0 else { return }
        
        let scale = min(bounds.width / mSize.width, bounds.height / mSize.height)
        let drawOriginX = (bounds.width - mSize.width * scale) / 2.0
        let drawOriginY = (bounds.height - mSize.height * scale) / 2.0
        
        context.saveGState()
        context.translateBy(x: drawOriginX, y: drawOriginY)
        context.scaleBy(x: scale, y: scale)
        
        // Draw tiles
        for tile in engine.tiles {
            context.saveGState()
            context.addPath(tile.geometry.outline)
            context.clip()
            
            if let imageURL = tile.bestImageURL {
                if let cgImg = MosaicThumbnailCache.shared.thumbnail(for: imageURL) {
                    let b = tile.geometry.bounds
                    let imgW = CGFloat(cgImg.width)
                    let imgH = CGFloat(cgImg.height)
                    let fillScale = max(b.width / imgW, b.height / imgH)
                    let drawW = imgW * fillScale
                    let drawH = imgH * fillScale
                    let drawX = b.midX - drawW / 2.0
                    let drawY = b.midY - drawH / 2.0
                    
                    // Draw tile image right-side up
                    drawUprightImage(cgImg, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH), in: context)
                }
            } else {
                // If not yet matched, draw dimmed snippet of original image right-side up
                drawUprightImage(target, in: CGRect(origin: .zero, size: mSize), in: context)
                context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
                context.fill(tile.geometry.bounds)
            }
            context.restoreGState()
            
            // Draw tile boundary stroke
            if strokeWidth > 0.01 {
                context.saveGState()
                context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.3))
                context.setLineWidth(CGFloat(strokeWidth) / scale)
                context.addPath(tile.geometry.outline)
                context.strokePath()
                context.restoreGState()
            }
        }
        
        // Classic "Blend with Original" overlay, right-side up
        if blendOpacity > 0.01 {
            context.saveGState()
            context.setAlpha(CGFloat(blendOpacity))
            drawUprightImage(target, in: CGRect(origin: .zero, size: mSize), in: context)
            context.restoreGState()
        }
        
        context.restoreGState()
    }
}
