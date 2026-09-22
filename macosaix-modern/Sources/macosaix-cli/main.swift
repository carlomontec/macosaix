import Foundation
import CoreGraphics
import MacOSaiXCore
import MacOSaiXKit

func printUsage() {
    print("""
    MacOSaiX Remake CLI v3.0.0 (Apple Silicon Native)
    A modern remake of Frank M. Midgley's classic Mac photomosaic software.
    Revived and rebuilt with AI-assisted coding by Carlo Monjaraz-Tec (2026).
    
    Usage:
      macosaix-cli --target <image> --sources <folder> [options]
      
    Options:
      --target <path>        Target image to turn into a mosaic (HEIC, JPEG, PNG, etc.)
      --sources <folder>     Folder of source photos (HEIC, JPEG, PNG, etc.)
      --output <path>        Output image path (default: mosaic.png)
      --shape <type>         Tile shape: rect | hex | puzzle (default: rect)
      --across <N>           Tiles horizontally (default: 30)
      --down <N>             Tiles vertically (default: 20)
      --curviness <float>    Puzzle edge curviness 0.0 - 1.0 (default: 0.5)
      --max-reuse <N>        Maximum times any photo can be reused (default: 0 = unlimited)
      --min-distance <N>     Minimum tile distance between identical photos (default: 2)
      --width <pixels>       Output mosaic pixel width (default: 2400)
      --stroke <pixels>      Tile border stroke width (default: 0.0)
      --color-transfer <f>   Reinhard perceptual color transfer 0.0 - 1.0 (default: 0.0)
      --metric <type>        Color metric: riemersma | rgb (default: riemersma)
      --force                Bypass memory safety check if estimated RAM is very high
      --help                 Show this help message
    """)
}

func parseArguments() -> [String: String] {
    var args: [String: String] = [:]
    var key: String? = nil
    
    for arg in CommandLine.arguments.dropFirst() {
        if arg.hasPrefix("--") {
            key = String(arg.dropFirst(2))
            args[key!] = ""
        } else if let k = key {
            args[k] = arg
            key = nil
        }
    }
    return args
}

func main() async {
    let args = parseArguments()
    
    if args["help"] != nil || args.isEmpty {
        printUsage()
        exit(0)
    }
    
    guard let targetPath = args["target"] else {
        print("Error: --target argument is required.")
        printUsage()
        exit(1)
    }
    
    guard let sourcesPath = args["sources"] else {
        print("Error: --sources argument is required.")
        printUsage()
        exit(1)
    }
    
    let outputPath = args["output"] ?? "mosaic.png"
    let shapeStr = args["shape"]?.lowercased() ?? "rect"
    let across = Int(args["across"] ?? "30") ?? 30
    let down = Int(args["down"] ?? "20") ?? 20
    let curviness = Float(args["curviness"] ?? "0.5") ?? 0.5
    let maxReuse = Int(args["max-reuse"] ?? "0") ?? 0
    let minDistance = Int(args["min-distance"] ?? "2") ?? 2
    let outputWidth = Int(args["width"] ?? "2400") ?? 2400
    let strokeWidth = Float(args["stroke"] ?? "0.0") ?? 0.0
    let colorTransfer = max(0.0, min(1.0, Float(args["color-transfer"] ?? "0.0") ?? 0.0))
    let metricStr = args["metric"]?.lowercased() ?? "riemersma"
    
    let shapeType: MacOSaiXShapeType
    switch shapeStr {
    case "hex", "hexagonal":
        shapeType = .hexagonal
    case "puzzle":
        shapeType = .puzzle
    default:
        shapeType = .rectangular
    }
    
    let colorMetric: MacOSaiXColorMetric = (metricStr == "rgb") ? .RGB : .riemersma
    
    let targetURL = URL(fileURLWithPath: targetPath)
    let sourcesURL = URL(fileURLWithPath: sourcesPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    
    print("==================================================")
    print("  MacOSaiX Modern Engine (Option A)")
    print("==================================================")
    print("Target:        \(targetURL.lastPathComponent)")
    print("Sources dir:   \(sourcesURL.path)")
    print("Shape:         \(shapeStr.uppercased())")
    print("Grid:          \(across) x \(down) tiles")
    print("Max reuse:     \(maxReuse == 0 ? "Unlimited" : "\(maxReuse)")")
    print("Min distance:  \(minDistance) tiles")
    print("Color metric:  \(metricStr)")
    if colorTransfer > 0.001 {
        print("Color transfer: \(Int(colorTransfer * 100))%")
    }
    print("Output width:  \(outputWidth) px")
    print("Output file:   \(outputURL.path)")
    print("--------------------------------------------------")
    
    let engine = MosaicEngine(
        shapeType: shapeType,
        tilesAcross: across,
        tilesDown: down,
        curviness: curviness,
        maxReuse: maxReuse,
        minDistance: minDistance,
        metric: colorMetric
    )
    
    do {
        print("Preparing target image and tile geometries...")
        let prepStart = Date()
        try engine.prepare(targetURL: targetURL)
        print(String(format: "Tiles prepared in %.2f seconds.", Date().timeIntervalSince(prepStart)))
    } catch {
        print("Error preparing mosaic: \(error.localizedDescription)")
        exit(1)
    }
    
    let loader = ImageLoader()
    print("Scanning source folder for images...")
    let imageURLs = loader.findImages(in: sourcesURL)
    if imageURLs.isEmpty {
        print("Error: No supported images found in \(sourcesURL.path).")
        exit(1)
    }
    
    let heicCount = imageURLs.filter { $0.pathExtension.lowercased() == "heic" }.count
    print("Found \(imageURLs.count) photos (\(heicCount) HEIC).")
    
    // RAM & Memory Pre-Flight Check
    let scale = CGFloat(outputWidth) / engine.mosaicSize.width
    let outputHeight = max(1, Int(engine.mosaicSize.height * scale))
    let memEstimate = MemoryChecker.estimate(
        sourceImageCount: imageURLs.count,
        tileCount: engine.tiles.count,
        outputWidth: outputWidth,
        outputHeight: outputHeight
    )
    MemoryChecker.printReport(
        estimate: memEstimate,
        sourceCount: imageURLs.count,
        tileCount: engine.tiles.count,
        width: outputWidth,
        height: outputHeight
    )
    
    if memEstimate.isDangerous && args["force"] == nil {
        print("\n[ABORTED] The estimated peak RAM exceeds 80% of your system's physical memory.")
        print("To run anyway, add --force to your command line, or reduce --width.")
        exit(1)
    }
    
    print("Extracting thumbnails and running matching...")
    
    let matchStart = Date()
    var processedCount = 0
    let totalImages = imageURLs.count
    
    for url in imageURLs {
        if let thumbPixels = loader.loadThumbnail(from: url, targetSize: 16) {
            let candidate = SourceImageCandidate(
                identifier: url.path,
                url: url,
                thumbnailPixels: thumbPixels
            )
            engine.testCandidate(candidate)
        }
        
        processedCount += 1
        if processedCount % 25 == 0 || processedCount == totalImages {
            let percent = Double(processedCount) / Double(totalImages) * 100.0
            let matchedTiles = engine.tiles.filter { $0.bestImageURL != nil }.count
            print(String(format: "\r[%3.0f%%] Processed %d/%d photos | Matched tiles: %d/%d",
                         percent, processedCount, totalImages, matchedTiles, engine.tiles.count),
                  terminator: "")
            fflush(stdout)
        }
    }
    print("")
    print(String(format: "Matching completed in %.2f seconds.", Date().timeIntervalSince(matchStart)))
    
    let matchedTiles = engine.tiles.filter { $0.bestImageURL != nil }.count
    let avgScore: Float
    if matchedTiles > 0 {
        let totalScore = engine.tiles.compactMap { $0.bestImageURL != nil ? $0.bestScore : nil }.reduce(0.0, +)
        avgScore = totalScore / Float(matchedTiles)
    } else {
        avgScore = 1.0
    }
    print(String(format: "Tiles filled: %d / %d (Avg match score: %.3f - lower is better)",
                 matchedTiles, engine.tiles.count, avgScore))
    
    print("Rendering high-resolution mosaic...")
    let renderStart = Date()
    let renderer = MosaicRenderer()
    do {
        try renderer.render(
            tiles: engine.tiles,
            mosaicSize: engine.mosaicSize,
            outputWidth: outputWidth,
            strokeWidth: strokeWidth,
            colorTransferStrength: colorTransfer,
            outputURL: outputURL
        )
        print(String(format: "Rendered and saved to \(outputURL.path) in %.2f seconds.",
                     Date().timeIntervalSince(renderStart)))
        print("Success! Mosaic is ready.")
    } catch {
        print("Error rendering mosaic: \(error.localizedDescription)")
        exit(1)
    }
}

await main()
