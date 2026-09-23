#import "MacOSaiXShapes.h"
#import <stdlib.h>

typedef NS_ENUM(NSInteger, PuzzleTabType) {
    PuzzleTabTypeNoTab = 0,
    PuzzleTabTypeInwards = -1,
    PuzzleTabTypeOutwards = 1
};

@implementation MacOSaiXTileGeometry

- (instancetype)initWithIndex:(NSInteger)index
                        gridX:(NSInteger)gx
                        gridY:(NSInteger)gy
                       bounds:(CGRect)bounds
                      outline:(CGPathRef)outline
{
    self = [super init];
    if (self) {
        _tileIndex = index;
        _gridX = gx;
        _gridY = gy;
        _bounds = bounds;
        _outline = CGPathRetain(outline);
    }
    return self;
}

- (void)dealloc
{
    if (_outline) {
        CGPathRelease(_outline);
        _outline = NULL;
    }
}

@end

static CGPathRef createPuzzlePiecePath(CGRect tileBounds,
                                      PuzzleTabType topTabType,
                                      PuzzleTabType leftTabType,
                                      PuzzleTabType rightTabType,
                                      PuzzleTabType bottomTabType,
                                      float topLeftHCurve, float topLeftVCurve,
                                      float topRightHCurve, float topRightVCurve,
                                      float bottomLeftHCurve, float bottomLeftVCurve,
                                      float bottomRightHCurve, float bottomRightVCurve)
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    const float xSize = tileBounds.size.width;
    const float ySize = tileBounds.size.height;
    const float tabSize = (xSize < ySize ? xSize : ySize) / 3.0f;
    
    const float cTopLeftH = topLeftHCurve * tabSize * 0.25f;
    const float cTopLeftV = topLeftVCurve * tabSize * 0.25f;
    const float cTopRightH = topRightHCurve * tabSize * 0.25f;
    const float cTopRightV = topRightVCurve * tabSize * 0.25f;
    const float cBottomLeftH = bottomLeftHCurve * tabSize * 0.25f;
    const float cBottomLeftV = bottomLeftVCurve * tabSize * 0.25f;
    const float cBottomRightH = bottomRightHCurve * tabSize * 0.25f;
    const float cBottomRightV = bottomRightVCurve * tabSize * 0.25f;
    
    // Start at local bottom-left corner (0, 0)
    CGPathMoveToPoint(path, NULL, 0.0f, 0.0f);
    
    // Bottom edge
    if (bottomTabType == PuzzleTabTypeNoTab) {
        CGPathAddCurveToPoint(path, NULL,
                              xSize / 3.0f, tabSize * bottomLeftHCurve,
                              xSize * 2.0f / 3.0f, tabSize * bottomRightHCurve,
                              xSize, 0.0f);
    } else {
        float orient = (bottomTabType == PuzzleTabTypeInwards) ? 1.0f : -1.0f;
        CGPathAddCurveToPoint(path, NULL, xSize / 12.0f, cBottomLeftH, xSize / 6.0f, cBottomLeftH, xSize / 4.0f, 0.0f);
        CGPathAddCurveToPoint(path, NULL, xSize / 3.0f, -cBottomLeftH, xSize / 2.0f, tabSize / 4.0f * orient, xSize * 5.0f / 12.0f, tabSize / 2.0f * orient);
        CGPathAddCurveToPoint(path, NULL, xSize / 3.0f, tabSize * 0.75f * orient, xSize * 3.0f / 8.0f, tabSize * orient, xSize / 2.0f, tabSize * orient);
        CGPathAddCurveToPoint(path, NULL, xSize * 15.0f / 24.0f, tabSize * orient, xSize * 2.0f / 3.0f, tabSize * 0.75f * orient, xSize * 7.0f / 12.0f, tabSize / 2.0f * orient);
        CGPathAddCurveToPoint(path, NULL, xSize / 2.0f, tabSize / 4.0f * orient, xSize * 2.0f / 3.0f, -cBottomRightH, xSize * 3.0f / 4.0f, 0.0f);
        CGPathAddCurveToPoint(path, NULL, xSize * 10.0f / 12.0f, cBottomRightH, xSize * 11.0f / 12.0f, cBottomRightH, xSize, 0.0f);
    }
    
    // Right edge
    if (rightTabType == PuzzleTabTypeNoTab) {
        CGPathAddCurveToPoint(path, NULL,
                              xSize + tabSize * bottomRightVCurve, ySize / 3.0f,
                              xSize + tabSize * topRightVCurve, ySize * 2.0f / 3.0f,
                              xSize, ySize);
    } else {
        float orient = (rightTabType == PuzzleTabTypeInwards) ? -1.0f : 1.0f;
        CGPathAddCurveToPoint(path, NULL, xSize + cBottomRightV, ySize / 12.0f, xSize + cBottomRightV, ySize / 6.0f, xSize, ySize / 4.0f);
        CGPathAddCurveToPoint(path, NULL, xSize - cBottomRightV, ySize / 3.0f, xSize + tabSize / 4.0f * orient, ySize / 2.0f, xSize + tabSize / 2.0f * orient, ySize * 5.0f / 12.0f);
        CGPathAddCurveToPoint(path, NULL, xSize + tabSize * 0.75f * orient, ySize / 3.0f, xSize + tabSize * orient, ySize * 3.0f / 8.0f, xSize + tabSize * orient, ySize / 2.0f);
        CGPathAddCurveToPoint(path, NULL, xSize + tabSize * orient, ySize * 15.0f / 24.0f, xSize + tabSize * 0.75f * orient, ySize * 2.0f / 3.0f, xSize + tabSize / 2.0f * orient, ySize * 7.0f / 12.0f);
        CGPathAddCurveToPoint(path, NULL, xSize + tabSize / 4.0f * orient, ySize / 2.0f, xSize - cTopRightV, ySize * 2.0f / 3.0f, xSize, ySize * 3.0f / 4.0f);
        CGPathAddCurveToPoint(path, NULL, xSize + cTopRightV, ySize * 10.0f / 12.0f, xSize + cTopRightV, ySize * 11.0f / 12.0f, xSize, ySize);
    }
    
    // Top edge
    if (topTabType == PuzzleTabTypeNoTab) {
        CGPathAddCurveToPoint(path, NULL,
                              xSize * 2.0f / 3.0f, ySize + tabSize * topRightHCurve,
                              xSize / 3.0f, ySize + tabSize * topLeftHCurve,
                              0.0f, ySize);
    } else {
        float orient = (topTabType == PuzzleTabTypeInwards) ? -1.0f : 1.0f;
        CGPathAddCurveToPoint(path, NULL, xSize * 11.0f / 12.0f, ySize + cTopRightH, xSize * 10.0f / 12.0f, ySize + cTopRightH, xSize * 3.0f / 4.0f, ySize);
        CGPathAddCurveToPoint(path, NULL, xSize * 2.0f / 3.0f, ySize - cTopRightH, xSize / 2.0f, ySize + tabSize / 4.0f * orient, xSize * 7.0f / 12.0f, ySize + tabSize / 2.0f * orient);
        CGPathAddCurveToPoint(path, NULL, xSize * 2.0f / 3.0f, ySize + tabSize * 0.75f * orient, xSize * 15.0f / 24.0f, ySize + tabSize * orient, xSize / 2.0f, ySize + tabSize * orient);
        CGPathAddCurveToPoint(path, NULL, xSize * 3.0f / 8.0f, ySize + tabSize * orient, xSize / 3.0f, ySize + tabSize * 0.75f * orient, xSize * 5.0f / 12.0f, ySize + tabSize / 2.0f * orient);
        CGPathAddCurveToPoint(path, NULL, xSize / 2.0f, ySize + tabSize / 4.0f * orient, xSize / 3.0f, ySize - cTopLeftH, xSize / 4.0f, ySize);
        CGPathAddCurveToPoint(path, NULL, xSize / 6.0f, ySize + cTopLeftH, xSize / 12.0f, ySize + cTopLeftH, 0.0f, ySize);
    }
    
    // Left edge
    if (leftTabType == PuzzleTabTypeNoTab) {
        CGPathAddCurveToPoint(path, NULL,
                              tabSize * topLeftVCurve, ySize * 2.0f / 3.0f,
                              tabSize * bottomLeftVCurve, ySize / 3.0f,
                              0.0f, 0.0f);
    } else {
        float orient = (leftTabType == PuzzleTabTypeInwards) ? 1.0f : -1.0f;
        CGPathAddCurveToPoint(path, NULL, cTopLeftV, ySize * 11.0f / 12.0f, cTopLeftV, ySize * 10.0f / 12.0f, 0.0f, ySize * 3.0f / 4.0f);
        CGPathAddCurveToPoint(path, NULL, -cTopLeftV, ySize * 2.0f / 3.0f, tabSize / 4.0f * orient, ySize / 2.0f, tabSize / 2.0f * orient, ySize * 7.0f / 12.0f);
        CGPathAddCurveToPoint(path, NULL, tabSize * 0.75f * orient, ySize * 2.0f / 3.0f, tabSize * orient, ySize * 15.0f / 24.0f, tabSize * orient, ySize / 2.0f);
        CGPathAddCurveToPoint(path, NULL, tabSize * orient, ySize * 3.0f / 8.0f, tabSize * 0.75f * orient, ySize / 3.0f, tabSize / 2.0f * orient, ySize * 5.0f / 12.0f);
        CGPathAddCurveToPoint(path, NULL, tabSize / 4.0f * orient, ySize / 2.0f, -cBottomLeftV, ySize / 3.0f, 0.0f, ySize / 4.0f);
        CGPathAddCurveToPoint(path, NULL, cBottomLeftV, ySize / 6.0f, cBottomLeftV, ySize / 12.0f, 0.0f, 0.0f);
    }
    
    CGPathCloseSubpath(path);
    
    // Translate path to tileBounds origin
    CGAffineTransform transform = CGAffineTransformMakeTranslation(tileBounds.origin.x, tileBounds.origin.y);
    CGPathRef finalPath = CGPathCreateCopyByTransformingPath(path, &transform);
    CGPathRelease(path);
    
    return finalPath;
}

// MARK: - Integral Image (Summed-Area Table) for O(1) Variance

typedef struct {
    size_t width;
    size_t height;
    double *sum;       // Cumulative luminance sum: (width + 1) * (height + 1)
    double *sumSq;     // Cumulative squared luminance sum: (width + 1) * (height + 1)
    double *sumGrad;   // Cumulative Sobel gradient magnitude sum: (width + 1) * (height + 1)
    unsigned char *smoothedGray; // 3x3 pre-smoothed grayscale buffer (w * h) for Julia Range
    unsigned char *rgbBuffer;    // 32-bit RGBA buffer (w * h * 4) for Color Range
} MacOSaiXIntegralImage;

static MacOSaiXIntegralImage MacOSaiXCreateIntegralImage(CGImageRef image) {
    MacOSaiXIntegralImage ii = {0, 0, NULL, NULL, NULL, NULL, NULL};
    if (!image) return ii;
    
    const size_t origW = CGImageGetWidth(image);
    const size_t origH = CGImageGetHeight(image);
    if (origW == 0 || origH == 0) return ii;
    
    // Cap analysis resolution to 1024 max dimension for instant (< 2ms) integral image building
    size_t w = origW;
    size_t h = origH;
    const size_t maxDim = 1024;
    if (w > maxDim || h > maxDim) {
        if (w > h) {
            h = (h * maxDim) / w;
            w = maxDim;
        } else {
            w = (w * maxDim) / h;
            h = maxDim;
        }
    }
    if (w < 16) w = 16;
    if (h < 16) h = 16;
    
    unsigned char *grayBuffer = (unsigned char *)calloc(w * h, sizeof(unsigned char));
    unsigned char *rgbBuffer = (unsigned char *)calloc(w * h * 4, sizeof(unsigned char));
    if (!grayBuffer || !rgbBuffer) {
        if (grayBuffer) free(grayBuffer);
        if (rgbBuffer) free(rgbBuffer);
        return ii;
    }
    
    // Render Grayscale buffer
    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    CGContextRef grayCtx = CGBitmapContextCreate(grayBuffer, w, h, 8, w, graySpace, kCGImageAlphaNone);
    CGColorSpaceRelease(graySpace);
    
    if (grayCtx) {
        CGContextSetInterpolationQuality(grayCtx, kCGInterpolationLow);
        CGContextTranslateCTM(grayCtx, 0, h);
        CGContextScaleCTM(grayCtx, 1.0, -1.0);
        CGContextDrawImage(grayCtx, CGRectMake(0, 0, w, h), image);
        CGContextRelease(grayCtx);
    }
    
    // Render 32-bit RGBA buffer for color-range segmentation
    CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef rgbCtx = CGBitmapContextCreate(rgbBuffer, w, h, 8, w * 4, rgbSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbSpace);
    
    if (rgbCtx) {
        CGContextSetInterpolationQuality(rgbCtx, kCGInterpolationLow);
        CGContextTranslateCTM(rgbCtx, 0, h);
        CGContextScaleCTM(rgbCtx, 1.0, -1.0);
        CGContextDrawImage(rgbCtx, CGRectMake(0, 0, w, h), image);
        CGContextRelease(rgbCtx);
    }
    
    // ── Pre-smoothed Grayscale buffer (3x3 Box Filter) for Julia Range ──
    // Eliminates isolated sensor noise / hot pixels while preserving genuine structural contours
    unsigned char *smoothedGray = (unsigned char *)calloc(w * h, sizeof(unsigned char));
    if (smoothedGray) {
        for (size_t y = 0; y < h; y++) {
            for (size_t x = 0; x < w; x++) {
                if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
                    smoothedGray[y * w + x] = grayBuffer[y * w + x];
                } else {
                    int sum3x3 = (int)grayBuffer[(y - 1) * w + (x - 1)] + (int)grayBuffer[(y - 1) * w + x] + (int)grayBuffer[(y - 1) * w + (x + 1)] +
                                 (int)grayBuffer[y * w + (x - 1)]       + (int)grayBuffer[y * w + x]       + (int)grayBuffer[y * w + (x + 1)] +
                                 (int)grayBuffer[(y + 1) * w + (x - 1)] + (int)grayBuffer[(y + 1) * w + x] + (int)grayBuffer[(y + 1) * w + (x + 1)];
                    smoothedGray[y * w + x] = (unsigned char)(sum3x3 / 9);
                }
            }
        }
    }
    
    // ── Compute Sobel gradient magnitude map ──
    double *gradBuffer = (double *)calloc(w * h, sizeof(double));
    if (gradBuffer) {
        for (size_t y = 1; y < h - 1; y++) {
            for (size_t x = 1; x < w - 1; x++) {
                double p00 = (double)grayBuffer[(y - 1) * w + (x - 1)];
                double p01 = (double)grayBuffer[(y - 1) * w + x];
                double p02 = (double)grayBuffer[(y - 1) * w + (x + 1)];
                double p10 = (double)grayBuffer[y * w + (x - 1)];
                double p12 = (double)grayBuffer[y * w + (x + 1)];
                double p20 = (double)grayBuffer[(y + 1) * w + (x - 1)];
                double p21 = (double)grayBuffer[(y + 1) * w + x];
                double p22 = (double)grayBuffer[(y + 1) * w + (x + 1)];
                
                double gx = -p00 + p02 - 2.0 * p10 + 2.0 * p12 - p20 + p22;
                double gy = -p00 - 2.0 * p01 - p02 + p20 + 2.0 * p21 + p22;
                
                gradBuffer[y * w + x] = sqrt(gx * gx + gy * gy) / 1442.0;
            }
        }
    }
    
    const size_t tableW = w + 1;
    const size_t tableH = h + 1;
    const size_t totalCells = tableW * tableH;
    
    double *sum = (double *)calloc(totalCells, sizeof(double));
    double *sumSq = (double *)calloc(totalCells, sizeof(double));
    double *sumGrad = (double *)calloc(totalCells, sizeof(double));
    
    if (sum && sumSq && sumGrad) {
        for (size_t y = 0; y < h; y++) {
            double rowSum = 0.0;
            double rowSumSq = 0.0;
            double rowSumGrad = 0.0;
            const unsigned char *rowPtr = grayBuffer + (y * w);
            
            for (size_t x = 0; x < w; x++) {
                double val = (double)rowPtr[x] / 255.0;
                rowSum += val;
                rowSumSq += val * val;
                rowSumGrad += gradBuffer ? gradBuffer[y * w + x] : 0.0;
                
                size_t idx = (y + 1) * tableW + (x + 1);
                size_t aboveIdx = y * tableW + (x + 1);
                
                sum[idx] = sum[aboveIdx] + rowSum;
                sumSq[idx] = sumSq[aboveIdx] + rowSumSq;
                sumGrad[idx] = sumGrad[aboveIdx] + rowSumGrad;
            }
        }
    }
    
    free(grayBuffer);
    if (gradBuffer) free(gradBuffer);
    
    ii.width = w;
    ii.height = h;
    ii.sum = sum;
    ii.sumSq = sumSq;
    ii.sumGrad = sumGrad;
    ii.smoothedGray = smoothedGray;
    ii.rgbBuffer = rgbBuffer;
    return ii;
}

static void MacOSaiXDestroyIntegralImage(MacOSaiXIntegralImage *ii) {
    if (ii->sum) { free(ii->sum); ii->sum = NULL; }
    if (ii->sumSq) { free(ii->sumSq); ii->sumSq = NULL; }
    if (ii->sumGrad) { free(ii->sumGrad); ii->sumGrad = NULL; }
    if (ii->smoothedGray) { free(ii->smoothedGray); ii->smoothedGray = NULL; }
    if (ii->rgbBuffer) { free(ii->rgbBuffer); ii->rgbBuffer = NULL; }
    ii->width = 0;
    ii->height = 0;
}

// Evaluates standard deviation of luminance in any rect in O(1) constant time
static double MacOSaiXEvaluateVariance(const MacOSaiXIntegralImage *ii, CGRect rect, CGSize mosaicSize) {
    if (ii->width == 0 || ii->height == 0 || mosaicSize.width <= 0.0 || mosaicSize.height <= 0.0) {
        return 0.0;
    }
    
    double scaleX = (double)ii->width / (double)mosaicSize.width;
    double scaleY = (double)ii->height / (double)mosaicSize.height;
    
    double x0 = fmax(0.0, rect.origin.x * scaleX);
    double y0 = fmax(0.0, rect.origin.y * scaleY);
    double x1 = fmin((double)ii->width, (rect.origin.x + rect.size.width) * scaleX);
    double y1 = fmin((double)ii->height, (rect.origin.y + rect.size.height) * scaleY);
    
    size_t ix0 = (size_t)floor(x0);
    size_t iy0 = (size_t)floor(y0);
    size_t ix1 = (size_t)ceil(x1);
    size_t iy1 = (size_t)ceil(y1);
    
    if (ix1 <= ix0) ix1 = ix0 + 1;
    if (iy1 <= iy0) iy1 = iy0 + 1;
    if (ix1 > ii->width) ix1 = ii->width;
    if (iy1 > ii->height) iy1 = ii->height;
    
    size_t tableW = ii->width + 1;
    
    double A = ii->sum[iy0 * tableW + ix0];
    double B = ii->sum[iy0 * tableW + ix1];
    double C = ii->sum[iy1 * tableW + ix0];
    double D = ii->sum[iy1 * tableW + ix1];
    double sum = D - B - C + A;
    
    double Asq = ii->sumSq[iy0 * tableW + ix0];
    double Bsq = ii->sumSq[iy0 * tableW + ix1];
    double Csq = ii->sumSq[iy1 * tableW + ix0];
    double Dsq = ii->sumSq[iy1 * tableW + ix1];
    double sumSq = Dsq - Bsq - Csq + Asq;
    
    double count = (double)((ix1 - ix0) * (iy1 - iy0));
    if (count <= 1.0) return 0.0;
    
    double mean = sum / count;
    double variance = (sumSq / count) - (mean * mean);
    return (variance > 0.0) ? sqrt(variance) : 0.0;
}

// Evaluates mean Sobel gradient magnitude in any rect in O(1) constant time
static double MacOSaiXEvaluateGradient(const MacOSaiXIntegralImage *ii, CGRect rect, CGSize mosaicSize) {
    if (ii->width == 0 || ii->height == 0 || !ii->sumGrad || mosaicSize.width <= 0.0 || mosaicSize.height <= 0.0) {
        return 0.0;
    }
    
    double scaleX = (double)ii->width / (double)mosaicSize.width;
    double scaleY = (double)ii->height / (double)mosaicSize.height;
    
    double x0 = fmax(0.0, rect.origin.x * scaleX);
    double y0 = fmax(0.0, rect.origin.y * scaleY);
    double x1 = fmin((double)ii->width, (rect.origin.x + rect.size.width) * scaleX);
    double y1 = fmin((double)ii->height, (rect.origin.y + rect.size.height) * scaleY);
    
    size_t ix0 = (size_t)floor(x0);
    size_t iy0 = (size_t)floor(y0);
    size_t ix1 = (size_t)ceil(x1);
    size_t iy1 = (size_t)ceil(y1);
    
    if (ix1 <= ix0) ix1 = ix0 + 1;
    if (iy1 <= iy0) iy1 = iy0 + 1;
    if (ix1 > ii->width) ix1 = ii->width;
    if (iy1 > ii->height) iy1 = ii->height;
    
    size_t tableW = ii->width + 1;
    
    double A = ii->sumGrad[iy0 * tableW + ix0];
    double B = ii->sumGrad[iy0 * tableW + ix1];
    double C = ii->sumGrad[iy1 * tableW + ix0];
    double D = ii->sumGrad[iy1 * tableW + ix1];
    double sum = D - B - C + A;
    
    double count = (double)((ix1 - ix0) * (iy1 - iy0));
    if (count <= 1.0) return 0.0;
    
    return sum / count;
}

// Hybrid subdivision criterion: weighted blend of luminance stddev and edge density
// alpha = 1.0 → pure variance (legacy); alpha = 0.0 → pure edge density
static double MacOSaiXEvaluateHybrid(const MacOSaiXIntegralImage *ii, CGRect rect, CGSize mosaicSize, float alpha) {
    double sigma = MacOSaiXEvaluateVariance(ii, rect, mosaicSize);
    double edgeDensity = MacOSaiXEvaluateGradient(ii, rect, mosaicSize);
    
    // Normalize both to [0, 1] range using empirically calibrated max values
    // σ > 0.30 is effectively noise/maximum texture; edge density > 0.25 is dense edges
    double normSigma = fmin(1.0, sigma / 0.30);
    double normEdge = fmin(1.0, edgeDensity / 0.25);
    
    return (double)alpha * normSigma + (1.0 - (double)alpha) * normEdge;
}

// JuliaImages Extrema Range criterion: (max - min) on 3x3 pre-smoothed luminance buffer
// Guarantees that sharp 1-pixel contours (eyelash, lip, contour) are detected without area dilution
static double MacOSaiXEvaluateJuliaRange(const MacOSaiXIntegralImage *ii, CGRect rect, CGSize mosaicSize) {
    if (ii->width == 0 || ii->height == 0 || !ii->smoothedGray || mosaicSize.width <= 0.0 || mosaicSize.height <= 0.0) {
        return 0.0;
    }
    
    double scaleX = (double)ii->width / (double)mosaicSize.width;
    double scaleY = (double)ii->height / (double)mosaicSize.height;
    
    size_t ix0 = (size_t)floor(fmax(0.0, rect.origin.x * scaleX));
    size_t iy0 = (size_t)floor(fmax(0.0, rect.origin.y * scaleY));
    size_t ix1 = (size_t)ceil(fmin((double)ii->width, (rect.origin.x + rect.size.width) * scaleX));
    size_t iy1 = (size_t)ceil(fmin((double)ii->height, (rect.origin.y + rect.size.height) * scaleY));
    
    if (ix1 <= ix0) ix1 = ix0 + 1;
    if (iy1 <= iy0) iy1 = iy0 + 1;
    if (ix1 > ii->width) ix1 = ii->width;
    if (iy1 > ii->height) iy1 = ii->height;
    
    const size_t w = ii->width;
    const unsigned char *buf = ii->smoothedGray;
    unsigned char minVal = 255;
    unsigned char maxVal = 0;
    
    for (size_t y = iy0; y < iy1; y++) {
        const unsigned char *row = buf + (y * w);
        for (size_t x = ix0; x < ix1; x++) {
            unsigned char v = row[x];
            if (v < minVal) minVal = v;
            if (v > maxVal) maxVal = v;
        }
    }
    
    return (double)(maxVal - minVal) / 255.0;
}

// RGB Chebyshev Range criterion: max(ΔR, ΔG, ΔB) on 32-bit RGBA buffer
// Captures chromatic edges even when luminance is identical (e.g. red lips on skin)
static double MacOSaiXEvaluateColorRange(const MacOSaiXIntegralImage *ii, CGRect rect, CGSize mosaicSize) {
    if (ii->width == 0 || ii->height == 0 || !ii->rgbBuffer || mosaicSize.width <= 0.0 || mosaicSize.height <= 0.0) {
        return 0.0;
    }
    
    double scaleX = (double)ii->width / (double)mosaicSize.width;
    double scaleY = (double)ii->height / (double)mosaicSize.height;
    
    size_t ix0 = (size_t)floor(fmax(0.0, rect.origin.x * scaleX));
    size_t iy0 = (size_t)floor(fmax(0.0, rect.origin.y * scaleY));
    size_t ix1 = (size_t)ceil(fmin((double)ii->width, (rect.origin.x + rect.size.width) * scaleX));
    size_t iy1 = (size_t)ceil(fmin((double)ii->height, (rect.origin.y + rect.size.height) * scaleY));
    
    if (ix1 <= ix0) ix1 = ix0 + 1;
    if (iy1 <= iy0) iy1 = iy0 + 1;
    if (ix1 > ii->width) ix1 = ii->width;
    if (iy1 > ii->height) iy1 = ii->height;
    
    const size_t w = ii->width;
    const unsigned char *buf = ii->rgbBuffer;
    unsigned char minR = 255, maxR = 0;
    unsigned char minG = 255, maxG = 0;
    unsigned char minB = 255, maxB = 0;
    
    for (size_t y = iy0; y < iy1; y++) {
        const unsigned char *row = buf + (y * w * 4);
        for (size_t x = ix0; x < ix1; x++) {
            size_t px = x * 4;
            unsigned char r = row[px];
            unsigned char g = row[px + 1];
            unsigned char b = row[px + 2];
            if (r < minR) minR = r; if (r > maxR) maxR = r;
            if (g < minG) minG = g; if (g > maxG) maxG = g;
            if (b < minB) minB = b; if (b > maxB) maxB = b;
        }
    }
    
    unsigned char diffR = maxR - minR;
    unsigned char diffG = maxG - minG;
    unsigned char diffB = maxB - minB;
    unsigned char maxDiff = (diffR > diffG) ? ((diffR > diffB) ? diffR : diffB) : ((diffG > diffB) ? diffG : diffB);
    return (double)maxDiff / 255.0;
}

#pragma mark - Hierarchical Quadtree Decomposition & 2:1 Balancing

typedef struct MacOSaiXQuadNode {
    CGRect bounds;
    NSInteger depth;
    BOOL isLeaf;
    struct MacOSaiXQuadNode *children[4]; // 0: NW, 1: NE, 2: SW, 3: SE
} MacOSaiXQuadNode;

static MacOSaiXQuadNode *MacOSaiXCreateLeafNode(CGRect bounds, NSInteger depth) {
    MacOSaiXQuadNode *node = (MacOSaiXQuadNode *)calloc(1, sizeof(MacOSaiXQuadNode));
    if (!node) return NULL;
    node->bounds = bounds;
    node->depth = depth;
    node->isLeaf = YES;
    return node;
}

static void MacOSaiXSplitNode(MacOSaiXQuadNode *node) {
    if (!node || !node->isLeaf) return;
    
    float halfW = node->bounds.size.width * 0.5f;
    float halfH = node->bounds.size.height * 0.5f;
    float x = node->bounds.origin.x;
    float y = node->bounds.origin.y;
    
    node->isLeaf = NO;
    node->children[0] = MacOSaiXCreateLeafNode(CGRectMake(x, y, halfW, halfH), node->depth + 1);
    node->children[1] = MacOSaiXCreateLeafNode(CGRectMake(x + halfW, y, halfW, halfH), node->depth + 1);
    node->children[2] = MacOSaiXCreateLeafNode(CGRectMake(x, y + halfH, halfW, halfH), node->depth + 1);
    node->children[3] = MacOSaiXCreateLeafNode(CGRectMake(x + halfW, y + halfH, halfW, halfH), node->depth + 1);
}

static MacOSaiXQuadNode *MacOSaiXBuildQuadTree(CGRect rect,
                                               NSInteger depth,
                                               NSInteger maxDepth,
                                               float threshold,
                                               float minDimension,
                                               const MacOSaiXIntegralImage *ii,
                                               CGSize mosaicSize,
                                               float alpha,
                                               MacOSaiXQuadtreeAlgorithm algorithm)
{
    MacOSaiXQuadNode *node = MacOSaiXCreateLeafNode(rect, depth);
    if (!node) return NULL;
    
    double score = 0.0;
    if (ii && ii->width > 0) {
        switch (algorithm) {
            case MacOSaiXQuadtreeAlgorithmJuliaRange:
                score = MacOSaiXEvaluateJuliaRange(ii, rect, mosaicSize);
                break;
            case MacOSaiXQuadtreeAlgorithmColorRange:
                score = MacOSaiXEvaluateColorRange(ii, rect, mosaicSize);
                break;
            case MacOSaiXQuadtreeAlgorithmVariance:
            default:
                score = MacOSaiXEvaluateHybrid(ii, rect, mosaicSize, alpha);
                break;
        }
    }
    
    // Strict stopping condition:
    // Can subdivide ONLY IF depth < maxDepth AND both child dimensions will be >= minDimension
    const BOOL canSubdivide = (depth < maxDepth) &&
                              (rect.size.width >= (minDimension * 2.0f)) &&
                              (rect.size.height >= (minDimension * 2.0f)) &&
                              (score >= (double)threshold);
    
    if (canSubdivide) {
        MacOSaiXSplitNode(node);
        if (!node->isLeaf) {
            for (int i = 0; i < 4; i++) {
                MacOSaiXQuadNode *child = node->children[i];
                if (child) {
                    CGRect childRect = child->bounds;
                    free(child);
                    node->children[i] = MacOSaiXBuildQuadTree(childRect,
                                                             depth + 1,
                                                             maxDepth,
                                                             threshold,
                                                             minDimension,
                                                             ii,
                                                             mosaicSize,
                                                             alpha,
                                                             algorithm);
                }
            }
        }
    }
    return node;
}

static void MacOSaiXCollectLeaves(MacOSaiXQuadNode *node, NSMutableArray<NSValue *> *leavesList) {
    if (!node) return;
    if (node->isLeaf) {
        [leavesList addObject:[NSValue valueWithPointer:node]];
    } else {
        for (int i = 0; i < 4; i++) {
            if (node->children[i]) {
                MacOSaiXCollectLeaves(node->children[i], leavesList);
            }
        }
    }
}

static void MacOSaiXFreeQuadTree(MacOSaiXQuadNode *node) {
    if (!node) return;
    if (!node->isLeaf) {
        for (int i = 0; i < 4; i++) {
            if (node->children[i]) {
                MacOSaiXFreeQuadTree(node->children[i]);
            }
        }
    }
    free(node);
}

// Determines if two rectangles share an edge (Klein et al. 2002; Samet 1984)
static inline BOOL MacOSaiXNodesShareEdge(const CGRect a, const CGRect b) {
    const float eps = 0.1f;
    
    // Check horizontal adjacency (A's right touches B's left, or B's right touches A's left)
    const CGFloat aRight = a.origin.x + a.size.width;
    const CGFloat bRight = b.origin.x + b.size.width;
    const BOOL horizontalTouch = (fabs(aRight - b.origin.x) < (CGFloat)eps) ||
                                 (fabs(bRight - a.origin.x) < (CGFloat)eps);
    if (horizontalTouch) {
        CGFloat overlapMin = fmax(a.origin.y, b.origin.y);
        CGFloat overlapMax = fmin(a.origin.y + a.size.height, b.origin.y + b.size.height);
        if (overlapMax - overlapMin > (CGFloat)eps) {
            return YES;
        }
    }
    
    // Check vertical adjacency (A's bottom touches B's top, or B's bottom touches A's top)
    const CGFloat aBottom = a.origin.y + a.size.height;
    const CGFloat bBottom = b.origin.y + b.size.height;
    const BOOL verticalTouch = (fabs(aBottom - b.origin.y) < (CGFloat)eps) ||
                               (fabs(bBottom - a.origin.y) < (CGFloat)eps);
    if (verticalTouch) {
        CGFloat overlapMin = fmax(a.origin.x, b.origin.x);
        CGFloat overlapMax = fmin(a.origin.x + a.size.width, b.origin.x + b.size.width);
        if (overlapMax - overlapMin > (CGFloat)eps) {
            return YES;
        }
    }
    
    return NO;
}

// 2:1 Balanced Quadtree constraint: ensures adjacent leaf cells differ by at most 1 subdivision depth
static void MacOSaiXBalanceQuadNodes(NSArray<NSValue *> *rootNodes,
                                     NSMutableArray<NSValue *> *leavesList,
                                     NSInteger maxDepth,
                                     float minDimension)
{
    BOOL changed = YES;
    int pass = 0;
    const int maxPasses = 8;
    
    while (changed && pass < maxPasses) {
        changed = NO;
        pass++;
        
        NSUInteger count = leavesList.count;
        NSMutableSet<NSValue *> *nodesToSplit = [NSMutableSet set];
        
        for (NSUInteger i = 0; i < count; i++) {
            MacOSaiXQuadNode *nodeA = (MacOSaiXQuadNode *)[leavesList[i] pointerValue];
            if (!nodeA->isLeaf || nodeA->depth >= maxDepth) continue;
            if (nodeA->bounds.size.width < (minDimension * 2.0f) || nodeA->bounds.size.height < (minDimension * 2.0f)) continue;
            
            for (NSUInteger j = 0; j < count; j++) {
                if (i == j) continue;
                MacOSaiXQuadNode *nodeB = (MacOSaiXQuadNode *)[leavesList[j] pointerValue];
                
                // Only inspect if B is at least 2 levels deeper than A
                if (nodeB->depth < nodeA->depth + 2) continue;
                
                if (MacOSaiXNodesShareEdge(nodeA->bounds, nodeB->bounds)) {
                    [nodesToSplit addObject:leavesList[i]];
                    break;
                }
            }
        }
        
        if (nodesToSplit.count > 0) {
            changed = YES;
            for (NSValue *val in nodesToSplit) {
                MacOSaiXQuadNode *node = (MacOSaiXQuadNode *)[val pointerValue];
                MacOSaiXSplitNode(node);
            }
            
            [leavesList removeAllObjects];
            for (NSValue *rootVal in rootNodes) {
                MacOSaiXQuadNode *root = (MacOSaiXQuadNode *)[rootVal pointerValue];
                MacOSaiXCollectLeaves(root, leavesList);
            }
        }
    }
}

@implementation MacOSaiXShapes

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
{
    return [self generateShapesForType:type
                           targetImage:NULL
                            mosaicSize:mosaicSize
                           tilesAcross:across
                             tilesDown:down
                             curviness:curviness
                              tabRatio:tabRatio
                              maxDepth:3
                       detailThreshold:0.15f
                              balanced:YES
                           detailAlpha:0.5f
                             algorithm:MacOSaiXQuadtreeAlgorithmJuliaRange
                            minTileDim:16.0f];
}

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                               targetImage:(CGImageRef)targetImage
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
                                                  maxDepth:(NSInteger)maxDepth
                                           detailThreshold:(float)threshold
{
    return [self generateShapesForType:type
                           targetImage:targetImage
                            mosaicSize:mosaicSize
                           tilesAcross:across
                             tilesDown:down
                             curviness:curviness
                              tabRatio:tabRatio
                              maxDepth:maxDepth
                       detailThreshold:threshold
                              balanced:YES
                           detailAlpha:0.5f
                             algorithm:MacOSaiXQuadtreeAlgorithmJuliaRange
                            minTileDim:16.0f];
}

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                               targetImage:(CGImageRef)targetImage
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
                                                  maxDepth:(NSInteger)maxDepth
                                           detailThreshold:(float)threshold
                                                  balanced:(BOOL)balanced
{
    return [self generateShapesForType:type
                           targetImage:targetImage
                            mosaicSize:mosaicSize
                           tilesAcross:across
                             tilesDown:down
                             curviness:curviness
                              tabRatio:tabRatio
                              maxDepth:maxDepth
                       detailThreshold:threshold
                              balanced:balanced
                           detailAlpha:0.5f
                             algorithm:MacOSaiXQuadtreeAlgorithmJuliaRange
                            minTileDim:16.0f];
}

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                               targetImage:(CGImageRef)targetImage
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
                                                  maxDepth:(NSInteger)maxDepth
                                           detailThreshold:(float)threshold
                                                  balanced:(BOOL)balanced
                                               detailAlpha:(float)detailAlpha
{
    return [self generateShapesForType:type
                           targetImage:targetImage
                            mosaicSize:mosaicSize
                           tilesAcross:across
                             tilesDown:down
                             curviness:curviness
                              tabRatio:tabRatio
                              maxDepth:maxDepth
                       detailThreshold:threshold
                              balanced:balanced
                           detailAlpha:detailAlpha
                             algorithm:MacOSaiXQuadtreeAlgorithmJuliaRange
                            minTileDim:16.0f];
}

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                               targetImage:(CGImageRef)targetImage
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
                                                  maxDepth:(NSInteger)maxDepth
                                           detailThreshold:(float)threshold
                                                  balanced:(BOOL)balanced
                                               detailAlpha:(float)detailAlpha
                                                 algorithm:(MacOSaiXQuadtreeAlgorithm)algorithm
                                                minTileDim:(float)minTileDim
{
    const NSInteger xCount = (across > 0) ? across : 30;
    const NSInteger yCount = (down > 0) ? down : 20;
    
    NSMutableArray<MacOSaiXTileGeometry *> *results = [NSMutableArray arrayWithCapacity:(xCount * yCount)];
    
    if (type == MacOSaiXShapeTypeRectangular) {
        const float xSize = mosaicSize.width / (float)xCount;
        const float ySize = mosaicSize.height / (float)yCount;
        NSInteger index = 0;
        
        for (NSInteger y = 0; y < yCount; y++) {
            for (NSInteger x = 0; x < xCount; x++) {
                CGRect tileRect = CGRectMake(x * xSize, y * ySize, xSize, ySize);
                CGPathRef rectPath = CGPathCreateWithRect(tileRect, NULL);
                
                MacOSaiXTileGeometry *geom = [[MacOSaiXTileGeometry alloc] initWithIndex:index++
                                                                                  gridX:x
                                                                                  gridY:y
                                                                                 bounds:tileRect
                                                                                outline:rectPath];
                CGPathRelease(rectPath);
                [results addObject:geom];
            }
        }
    } else if (type == MacOSaiXShapeTypeQuadtree) {
        const float xSize = mosaicSize.width / (float)xCount;
        const float ySize = mosaicSize.height / (float)yCount;
        
        MacOSaiXIntegralImage ii = (targetImage != NULL) ? MacOSaiXCreateIntegralImage(targetImage) : (MacOSaiXIntegralImage){0, 0, NULL, NULL, NULL, NULL, NULL};
        
        const float effectiveMinDim = (minTileDim > 1.0f) ? minTileDim : 16.0f;
        const float effDepth = (maxDepth > 0) ? (float)maxDepth : 3.0f;
        const float minUnitW = xSize / powf(2.0f, effDepth);
        const float minUnitH = ySize / powf(2.0f, effDepth);
        
        NSMutableArray<NSValue *> *rootNodes = [NSMutableArray arrayWithCapacity:(xCount * yCount)];
        NSMutableArray<NSValue *> *leavesList = [NSMutableArray arrayWithCapacity:(xCount * yCount * 4)];
        
        for (NSInteger y = 0; y < yCount; y++) {
            for (NSInteger x = 0; x < xCount; x++) {
                CGRect baseRect = CGRectMake(x * xSize, y * ySize, xSize, ySize);
                MacOSaiXQuadNode *root = MacOSaiXBuildQuadTree(baseRect,
                                                              0,
                                                              maxDepth,
                                                              threshold,
                                                              effectiveMinDim,
                                                              &ii,
                                                              mosaicSize,
                                                              detailAlpha,
                                                              algorithm);
                if (root) {
                    [rootNodes addObject:[NSValue valueWithPointer:root]];
                    MacOSaiXCollectLeaves(root, leavesList);
                }
            }
        }
        
        // Apply 2:1 balancing pass to eliminate harsh size disparity while respecting minTileDim
        if (balanced) {
            MacOSaiXBalanceQuadNodes(rootNodes, leavesList, maxDepth, effectiveMinDim);
        }
        
        // Convert balanced leaves into MacOSaiXTileGeometry
        NSInteger tileIndex = 0;
        for (NSValue *leafVal in leavesList) {
            MacOSaiXQuadNode *leaf = (MacOSaiXQuadNode *)[leafVal pointerValue];
            CGRect rect = leaf->bounds;
            CGPathRef rectPath = CGPathCreateWithRect(rect, NULL);
            NSInteger gx = (minUnitW > 0.0f) ? (NSInteger)round(CGRectGetMidX(rect) / minUnitW) : 0;
            NSInteger gy = (minUnitH > 0.0f) ? (NSInteger)round(CGRectGetMidY(rect) / minUnitH) : 0;
            
            MacOSaiXTileGeometry *geom = [[MacOSaiXTileGeometry alloc] initWithIndex:tileIndex++
                                                                              gridX:gx
                                                                              gridY:gy
                                                                             bounds:rect
                                                                            outline:rectPath];
            CGPathRelease(rectPath);
            [results addObject:geom];
        }
        
        // Free all quadtree nodes
        for (NSValue *rootVal in rootNodes) {
            MacOSaiXQuadNode *root = (MacOSaiXQuadNode *)[rootVal pointerValue];
            MacOSaiXFreeQuadTree(root);
        }
        
        MacOSaiXDestroyIntegralImage(&ii);
    } else if (type == MacOSaiXShapeTypeHexagonal) {
        const float xSize = mosaicSize.width / ((float)xCount - (1.0f / 3.0f));
        const float ySize = mosaicSize.height / (float)yCount;
        NSInteger index = 0;
        
        for (NSInteger x = 0; x < xCount; x++) {
            NSInteger currentYCount = (x % 2 == 0) ? yCount : (yCount + 1);
            for (NSInteger y = 0; y < currentYCount; y++) {
                float originX = xSize * ((float)x - (1.0f / 3.0f));
                float originY = ySize * ((x % 2 == 0) ? (float)y : ((float)y - 0.5f));
                
                CGMutablePathRef hexPath = CGPathCreateMutable();
                
                #define CLAMP_X(v) fminf(fmaxf((v), 0.0f), (float)mosaicSize.width)
                #define CLAMP_Y(v) fminf(fmaxf((v), 0.0f), (float)mosaicSize.height)
                
                CGPathMoveToPoint(hexPath, NULL, CLAMP_X(originX + xSize / 3.0f), CLAMP_Y(originY));
                CGPathAddLineToPoint(hexPath, NULL, CLAMP_X(originX + xSize), CLAMP_Y(originY));
                CGPathAddLineToPoint(hexPath, NULL, CLAMP_X(originX + xSize * 4.0f / 3.0f), CLAMP_Y(originY + ySize / 2.0f));
                CGPathAddLineToPoint(hexPath, NULL, CLAMP_X(originX + xSize), CLAMP_Y(originY + ySize));
                CGPathAddLineToPoint(hexPath, NULL, CLAMP_X(originX + xSize / 3.0f), CLAMP_Y(originY + ySize));
                CGPathAddLineToPoint(hexPath, NULL, CLAMP_X(originX), CLAMP_Y(originY + ySize / 2.0f));
                CGPathCloseSubpath(hexPath);
                
                #undef CLAMP_X
                #undef CLAMP_Y
                
                CGRect bounds = CGPathGetBoundingBox(hexPath);
                MacOSaiXTileGeometry *geom = [[MacOSaiXTileGeometry alloc] initWithIndex:index++
                                                                                  gridX:x
                                                                                  gridY:y
                                                                                 bounds:bounds
                                                                                outline:hexPath];
                CGPathRelease(hexPath);
                [results addObject:geom];
            }
        }
    } else if (type == MacOSaiXShapeTypePuzzle) {
        // Tab directions matrix
        // xCount * 2 + 1 horizontal/vertical separators
        int tabTypes[xCount * 2 + 1][yCount];
        for (int x = 0; x < xCount * 2 + 1; x++) {
            for (int y = 0; y < yCount; y++) {
                if ((random() % 100) >= (int)(tabRatio * 100.0f)) {
                    tabTypes[x][y] = PuzzleTabTypeNoTab;
                } else {
                    tabTypes[x][y] = (random() % 2 == 0) ? PuzzleTabTypeInwards : PuzzleTabTypeOutwards;
                }
            }
        }
        
        // Curviness matrices
        float hCurviness[xCount + 1][yCount + 1];
        float vCurviness[xCount + 1][yCount + 1];
        for (int x = 0; x <= xCount; x++) {
            for (int y = 0; y <= yCount; y++) {
                hCurviness[x][y] = (y == 0 || y == yCount) ? 0.0f : ((float)(random() % 200 - 100) / 100.0f) * curviness;
                vCurviness[x][y] = (x == 0 || x == xCount) ? 0.0f : ((float)(random() % 200 - 100) / 100.0f) * curviness;
            }
        }
        
        const float xSize = mosaicSize.width / (float)xCount;
        const float ySize = mosaicSize.height / (float)yCount;
        NSInteger index = 0;
        
        for (NSInteger y = 0; y < yCount; y++) {
            for (NSInteger x = 0; x < xCount; x++) {
                CGRect tileBounds = CGRectMake(xSize * x, ySize * y, xSize, ySize);
                
                PuzzleTabType topTab = (y == yCount - 1) ? PuzzleTabTypeNoTab : (PuzzleTabType)tabTypes[x * 2][y];
                PuzzleTabType leftTab = (x == 0) ? PuzzleTabTypeNoTab : (PuzzleTabType)tabTypes[x * 2 - 1][y];
                PuzzleTabType rightTab = (x == xCount - 1) ? PuzzleTabTypeNoTab : (PuzzleTabType)(-tabTypes[x * 2 + 1][y]);
                PuzzleTabType bottomTab = (y == 0) ? PuzzleTabTypeNoTab : (PuzzleTabType)(-tabTypes[x * 2][y - 1]);
                
                CGPathRef piecePath = createPuzzlePiecePath(tileBounds,
                                                           topTab, leftTab, rightTab, bottomTab,
                                                           hCurviness[x][y + 1],
                                                           -vCurviness[x][y + 1],
                                                           -hCurviness[x + 1][y + 1],
                                                           -vCurviness[x + 1][y + 1],
                                                           hCurviness[x][y],
                                                           vCurviness[x][y],
                                                           -hCurviness[x + 1][y],
                                                           vCurviness[x + 1][y]);
                
                CGRect bounds = CGPathGetBoundingBox(piecePath);
                MacOSaiXTileGeometry *geom = [[MacOSaiXTileGeometry alloc] initWithIndex:index++
                                                                                  gridX:x
                                                                                  gridY:y
                                                                                 bounds:bounds
                                                                                outline:piecePath];
                CGPathRelease(piecePath);
                [results addObject:geom];
            }
        }
    }
    
    return results;
}

@end
