# MacOSaiX Remake — Modern Apple Silicon Architecture

<p align="center">
  <img src="../docs/screenshot.png" alt="MacOSaiX Remake in Action" width="850">
</p>

<p align="center">
  <strong>The classic Mac photomosaic creator revived and rebuilt for modern Apple Silicon.</strong><br>
  Modernized and expanded by <strong>Carlo Monjaraz-Tec</strong> (2026) from <strong>Frank M. Midgley's</strong> original MacOSaiX.
</p>

<p align="center">
  <a href="../MANUAL.md"><strong>📖 Full User Manual & Algorithmic Handbook</strong></a> |
  <a href="../README.md"><strong>Project Highlights</strong></a>
</p>

---

## Architecture Overview

`macosaix-modern` is structured into four modular targets:

1. **`MacOSaiXCore` (Objective-C / C)**:
   - High-performance mathematical shapes and tessellations (`MacOSaiXShapes.m`).
   - Adaptive Quadtree decomposition engine with 4 algorithms:
     - **Whole Canvas Quadtree**: Single-root canvas decomposition.
     - **Julia Extrema Range**: `(max - min) < threshold` homogeneity test.
     - **RGB Color Range**: Chebyshev multi-channel color divergence.
     - **Variance / Hybrid**: Crow (1984) Summed-Area Table integral images.
   - 2:1 balanced neighbor transitions and strict minimum tile size floors.
   - Perceptual color matching engine with Riemersma weighting and OKLab Reinhard color transfer (`MacOSaiXMatcher.m`).

2. **`MacOSaiXKit` (Swift Package)**:
   - **`ImageLoader`**: Hardware-accelerated decoding via `ImageIO` (AVIF, HEIC, WebP, PNG, JPEG, TIFF).
   - **`MosaicEngine`**: Multi-threaded parallel solver utilizing Swift Concurrency `TaskGroup`.
   - **`MosaicProject`**: Lightweight zipped project archiver (`.macosaix`).
   - **`MosaicRenderer`**: Bounded RAM high-resolution mosaic renderer.
   - **`MosaicThumbnailCache`**: In-memory and disk caching for source libraries.

3. **`MacOSaiXApp` (SwiftUI + AppKit Application)**:
   - **`MainWindowView`**: Dual-pane window with top-right action playback bar (`Start`/`Pause`/`Stop`).
   - **`SidebarView`**: Modern controls for target selection, source directories, tile shapes, and matching filters.
   - **`MosaicCanvasView`**: Interactive canvas featuring 2D inertial trackpad glide, pinch-to-zoom, and progressive live assembly.

4. **`macosaix-cli` (Command-Line Tool)**:
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
open "../MacOSaiX Remake.app"
```

For complete usage instructions, algorithm explanations, and CLI options, see [**MANUAL.md**](../MANUAL.md).
