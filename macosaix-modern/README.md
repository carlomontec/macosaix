# MosaicLab — Apple Silicon Architecture

<p align="center">
  <img src="../docs/screenshot.png" alt="MosaicLab in Action" width="850">
</p>

<p align="center">
  <strong>A native macOS and iOS photomosaic tool built with modern Swift and image processing algorithms.</strong><br>
  Engineered by <strong>Carlo Monjaraz-Tec</strong> (2026). Inspired by classic Mac software <em>MacOSaiX</em> by Frank M. Midgley.
</p>

<p align="center">
  <a href="../MANUAL.md"><strong>📖 Full User Manual & Algorithmic Handbook</strong></a> |
  <a href="../README.md"><strong>Project Highlights</strong></a>
</p>

---

## Architecture Overview

`macosaix-modern` is a 100% pure-Swift modular package targeting `.macOS(.v13)` and `.iOS(.v16)`:

1. **`MacOSaiXKit` (Pure-Swift Computational Engine)**:
   - **`Core/TileGeometry.swift`**: Native vector tessellation for rectangular, hexagonal, and cubic Bézier puzzle pieces. Adaptive quadtree decomposition supporting Julia-range extrema, Chebyshev RGB color-range, and $O(1)$ integral image variance with 2:1 topological balancing.
   - **`Core/TileMatcher.swift`**: Vectorized Riemersma perceptual color metric, Euclidean RGB, monochrome luminance, and Sobel HOG 8-bin directional vector matching with saliency gating.
   - **`Core/TileModel.swift`**: Bounded 16x16 thumbnail extraction and vector mask rasterization via modern CoreGraphics bitmap contexts.
   - **`ImageLoader.swift`**: Hardware-accelerated decoding via `ImageIO` (AVIF, HEIC, WebP, PNG, JPEG, TIFF).
   - **`MosaicEngine.swift`**: Multi-threaded parallel solver utilizing Swift Concurrency `TaskGroup`.
   - **`MosaicProject.swift`**: Lightweight project serialization (`.mosaiclab` and `.macosaix`).
   - **`ColorTransfer.swift`**: Statistical palette distribution shifting in perceptual OKLab space.
   - **`ApplePhotosSource.swift`**: PhotoKit integration for Apple Photos albums and smart collections.
   - **`LocalFolderImageSource.swift`**: Asynchronous file system crawler with deep folder discovery.
   - **`MosaicRenderer.swift`**: Memory-bounded high-resolution vector mosaic exporter.
   - **`ThumbnailCache.swift`**: High-performance in-memory and disk caching.
   - **`Platform/PlatformCompatibility.swift`**: Cross-platform AppKit/UIKit abstractions.

2. **`MacOSaiXApp` (Universal SwiftUI Application)**:
   - **`MainWindowView`**: Dual-pane window with top-right action playback bar (`Start`/`Pause`/`Stop`).
   - **`SidebarView`**: Modern controls for target selection, source directories, tile shapes, and matching filters.
   - **`MosaicCanvasView`**: Interactive canvas featuring 2D inertial trackpad glide, pinch-to-zoom, and progressive live assembly.
   - **`TileDetailPopover.swift`**: Interactive single-tile inspector and instant candidate substitution.

3. **`macosaix-cli` (Command-Line Tool)**:
   - Headless CLI executable for scripting, batch jobs, and server pipelines.
   - Built-in physical RAM pre-flight safety check to protect against memory exhaustion.

---

## Building & Bundling

### Build Debug / Release
```bash
swift build -c release
```

### Bundle the macOS App
```bash
bash scripts/bundle_app.sh
open "../MosaicLab.app"
```
