#import "MacOSaiXMatcher.h"
#include <math.h>
#include <string.h>

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

- (float)compareTargetPixels:(const unsigned char *)targetPixels
              targetEdgeDesc:(MacOSaiXEdgeDescriptor)targetEdgeDesc
             candidatePixels:(const unsigned char *)candidatePixels
           candidateEdgeDesc:(MacOSaiXEdgeDescriptor)candidateEdgeDesc
                  maskPixels:(const unsigned char *)maskPixels
                       width:(int)width
                      height:(int)height
                      metric:(MacOSaiXColorMetric)metric
                  edgeWeight:(float)edgeWeight
{
    float colorScore = [self compareTargetPixels:targetPixels
                                 candidatePixels:candidatePixels
                                      maskPixels:maskPixels
                                           width:width
                                          height:height
                                          metric:metric];
    
    if (edgeWeight <= 0.001f || !targetEdgeDesc.hasEdges) {
        return colorScore;
    }
    
    float edgeDist = MacOSaiXCompareEdgeDescriptors(targetEdgeDesc, candidateEdgeDesc);
    
    // Saliency gating: scale effective edge weight by target tile energy
    // Below energy 8, gate is 0. Full gate at energy 32+.
    float saliencyGate = (targetEdgeDesc.energy - 8.0f) / (32.0f - 8.0f);
    if (saliencyGate < 0.0f) saliencyGate = 0.0f;
    if (saliencyGate > 1.0f) saliencyGate = 1.0f;
    
    float effectiveWeight = edgeWeight * saliencyGate;
    
    return (1.0f - effectiveWeight) * colorScore + effectiveWeight * edgeDist;
}

@end

MacOSaiXEdgeDescriptor MacOSaiXComputeEdgeDescriptor(const unsigned char *rgba, int width, int height)
{
    MacOSaiXEdgeDescriptor desc;
    memset(&desc, 0, sizeof(desc));
    
    if (!rgba || width < 3 || height < 3) {
        return desc;
    }
    
    // 1. Grayscale luminance
    int totalPixels = width * height;
    float *luma = (float *)alloca(totalPixels * sizeof(float));
    for (int i = 0; i < totalPixels; i++) {
        int idx = i * 4;
        luma[i] = 0.299f * rgba[idx] + 0.587f * rgba[idx + 1] + 0.114f * rgba[idx + 2];
    }
    
    // 2. Sobel 3x3 convolution
    float rawBins[8] = {0.0f};
    float totalEnergy = 0.0f;
    int edgeCount = 0;
    
    const float pi = 3.14159265358979323846f;
    const float binWidth = pi / 8.0f; // 22.5 degrees per bin
    
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            // Sobel Gx:
            // -1  0  1
            // -2  0  2
            // -1  0  1
            float gx = (luma[(y - 1) * width + (x + 1)] - luma[(y - 1) * width + (x - 1)]) +
                       2.0f * (luma[y * width + (x + 1)] - luma[y * width + (x - 1)]) +
                       (luma[(y + 1) * width + (x + 1)] - luma[(y + 1) * width + (x - 1)]);
            
            // Sobel Gy:
            // -1 -2 -1
            //  0  0  0
            //  1  2  1
            float gy = (luma[(y + 1) * width + (x - 1)] - luma[(y - 1) * width + (x - 1)]) +
                       2.0f * (luma[(y + 1) * width + x] - luma[(y - 1) * width + x]) +
                       (luma[(y + 1) * width + (x + 1)] - luma[(y - 1) * width + (x + 1)]);
            
            float mag = sqrtf(gx * gx + gy * gy);
            totalEnergy += mag;
            edgeCount++;
            
            // Edge angle in [0, pi)
            float angle = atan2f(gy, gx);
            if (angle < 0.0f) {
                angle += pi;
            }
            if (angle >= pi) {
                angle -= pi;
            }
            
            // Bilinear interpolation between the two nearest bin centers
            // Bin centers are at: (k + 0.5) * binWidth
            float binIdx = (angle / binWidth) - 0.5f;
            if (binIdx < 0.0f) {
                binIdx += 8.0f;
            }
            int b0 = ((int)binIdx) % 8;
            int b1 = (b0 + 1) % 8;
            float frac = binIdx - floorf(binIdx);
            
            rawBins[b0] += mag * (1.0f - frac);
            rawBins[b1] += mag * frac;
        }
    }
    
    desc.energy = (edgeCount > 0) ? (totalEnergy / (float)edgeCount) : 0.0f;
    desc.hasEdges = (desc.energy >= 8.0f);
    
    // L2 normalize bins
    float normSq = 0.0f;
    for (int i = 0; i < 8; i++) {
        normSq += rawBins[i] * rawBins[i];
    }
    float norm = sqrtf(normSq);
    if (norm > 0.0001f) {
        for (int i = 0; i < 8; i++) {
            desc.bins[i] = rawBins[i] / norm;
        }
    }
    
    return desc;
}

float MacOSaiXCompareEdgeDescriptors(MacOSaiXEdgeDescriptor a, MacOSaiXEdgeDescriptor b)
{
    // If target has no noticeable edges, orientation difference is irrelevant (return 0.0 distance)
    if (!a.hasEdges) {
        return 0.0f;
    }
    // If candidate has no edges but target does, penalize by edge absence
    if (!b.hasEdges) {
        return 1.0f;
    }
    
    // Dot product of L2-normalized 8-bin histograms
    float dot = 0.0f;
    for (int i = 0; i < 8; i++) {
        dot += a.bins[i] * b.bins[i];
    }
    if (dot > 1.0f) dot = 1.0f;
    if (dot < 0.0f) dot = 0.0f;
    
    // Distance in [0.0 (identical direction) .. 1.0 (orthogonal)]
    return (1.0f - dot);
}
