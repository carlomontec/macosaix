import SwiftUI
import AppKit
import CoreGraphics
import ImageIO
import MacOSaiXCore
import MacOSaiXKit
import UniformTypeIdentifiers

@MainActor
public final class MosaicViewModel: ObservableObject {
    // MARK: - Target Image State
    @Published public var targetImageURL: URL?
    @Published public var targetNSImage: NSImage?
    @Published public var targetCGImage: CGImage?
    @Published public var targetResolutionText: String = "No image loaded"
    
    // MARK: - Settings State
    @Published public var shapeType: MacOSaiXShapeType = .rectangular {
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
    @Published public var formatBreakdownText: String = ""
    
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
    @Published public var isAboutPresented: Bool = false
    
    // Memory Estimation
    @Published public var estimatedRAMText: String = "0 MB"
    @Published public var isMemorySafe: Bool = true
    
    // Canvas interaction state
    @Published public var zoomScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    @Published public var dragBaseOffset: CGSize = .zero
    
    // Drag & drop highlight state
    @Published public var isTargetDropTargeted: Bool = false
    @Published public var isSourcesDropTargeted: Bool = false
    
    // Export Sheet state
    @Published public var exportPreset: Int = 3000
    @Published public var exportCustomWidth: Int = 3000
    @Published public var exportIsCustom: Bool = false
    @Published public var exportFormat: String = "HEIC"
    @Published public var isExporting: Bool = false
    @Published public var exportErrorMessage: String?
    
    private var matchingTask: Task<Void, Never>?
    private var tilePrepTask: Task<Void, Never>?
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
        self.statusMessage = "Loading \(url.lastPathComponent)..."
        
        Task.detached(priority: .userInitiated) { [weak self] in
            let opts: [CFString: Any] = [kCGImageSourceShouldCache: false]
            guard let source = CGImageSourceCreateWithURL(url as CFURL, opts as CFDictionary) else {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Could not open image: \(url.lastPathComponent)"
                }
                return
            }
            
            // Fast metadata read without full pixel decoding
            var origW: Int = 0
            var origH: Int = 0
            if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
                origW = (props[kCGImagePropertyPixelWidth] as? Int) ?? 0
                origH = (props[kCGImagePropertyPixelHeight] as? Int) ?? 0
            }
            
            // Downsample large images to max 2048 px to avoid memory spikes and freezes
            let maxDim: Int = 2048
            let thumbOpts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDim,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true
            ]
            
            guard let rawCGImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOpts as CFDictionary) else {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Could not decode image: \(url.lastPathComponent)"
                }
                return
            }
            
            // Normalize image (including 10-bit AVIF, HDR HEIC, IOSurface) to standard 8-bit sRGB bitmap
            let cgImage = MosaicEngine.normalizeToStandardSRGB(rawCGImage)
            
            let loadedW = cgImage.width
            let loadedH = cgImage.height
            let resText: String
            if origW > maxDim || origH > maxDim {
                resText = "\(origW) × \(origH) px (optimized to \(loadedW) × \(loadedH))"
            } else {
                resText = "\(loadedW) × \(loadedH) px"
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: loadedW, height: loadedH))
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.targetImageURL = url
                self.targetCGImage = cgImage
                self.targetNSImage = nsImage
                self.targetResolutionText = resText
                self.statusMessage = "Target image loaded (\(loadedW) × \(loadedH) px)."
                self.prepareTiles()
            }
        }
    }
    
    // MARK: - Tile Preparation
    public func prepareTiles() {
        guard let cgImg = targetCGImage else { return }
        
        tilePrepTask?.cancel()
        
        let shape = self.shapeType
        let across = self.tilesAcross
        let down = self.tilesDown
        let curv = Float(self.curviness)
        let reuse = self.maxReuse
        let minDist = self.minDistance
        let metric = self.colorMetric
        
        tilePrepTask = Task.detached(priority: .userInitiated) { [weak self, cgImg] in
            let newEngine = MosaicEngine(
                shapeType: shape,
                tilesAcross: across,
                tilesDown: down,
                curviness: curv,
                maxReuse: reuse,
                minDistance: minDist,
                metric: metric
            )
            
            do {
                try newEngine.prepare(with: cgImg)
                if Task.isCancelled { return }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.engine = newEngine
                    self.totalTilesCount = newEngine.tiles.count
                    self.matchedTilesCount = 0
                    self.processedImagesCount = 0
                    self.averageScore = 1.0
                    self.canvasVersion += 1
                    self.statusMessage = "Ready: \(newEngine.tiles.count) tile shapes generated."
                    self.updateMemoryEstimate()
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Error generating tiles: \(error.localizedDescription)"
                }
            }
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
        self.heicCount = allURLs.filter { 
            let ext = $0.pathExtension.lowercased()
            return ext == "heic" || ext == "heif"
        }.count
        
        // Multi-format breakdown
        var counts: [String: Int] = [:]
        for url in allURLs {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "heic", "heif":
                counts["HEIC", default: 0] += 1
            case "avif":
                counts["AVIF", default: 0] += 1
            case "jpg", "jpeg":
                counts["JPEG", default: 0] += 1
            case "png":
                counts["PNG", default: 0] += 1
            case "tiff", "tif":
                counts["TIFF", default: 0] += 1
            case "webp":
                counts["WebP", default: 0] += 1
            case "gif":
                counts["GIF", default: 0] += 1
            case "bmp":
                counts["BMP", default: 0] += 1
            default:
                if !ext.isEmpty {
                    counts[ext.uppercased(), default: 0] += 1
                }
            }
        }
        let sorted = counts.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        self.formatBreakdownText = sorted.map { "\($0.value) \($0.key)" }.joined(separator: " • ")
        
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
            let batchSize = max(8, ProcessInfo.processInfo.activeProcessorCount * 2)
            
            var index = 0
            while index < total {
                if Task.isCancelled { break }
                
                // Check pause state
                while engine.isPaused && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                if Task.isCancelled { break }
                
                let endIndex = min(index + batchSize, total)
                let currentChunk = Array(candidates[index..<endIndex])
                index = endIndex
                
                // Decode thumbnails in parallel across all Apple Silicon CPU cores
                var chunkCandidates: [SourceImageCandidate] = []
                chunkCandidates.reserveCapacity(currentChunk.count)
                
                await withTaskGroup(of: SourceImageCandidate?.self) { group in
                    for url in currentChunk {
                        group.addTask {
                            if Task.isCancelled { return nil }
                            if let thumbData = loader.loadThumbnail(from: url, targetSize: 16) {
                                return SourceImageCandidate(identifier: url.path, url: url, thumbnailPixels: thumbData)
                            }
                            return nil
                        }
                    }
                    
                    for await cand in group {
                        if let cand = cand {
                            chunkCandidates.append(cand)
                        }
                    }
                }
                
                if Task.isCancelled { break }
                
                var anyChunkUpdated = false
                for cand in chunkCandidates {
                    if Task.isCancelled { break }
                    let updated = engine.testCandidate(cand)
                    if updated {
                        anyChunkUpdated = true
                        // Pre-heat thumbnail cache in background for smooth rendering
                        MosaicThumbnailCache.shared.preheatThumbnail(for: cand.url, maxPixelSize: 140)
                    }
                }
                
                if anyChunkUpdated {
                    await MainActor.run { [weak self] in
                        self?.canvasVersion += 1
                    }
                }
                
                count += currentChunk.count
                let currentCount = count
                
                // Update UI status at the end of each batch or on completion
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
    public func presentSavePanelAndExport(outputWidth: Int, format: String) {
        guard let engine = self.engine else { return }
        
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Mosaic.\(format.lowercased())"
        
        let utType: UTType
        switch format.uppercased() {
        case "HEIC":
            utType = .heic
        case "AVIF":
            utType = UTType(filenameExtension: "avif") ?? .png
        case "JPG", "JPEG":
            utType = .jpeg
        default:
            utType = .png
        }
        panel.allowedContentTypes = [utType]
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let destinationURL = panel.url else { return }
            
            self.isExporting = true
            self.statusMessage = "Exporting \(outputWidth)px mosaic (\(format.uppercased()))..."
            
            let tilesCopy = engine.tiles
            let mosaicSizeCopy = engine.mosaicSize
            let stroke = Float(self.strokeWidth)
            
            Task.detached(priority: .userInitiated) {
                let renderer = MosaicRenderer()
                do {
                    try renderer.render(
                        tiles: tilesCopy,
                        mosaicSize: mosaicSizeCopy,
                        outputWidth: outputWidth,
                        strokeWidth: stroke,
                        outputURL: destinationURL
                    )
                    await MainActor.run {
                        self.isExporting = false
                        self.statusMessage = "Export complete: \(destinationURL.lastPathComponent)"
                        NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                    }
                } catch {
                    await MainActor.run {
                        self.isExporting = false
                        self.statusMessage = "Export failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // MARK: - Project Save & Open (.macosaix)
    @Published public var currentProjectURL: URL?
    
    public func newProject() {
        matchingTask?.cancel()
        tilePrepTask?.cancel()
        isRunning = false
        isPaused = false
        engine = nil
        targetImageURL = nil
        targetCGImage = nil
        targetNSImage = nil
        targetResolutionText = "No image loaded"
        sourceFolders = []
        foundImageURLs = []
        heicCount = 0
        formatBreakdownText = ""
        matchedTilesCount = 0
        totalTilesCount = 0
        currentProjectURL = nil
        zoomScale = 1.0
        panOffset = .zero
        dragBaseOffset = .zero
        canvasVersion += 1
        statusMessage = "New project. Drag a picture to begin."
    }
    
    public func saveProject() {
        if let currentURL = currentProjectURL {
            saveProject(to: currentURL)
        } else {
            saveProjectAsPrompt()
        }
    }
    
    public func saveProjectAsPrompt() {
        guard targetCGImage != nil else {
            statusMessage = "Cannot save project: No target image loaded."
            return
        }
        
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let defaultName = (targetImageURL?.deletingPathExtension().lastPathComponent ?? "Mosaic") + ".macosaix"
        panel.nameFieldStringValue = defaultName
        if let macosaixType = UTType(filenameExtension: "macosaix") {
            panel.allowedContentTypes = [macosaixType]
        }
        panel.prompt = "Save Project"
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let destinationURL = panel.url else { return }
            self.saveProject(to: destinationURL)
        }
    }
    
    public func saveProject(to destinationURL: URL) {
        guard let engine = self.engine, let targetURL = self.targetImageURL else {
            statusMessage = "No active mosaic to save."
            return
        }
        
        let shapeStr: String
        switch shapeType {
        case .hexagonal: shapeStr = "hexagonal"
        case .puzzle: shapeStr = "puzzle"
        default: shapeStr = "rectangular"
        }
        
        let metricStr = (colorMetric == .RGB) ? "rgb" : "riemersma"
        
        let settings = MacOSaiXProject.ProjectSettings(
            shapeType: shapeStr,
            tilesAcross: tilesAcross,
            tilesDown: tilesDown,
            curviness: Float(curviness),
            strokeWidth: strokeWidth,
            maxReuse: maxReuse,
            minDistance: minDistance,
            colorMetric: metricStr,
            blendOpacity: blendOpacity
        )
        
        var tileRecords: [MacOSaiXProject.TileMatchRecord] = []
        tileRecords.reserveCapacity(engine.tiles.count)
        for (idx, tile) in engine.tiles.enumerated() {
            tileRecords.append(
                MacOSaiXProject.TileMatchRecord(
                    index: idx,
                    imagePath: tile.bestImageURL?.path,
                    score: tile.bestScore
                )
            )
        }
        
        let project = MacOSaiXProject(
            version: "3.0.0",
            createdAt: Date(),
            targetImagePath: targetURL.path,
            sourceFolders: sourceFolders.map { $0.path },
            settings: settings,
            tiles: tileRecords
        )
        
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                try MosaicProjectManager.shared.saveProject(project, to: destinationURL)
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.currentProjectURL = destinationURL
                    self.statusMessage = "Project saved: \(destinationURL.lastPathComponent)"
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Failed to save project: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func openProjectPrompt() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        var types: [UTType] = [.json]
        if let macosaixType = UTType(filenameExtension: "macosaix") {
            types.append(macosaixType)
        }
        panel.allowedContentTypes = types
        panel.prompt = "Open Project"
        
        if panel.runModal() == .OK, let url = panel.url {
            openProject(from: url)
        }
    }
    
    public func openProject(from projectURL: URL) {
        statusMessage = "Opening \(projectURL.lastPathComponent)..."
        
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let project = try MosaicProjectManager.shared.loadProject(from: projectURL)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    self.stopMatching()
                    
                    switch project.settings.shapeType.lowercased() {
                    case "hex", "hexagonal":
                        self.shapeType = .hexagonal
                    case "puzzle":
                        self.shapeType = .puzzle
                    default:
                        self.shapeType = .rectangular
                    }
                    
                    self.tilesAcross = project.settings.tilesAcross
                    self.tilesDown = project.settings.tilesDown
                    self.curviness = Double(project.settings.curviness)
                    self.strokeWidth = project.settings.strokeWidth
                    self.maxReuse = project.settings.maxReuse
                    self.minDistance = project.settings.minDistance
                    self.colorMetric = (project.settings.colorMetric == "rgb") ? .RGB : .riemersma
                    self.blendOpacity = project.settings.blendOpacity
                    
                    self.sourceFolders = project.sourceFolders.compactMap { path in
                        let url = URL(fileURLWithPath: path)
                        return FileManager.default.fileExists(atPath: path) ? url : nil
                    }
                    self.rescanSources()
                    
                    let targetURL = URL(fileURLWithPath: project.targetImagePath)
                    guard FileManager.default.fileExists(atPath: targetURL.path) else {
                        self.statusMessage = "Original image not found at \(targetURL.path)"
                        return
                    }
                    
                    self.loadTargetImageAndRestoreMatches(targetURL: targetURL, tileRecords: project.tiles, projectURL: projectURL)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Could not open project: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadTargetImageAndRestoreMatches(
        targetURL: URL,
        tileRecords: [MacOSaiXProject.TileMatchRecord],
        projectURL: URL
    ) {
        Task.detached(priority: .userInitiated) { [weak self] in
            let opts: [CFString: Any] = [kCGImageSourceShouldCache: false]
            guard let source = CGImageSourceCreateWithURL(targetURL as CFURL, opts as CFDictionary) else {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Could not open target image: \(targetURL.lastPathComponent)"
                }
                return
            }
            
            let maxDim: Int = 2048
            let thumbOpts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDim,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true
            ]
            
            guard let rawCGImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOpts as CFDictionary) else {
                await MainActor.run { [weak self] in
                    self?.statusMessage = "Could not decode target image: \(targetURL.lastPathComponent)"
                }
                return
            }
            
            // Normalize image (including 10-bit AVIF, HDR HEIC, IOSurface) to standard 8-bit sRGB bitmap
            let cgImage = MosaicEngine.normalizeToStandardSRGB(rawCGImage)
            
            let loadedW = cgImage.width
            let loadedH = cgImage.height
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: loadedW, height: loadedH))
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.targetImageURL = targetURL
                self.targetCGImage = cgImage
                self.targetNSImage = nsImage
                self.targetResolutionText = "\(loadedW) × \(loadedH) px"
                
                let newEngine = MosaicEngine(
                    shapeType: self.shapeType,
                    tilesAcross: self.tilesAcross,
                    tilesDown: self.tilesDown,
                    curviness: Float(self.curviness),
                    maxReuse: self.maxReuse,
                    minDistance: self.minDistance,
                    metric: self.colorMetric
                )
                
                do {
                    try newEngine.prepare(with: cgImage)
                    
                    var restoredCount = 0
                    for record in tileRecords {
                        if record.index >= 0 && record.index < newEngine.tiles.count,
                           let path = record.imagePath {
                            let url = URL(fileURLWithPath: path)
                            if FileManager.default.fileExists(atPath: path) {
                                let tile = newEngine.tiles[record.index]
                                tile.bestImageIdentifier = path
                                tile.bestImageURL = url
                                tile.bestScore = record.score
                                restoredCount += 1
                                MosaicThumbnailCache.shared.preheatThumbnail(for: url)
                            }
                        }
                    }
                    
                    self.engine = newEngine
                    self.totalTilesCount = newEngine.tiles.count
                    self.matchedTilesCount = restoredCount
                    self.currentProjectURL = projectURL
                    self.canvasVersion += 1
                    self.updateMemoryEstimate()
                    self.statusMessage = "Project restored! \(restoredCount)/\(newEngine.tiles.count) tiles matched."
                } catch {
                    self.statusMessage = "Error preparing mosaic tiles: \(error.localizedDescription)"
                }
            }
        }
    }
}
