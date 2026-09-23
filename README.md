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

## 🚀 Additional Features & Algorithms (Over Original MacOSaiX)

While faithfully honoring Frank M. Midgley's original architecture and aesthetics, **MacOSaiX Remake** introduces modern computational photography and computer vision algorithms not present in the classic 2002–2009 application:

### 1. Reinhard Perceptual Color Transfer in OKLab Space 🎨🔬
Traditional photomosaics often suffer when the user's photo collection lacks certain hues present in the target image (e.g. skin tones, azure skies, deep greens). Simple opacity blending washes out individual photos and feels like an artificial overlay.

Instead, we implement **Reinhard Statistical Color Transfer** formulated inside the modern **OKLab color space**:
- **Why OKLab?**: Unlike traditional Ruderman $\ell\alpha\beta$, OKLab cleanly decorrelates perceived lightness ($L$) from chromatic opponent channels ($a, b$). Constituent photos keep their internal contrast, textures, and deep shadows razor-sharp while naturally adopting the target tile's color palette.
- **Mathematical Formulation**:
  1. **sRGB $\to$ Linear RGB $\to$ LMS Cone Response $\to$ OKLab**:
     $$\begin{bmatrix} L \\ a \\ b \end{bmatrix} = \mathbf{M}_2 \cdot \left( \mathbf{M}_1 \cdot \begin{bmatrix} R_{\text{linear}} \\ G_{\text{linear}} \\ B_{\text{linear}} \end{bmatrix} \right)^{1/3}$$
  2. **Channel-Wise Statistical Normalization & Shifting**:
     For each channel $c \in \{L, a, b\}$, candidate pixels are aligned to the target tile's distribution:
     $$c_{\text{trans}} = \mu_{\text{target}, c} + \left( \frac{\sigma_{\text{target}, c}}{\sigma_{\text{src}, c}} \right) \cdot (c_{\text{src}} - \mu_{\text{src}, c})$$
  3. **Controlled Strength Interpolation**:
     $$c_{\text{final}} = (1 - \lambda) \cdot c_{\text{src}} + \lambda \cdot c_{\text{trans}}, \quad \lambda \in [0.0, 1.0]$$
- **Interactive Real-Time GUI**:
  - Floating slider (`Transfer: 0% – 100%`) with dynamic quantized caching for silky 60+ FPS scrub performance.
  - Sweet spot at **30%–50%** for ideal harmony between macro fidelity and constituent photo recognition.
  - In-app **`(i)` educational popover** displaying live explanations and literature citations.
- **Academic References**:
  - **Reinhard, E., Ashikhmin, M., Gooch, B., & Shirley, P. (2001)**. *Color Transfer between Images*. IEEE Computer Graphics and Applications, 21(5), 34–41.
  - **Ottosson, B. (2020)**. *A perceptual color space for image processing* (Oklab).

### 2. Edge-Aware & Directional Matching (Sobel HOG) 🧭📐
Traditional photomosaics evaluate only color distance. If a target tile contains a high-contrast diagonal edge (an architectural beam, a jawline, an eye contour, or a horizon), standard color matching might place a flat photo or an image whose internal lines clash with the contour.

**Edge-Aware Directional Matching** aligns the structural flow of constituent photos with the target image contours using a **Histogram of Oriented Gradients (HOG)**:
- **Sobel Spatial Gradients**: Applies horizontal and vertical $3 \times 3$ Sobel convolution filters ($G_x, G_y$) to compute gradient magnitude $M = \sqrt{G_x^2 + G_y^2}$ and unsigned orientation $\theta = \operatorname{atan2}(G_y, G_x) \pmod \pi \in [0, \pi)$.
- **8-Bin Interpolated Orientation Histograms**: Accumulates edge energy into an $L_2$-normalized 8-bin orientation vector with bilinear angular interpolation to prevent hard bin boundary artifacts.
- **Saliency Gating**: Automatically scales edge weighting based on the target tile's edge energy. Flat regions (skies, smooth gradients) have zero edge energy, so the algorithm automatically defaults to pure color matching without noise or unwanted penalties.
- **Combined Distance Metric**:
  $$D_{\text{total}} = (1 - \alpha_{\text{eff}}) \cdot D_{\text{color}} + \alpha_{\text{eff}} \cdot (1 - \mathbf{h}_{\text{target}} \cdot \mathbf{h}_{\text{candidate}})$$
- **Interactive GUI & CLI**:
  - **Edge Alignment** slider (0% to 100%) in the Matching sidebar with an in-app `(i)` educational popover.
  - `--edge-weight <float>` option in `macosaix-cli`.
- **Academic References**:
  - **Dalal, N., & Triggs, B. (2005)**. *Histograms of Oriented Gradients for Human Detection*. IEEE CVPR, 1, 886–893.
  - **Park, J., Kang, K., & Chung, K. (2006)**. *Edge-based Tile Mosaic Simulation*. Computer Graphics Forum, 25(3), 441–448.

### 3. Adaptive Multi-Resolution Tiling (Quadtree Decomposition) 🔲🔍
Uniform grid mosaics impose a frustrating trade-off: small tiles reveal intricate subject details but make individual constituent photos tiny and illegible; large tiles showcase photos beautifully but turn facial features, eyes, and text into coarse blocks.

**Adaptive Quadtree Tiling** dynamically concentrates small, fine-grained tiles on high-detail regions while preserving large, expansive photo tiles in uniform background areas:
- **$O(1)$ Constant-Time Variance via Integral Images**: Computes cumulative Summed-Area Tables for luminance ($I$) and squared luminance ($I^2$) across the target image. The variance $\sigma_Y$ of any candidate quadrant is computed in exactly 8 table lookups, executing full quadtree re-tessellation across thousands of tiles in **< 2 milliseconds**.
- **Hierarchical Quadrant Subdivision**: Starting from a base coarse grid, any cell whose local variance exceeds the user's **Detail Sensitivity** threshold recursively splits into 4 quadrants (NW, NE, SW, SE) up to the specified **Max Depth** (allowing up to $64\times$ smaller focal tiles).
- **Synergistic Compounding**: Seamlessly compounds with both **Reinhard OKLab Color Transfer** and **Sobel HOG Edge Alignment**.
- **Interactive GUI & CLI**:
  - Select **Adaptive** in the Tile Shapes picker to unlock **Base Grid**, **Max Subdivision Levels** (1–4), and **Detail Sensitivity** (5%–40%) controls with an in-app `(i)` educational popover.
  - `--shape quadtree`, `--quadtree-depth <N>`, and `--quadtree-thresh <float>` in `macosaix-cli`.
- **Academic References**:
  - **Finkel, R. A., & Bentley, J. L. (1974)**. *Quad Trees: A Data Structure for Retrieval on Composite Keys*. Acta Informatica, 4(1), 1–9.
  - **Crow, F. C. (1984)**. *Summed-Area Tables for Texture Mapping*. ACM SIGGRAPH Computer Graphics, 18(3), 207–212.
  - **Klein, A. W., Grant, T., Finkelstein, A., & Salesin, D. H. (2002)**. *Non-photorealistic Virtual Environments*. ACM SIGGRAPH, 527–534.

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
| **`--shape <type>`** | Tile geometry: `rect` (square), `hex` (hexagon), `puzzle` (jigsaw), or `quadtree` (adaptive). | `rect` | `rect`, `puzzle`, or `quadtree` |
| **`--across <N>`** | Number of tiles horizontally (or base grid across for quadtree). | `30` | `30` to `60` (or `12`–`24` for quadtree) |
| **`--down <N>`** | Number of tiles vertically (or base grid down for quadtree). | `20` | `20` to `45` (match aspect ratio) |
| **`--quadtree-depth <N>`** | *(Quadtree only)* Max subdivision depth (1 = 2×, 2 = 4×, 3 = 8×, 4 = 16×). | `3` | `2` or `3` |
| **`--quadtree-thresh <f>`**| *(Quadtree only)* Detail sensitivity threshold (`0.05` = fine, `0.40` = coarse). | `0.15` | `0.10` to `0.18` |
| **`--curviness <float>`** | *(Puzzle only)* Edge waviness from `0.0` (straight tabs) to `1.0` (very wavy). | `0.5` | `0.3` to `0.7` |
| **`--max-reuse <N>`** | Max appearances per photo (`0` = unlimited, `1` = all unique photos). | `0` | `0`, `1`, or `3`–`5` |
| **`--min-distance <N>`** | Minimum grid spacing between duplicate photos to prevent clustering. | `2` | `2` to `5` |
| **`--width <pixels>`** | Output resolution width in pixels. | `2400` | `2400` (screen), `4000`–`8000` (print) |
| **`--stroke <pixels>`** | Border cutline stroke width (`0.0` for seamless, `0.5`+ for puzzle die-cuts). | `0.0` | `0.5` or `1.0` |
| **`--color-transfer <float>`** | Reinhard perceptual color transfer (`0.0` = original, `1.0` = full match). | `0.0` | `0.3` to `0.5` |
| **`--edge-weight <float>`** | Edge-aware directional matching (`0.0` = color only, `1.0` = max edge weighting). | `0.0` | `0.25` to `0.45` |
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
