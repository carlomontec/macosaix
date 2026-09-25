# MacOSaiX Remake

<p align="center">
  <img src="docs/screenshot.png" alt="MacOSaiX Remake in Action" width="850">
</p>

<p align="center">
  <strong>An open-source Apple Silicon revival of Frank M. Midgley's classic Mac OS X photomosaic software.</strong><br>
  Original software by <strong>Frank M. Midgley</strong> (2002–2009).
</p>

---

## Overview

**MacOSaiX Remake** is a modern revival of *MacOSaiX*, the classic open-source photomosaic creator developed for Mac OS X by Frank M. Midgley between 2002 and 2009.

This project updates the classic software to compile and run natively on 64-bit Apple Silicon and modern macOS versions. The focus is software preservation: maintaining the authentic user interface, mathematical tessellations, and color metrics while providing native performance on current hardware.

---

## Features

- **Classic 2-Pane Interface**: Sidebar controls with a live progressive assembly canvas and interactive blend slider.
- **Authentic Tile Tessellations**:
  - **Interlocking Jigsaw Puzzles (`puzzle`)**: Mathematically generated jigsaw pieces with cubic Bézier tabs and sockets that interlock seamlessly.
  - **Hexagonal Honeycombs (`hex`)**: Structured geometric honeycomb lattice.
  - **Classic Rectangles (`rect`)**: Traditional uniform rectangular grid.
- **Riemersma Perceptual Color Metric**: Color matching weighted by human visual perception rather than raw Euclidean distance.
- **Trackpad Navigation**: 2D inertial trackpad glide and pinch-to-zoom across high-resolution mosaics.
- **Modern Media Pipeline**: Native ImageIO decoding for HEIC, AVIF, WebP, JPEG, and PNG.
- **Project Save & Resume**: Lightweight `.macosaix` project save and open.

---

## Building and Running

### Build from Source

```bash
cd macosaix-modern
swift build -c release
bash scripts/bundle_app.sh
open "../MacOSaiX Remake.app"
```

> [!NOTE]
> If launching an ad-hoc signed build locally, macOS may require confirming the open dialog:
> ```bash
> xattr -cr "../MacOSaiX Remake.app"
> ```

---

## Project Structure

```
MacOSaiX_Remake/
├── MacOSaiX Remake.app/     # Bundled macOS application
├── README.md                # Project overview
├── docs/                    # Screenshots and assets
└── macosaix-modern/         # Swift Package & modernization source code
    ├── Package.swift        # Swift Package manifest
    ├── scripts/             # App bundle packaging scripts
    └── Sources/
        ├── MacOSaiXCore/    # Preserved C / Objective-C math & geometry
        ├── MacOSaiXKit/     # Shared Swift engine & ImageIO pipeline
        └── MacOSaiXApp/     # Modern SwiftUI macOS application
```

---

## Credits & License

- **Original Software & Mathematical Concepts**: **Frank M. Midgley** (MacOSaiX, 2002–2009).
- **License**: GNU General Public License v3.0 ([GPL-3.0](LICENSE)).
