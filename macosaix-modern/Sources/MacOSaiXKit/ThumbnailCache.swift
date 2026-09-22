import Foundation
import CoreGraphics
import ImageIO

/// Thread-safe, memory-bounded cache for tile display thumbnails (140px max dimension).
/// Evicts automatically under memory pressure and bounds total RAM footprint.
public final class MosaicThumbnailCache: @unchecked Sendable {
    public static let shared = MosaicThumbnailCache()
    
    private let cache = NSCache<NSURL, CGImage>()
    
    public init() {
        cache.countLimit = 3000
        cache.totalCostLimit = 150 * 1024 * 1024 // 150 MB max RAM
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
    
    public func preheatThumbnail(for url: URL, maxPixelSize: Int = 140) {
        _ = thumbnail(for: url, maxPixelSize: maxPixelSize)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
}
