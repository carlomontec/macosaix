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
    
    public init(
        shapeType: MacOSaiXShapeType,
        tilesAcross: Int,
        tilesDown: Int,
        curviness: Float,
        maxReuse: Int = 0,
        minDistance: Int = 0,
        metric: MacOSaiXColorMetric = .riemersma
    ) {
        self.shapeType = shapeType
        self.tilesAcross = tilesAcross
        self.tilesDown = tilesDown
        self.curviness = curviness
        self.maxReuse = maxReuse
        self.minDistance = minDistance
        self.metric = metric
    }
    
    /// Loads the target image and prepares all tile geometries, masks, and target snippets.
    public func prepare(targetURL: URL) throws {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: true
        ]
        guard let source = CGImageSourceCreateWithURL(targetURL as CFURL, options as CFDictionary),
              let img = CGImageSourceCreateImageAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else {
            throw NSError(domain: "MosaicEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load target image: \(targetURL.path)"])
        }
        
        self.targetImage = img
        self.mosaicSize = CGSize(width: img.width, height: img.height)
        
        // Generate tile shapes
        let geometries = MacOSaiXShapes.generateShapes(
            for: shapeType,
            mosaicSize: mosaicSize,
            across: tilesAcross,
            down: tilesDown,
            curviness: curviness,
            tabRatio: 0.8
        )
        
        print("Generated \(geometries.count) tile shapes.")
        
        // Build tile objects and extract thumbnails & masks
        self.tiles = geometries.map { geom in
            let tile = MacOSaiXTile(geometry: geom)
            tile.rasterizeMask(withResolution: 16)
            tile.extractTargetThumbnail(from: img, mosaicSize: self.mosaicSize)
            return tile
        }
    }
    
    /// Processes an image candidate and tests it against all tiles.
    public func testCandidate(_ candidate: SourceImageCandidate) {
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
                candidatePixels: candidatePixels,
                maskPixels: maskBytes,
                width: 16,
                height: 16,
                metric: metric
            )
            
            // Only consider if it beats the current best match
            if score < tile.bestScore {
                candidateScores.append((tileIndex: idx, score: score))
            }
        }
        
        if candidateScores.isEmpty {
            return
        }
        
        // Sort candidate matches best first (lowest score = best)
        candidateScores.sort { $0.score < $1.score }
        
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
        }
    }
}
