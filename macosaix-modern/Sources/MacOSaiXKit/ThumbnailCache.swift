import Foundation
import CoreGraphics
import ImageIO

/// Thread-safe, memory-bounded cache for tile display thumbnails (140px max dimension).
/// Evicts automatically under memory pressure and bounds total RAM footprint.
public final class MosaicThumbnailCache: @unchecked Sendable {
    public static let shared = MosaicThumbnailCache()
    
    private let cache = NSCache<NSURL, CGImage>()
    private let transferredCache = NSCache<NSString, CGImage>()
    
    public init() {
        cache.countLimit = 3000
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB max RAM
        transferredCache.countLimit = 2000
        transferredCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB max RAM
    }
    
    public func thumbnail(for url: URL, maxPixelSize: Int = 140) -> CGImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        let opts: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let src = CGImageSourceCreateWithURL(url as CFURL, opts as CFDictionary) else {
            return nil
        }
        let thumbOpts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, thumbOpts as CFDictionary) else {
            return nil
        }
        let cost = thumb.bytesPerRow * thumb.height
        cache.setObject(thumb, forKey: key, cost: cost)
        return thumb
    }
    
    /// Retrieves a tile display thumbnail, optionally applying Reinhard perceptual color transfer.
    public func thumbnail(
        for url: URL,
        targetStats: ColorStatistics?,
        colorTransferStrength: Float,
        maxPixelSize: Int = 140
    ) -> CGImage? {
        guard let base = thumbnail(for: url, maxPixelSize: maxPixelSize) else {
            return nil
        }
        
        guard let stats = targetStats, colorTransferStrength > 0.001 else {
            return base
        }
        
        // Quantize strength to 2% intervals to maximize cache hits while dragging the slider
        let quantizedPct = Int(round(colorTransferStrength * 50.0)) * 2
        let key = "\(url.path)#\(Int(stats.meanL * 1000))_\(Int(stats.meanA * 1000))_\(Int(stats.meanB * 1000))#\(quantizedPct)" as NSString
        if let cached = transferredCache.object(forKey: key) {
            return cached
        }
        
        let transferred = ColorTransfer.applyColorTransfer(to: base, targetStats: stats, strength: colorTransferStrength)
        let cost = transferred.bytesPerRow * transferred.height
        transferredCache.setObject(transferred, forKey: key, cost: cost)
        return transferred
    }
    
    public func preheatThumbnail(for url: URL, maxPixelSize: Int = 140) {
        _ = thumbnail(for: url, maxPixelSize: maxPixelSize)
    }
    
    public func clear() {
        cache.removeAllObjects()
        transferredCache.removeAllObjects()
    }
}
