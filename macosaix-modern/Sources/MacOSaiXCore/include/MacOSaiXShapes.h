#ifndef MacOSaiXShapes_h
#define MacOSaiXShapes_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, MacOSaiXShapeType) {
    MacOSaiXShapeTypeRectangular = 0,
    MacOSaiXShapeTypeHexagonal = 1,
    MacOSaiXShapeTypePuzzle = 2
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

@end

#endif /* MacOSaiXShapes_h */
