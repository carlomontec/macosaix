#import "MacOSaiXTile.h"

@implementation MacOSaiXTile {
    NSMutableData *_targetPixelsData;
    NSMutableData *_maskPixelsData;
}

- (instancetype)initWithGeometry:(MacOSaiXTileGeometry *)geometry
{
    self = [super init];
    if (self) {
        _geometry = geometry;
        _bestScore = 1.0f; // 1.0 = worst match
        _bestImageIdentifier = nil;
        _bestImageURL = nil;
    }
    return self;
}

- (NSData *)targetPixels
{
    return _targetPixelsData;
}

- (NSData *)maskPixels
{
    return _maskPixelsData;
}

- (void)extractTargetThumbnailFromImage:(CGImageRef)targetImage
                             mosaicSize:(CGSize)mosaicSize
{
    const int size = 16;
    const int bytesPerRow = size * 4;
    _targetPixelsData = [NSMutableData dataWithLength:size * bytesPerRow];
    unsigned char *buffer = (unsigned char *)_targetPixelsData.mutableBytes;
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(buffer,
                                                 size,
                                                 size,
                                                 8,
                                                 bytesPerRow,
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    
    if (!context) return;
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    // Invert Y coordinate space because CGImage uses top-down / bottom-up convention
    // Draw the tile's sub-rectangle of targetImage into [0, 0, 16, 16]
    CGRect bounds = _geometry.bounds;
    
    // Scale from mosaic size to target image pixel size
    const size_t imgWidth = CGImageGetWidth(targetImage);
    const size_t imgHeight = CGImageGetHeight(targetImage);
    
    const float scaleX = (float)imgWidth / (float)mosaicSize.width;
    const float scaleY = (float)imgHeight / (float)mosaicSize.height;
    
    CGRect cropRect = CGRectMake(bounds.origin.x * scaleX,
                                 bounds.origin.y * scaleY,
                                 bounds.size.width * scaleX,
                                 bounds.size.height * scaleY);
    
    CGImageRef subImage = CGImageCreateWithImageInRect(targetImage, cropRect);
    if (subImage) {
        CGContextDrawImage(context, CGRectMake(0, 0, size, size), subImage);
        CGImageRelease(subImage);
    } else {
        // Fallback: draw full image positioned
        CGContextDrawImage(context, CGRectMake(0, 0, size, size), targetImage);
    }
    
    CGContextRelease(context);
}

- (void)rasterizeMaskWithResolution:(int)resolution
{
    const int size = (resolution > 0) ? resolution : 16;
    const int bytesPerRow = size;
    _maskPixelsData = [NSMutableData dataWithLength:size * bytesPerRow];
    unsigned char *buffer = (unsigned char *)_maskPixelsData.mutableBytes;
    
    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(buffer,
                                                 size,
                                                 size,
                                                 8,
                                                 bytesPerRow,
                                                 graySpace,
                                                 kCGImageAlphaNone);
    CGColorSpaceRelease(graySpace);
    
    if (!context) return;
    
    // Clear to black (0)
    CGContextSetGrayFillColor(context, 0.0f, 1.0f);
    CGContextFillRect(context, CGRectMake(0, 0, size, size));
    
    // Fill tile path with white (1.0)
    CGContextSetGrayFillColor(context, 1.0f, 1.0f);
    
    CGRect bounds = _geometry.bounds;
    if (bounds.size.width > 0.001f && bounds.size.height > 0.001f) {
        CGContextScaleCTM(context,
                          (float)size / bounds.size.width,
                          (float)size / bounds.size.height);
        CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
        
        CGContextAddPath(context, _geometry.outline);
        CGContextFillPath(context);
    }
    
    CGContextRelease(context);
}

@end
