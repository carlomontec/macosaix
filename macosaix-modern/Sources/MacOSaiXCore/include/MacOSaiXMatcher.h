#ifndef MacOSaiXMatcher_h
#define MacOSaiXMatcher_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, MacOSaiXColorMetric) {
    MacOSaiXColorMetricRiemersma = 0,
    MacOSaiXColorMetricRGB = 1
};

@interface MacOSaiXMatcher : NSObject

+ (nonnull instancetype)sharedMatcher;

/// Compares two 16x16 pixel buffers (RGBA, 4 bytes per pixel) with a 16x16 8-bit grayscale mask.
/// Returns a score from 0.0 (perfect match) to 1.0 (worst match).
- (float)compareTargetPixels:(nonnull const unsigned char *)targetPixels
             candidatePixels:(nonnull const unsigned char *)candidatePixels
                  maskPixels:(nullable const unsigned char *)maskPixels
                       width:(int)width
                      height:(int)height
                      metric:(MacOSaiXColorMetric)metric;

@end

#endif /* MacOSaiXMatcher_h */
