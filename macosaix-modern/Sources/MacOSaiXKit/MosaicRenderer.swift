import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import MacOSaiXCore

public final class MosaicRenderer {
    public init() {}
    
    public func render(
        tiles: [MacOSaiXTile],
        mosaicSize: CGSize,
        outputWidth: Int,
        strokeWidth: Float = 0.0,
        outputURL: URL
    ) throws {
        let scale = CGFloat(outputWidth) / mosaicSize.width
        let outputHeight = max(1, Int(mosaicSize.height * scale))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = outputWidth * 4
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw NSError(domain: "MosaicRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
        }
        
        // High quality interpolation
        context.interpolationQuality = .high
        
        // Clear to transparent/black
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
        
        // Transform context from mosaic coordinate space to output pixel space
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        
        // Render each tile with bounded memory footprint
        for tile in tiles {
            autoreleasepool {
                context.saveGState()
                
                // Clip to tile's exact vector outline
                context.addPath(tile.geometry.outline)
                context.clip()
                
                if let imageURL = tile.bestImageURL {
                    let bounds = tile.geometry.bounds
                    let targetPixelDim = max(16, Int(max(bounds.width, bounds.height) * scale * 1.5))
                    
                    let opts: [CFString: Any] = [
                        kCGImageSourceShouldCache: false
                    ]
                    
                    var img: CGImage? = nil
                    if let src = CGImageSourceCreateWithURL(imageURL as CFURL, opts as CFDictionary) {
                        let drawOpts: [CFString: Any] = [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceThumbnailMaxPixelSize: targetPixelDim,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceShouldCacheImmediately: true
                        ]
                        img = CGImageSourceCreateThumbnailAtIndex(src, 0, drawOpts as CFDictionary)
                    }
                    
                    if let cgImage = img {
                        let imgW = CGFloat(cgImage.width)
                        let imgH = CGFloat(cgImage.height)
                        let fillScale = max(bounds.width / imgW, bounds.height / imgH)
                        let drawW = imgW * fillScale
                        let drawH = imgH * fillScale
                        let drawX = bounds.midX - drawW / 2.0
                        let drawY = bounds.midY - drawH / 2.0
                        
                        context.draw(cgImage, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
                    }
                } else {
                    // Fallback fill
                    context.setFillColor(CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0))
                    context.fill(tile.geometry.bounds)
                }
                
                context.restoreGState()
                
                // Optional outline stroke around tile borders
                if strokeWidth > 0.001 {
                    context.saveGState()
                    context.setStrokeColor(CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.35))
                    context.setLineWidth(CGFloat(strokeWidth) / scale)
                    context.addPath(tile.geometry.outline)
                    context.strokePath()
                    context.restoreGState()
                }
            }
        }
        
        context.restoreGState()
        
        // Export to disk via CGImageDestination
        guard let finalCGImage = context.makeImage() else {
            throw NSError(domain: "MosaicRenderer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate final image from context"])
        }
        
        let ext = outputURL.pathExtension.lowercased()
        let uti: CFString
        if ext == "jpg" || ext == "jpeg" {
            uti = UTType.jpeg.identifier as CFString
        } else {
            uti = UTType.png.identifier as CFString
        }
        
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, uti, 1, nil) else {
            throw NSError(domain: "MosaicRenderer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination at \(outputURL.path)"])
        }
        
        let exportProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.95
        ]
        
        CGImageDestinationAddImage(destination, finalCGImage, exportProperties as CFDictionary)
        if !CGImageDestinationFinalize(destination) {
            throw NSError(domain: "MosaicRenderer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to write image to \(outputURL.path)"])
        }
    }
}
