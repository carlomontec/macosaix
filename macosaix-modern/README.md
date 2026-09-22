# MacOSaiX Remake

A modern, native Apple Silicon remake of **MacOSaiX** — the classic Mac photomosaic creator originally developed by **Frank M. Midgley** (2002–2007). 

Revived and extended with **AI-assisted coding** by **Carlo Monjaraz-Tec** (2026).

It takes a **target image** (the big picture) and recreates it using hundreds or thousands of smaller photos from a **folder of images** (including iPhone `.heic` photos), supporting **interlocking jigsaw puzzle pieces**, **hexagons**, and **rectangles**.

---

## The GUI App (`MacOSaiX Remake.app`)

A full modern native macOS GUI application is included!
```bash
open "MacOSaiX Remake.app"
```

---

## Quick Start

```bash
cd /Users/carlo/code/macosaix/macosaix-modern

.build/release/macosaix-cli \
  --target "/path/to/main_picture.heic" \
  --sources "/path/to/my_photos_folder" \
  --output "my_mosaic.png"
```

---

## Plain-English Guide to All Options

| Option | What it does | Default | Recommended Values |
| :--- | :--- | :--- | :--- |
| **`--target <file>`** | **Required**. The main image you want to recreate as a mosaic. Supports iPhone HEIC, JPEG, PNG, TIFF, WebP. | *None* | Any photo |
| **`--sources <folder>`** | **Required**. The folder containing the small photos that will form the mosaic tiles. It searches subfolders automatically. | *None* | A folder with 50 to 10,000+ photos |
| **`--output <file>`** | Where to save the final mosaic. Extension can be `.png` (lossless, highest quality) or `.jpg` / `.jpeg`. | `mosaic.png` | `~/Desktop/mosaic.png` |
| **`--shape <type>`** | The shape of the tiles. Choices: `puzzle`, `hex`, or `rect`. | `puzzle` | See below for details |
| **`--across <N>`** | Number of tiles horizontally. | `30` | `30` to `60` (more = more detail) |
| **`--down <N>`** | Number of tiles vertically. | `20` | `20` to `45` (match your photo's aspect ratio) |
| **`--curviness <float>`** | *(Puzzle shape only)* How wavy and organic the puzzle edges are. `0.0` is straight edges with tabs; `1.0` is very wavy. | `0.5` | `0.3` to `0.7` |
| **`--max-reuse <N>`** | How many times any single photo is allowed to appear in the whole mosaic. `0` means unlimited reuse. | `0` | `0` (unlimited), `1` (each photo only used once), or `3` to `5` |
| **`--min-distance <N>`** | Prevents identical photos from clustering together. Measures distance in tile grid units. | `2` | `2` to `5` |
| **`--width <pixels>`** | Width of the final output image in pixels. | `2400` | `2400` (screen/web), `4000` to `8000` (printing/posters) |
| **`--stroke <pixels>`** | Draws a subtle cut/border line around each tile piece. | `0.0` | `0.5` or `1.0` for puzzle pieces, `0.0` for seamless |
| **`--metric <type>`** | Color matching algorithm: `riemersma` (human eye perceptual color formula) or `rgb` (standard RGB distance). | `riemersma` | `riemersma` (recommended) |
| **`--force`** | Bypasses the RAM safety guard if you intentionally want to generate a massive gigapixel mosaic. | *Off* | Flag (no value) |

---

## The Tile Shapes Explained

### 1. `puzzle` (Jigsaw Puzzle)
Every single tile is a real interlocking jigsaw puzzle piece with cubic Bezier tabs and sockets. Adjacent pieces connect into each other seamlessly.
- **Tip**: Add `--stroke 0.5` or `--stroke 1.0` to draw thin puzzle die-cut lines so the jigsaw pieces clearly pop out!

### 2. `hex` (Hexagonal Honeycomb)
Arranges your photos into an alternating hexagonal honeycomb lattice. Gives a modern geometric art feel.
- **Tip**: Works great with `--across 40 --down 30` or higher.

### 3. `rect` (Classic Grid)
The traditional photomosaic grid with clean rectangular tiles.
- **Tip**: Best for showing off the small photos without any cropping of curved edges.

---

## Ready-to-Use Recipes

### 1. The High-Def Jigsaw Puzzle Poster
Great for printing on a canvas or poster:
```bash
.build/release/macosaix-cli \
  --target ~/Pictures/Portrait.heic \
  --sources ~/Pictures/VacationPhotos \
  --shape puzzle \
  --across 40 \
  --down 30 \
  --curviness 0.5 \
  --stroke 0.75 \
  --width 4800 \
  --output ~/Desktop/puzzle_poster.png
```

### 2. The "No Duplicates" Fine-Art Mosaic
Ensures every tile is a unique photo (requires having enough photos in your sources folder to fill all tiles):
```bash
.build/release/macosaix-cli \
  --target ~/Pictures/Landscape.heic \
  --sources ~/Pictures/AllPhotos \
  --shape puzzle \
  --across 30 \
  --down 20 \
  --max-reuse 1 \
  --output ~/Desktop/unique_mosaic.png
```

### 3. Hexagonal Honeycomb
```bash
.build/release/macosaix-cli \
  --target ~/Pictures/Pet.heic \
  --sources ~/Pictures/CameraRoll \
  --shape hex \
  --across 50 \
  --down 35 \
  --stroke 0.5 \
  --width 3000 \
  --output ~/Desktop/honeycomb.png
```

### 4. Fast Draft / Quick Preview
Low tile count and 1200px width so you can test color matches in 0.2 seconds:
```bash
.build/release/macosaix-cli \
  --target ~/Pictures/Vacation.heic \
  --sources ~/Pictures/CameraRoll \
  --across 20 \
  --down 15 \
  --width 1200 \
  --output ~/Desktop/preview.png
```

---

## How Matching Works Under the Hood

1. **Hardware HEIC & Image Loading**: When scanning your photos folder, Apple's `ImageIO` extracts 16x16 thumbnail representations directly in hardware without decompressing huge 48-megapixel photos into RAM.
2. **Vector Masking**: For puzzle and hexagonal shapes, a 16x16 grayscale vector mask is rasterized for each tile's outline.
3. **Perceptual Weighting (Riemersma Metric)**: Pixels outside the puzzle tab are ignored; pixels inside are weighted according to how human eyes perceive color differences between red, green, and blue.
4. **Placement Constraints**: As each photo is evaluated, the engine checks `--max-reuse` and `--min-distance` so identical photos don't end up side-by-side.
5. **High-Res Vector-Clipped Export**: During export, each tile's full-resolution photo is clipped to the exact vector shape of that piece.
