#import "MacOSaiXMatcher.h"

#define MAX_COLOR_DIFF_RIEMERSMA (255.0f * 255.0f * 9.0f)
#define MAX_COLOR_DIFF_RGB (255.0f * 255.0f * 3.0f)

static inline float colorDifferenceRiemersma(unsigned char r1, unsigned char g1, unsigned char b1,
                                            unsigned char r2, unsigned char g2, unsigned char b2)
{
    int redDiff   = (int)r1 - (int)r2;
    int greenDiff = (int)g1 - (int)g2;
    int blueDiff  = (int)b1 - (int)b2;
    
    float redAverage = ((float)r1 + (float)r2) * 0.5f;
    return ((2.0f + redAverage / 255.0f) * (float)(redDiff * redDiff) +
            4.0f * (float)(greenDiff * greenDiff) +
            (2.0f + (255.0f - redAverage) / 255.0f) * (float)(blueDiff * blueDiff));
}

static inline float colorDifferenceRGB(unsigned char r1, unsigned char g1, unsigned char b1,
                                      unsigned char r2, unsigned char g2, unsigned char b2)
{
    int redDiff   = (int)r1 - (int)r2;
    int greenDiff = (int)g1 - (int)g2;
    int blueDiff  = (int)b1 - (int)b2;
    
    return (float)(redDiff * redDiff + greenDiff * greenDiff + blueDiff * blueDiff);
}

@implementation MacOSaiXMatcher

+ (instancetype)sharedMatcher
{
    static MacOSaiXMatcher *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MacOSaiXMatcher alloc] init];
    });
    return shared;
}

- (float)compareTargetPixels:(const unsigned char *)targetPixels
             candidatePixels:(const unsigned char *)candidatePixels
                  maskPixels:(const unsigned char *)maskPixels
                       width:(int)width
                      height:(int)height
                      metric:(MacOSaiXColorMetric)metric
{
    if (!targetPixels || !candidatePixels || width <= 0 || height <= 0) {
        return 1.0f;
    }
    
    const float maxDiff = (metric == MacOSaiXColorMetricRiemersma) ? MAX_COLOR_DIFF_RIEMERSMA : MAX_COLOR_DIFF_RGB;
    float accumulatedSimilarity = 0.0f;
    float totalPixelWeight = 0.0f;
    
    const int totalPixels = width * height;
    
    for (int i = 0; i < totalPixels; i++) {
        const int pixelOffset = i * 4; // RGBA 4 bytes per pixel
        
        // Weight from mask (0..255 -> 0.0..1.0). If no mask, weight is 1.0.
        float weight = 1.0f;
        if (maskPixels) {
            weight = (float)maskPixels[i] / 255.0f;
            if (weight <= 0.001f) {
                continue;
            }
        }
        
        unsigned char tr = targetPixels[pixelOffset];
        unsigned char tg = targetPixels[pixelOffset + 1];
        unsigned char tb = targetPixels[pixelOffset + 2];
        
        unsigned char cr = candidatePixels[pixelOffset];
        unsigned char cg = candidatePixels[pixelOffset + 1];
        unsigned char cb = candidatePixels[pixelOffset + 2];
        
        float diff = (metric == MacOSaiXColorMetricRiemersma) ?
            colorDifferenceRiemersma(tr, tg, tb, cr, cg, cb) :
            colorDifferenceRGB(tr, tg, tb, cr, cg, cb);
        
        float similarity = maxDiff - diff;
        if (similarity < 0.0f) similarity = 0.0f;
        
        accumulatedSimilarity += similarity * weight;
        totalPixelWeight += weight;
    }
    
    if (totalPixelWeight <= 0.0001f) {
        return 1.0f;
    }
    
    // Convert similarity to normalized match difference [0.0 (perfect) .. 1.0 (opposite)]
    float score = 1.0f - (accumulatedSimilarity / (totalPixelWeight * maxDiff));
    if (score < 0.0f) score = 0.0f;
    if (score > 1.0f) score = 1.0f;
    
    return score;
}

@end
