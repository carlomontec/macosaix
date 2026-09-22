# MacOSaiX Remake (Apple Silicon Native)

<p align="center">
  <img src="docs/screenshot.png" alt="MacOSaiX Remake in Action" width="850">
</p>

<p align="center">
  <strong>The classic Mac photomosaic creator revived and rebuilt for modern Apple Silicon.</strong><br>
  Originally created by <strong>Frank M. Midgley</strong> (2002–2009) for Mac OS X.<br>
  Modernized, re-engineered, and expanded with <strong>AI-assisted coding</strong> by <strong>Carlo Monjaraz-Tec</strong> (2026).
</p>

---

## Highlights & Features

### 🖥️ Native macOS GUI (`MacOSaiX Remake.app`)
- **Modern SwiftUI + AppKit Architecture**: Faithful to Frank Midgley's iconic 2-pane layout (sidebar controls + live progressive canvas + interactive blend slider).
- **2D Trackpad Navigation & Pinch-to-Zoom**: Smooth two-finger gliding across the mosaic with native macOS momentum and inertia; pinch-to-zoom (25% to 400%) or `⌘ + Scroll Wheel`.
- **Project Save & Open (`.macosaix`)**: Save complete mosaic setups as lightweight, compressed packages (`mosaic.json` zipped via `ditto`). Preserves settings, target paths, source directories, and matched tiles without duplicating gigabytes of raw photos (~30–60 KB). Double-click `.macosaix` files directly in Finder to resume instantly.
- **Folder Drag-and-Drop**: Drag one or multiple folders directly from Finder into the **Photo Sources** list in the sidebar.
- **Freeze-Free Architecture**: Large images (up to 8K+) are automatically subsampled to 2048px using hardware ImageIO. Tile geometry generation, mask rasterization, and candidate testing run asynchronously in detached background tasks, keeping the UI completely fluid.
- **Live Progressive Rendering**: Watch your mosaic assemble in real time as each candidate image is tested and matched.
- **Retro App & Document Icons**: Bundled with authentic, remastered high-resolution `.icns` artwork.

### 🧩 True Mathematical Tile Geometries
- **Interlocking Jigsaw Puzzles (`puzzle`)**: Every piece is a mathematically generated jigsaw piece with cubic Bezier tabs and sockets that interlock seamlessly with neighboring pieces. Configurable curviness and piece outline cutlines.
- **Hexagonal Tessellations (`hex`)**: Geometric honeycomb lattice that gives photomosaics a modern, structured visual feel.
- **Classic Rectangles (`square` / `rect`)**: Clean rectangular grid for traditional photomosaics with maximum photo visibility.

### 🎨 Human Eye Color Matching & Smart Placement
- **Riemersma Perceptual Metric**: Weights RGB color differences using human eye spectral sensitivities rather than simple Euclidean distance, producing strikingly accurate photographic mosaics.
- **Masked Vector Matching**: Evaluates candidates through the exact vector shape of each tile (excluding non-tile areas under puzzle tabs).
- **Minimum Distance Constraint**: Prevents identical photos from clustering near each other (configurable in tile grid units).
- **Max Reuse Caps**: Limit how many times any single image can appear in the mosaic (e.g. `1` for all-unique photos, or unlimited).

### 🌄 Comprehensive Modern Image Format Support
- Native hardware decoding and export for **AVIF**, **HEIC/HEIF** (with full EXIF auto-rotation), **WebP**, JPEG, PNG, TIFF, GIF, and BMP.
- Automatic normalization of 10-bit and HDR surfaces to standard 8-bit sRGB in-memory raster buffers, eliminating hardware surface memory faults.

---

## Launching the Desktop Application

A pre-built, codesigned application is included in the repository:

```bash
open "MacOSaiX Remake.app"
```

To build and package from source anytime:
```bash
cd macosaix-modern
swift build -c release
cp .build/out/Products/Release/MacOSaiXApp "../MacOSaiX Remake.app/Contents/MacOS/MacOSaiX Remake"
codesign --force --deep --sign - "../MacOSaiX Remake.app"
open "../MacOSaiX Remake.app"
```

---

## Command-Line Interface (`macosaix-cli`)

For headless environments, server automation, or power users, `macosaix-cli` provides full command-line control.

### 1. Build the CLI

```bash
cd macosaix-modern
swift build -c release
```

The binary will be compiled to `macosaix-modern/.build/release/macosaix-cli`.

*(Optional) Link it to your system path:*
```bash
sudo ln -sf "$(pwd)/.build/release/macosaix-cli" /usr/local/bin/macosaix-cli
```

### 2. Generate a Mosaic

```bash
# Make a jigsaw puzzle mosaic from an iPhone HEIC photo and your photo library:
macosaix-cli \
  --target "~/Pictures/Portrait.heic" \
  --sources "~/Pictures/Photos" \
  --shape puzzle \
  --across 40 \
  --down 30 \
  --stroke 0.5 \
  --width 3000 \
  --output "~/Desktop/my_mosaic.png"
```

---

## CLI Options Reference

| Option | Description | Default | Recommended |
| :--- | :--- | :--- | :--- |
| **`--target <file>`** | **Required**. Main image to recreate (AVIF, HEIC, JPEG, PNG, TIFF, WebP). | *None* | High-contrast image |
| **`--sources <folder>`** | **Required**. Directory of tile photos (subdirectories searched recursively). | *None* | 100 to 10,000+ photos |
| **`--output <file>`** | Final mosaic destination path (`.png`, `.jpg`, `.avif`). | `mosaic.png` | `~/Desktop/mosaic.png` |
| **`--shape <type>`** | Tile geometry: `rect` (square), `hex` (hexagon), or `puzzle` (jigsaw). | `rect` | `rect` or `puzzle` |
| **`--across <N>`** | Number of tiles horizontally. | `30` | `30` to `60` |
| **`--down <N>`** | Number of tiles vertically. | `20` | `20` to `45` (match aspect ratio) |
| **`--curviness <float>`** | *(Puzzle only)* Edge waviness from `0.0` (straight tabs) to `1.0` (very wavy). | `0.5` | `0.3` to `0.7` |
| **`--max-reuse <N>`** | Max appearances per photo (`0` = unlimited, `1` = all unique photos). | `0` | `0`, `1`, or `3`–`5` |
| **`--min-distance <N>`** | Minimum grid spacing between duplicate photos to prevent clustering. | `2` | `2` to `5` |
| **`--width <pixels>`** | Output resolution width in pixels. | `2400` | `2400` (screen), `4000`–`8000` (print) |
| **`--stroke <pixels>`** | Border cutline stroke width (`0.0` for seamless, `0.5`+ for puzzle die-cuts). | `0.0` | `0.5` or `1.0` |
| **`--metric <type>`** | Color metric: `riemersma` (human eye perceptual) or `rgb` (Euclidean). | `riemersma` | `riemersma` |
| **`--force`** | Bypasses the physical RAM pre-flight guard for massive ultra-high-res renders. | *Off* | Flag (no argument) |

---

## Ready-to-Use Recipes

### 1. The High-Def Jigsaw Puzzle Poster
```bash
macosaix-cli \
  --target portrait.avif \
  --sources ~/Pictures/Vacation \
  --shape puzzle \
  --across 40 \
  --down 30 \
  --curviness 0.5 \
  --stroke 0.75 \
  --width 4800 \
  --output puzzle_poster.png
```

### 2. The "No Duplicates" Fine-Art Mosaic
Every single tile is guaranteed to be a distinct photo (requires sufficient photos in your sources folder):
```bash
macosaix-cli \
  --target landscape.heic \
  --sources ~/Pictures/CameraRoll \
  --shape rect \
  --across 40 \
  --down 30 \
  --max-reuse 1 \
  --output unique_mosaic.png
```

### 3. Hexagonal Honeycomb
```bash
macosaix-cli \
  --target photo.jpg \
  --sources ~/Pictures/CameraRoll \
  --shape hex \
  --across 50 \
  --down 35 \
  --stroke 0.5 \
  --width 3000 \
  --output honeycomb.png
```

---

## Project Structure

- **`macosaix-modern/`**: The modern Apple Silicon revival codebase:
  - `Sources/MacOSaiXCore/`: Objective-C core module containing the original cubic Bezier puzzle tab mathematics, hexagonal tessellations, and Riemersma perceptual color matching.
  - `Sources/MacOSaiXKit/`: Shared Swift package providing `ImageLoader` (AVIF/HEIC ImageIO decoding), `MosaicEngine` (parallel solver), `MosaicProject` (compressed `.macosaix` zip manager), `MosaicRenderer`, and `MosaicThumbnailCache`.
  - `Sources/MacOSaiXApp/`: Native SwiftUI GUI application with sidebar controls, live progressive canvas, blend slider, and 2D trackpad navigation.
  - `Sources/macosaix-cli/`: High-performance command-line tool.
- **`MacOSaiX Remake.app/`**: Standalone, codesigned macOS application bundle.
- **`MacOSaiX/`**, **`Standard Plugins/`**: Original 2002–2009 Mac OS X codebase by Frank Midgley (archival reference).

---

## Credits & License

- **Modern Revival & Engineering**: **Carlo Monjaraz-Tec** (AI-assisted coding, 2026).
- **Original Software & Mathematical Concepts**: **Frank M. Midgley** (MacOSaiX 1.x – 2.x, 2002–2009).

### License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for the full text.

- **Copyleft Protection**: Any derivative works, modifications, or applications incorporating this code must also be licensed under the GNU GPL-3.0 with source code made available.
- **Historical Attribution**: The original MacOSaiX legacy codebase (`MacOSaiX/`, `Standard Plugins/`) and artwork remain copyright © 2001–2009 Frank M. Midgley and are preserved here for historical reference.
