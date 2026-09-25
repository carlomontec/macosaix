# MacOSaiX Remake — Multi-Source Image Providers Roadmap 📸☁️

This document outlines the architecture, setup requirements, and implementation plan for adding **Apple Photos**, **Google Photos**, and **Microsoft OneDrive** to MacOSaiX Remake.

Use this document to kick off the dedicated feature branch and implementation conversation.

---

## 🏛️ 1. Core Architecture: `MosaicImageSource` Protocol

Currently, `MosaicEngine` scans filesystem directories directly (`URL`). To support local and cloud sources interchangeably, we abstract image acquisition behind a unified protocol:

```swift
import Foundation
import CoreGraphics

/// Identifies an individual image candidate regardless of where it resides.
public struct MosaicCandidateItem: Identifiable, Sendable {
    public let id: String                    // Local path, PHAsset identifier, or Google mediaItemId
    public let displayName: String
    public let sourceProviderID: String      // "local", "apple-photos", "google-photos", "onedrive"
    public let originalURL: URL?             // Optional local file URL if available
}

/// Universal abstraction for local, native OS, and cloud photo sources.
public protocol MosaicImageSource: AnyObject, Sendable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }             // SF Symbol name (e.g. "photo.on.rectangle", "icloud")
    var isConfigured: Bool { get }           // True if authorized / logged in

    /// Enumerate all available photos or albums
    func enumerateCandidates(progress: @Sendable (Int, Int) -> Void) async throws -> [MosaicCandidateItem]

    /// Extract or download a low-resolution thumbnail (16x16 or 64x64) for candidate matching
    func loadCandidateThumbnail(for item: MosaicCandidateItem) async throws -> CGImage

    /// Load or download full-resolution image when a photo wins a tile on the canvas
    func loadFullResolutionImage(for item: MosaicCandidateItem) async throws -> CGImage
}
```

---

## 🍏 2. Apple Photos (`PhotoKit`)

### Overview & Capabilities
- **Native macOS Framework**: `import Photos`
- **Zero API Keys & Zero Logins**: Uses macOS's native permissions system.
- **iCloud Transparency**:
  - Scanning reads from macOS's local thumbnail database (`isNetworkAccessAllowed = false`, `deliveryMode = .fastFormat`) — scans 50,000 photos in seconds with **zero network traffic**.
  - High-res images for winning tiles are downloaded on demand (`isNetworkAccessAllowed = true`).

### Required Configuration in `Info.plist`
Add the privacy description to `macosaix-modern/scripts/bundle_app.sh`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>MacOSaiX needs access to your Photos library to use your pictures as mosaic tiles.</string>
```

### Implementation Details
```swift
import Photos

final class ApplePhotosSource: MosaicImageSource {
    let id = "apple-photos"
    let displayName = "Apple Photos"
    let iconName = "photo.stack"

    func checkAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited { return true }
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
    }

    func enumerateAlbums() -> [(id: String, title: String)] {
        var albums: [(String, String)] = [("all", "All Photos"), ("favorites", "Favorites")]
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            if let title = collection.localizedTitle {
                albums.append((collection.localIdentifier, title))
            }
        }
        return albums
    }

    func loadCandidateThumbnail(for item: MosaicCandidateItem) async throws -> CGImage {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false // ⚡️ Local cache only
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        // Request 64x64 via PHImageManager.default()
        ...
    }
}
```

---

## 🌐 3. Google Photos (Google Photos REST API)

### Developer Setup (What Carlo Needs Before Starting)
1. Go to **[Google Cloud Console](https://console.cloud.google.com/)**.
2. Create a new project: `MacOSaiX`.
3. Enable the **Google Photos Library API** (or **Google Photos Picker API**).
4. Go to **Credentials** $\to$ **Create Credentials** $\to$ **OAuth client ID**:
   - Application type: **macOS** or **iOS**.
   - Bundle ID: `com.midgley.macosaix`.
5. Go to **OAuth Consent Screen**:
   - User Type: **External**.
   - Add Carlo's email (and friends' emails) under **Test Users**.
   - *Note: Test users bypass Google verification and security audits!*

### Authentication in macOS
- Use macOS native `ASWebAuthenticationSession` (opens a secure sheet, redirects to custom scheme `macosaix-oauth://callback` or loopback `http://localhost:8080`).
- Tokens (Access Token + Refresh Token) are stored in the macOS **Keychain**.

### Secret Superpower: Dynamic CDN Resizing (`baseUrl`)
Google Photos media items provide a `baseUrl`:
- **For Candidate Matching (64×64 thumbnail)**:
  `GET {baseUrl}=w64-h64-c` (Fast, 2KB image from Google CDN).
- **For Final Export / Canvas (High-Res)**:
  `GET {baseUrl}=w2048-h2048` or `GET {baseUrl}=d` (Full original download).

---

## ☁️ 4. Microsoft OneDrive

### Approach A: Local Synced Folder Auto-Detection (Zero Code & Instant)
If the user runs the OneDrive macOS desktop client:
- Automatically check if either directory exists:
  - `~/Library/CloudStorage/OneDrive-Personal/Pictures`
  - `~/OneDrive/Pictures`
- Provide a one-click button: **"Add Synced OneDrive Photos"** which automatically adds it to our local folder scanner.

### Approach B: Microsoft Graph Cloud API
1. Register app in **[Microsoft Azure Portal](https://portal.azure.com/)** $\to$ App Registrations.
2. Supported account types: *Personal Microsoft accounts only*.
3. API Permissions: `Files.Read` (Delegated).
4. Authentication: OAuth 2.0 PKCE flow via `ASWebAuthenticationSession`.
5. Endpoints:
   - Enumerate: `GET https://graph.microsoft.com/v1.0/me/drive/special/photos/children`
   - Thumbnails: `GET https://graph.microsoft.com/v1.0/me/drive/items/{id}/thumbnails/0/small/content`

---

## 🎨 5. Sidebar UI Design

In `SidebarView.swift`, replace the simple folder list with a segmented or tabbed source manager:

```text
┌──────────────────────────────────────────────┐
│ IMAGE SOURCES                                │
│ [📁 Local]  [🍏 Photos]  [🌐 Google]  [☁️ MS] │
├──────────────────────────────────────────────┤
│ 🍏 Apple Photos                              │
│   Album: [ Favorites             ▼ ]         │
│   Photos found: 1,420                        │
│                                              │
│ 📁 Folders                                   │
│   ✓ ~/Pictures/Vacation2024 (850 photos)     │
│   ✓ /Volumes/ExtremeSSD/Raw (12,000 photos)  │
│   [+ Add Folder...]                          │
│                                              │
│ 🌐 Google Photos                             │
│   [ Connect Account... ]                     │
└──────────────────────────────────────────────┘
```

---

## 🚀 6. Prompt to Kick Off the New Conversation

When you are ready to implement this in a new conversation, paste the following prompt:

```text
Hi! We are working on MacOSaiX Remake (/Users/carlo/code/macosaix/macosaix).
Please inspect IMAGE_SOURCES.md in the repository root.
We are creating a new branch: feature/cloud-sources.
Our objective in this session is to implement Phase 1: Apple Photos (PhotoKit) integration:
1. Define the MosaicImageSource protocol in MacOSaiXKit.
2. Implement ApplePhotosSource using PhotoKit (PHPhotoLibrary & PHImageManager with local thumbnail caching).
3. Add the NSPhotoLibraryUsageDescription entitlement to bundle_app.sh.
4. Update SidebarView and MosaicViewModel to let the user select between Local Folders and Apple Photos (with Album picker: All Photos, Favorites, Custom Albums).
Let's build and verify on Apple Silicon!
```
