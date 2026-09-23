import Foundation
import CoreGraphics
import ImageIO
import MacOSaiXCore

public final class MosaicEngine: @unchecked Sendable {
    public let shapeType: MacOSaiXShapeType
    public let tilesAcross: Int
    public let tilesDown: Int
    public let curviness: Float
    public let maxReuse: Int
    public let minDistance: Int
    public let metric: MacOSaiXColorMetric
    
    public private(set) var tiles: [MacOSaiXTile] = []
    public private(set) var mosaicSize: CGSize = .zero
    public private(set) var targetImage: CGImage?
    
    public var isCancelled: Bool = false
    public var isPaused: Bool = false
    public var edgeWeight: Float = 0.0
    public var quadtreeMaxDepth: Int = 3
    public var quadtreeThreshold: Float = 0.15
    public var quadtreeBalanced: Bool = true
    public var quadtreeDetailAlpha: Float = 0.5
    public var quadtreeAlgorithm: MacOSaiXQuadtreeAlgorithm = .juliaRange
    public var quadtreeMinTileDim: Float = 16.0
    
    /// Optional callback called on match updates (for live GUI rendering).
    public var onTileUpdated: ((_ tileIndex: Int) -> Void)?
    
    public init(
        shapeType: MacOSaiXShapeType,
        tilesAcross: Int,
        tilesDown: Int,
        curviness: Float,
        maxReuse: Int = 0,
        minDistance: Int = 0,
        metric: MacOSaiXColorMetric = .riemersma,
        edgeWeight: Float = 0.0,
        quadtreeMaxDepth: Int = 3,
        quadtreeThreshold: Float = 0.15,
        quadtreeBalanced: Bool = true,
        quadtreeDetailAlpha: Float = 0.5,
        quadtreeAlgorithm: MacOSaiXQuadtreeAlgorithm = .juliaRange,
        quadtreeMinTileDim: Float = 16.0
    ) {
        self.shapeType = shapeType
        self.tilesAcross = tilesAcross
        self.tilesDown = tilesDown
        self.curviness = curviness
        self.maxReuse = maxReuse
        self.minDistance = minDistance
        self.metric = metric
        self.edgeWeight = edgeWeight
        self.quadtreeMaxDepth = quadtreeMaxDepth
        self.quadtreeThreshold = quadtreeThreshold
        self.quadtreeBalanced = quadtreeBalanced
        self.quadtreeDetailAlpha = quadtreeDetailAlpha
        self.quadtreeAlgorithm = quadtreeAlgorithm
        self.quadtreeMinTileDim = quadtreeMinTileDim
    }
    
    /// Loads the target image from a URL and prepares tile geometries, masks, and snippets.
    /// Downsamples images larger than maxDimension (default 2048) to avoid memory spikes and freezes.
    public func prepare(targetURL: URL, maxDimension: Int = 2048) throws {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(targetURL as CFURL, options as CFDictionary) else {
            throw NSError(domain: "MosaicEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open target image: \(targetURL.path)"])
        }
        
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let img = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            throw NSError(domain: "MosaicEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load target image: \(targetURL.path)"])
        }
        
        try prepare(with: img)
    }
    
    /// Normalizes any input CGImage (including 10-bit AVIF, HDR HEIC, IOSurface wrappers)
    /// into a standard 8-bit per channel sRGB in-memory raster CGImage.
    public static func normalizeToStandardSRGB(_ image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = width * 4
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return image
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage() ?? image
    }
    
    /// Prepares tile geometries, masks, and snippets using an in-memory CGImage.
    public func prepare(with image: CGImage) throws {
        let normalizedImage = Self.normalizeToStandardSRGB(image)
        self.targetImage = normalizedImage
        self.mosaicSize = CGSize(width: normalizedImage.width, height: normalizedImage.height)
        self.isCancelled = false
        self.isPaused = false
        
        // Generate tile shapes using battle-tested geometry formulas
        let geometries = MacOSaiXShapes.generateShapes(
            for: shapeType,
            targetImage: normalizedImage,
            mosaicSize: mosaicSize,
            across: tilesAcross,
            down: tilesDown,
            curviness: curviness,
            tabRatio: 0.8,
            maxDepth: quadtreeMaxDepth,
            detailThreshold: quadtreeThreshold,
            balanced: quadtreeBalanced,
            detailAlpha: quadtreeDetailAlpha,
            algorithm: quadtreeAlgorithm,
            minTileDim: quadtreeMinTileDim
        )
        
        // Build tile objects and extract thumbnails & masks
        self.tiles = geometries.map { geom in
            let tile = MacOSaiXTile(geometry: geom)
            tile.rasterizeMask(withResolution: 16)
            tile.extractTargetThumbnail(from: normalizedImage, mosaicSize: self.mosaicSize)
            return tile
        }
    }
    
    /// Processes an image candidate and tests it against all tiles. Returns true if any tile was updated.
    @discardableResult
    public func testCandidate(_ candidate: SourceImageCandidate) -> Bool {
        if isCancelled { return false }
        
        let matcher = MacOSaiXMatcher.shared()
        let candidatePixels = (candidate.thumbnailPixels as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        // 1. Calculate scores for all tiles
        var candidateScores: [(tileIndex: Int, score: Float)] = []
        candidateScores.reserveCapacity(tiles.count)
        
        for (idx, tile) in tiles.enumerated() {
            guard let targetData = tile.targetPixels, let maskData = tile.maskPixels else {
                continue
            }
            let targetBytes = (targetData as NSData).bytes.assumingMemoryBound(to: UInt8.self)
            let maskBytes = (maskData as NSData).bytes.assumingMemoryBound(to: UInt8.self)
            
            let score = matcher.compareTargetPixels(
                targetBytes,
                targetEdgeDesc: tile.edgeDescriptor,
                candidatePixels: candidatePixels,
                candidateEdgeDesc: candidate.edgeDescriptor,
                maskPixels: maskBytes,
                width: 16,
                height: 16,
                metric: metric,
                edgeWeight: edgeWeight
            )
            
            // Only consider if it beats the current best match
            if score < tile.bestScore {
                candidateScores.append((tileIndex: idx, score: score))
            }
        }
        
        if candidateScores.isEmpty {
            return false
        }
        
        // Sort candidate matches best first (lowest score = best)
        candidateScores.sort { $0.score < $1.score }
        
        var anyUpdated = false
        
        // 2. Assign to tiles respecting constraints
        for match in candidateScores {
            let tile = tiles[match.tileIndex]
            
            // Check reuse count
            if maxReuse > 0 {
                let currentUses = tiles.reduce(0) { count, t in
                    (t.bestImageIdentifier == candidate.identifier) ? count + 1 : count
                }
                if currentUses >= maxReuse {
                    break // Cannot reuse this image anymore
                }
            }
            
            // Check minimum distance constraint
            if minDistance > 0 {
                let gx = tile.geometry.gridX
                let gy = tile.geometry.gridY
                
                let tooClose = tiles.contains { otherTile in
                    guard otherTile.bestImageIdentifier == candidate.identifier else { return false }
                    let dx = otherTile.geometry.gridX - gx
                    let dy = otherTile.geometry.gridY - gy
                    let distSquared = dx * dx + dy * dy
                    return distSquared < (self.minDistance * self.minDistance)
                }
                
                if tooClose {
                    continue // Try next best tile
                }
            }
            
            // Update tile match
            tile.bestScore = match.score
            tile.bestImageIdentifier = candidate.identifier
            tile.bestImageURL = candidate.url
            anyUpdated = true
            
            onTileUpdated?(match.tileIndex)
        }
        
        return anyUpdated
    }
}
