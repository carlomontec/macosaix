#ifndef MacOSaiXShapes_h
#define MacOSaiXShapes_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, MacOSaiXShapeType) {
    MacOSaiXShapeTypeRectangular = 0,
    MacOSaiXShapeTypeHexagonal = 1,
    MacOSaiXShapeTypePuzzle = 2,
    MacOSaiXShapeTypeQuadtree = 3
};

typedef NS_ENUM(NSInteger, MacOSaiXQuadtreeAlgorithm) {
    MacOSaiXQuadtreeAlgorithmJuliaRange = 0,
    MacOSaiXQuadtreeAlgorithmColorRange = 1,
    MacOSaiXQuadtreeAlgorithmVariance = 2
};

@interface MacOSaiXTileGeometry : NSObject

@property (nonatomic, readonly) NSInteger tileIndex;
@property (nonatomic, readonly) NSInteger gridX;
@property (nonatomic, readonly) NSInteger gridY;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly, nonnull) CGPathRef outline;

- (nonnull instancetype)initWithIndex:(NSInteger)index
                                gridX:(NSInteger)gx
                                gridY:(NSInteger)gy
                               bounds:(CGRect)bounds
                              outline:(nonnull CGPathRef)outline;

@end

@interface MacOSaiXShapes : NSObject

+ (nonnull NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                        mosaicSize:(CGSize)mosaicSize
                                                       tilesAcross:(NSInteger)across
                                                         tilesDown:(NSInteger)down
                                                         curviness:(float)curviness
                                                          tabRatio:(float)tabRatio
NS_SWIFT_NAME(generateShapes(for:mosaicSize:across:down:curviness:tabRatio:));

+ (nonnull NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                       targetImage:(nullable CGImageRef)targetImage
                                                        mosaicSize:(CGSize)mosaicSize
                                                       tilesAcross:(NSInteger)across
                                                         tilesDown:(NSInteger)down
                                                         curviness:(float)curviness
                                                          tabRatio:(float)tabRatio
                                                          maxDepth:(NSInteger)maxDepth
                                                   detailThreshold:(float)threshold
NS_SWIFT_NAME(generateShapes(for:targetImage:mosaicSize:across:down:curviness:tabRatio:maxDepth:detailThreshold:));

+ (nonnull NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                       targetImage:(nullable CGImageRef)targetImage
                                                        mosaicSize:(CGSize)mosaicSize
                                                       tilesAcross:(NSInteger)across
                                                         tilesDown:(NSInteger)down
                                                         curviness:(float)curviness
                                                          tabRatio:(float)tabRatio
                                                          maxDepth:(NSInteger)maxDepth
                                                   detailThreshold:(float)threshold
                                                          balanced:(BOOL)balanced
NS_SWIFT_NAME(generateShapes(for:targetImage:mosaicSize:across:down:curviness:tabRatio:maxDepth:detailThreshold:balanced:));

+ (nonnull NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                       targetImage:(nullable CGImageRef)targetImage
                                                        mosaicSize:(CGSize)mosaicSize
                                                       tilesAcross:(NSInteger)across
                                                         tilesDown:(NSInteger)down
                                                         curviness:(float)curviness
                                                          tabRatio:(float)tabRatio
                                                          maxDepth:(NSInteger)maxDepth
                                                   detailThreshold:(float)threshold
                                                          balanced:(BOOL)balanced
                                                       detailAlpha:(float)detailAlpha
NS_SWIFT_NAME(generateShapes(for:targetImage:mosaicSize:across:down:curviness:tabRatio:maxDepth:detailThreshold:balanced:detailAlpha:));

+ (nonnull NSArray<MacOSaiXTileGeometry *> *)generateShapesForType:(MacOSaiXShapeType)type
                                                       targetImage:(nullable CGImageRef)targetImage
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
NS_SWIFT_NAME(generateShapes(for:targetImage:mosaicSize:across:down:curviness:tabRatio:maxDepth:detailThreshold:balanced:detailAlpha:algorithm:minTileDim:));

@end

#endif /* MacOSaiXShapes_h */
