# MacOSaiX Remake (Apple Silicon Native)

**MacOSaiX Remake** is a modern, native Apple Silicon revival and remake of **MacOSaiX** — the legendary photomosaic software originally created by **Frank M. Midgley** (2002–2007) for Mac OS X. 

Revived, rebuilt, and modernized using **AI-assisted coding** by **Carlo Monjaraz-Tec** (2026), it preserves Frank Midgley's original mathematical foundations (cubic Bezier interlocking jigsaw puzzle pieces, hexagonal tessellations, and Riemersma perceptual color metrics) while rebuilding the entire runtime in Swift, SwiftUI, and native Apple frameworks.

---

## Modern Revival Features

- **Native macOS GUI App (`MacOSaiX Remake.app`)**: Faithful to Frank Midgley's classic 2-pane layout (sidebar controls + live progressive CoreGraphics canvas + interactive blend slider), built in modern Swift & SwiftUI.
- **Interlocking Jigsaw Puzzle Tiles**: Every piece is a real puzzle piece mathematically generated with cubic Bezier tabs and sockets that connect with adjacent pieces.
- **Hexagonal Tessellations**: Honeycomb tile layouts that give mosaics a modern geometric feel.
- **Masked Perceptual Color Matching**: Evaluates image candidates through the exact vector shape of each tile using the **Riemersma perceptual color difference metric** (human eye color weighting).
- **Smart Placement Constraints**: Minimum spatial distance rules (to prevent duplicate photos from sitting side-by-side) and maximum reuse caps per photo.
- **Native Apple HEIC & Modern Formats**: Uses Apple's native `ImageIO` framework to decode `.heic` photos directly from your iPhone, with hardware EXIF orientation handling.
- **RAM Pre-Flight Check**: Real-time memory safety check to ensure high-resolution renders never exceed safe physical RAM thresholds.

---

## Launching the GUI App (`MacOSaiX Remake.app`)

A pre-bundled and signed application is ready in the repository:
```bash
open "MacOSaiX Remake.app"
```
Or build and bundle it anytime from source:
```bash
cd macosaix-modern
./scripts/bundle_app.sh
```

---

## Quick Start (CLI)

You do **not** need full Xcode installed — Apple's Command Line Tools (`swift`, `clang`) are sufficient.

### 1. Build the Modern CLI

```bash
cd macosaix-modern
swift build -c release
```

The compiled binary will be located at:
```bash
macosaix-modern/.build/release/macosaix-cli
```

*(Optional) Install it to your system path:*
```bash
sudo ln -sf "$(pwd)/.build/release/macosaix-cli" /usr/local/bin/macosaix-cli
```

### 2. Generate a Mosaic from Terminal

```bash
# Make a jigsaw puzzle mosaic from an iPhone HEIC photo and your photo folder:
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

## Command-Line Options Reference

| Option | Description | Default | Recommended |
| :--- | :--- | :--- | :--- |
| **`--target <file>`** | **Required**. Main image to recreate (HEIC, JPEG, PNG, TIFF, WebP). | *None* | Any high-contrast image |
| **`--sources <folder>`** | **Required**. Folder containing tile photos (subfolders searched automatically). | *None* | Folder with 100 to 10,000+ photos |
| **`--output <file>`** | Output file path (`.png` for lossless quality, or `.jpg`). | `mosaic.png` | `~/Desktop/mosaic.png` |
| **`--shape <type>`** | Tile geometry: `puzzle` (jigsaw), `hex` (hexagon), or `rect` (rectangle). | `puzzle` | `puzzle` |
| **`--across <N>`** | Number of tiles horizontally. | `30` | `30` to `60` (more = more detail) |
| **`--down <N>`** | Number of tiles vertically. | `20` | `20` to `45` (match target aspect ratio) |
| **`--curviness <float>`** | *(Puzzle only)* Edge waviness from `0.0` (straight tabs) to `1.0` (very wavy). | `0.5` | `0.3` to `0.7` |
| **`--max-reuse <N>`** | Max times any photo can appear in the mosaic (`0` = unlimited, `1` = all unique). | `0` | `0`, `1`, or `3`–`5` |
| **`--min-distance <N>`** | Minimum grid distance between identical photos to prevent clustering. | `2` | `2` to `5` |
| **`--width <pixels>`** | Output image width in pixels. | `2400` | `2400` (screen), `4000`–`8000` (prints) |
| **`--stroke <pixels>`** | Width of subtle border line around pieces (`0.0` for seamless). | `0.0` | `0.5` or `1.0` (for puzzle pieces) |
| **`--metric <type>`** | Color metric: `riemersma` (human eye perceptual) or `rgb` (Euclidean). | `riemersma` | `riemersma` |
| **`--force`** | Bypasses the RAM safety guard for ultra-massive gigapixel renders. | *Off* | Flag (no argument) |

---

## Ready-to-Use Recipes

### The High-Def Jigsaw Puzzle Poster
```bash
macosaix-cli \
  --target portrait.heic \
  --sources ~/Pictures/Vacation \
  --shape puzzle \
  --across 40 \
  --down 30 \
  --curviness 0.5 \
  --stroke 0.75 \
  --width 4800 \
  --output puzzle_poster.png
```

### The "No Duplicates" Fine-Art Mosaic
Every single tile is guaranteed to be a distinct photo (requires enough source photos in your folder):
```bash
macosaix-cli \
  --target family.heic \
  --sources ~/Pictures/CameraRoll \
  --shape puzzle \
  --across 30 \
  --down 20 \
  --max-reuse 1 \
  --output unique_mosaic.png
```

### Hexagonal Honeycomb
```bash
macosaix-cli \
  --target pet.heic \
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
 
 - **`macosaix-modern/`**: The modern hybrid revival:
   - `Sources/MacOSaiXCore/`: Objective-C core module containing the original cubic Bezier puzzle tab mathematics, hexagonal tessellations, and Riemersma perceptual color matching.
   - `Sources/MacOSaiXKit/`: Shared Swift package providing `ImageLoader` (HEIC / ImageIO downsampling), `MosaicEngine` (parallel solver), `MosaicRenderer` (bounded-RAM exporter), and `MemoryChecker`.
   - `Sources/MacOSaiXApp/`: Native SwiftUI GUI application with sidebar controls, live progressive canvas, blend slider, and tile popover inspector.
   - `Sources/macosaix-cli/`: High-performance command-line tool.
   - `scripts/bundle_app.sh`: Automated build and packaging script for `MacOSaiX.app`.
 - **`MacOSaiX/`**, **`Standard Plugins/`**: Original 2002–2007 Objective-C Mac OS X application codebase by Frank Midgley.
