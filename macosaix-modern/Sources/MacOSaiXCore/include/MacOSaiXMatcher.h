#ifndef MacOSaiXMatcher_h
#define MacOSaiXMatcher_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, MacOSaiXColorMetric) {
    MacOSaiXColorMetricRiemersma = 0,
    MacOSaiXColorMetricRGB = 1
};

typedef struct {
    float bins[8];     // L2-normalized 8-bin orientation histogram in [0, pi)
    float energy;      // Average gradient magnitude per pixel
    bool hasEdges;     // True if energy > threshold (e.g. 6.0)
} MacOSaiXEdgeDescriptor;

#ifdef __cplusplus
extern "C" {
#endif

MacOSaiXEdgeDescriptor MacOSaiXComputeEdgeDescriptor(const unsigned char * _Nonnull rgba, int width, int height);
float MacOSaiXCompareEdgeDescriptors(MacOSaiXEdgeDescriptor a, MacOSaiXEdgeDescriptor b);

#ifdef __cplusplus
}
#endif

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

/// Compares two pixel buffers combining color difference with edge/directional alignment.
/// edgeWeight: 0.0 (color only) to 1.0 (maximum directional weighting).
- (float)compareTargetPixels:(nonnull const unsigned char *)targetPixels
              targetEdgeDesc:(MacOSaiXEdgeDescriptor)targetEdgeDesc
             candidatePixels:(nonnull const unsigned char *)candidatePixels
           candidateEdgeDesc:(MacOSaiXEdgeDescriptor)candidateEdgeDesc
                  maskPixels:(nullable const unsigned char *)maskPixels
                       width:(int)width
                      height:(int)height
                      metric:(MacOSaiXColorMetric)metric
                  edgeWeight:(float)edgeWeight;

@end

#endif /* MacOSaiXMatcher_h */
