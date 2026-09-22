import SwiftUI
import AppKit
import CoreGraphics
import ImageIO
import MacOSaiXCore
import MacOSaiXKit

@MainActor
public final class MosaicViewModel: ObservableObject {
    // MARK: - Target Image State
    @Published public var targetImageURL: URL?
    @Published public var targetNSImage: NSImage?
    @Published public var targetCGImage: CGImage?
    @Published public var targetResolutionText: String = "No image loaded"
    
    // MARK: - Settings State
    @Published public var shapeType: MacOSaiXShapeType = .puzzle {
        didSet { if shapeType != oldValue { prepareTiles() } }
    }
    @Published public var tilesAcross: Int = 30 {
        didSet { if tilesAcross != oldValue { prepareTiles() } }
    }
    @Published public var tilesDown: Int = 20 {
        didSet { if tilesDown != oldValue { prepareTiles() } }
    }
    @Published public var curviness: Double = 0.5 {
        didSet { if curviness != oldValue { prepareTiles() } }
    }
    @Published public var strokeWidth: Double = 0.5
    @Published public var maxReuse: Int = 0
    @Published public var minDistance: Int = 2
    @Published public var colorMetric: MacOSaiXColorMetric = .riemersma
    
    // Blend with Original (0.0 = 100% Mosaic, 1.0 = 100% Original Photo)
    @Published public var blendOpacity: Double = 0.0
    
    // MARK: - Image Sources State
    @Published public var sourceFolders: [URL] = []
    @Published public var foundImageURLs: [URL] = []
    @Published public var heicCount: Int = 0
    
    // MARK: - Execution & Matching State
    @Published public var engine: MosaicEngine?
    @Published public var isRunning: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var processedImagesCount: Int = 0
    @Published public var totalImagesCount: Int = 0
    @Published public var matchedTilesCount: Int = 0
    @Published public var totalTilesCount: Int = 0
    @Published public var averageScore: Float = 1.0
    @Published public var statusMessage: String = "Drag an image to begin"
    
    // Canvas Redraw Trigger
    @Published public var canvasVersion: Int = 0
    
    // Selected Tile for Inspection Popover
    @Published public var selectedTile: MacOSaiXTile?
    @Published public var isExportSheetPresented: Bool = false
    
    // Memory Estimation
    @Published public var estimatedRAMText: String = "0 MB"
    @Published public var isMemorySafe: Bool = true
    
    // Canvas interaction state
    @Published public var zoomScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    
    // Drag & drop highlight state
    @Published public var isTargetDropTargeted: Bool = false
    
    // Export Sheet state
    @Published public var exportPreset: Int = 3000
    @Published public var exportCustomWidth: Int = 3000
    @Published public var exportIsCustom: Bool = false
    @Published public var exportFormat: String = "PNG"
    @Published public var isExporting: Bool = false
    @Published public var exportErrorMessage: String?
    
    private var matchingTask: Task<Void, Never>?
    private let loader = ImageLoader()
    
    public init() {}
    
    public var canStart: Bool {
        return targetCGImage != nil && !foundImageURLs.isEmpty && !isRunning
    }
    
    public var hasCompletedTiles: Bool {
        return matchedTilesCount > 0
    }
    
    // MARK: - Target Image Handling
    public func setTargetImage(from url: URL) {
        let opts: [CFString: Any] = [kCGImageSourceShouldCache: true]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, opts as CFDictionary),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else {
            statusMessage = "Could not load image: \(url.lastPathComponent)"
            return
        }
        
        self.targetImageURL = url
        self.targetCGImage = cgImage
        self.targetNSImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        self.targetResolutionText = "\(cgImage.width) × \(cgImage.height) px"
        self.statusMessage = "Target image loaded. Choose photo sources."
        
        prepareTiles()
    }
    
    // MARK: - Tile Preparation
    public func prepareTiles() {
        guard let cgImg = targetCGImage else { return }
        
        let newEngine = MosaicEngine(
            shapeType: shapeType,
            tilesAcross: tilesAcross,
            tilesDown: tilesDown,
            curviness: Float(curviness),
            maxReuse: maxReuse,
            minDistance: minDistance,
            metric: colorMetric
        )
        
        do {
            try newEngine.prepare(with: cgImg)
            self.engine = newEngine
            self.totalTilesCount = newEngine.tiles.count
            self.matchedTilesCount = 0
            self.processedImagesCount = 0
            self.averageScore = 1.0
            self.canvasVersion += 1
            self.statusMessage = "Ready: \(newEngine.tiles.count) tile shapes generated."
            updateMemoryEstimate()
        } catch {
            self.statusMessage = "Error generating tiles: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Source Folder Handling
    public func addSourceFolder(_ url: URL) {
        if !sourceFolders.contains(url) {
            sourceFolders.append(url)
        }
        rescanSources()
    }
    
    public func removeSourceFolder(_ url: URL) {
        sourceFolders.removeAll { $0 == url }
        rescanSources()
    }
    
    public func rescanSources() {
        var allURLs: [URL] = []
        for folder in sourceFolders {
            let found = loader.findImages(in: folder)
            allURLs.append(contentsOf: found)
        }
        self.foundImageURLs = allURLs
        self.totalImagesCount = allURLs.count
        self.heicCount = allURLs.filter { $0.pathExtension.lowercased() == "heic" }.count
        
        updateMemoryEstimate()
        if targetCGImage != nil && !foundImageURLs.isEmpty {
            statusMessage = "Ready to start! Found \(foundImageURLs.count) photos."
        }
    }
    
    private func updateMemoryEstimate() {
        let est = MemoryChecker.estimate(
            sourceImageCount: foundImageURLs.count,
            tileCount: totalTilesCount,
            outputWidth: 3000,
            outputHeight: 2000
        )
        self.estimatedRAMText = MemoryChecker.formatBytes(est.totalPeakBytes)
        self.isMemorySafe = est.isSafe
    }
    
    // MARK: - Matching Execution
    public func toggleMatching() {
        if isRunning {
            pauseMatching()
        } else {
            startMatching()
        }
    }
    
    public func startMatching() {
        guard let engine = self.engine, !foundImageURLs.isEmpty else { return }
        
        self.isRunning = true
        self.isPaused = false
        self.statusMessage = "Matching photos..."
        
        let candidates = self.foundImageURLs
        
        matchingTask = Task.detached(priority: .userInitiated) { [weak self, engine, candidates] in
            let total = candidates.count
            var count = 0
            let loader = ImageLoader()
            
            for url in candidates {
                if Task.isCancelled { break }
                
                // Check pause state
                while engine.isPaused && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                if Task.isCancelled { break }
                
                if let thumbData = loader.loadThumbnail(from: url, targetSize: 16) {
                    let cand = SourceImageCandidate(identifier: url.path, url: url, thumbnailPixels: thumbData)
                    let updated = engine.testCandidate(cand)
                    
                    if updated {
                        await MainActor.run { [weak self] in
                            self?.canvasVersion += 1
                        }
                    }
                }
                
                count += 1
                let currentCount = count
                
                // Throttle UI status updates to every 10 images or on completion
                if currentCount % 10 == 0 || currentCount == total {
                    let matched = engine.tiles.filter { $0.bestImageURL != nil }.count
                    let avgScore: Float
                    if matched > 0 {
                        let totalScore = engine.tiles.compactMap { $0.bestImageURL != nil ? $0.bestScore : nil }.reduce(0.0, +)
                        avgScore = totalScore / Float(matched)
                    } else {
                        avgScore = 1.0
                    }
                    let pct = Int(Double(currentCount) / Double(total) * 100.0)
                    let status = "Matching: \(currentCount)/\(total) photos (\(pct)%) | \(matched)/\(engine.tiles.count) tiles"
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.processedImagesCount = currentCount
                        self.matchedTilesCount = matched
                        if matched > 0 {
                            self.averageScore = avgScore
                        }
                        self.statusMessage = status
                    }
                }
            }
            
            let finalMatched = engine.tiles.filter { $0.bestImageURL != nil }.count
            let finalTotal = engine.tiles.count
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isRunning = false
                self.statusMessage = "Completed! Filled \(finalMatched) of \(finalTotal) tiles."
                self.canvasVersion += 1
            }
        }
    }
    
    public func pauseMatching() {
        self.isPaused.toggle()
        self.engine?.isPaused = isPaused
        if isPaused {
            statusMessage = "Paused"
        } else {
            statusMessage = "Resuming matching..."
        }
    }
    
    public func stopMatching() {
        matchingTask?.cancel()
        engine?.isCancelled = true
        isRunning = false
        isPaused = false
        statusMessage = "Stopped"
    }
    
    // MARK: - Export
    public func exportMosaic(outputWidth: Int, destinationURL: URL) throws {
        guard let engine = self.engine else { return }
        let renderer = MosaicRenderer()
        try renderer.render(
            tiles: engine.tiles,
            mosaicSize: engine.mosaicSize,
            outputWidth: outputWidth,
            strokeWidth: Float(strokeWidth),
            outputURL: destinationURL
        )
    }
}
