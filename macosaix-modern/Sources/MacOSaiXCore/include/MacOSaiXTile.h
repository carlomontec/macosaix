#ifndef MacOSaiXTile_h
#define MacOSaiXTile_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MacOSaiXShapes.h"
#import "MacOSaiXMatcher.h"

@interface MacOSaiXTile : NSObject

@property (nonatomic, readonly, nonnull) MacOSaiXTileGeometry *geometry;
@property (nonatomic, readonly, nullable) NSData *targetPixels; // 16x16 RGBA (1024 bytes)
@property (nonatomic, readonly, nullable) NSData *maskPixels;   // 16x16 Grayscale (256 bytes)
@property (nonatomic, readonly) MacOSaiXEdgeDescriptor edgeDescriptor;

@property (nonatomic, assign) float bestScore;
@property (nonatomic, copy, nullable) NSString *bestImageIdentifier;
@property (nonatomic, retain, nullable) NSURL *bestImageURL;

- (nonnull instancetype)initWithGeometry:(nonnull MacOSaiXTileGeometry *)geometry;

/// Extracts a 16x16 RGBA thumbnail from the target image for this tile's bounding box.
- (void)extractTargetThumbnailFromImage:(nonnull CGImageRef)targetImage
                             mosaicSize:(CGSize)mosaicSize;

/// Rasterizes the vector outline into a 16x16 grayscale mask.
- (void)rasterizeMaskWithResolution:(int)resolution;

@end

#endif /* MacOSaiXTile_h */
