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

@implementation MacOSaiXShapes

+ (NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                mosaicSize:(CGSize)mosaicSize
                                               tilesAcross:(NSInteger)across
                                                 tilesDown:(NSInteger)down
                                                 curviness:(float)curviness
                                                  tabRatio:(float)tabRatio
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
